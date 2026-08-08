package com.iem.chat;

import com.iem.chat.AnalyticsCatalog.Dimension;
import com.iem.chat.AnalyticsCatalog.Metric;
import com.iem.exception.ApiException;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class AnalyticsService {

    private static final Logger log = LoggerFactory.getLogger(AnalyticsService.class);

    private static final ZoneId ZONE = ZoneId.of("Asia/Kolkata");

    private static final List<String> PERIODS = List.of(
            "today", "yesterday", "last_7_days", "last_30_days", "this_month", "all_time");

    private final EntityManager entityManager;

    public AnalyticsService(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    public static List<String> periods() {
        return PERIODS;
    }

    public record Range(Instant from, Instant to, String label) {
    }

    public static Range resolve(String period) {
        String key = period == null || period.isBlank() ? "last_30_days" : period.trim().toLowerCase();
        LocalDate today = LocalDate.now(ZONE);

        return switch (key) {
            case "today" -> new Range(start(today), start(today.plusDays(1)), "today");
            case "yesterday" -> new Range(start(today.minusDays(1)), start(today), "yesterday");
            case "last_7_days" -> new Range(start(today.minusDays(6)), start(today.plusDays(1)),
                    "the last 7 days");
            case "this_month" -> new Range(start(today.withDayOfMonth(1)), start(today.plusDays(1)),
                    "this month");
            case "all_time" -> new Range(null, null, "all time");
            case "last_30_days" -> new Range(start(today.minusDays(29)), start(today.plusDays(1)),
                    "the last 30 days");
            default -> throw new ApiException("Unknown period: " + period, 400);
        };
    }

    private static Instant start(LocalDate date) {
        return date.atStartOfDay(ZONE).toInstant();
    }

    @Transactional(readOnly = true)
    public Map<String, Object> run(String metricKey, String dimensionKey, String period,
                                   UUID municipalityScope, int limit) {

        Metric metric = AnalyticsCatalog.METRICS.get(
                metricKey == null ? "" : metricKey.trim().toLowerCase());

        if (metric == null) {
            throw new ApiException("Unknown metric. Available: "
                    + String.join(", ", AnalyticsCatalog.metricKeys()), 400);
        }

        Dimension dimension;
        try {
            dimension = dimensionKey == null || dimensionKey.isBlank()
                    ? Dimension.NONE
                    : Dimension.valueOf(dimensionKey.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException("Unknown dimension: " + dimensionKey, 400);
        }

        if (dimension != Dimension.NONE && !metric.dimensions().containsKey(dimension)) {
            throw new ApiException(metric.key() + " cannot be split by " + dimension
                    + ". Supported: " + metric.dimensions().keySet(), 400);
        }

        Range range = resolve(period);
        String groupExpression = dimension == Dimension.NONE ? null : metric.dimensions().get(dimension);

        StringBuilder sql = new StringBuilder("select ");
        if (groupExpression != null) {
            sql.append(groupExpression).append(" as bucket, ");
        }
        sql.append(metric.aggregate()).append(" as value from ").append(metric.from()).append(" where 1=1");

        if (metric.where() != null) {
            sql.append(" and ").append(metric.where());
        }
        if (range.from() != null) {
            sql.append(" and ").append(metric.dateColumn()).append(" >= :fromTs");
            sql.append(" and ").append(metric.dateColumn()).append(" < :toTs");
        }
        if (municipalityScope != null) {
            sql.append(" and ").append(metric.municipalityColumn()).append(" = :municipality");
        }
        if (groupExpression != null) {
            sql.append(" group by ").append(groupExpression);
            sql.append(dimension == Dimension.DAY ? " order by 1 asc" : " order by 2 desc");
            sql.append(" limit ").append(Math.min(Math.max(limit, 1), 60));
        }

        Query query = entityManager.createNativeQuery(sql.toString());
        if (range.from() != null) {
            query.setParameter("fromTs", range.from());
            query.setParameter("toTs", range.to());
        }
        if (municipalityScope != null) {
            query.setParameter("municipality", municipalityScope);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("metric", metric.key());
        result.put("description", metric.description());
        result.put("period", range.label());
        result.put("scope", municipalityScope == null ? "platform" : "your municipality");

        try {
            if (groupExpression == null) {
                Object value = query.getSingleResult();
                result.put("value", number(value));
                return result;
            }

            List<?> rows = query.getResultList();
            List<Map<String, Object>> breakdown = new ArrayList<>();
            BigDecimal total = BigDecimal.ZERO;

            for (Object row : rows) {
                Object[] cells = (Object[]) row;
                BigDecimal value = number(cells[1]);
                total = total.add(value);
                Map<String, Object> entry = new LinkedHashMap<>();
                entry.put("bucket", label(cells[0]));
                entry.put("value", value);
                breakdown.add(entry);
            }

            result.put("groupedBy", dimension.name().toLowerCase());
            result.put("total", total);
            result.put("breakdown", breakdown);
            return result;

        } catch (RuntimeException e) {
            log.error("Analytics query failed for metric {}: {}", metric.key(), e.getMessage());
            throw new ApiException("That metric could not be computed", 500);
        }
    }

    private static BigDecimal number(Object value) {
        if (value == null) {
            return BigDecimal.ZERO;
        }
        BigDecimal decimal = value instanceof BigDecimal b ? b : new BigDecimal(value.toString());
        return decimal.stripTrailingZeros().scale() <= 0
                ? decimal.setScale(0, RoundingMode.HALF_UP)
                : decimal.setScale(2, RoundingMode.HALF_UP);
    }

    private static String label(Object value) {
        if (value == null) {
            return "Unknown";
        }
        if (value instanceof java.sql.Timestamp ts) {
            return ts.toInstant().atZone(ZONE).toLocalDate().toString();
        }
        if (value instanceof Instant instant) {
            return instant.atZone(ZONE).toLocalDate().toString();
        }
        return value.toString();
    }
}
