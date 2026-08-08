package com.iem.admin;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.iem.admin.dto.SystemHealthResponse;
import com.iem.geo.MapboxClient;
import com.iem.mail.MailService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class SystemHealthService {

    private static final Logger log = LoggerFactory.getLogger(SystemHealthService.class);

    private static final String HEALTHY = "HEALTHY";
    private static final String DOWN = "DOWN";
    private static final String DEGRADED = "DEGRADED";
    private static final String DISABLED = "DISABLED";

    private final RestClient client;
    private final JdbcTemplate jdbcTemplate;
    private final MapboxClient mapbox;
    private final MailService mailService;
    private final String detectionBaseUrl;

    public SystemHealthService(JdbcTemplate jdbcTemplate,
                               MapboxClient mapbox,
                               MailService mailService,
                               @Value("${detection.base-url}") String detectionBaseUrl) {
        this.jdbcTemplate = jdbcTemplate;
        this.mapbox = mapbox;
        this.mailService = mailService;
        this.detectionBaseUrl = detectionBaseUrl;

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(2));
        factory.setReadTimeout(Duration.ofSeconds(4));
        this.client = RestClient.builder().requestFactory(factory).build();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record DetectionHealth(String status, String weights, Boolean cloudinary) {
    }

    public SystemHealthResponse check() {

        List<SystemHealthResponse.Service> services = new ArrayList<>();

        services.add(new SystemHealthResponse.Service("api-java", "Spring Boot 3.5", HEALTHY, 0L,
                "Auth, scans, pickups, routing, marketplace, admin"));

        services.add(database());
        services.add(detection());
        services.add(new SystemHealthResponse.Service("Mapbox", "Matrix + Directions",
                mapbox.isConfigured() ? HEALTHY : DISABLED, null,
                mapbox.isConfigured()
                        ? "Road distances and route ordering"
                        : "No token set - falls back to straight-line ordering"));
        services.add(new SystemHealthResponse.Service("Resend", "OTP, welcome, alerts",
                mailService.isEnabled() ? HEALTHY : DISABLED, null,
                mailService.isEnabled()
                        ? "Live email delivery"
                        : "MAIL_ENABLED=false - OTPs are printed to the application log"));

        return new SystemHealthResponse(Instant.now().toString(), services);
    }

    private SystemHealthResponse.Service database() {
        long started = System.currentTimeMillis();
        try {
            jdbcTemplate.queryForObject("select 1", Integer.class);
            return new SystemHealthResponse.Service("PostgreSQL", "Hikari pool", HEALTHY,
                    System.currentTimeMillis() - started, "Answered select 1");
        } catch (Exception e) {
            log.error("Database health check failed: {}", e.getMessage());
            return new SystemHealthResponse.Service("PostgreSQL", "Hikari pool", DOWN, null,
                    "Query failed: " + e.getMessage());
        }
    }

    private SystemHealthResponse.Service detection() {
        long started = System.currentTimeMillis();
        try {
            DetectionHealth health = client.get()
                    .uri(detectionBaseUrl + "/health")
                    .retrieve()
                    .body(DetectionHealth.class);

            long latency = System.currentTimeMillis() - started;

            if (health == null || !"ok".equalsIgnoreCase(health.status())) {
                return new SystemHealthResponse.Service("api-python", detectionBaseUrl, DEGRADED,
                        latency, "Responded but not with status ok");
            }

            String note = "Weights " + health.weights()
                    + (Boolean.TRUE.equals(health.cloudinary())
                            ? ", image upload on"
                            : ", image upload off");

            return new SystemHealthResponse.Service("api-python",
                    "FastAPI + YOLO · " + detectionBaseUrl, HEALTHY, latency, note);

        } catch (Exception e) {
            log.warn("Detection service health check failed: {}", e.getMessage());
            return new SystemHealthResponse.Service("api-python",
                    "FastAPI + YOLO · " + detectionBaseUrl, DOWN, null,
                    "Unreachable - scanning will return 503");
        }
    }
}
