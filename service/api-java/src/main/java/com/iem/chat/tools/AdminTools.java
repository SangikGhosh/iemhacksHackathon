package com.iem.chat.tools;

import com.iem.admin.AdminRepository;
import com.iem.chat.AnalyticsCatalog;
import com.iem.chat.AnalyticsService;
import com.iem.chat.ChatTool;
import com.iem.chat.ToolSchema;
import com.iem.chat.ToolSet;
import com.iem.enums.Role;
import com.iem.geo.CollectionPointRepository;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.Municipality;
import com.iem.model.User;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static com.iem.chat.tools.UserTools.clamp;

@Component
public class AdminTools implements ToolSet {

    private final ToolSchema schema;
    private final AnalyticsService analyticsService;
    private final AdminRepository adminRepository;
    private final MunicipalityRepository municipalityRepository;
    private final CollectionPointRepository pointRepository;

    public AdminTools(ToolSchema schema,
                      AnalyticsService analyticsService,
                      AdminRepository adminRepository,
                      MunicipalityRepository municipalityRepository,
                      CollectionPointRepository pointRepository) {
        this.schema = schema;
        this.analyticsService = analyticsService;
        this.adminRepository = adminRepository;
        this.municipalityRepository = municipalityRepository;
        this.pointRepository = pointRepository;
    }

    @Override
    public List<ChatTool> tools() {
        return List.of(analytics(), snapshot(), findPeople(), municipalities(), collectionPoints());
    }

    private ChatTool analytics() {
        return new ChatTool.Simple(
                "query_analytics",
                "Run an aggregate query over platform data. Pick one metric, optionally split it "
                        + "by a dimension and restrict it to a period. Use this for any counting, "
                        + "totalling, trend or breakdown question. Metrics: "
                        + AnalyticsCatalog.describe(),
                ADMINS,
                schema.object()
                        .enumeration("metric", "What to measure", AnalyticsCatalog.metricKeys())
                        .enumeration("group_by", "Optional split. Use 'day' for a trend, 'role' or "
                                        + "'status' or 'material' or 'bin' for a breakdown, "
                                        + "'municipality' to compare areas",
                                List.of("none", "day", "role", "status", "material", "bin", "municipality"))
                        .enumeration("period", "Time window. Defaults to last_30_days, so pass "
                                        + "all_time whenever the user asks for a lifetime or "
                                        + "overall figure rather than a recent one",
                                AnalyticsService.periods())
                        .integer("limit", "Maximum rows when grouping, 1 to 60")
                        .require("metric")
                        .build(),
                (ctx, args) -> analyticsService.run(
                        args.path("metric").asText(""),
                        args.path("group_by").asText("none"),
                        args.path("period").asText("last_30_days"),
                        ctx.scope(),
                        clamp(args.path("limit").asInt(15), 1, 60)));
    }

    private ChatTool snapshot() {
        return new ChatTool.Simple(
                "get_operations_snapshot",
                "Live totals across the whole platform right now: accounts by role, scans, "
                        + "pickups, waste diverted, points issued, marketplace turnover and "
                        + "collection point count",
                ADMINS,
                schema.empty(),
                (ctx, args) -> {
                    Map<String, Long> byRole = new LinkedHashMap<>();
                    for (Object[] row : adminRepository.usersByRole()) {
                        byRole.put(String.valueOf(row[0]), ((Number) row[1]).longValue());
                    }

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("scope", ctx.isPlatformWide() ? "platform" : "your municipality");
                    out.put("accountsByRole", byRole);
                    out.put("totalScans", adminRepository.totalScans());
                    out.put("totalObjectsDetected", adminRepository.totalObjects());
                    out.put("totalPickups", adminRepository.totalPickups());
                    out.put("completedPickups", adminRepository.completedPickups());
                    out.put("wasteDivertedKg", adminRepository.wasteDiverted());
                    out.put("carbonSavedKg", adminRepository.totalCarbon());
                    out.put("greenPointsIssued", adminRepository.totalPoints());
                    out.put("openListings", adminRepository.openListings());
                    out.put("soldListings", adminRepository.soldListings());
                    out.put("marketplaceTurnover", adminRepository.tradedValue());
                    out.put("collectionPoints", ctx.isPlatformWide()
                            ? pointRepository.count()
                            : pointRepository.countByMunicipalityId(ctx.municipalityId()));

                    Map<String, Object> pickupsByStatus = new LinkedHashMap<>();
                    for (Object[] row : adminRepository.pickupsByStatus()) {
                        pickupsByStatus.put(String.valueOf(row[0]), ((Number) row[1]).longValue());
                    }
                    out.put("pickupsByStatus", pickupsByStatus);

                    if (!ctx.isPlatformWide()) {
                        out.put("note", "Totals other than collection points are platform wide. "
                                + "Use query_analytics for figures scoped to your municipality.");
                    }
                    return out;
                });
    }

    private ChatTool findPeople() {
        return new ChatTool.Simple(
                "find_people",
                "List or search the people on the platform. Use this whenever the user asks "
                        + "who their collectors, recyclers, citizens or admins are, how many "
                        + "there are, or wants to look someone up by name or email. A municipal "
                        + "admin only sees staff belonging to their own municipality",
                ADMINS,
                schema.object()
                        .string("search", "Name or email fragment")
                        .enumeration("role", "Filter by role",
                                List.of("CITIZEN", "COLLECTOR", "RECYCLER", "MUNICIPAL_ADMIN", "SUPER_ADMIN"))
                        .integer("limit", "How many to return, 1 to 20")
                        .build(),
                (ctx, args) -> {
                    int limit = clamp(args.path("limit").asInt(10), 1, 20);
                    String search = args.path("search").asText("").trim();

                    Role filter = null;
                    String roleArg = args.path("role").asText("").trim();
                    if (!roleArg.isEmpty()) {
                        try {
                            filter = Role.valueOf(roleArg.toUpperCase());
                        } catch (IllegalArgumentException e) {
                            return Map.of("error", "Unknown role: " + roleArg);
                        }
                    }

                    boolean staffRole = filter == Role.COLLECTOR || filter == Role.RECYCLER
                            || filter == Role.MUNICIPAL_ADMIN;
                    UUID scope = ctx.isPlatformWide() || !staffRole ? null : ctx.municipalityId();
                    String term = search.isEmpty() ? null : "%" + search.toLowerCase() + "%";

                    List<User> found = adminRepository.search(filter, scope, term,
                            PageRequest.of(0, limit)).getContent();

                    List<Map<String, Object>> rows = new ArrayList<>();
                    for (User u : found) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("name", u.getFullName());
                        row.put("email", u.getEmail());
                        row.put("role", u.getRole().name());
                        row.put("points", u.getPoints());
                        row.put("walletBalance", u.getWalletBalance());
                        row.put("active", u.isActive());
                        row.put("joinedAt", u.getCreatedAt());
                        rows.add(row);
                    }

                    return Map.of("count", rows.size(), "people", rows);
                });
    }

    private ChatTool municipalities() {
        return new ChatTool.Simple(
                "get_municipalities",
                "Every municipality on the platform with its depot and collection point count",
                SUPER_ADMIN,
                schema.empty(),
                (ctx, args) -> {
                    List<Map<String, Object>> rows = new ArrayList<>();
                    for (Municipality m : municipalityRepository.findAll()) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("code", m.getCode());
                        row.put("name", m.getName());
                        row.put("district", m.getDistrict());
                        row.put("state", m.getState());
                        row.put("depot", m.getDepotName());
                        row.put("active", m.isActive());
                        row.put("collectionPoints", pointRepository.countByMunicipalityId(m.getId()));
                        rows.add(row);
                    }
                    return Map.of("count", rows.size(), "municipalities", rows);
                });
    }

    private ChatTool collectionPoints() {
        return new ChatTool.Simple(
                "get_collection_points",
                "Collection points, drop-off bins, scrap yards and compost hubs. A municipal "
                        + "admin sees only their own area",
                ADMINS,
                schema.object().integer("limit", "How many to return, 1 to 40").build(),
                (ctx, args) -> {
                    int limit = clamp(args.path("limit").asInt(10), 1, 40);

                    var points = ctx.isPlatformWide()
                            ? pointRepository.findAllWithMunicipality()
                            : pointRepository.findByMunicipalityIdWithMunicipality(ctx.municipalityId());

                    Map<String, Long> byType = new LinkedHashMap<>();
                    points.forEach(p -> byType.merge(p.getType(), 1L, Long::sum));

                    List<Map<String, Object>> rows = points.stream().limit(limit).map(p -> {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("code", p.getCode());
                        row.put("name", p.getName());
                        row.put("type", p.getType());
                        row.put("locality", p.getLocality());
                        row.put("ward", p.getWard());
                        row.put("municipality", p.getMunicipality().getName());
                        row.put("active", p.isActive());
                        return row;
                    }).toList();

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("total", points.size());
                    out.put("byType", byType);
                    out.put("showing", rows.size());
                    out.put("points", rows);
                    return out;
                });
    }
}
