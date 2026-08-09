package com.iem.chat;

import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Component
public class PriceCatalog {

    private static final Logger log = LoggerFactory.getLogger(PriceCatalog.class);

    private final RestClient client;
    private final Duration ttl;

    private volatile Map<String, Entry> cache = Map.of();
    private volatile Instant fetchedAt = Instant.EPOCH;

    public record Entry(String key,
                        String label,
                        String bin,
                        boolean recyclable,
                        double pricePerKg,
                        int rewardPoints,
                        double carbonSavedKg,
                        double unitWeightKg,
                        String category,
                        String stream) {
    }

    public PriceCatalog(@Value("${detection.base-url}") String baseUrl,
                        @Value("${chat.price-cache-minutes:30}") long cacheMinutes) {

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(5));
        factory.setReadTimeout(Duration.ofSeconds(10));

        this.client = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(factory)
                .build();
        this.ttl = Duration.ofMinutes(cacheMinutes);
    }

    public Map<String, Entry> all() {
        if (!cache.isEmpty() && Instant.now().isBefore(fetchedAt.plus(ttl))) {
            return cache;
        }
        refresh();
        return cache;
    }

    private synchronized void refresh() {
        if (!cache.isEmpty() && Instant.now().isBefore(fetchedAt.plus(ttl))) {
            return;
        }
        try {
            JsonNode body = client.get()
                    .uri("/api/v1/waste-types")
                    .retrieve()
                    .body(JsonNode.class);

            if (body == null || !body.hasNonNull("types")) {
                return;
            }

            Map<String, Entry> loaded = new LinkedHashMap<>();
            body.get("types").fields().forEachRemaining(field -> {
                JsonNode v = field.getValue();
                loaded.put(field.getKey(), new Entry(
                        field.getKey(),
                        v.path("label").asText(field.getKey()),
                        v.path("bin").asText(""),
                        v.path("recyclable").asBoolean(false),
                        v.path("estimatedPrice").path("value").asDouble(0),
                        v.path("rewardPoints").asInt(0),
                        v.path("carbonSavedKg").asDouble(0),
                        v.path("unitWeightKg").asDouble(0),
                        v.path("category").asText(""),
                        v.path("stream").asText("")));
            });

            cache = Map.copyOf(loaded);
            fetchedAt = Instant.now();
            log.info("Loaded {} waste types into the price catalog", cache.size());

        } catch (RuntimeException e) {
            log.warn("Could not refresh the price catalog: {}", e.getMessage());
        }
    }

    public List<Entry> search(String term) {
        Map<String, Entry> types = all();
        if (term == null || term.isBlank()) {
            return new ArrayList<>(types.values());
        }

        String needle = term.toLowerCase(Locale.ROOT).trim();

        List<Entry> exact = types.values().stream()
                .filter(e -> e.key().equalsIgnoreCase(needle) || e.label().equalsIgnoreCase(needle))
                .toList();
        if (!exact.isEmpty()) {
            return exact;
        }

        List<Entry> partial = types.values().stream()
                .filter(e -> e.key().replace('_', ' ').contains(needle)
                        || e.label().toLowerCase(Locale.ROOT).contains(needle)
                        || needle.contains(e.label().toLowerCase(Locale.ROOT))
                        || e.category().toLowerCase(Locale.ROOT).equals(needle))
                .toList();

        return partial;
    }

    public boolean isAvailable() {
        return !all().isEmpty();
    }
}
