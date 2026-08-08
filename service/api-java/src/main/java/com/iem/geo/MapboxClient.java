package com.iem.geo;

import com.iem.exception.ApiException;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import java.time.Duration;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class MapboxClient {

    private static final Logger log = LoggerFactory.getLogger(MapboxClient.class);

    public static final int MATRIX_MAX_COORDS = 25;

    private final RestClient client;
    private final String token;
    private final String profile;

    public MapboxClient(@Value("${mapbox.token:}") String token,
                        @Value("${mapbox.profile:mapbox/driving}") String profile,
                        @Value("${mapbox.timeout-seconds:15}") long timeoutSeconds) {
        this.token = token;
        this.profile = profile;

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(5));
        factory.setReadTimeout(Duration.ofSeconds(timeoutSeconds));

        this.client = RestClient.builder()
                .baseUrl("https://api.mapbox.com")
                .requestFactory(factory)
                .build();

        if (token == null || token.isBlank()) {
            log.warn("mapbox.token is not set - road distances fall back to straight-line estimates");
        }
    }

    public boolean isConfigured() {
        return token != null && !token.isBlank();
    }

    public record Point(double lat, double lon) {
        String asCoordinate() {
            return lon + "," + lat;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record MatrixResponse(String code, List<List<Double>> durations, List<List<Double>> distances) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record DirectionsResponse(String code, List<Route> routes) {
        @JsonIgnoreProperties(ignoreUnknown = true)
        public record Route(double distance, double duration, String geometry) {
        }
    }

    private static String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    public MatrixResponse matrix(List<Point> points) {

        if (points.size() > MATRIX_MAX_COORDS) {
            throw new ApiException(
                    "Too many stops for one matrix request, maximum is " + MATRIX_MAX_COORDS, 400);
        }

        String coordinates = points.stream()
                .map(Point::asCoordinate)
                .collect(Collectors.joining(";"));

        URI uri = URI.create("https://api.mapbox.com/directions-matrix/v1/" + profile + "/"
                + coordinates + "?annotations=distance,duration&access_token=" + encode(token));

        try {
            MatrixResponse response = client.get().uri(uri).retrieve().body(MatrixResponse.class);

            if (response == null || !"Ok".equals(response.code())) {
                throw new ApiException("Mapbox matrix request failed", 502);
            }
            return response;

        } catch (ResourceAccessException e) {
            log.error("Mapbox unreachable: {}", e.getMessage());
            throw new ApiException("Map service is unavailable. Please try again.", 503);
        } catch (RestClientException e) {
            log.error("Mapbox matrix rejected the request: {}", e.getMessage());
            throw new ApiException("Map service rejected the request", 502);
        }
    }

    public DirectionsResponse directions(List<Point> orderedPoints) {

        String coordinates = orderedPoints.stream()
                .map(Point::asCoordinate)
                .collect(Collectors.joining(";"));

        URI uri = URI.create("https://api.mapbox.com/directions/v5/" + profile + "/"
                + coordinates + "?geometries=polyline&overview=full&access_token=" + encode(token));

        try {
            DirectionsResponse response = client.get().uri(uri).retrieve().body(DirectionsResponse.class);

            if (response == null || !"Ok".equals(response.code()) || response.routes().isEmpty()) {
                throw new ApiException("Mapbox directions request failed", 502);
            }
            return response;

        } catch (ResourceAccessException e) {
            log.error("Mapbox unreachable: {}", e.getMessage());
            throw new ApiException("Map service is unavailable. Please try again.", 503);
        } catch (RestClientException e) {
            log.error("Mapbox directions rejected the request: {}", e.getMessage());
            throw new ApiException("Map service rejected the request", 502);
        }
    }
}
