package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.UserRepository;
import com.iem.detection.DetectionClient;
import com.iem.detection.DetectionRepository;
import com.iem.detection.dto.DetectionApiResponse;
import com.iem.enums.Role;
import com.iem.exception.ApiException;
import com.iem.model.Detection;
import com.iem.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class DetectionApiTests {

    @Autowired
    private TestRestTemplate rest;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DetectionRepository detectionRepository;

    @MockBean
    private DetectionClient detectionClient;

    private User user;
    private String token;

    @BeforeEach
    void setUp() {
        detectionRepository.deleteAll();
        userRepository.deleteAll();
        user = register("scanner-" + UUID.randomUUID() + "@example.com");
        token = authService.buildResponse(user).accessToken();
    }

    private User register(String email) {
        var request = new com.iem.auth.dto.RegisterRequest();
        request.setEmail(email);
        request.setFullName("Scanner User");
        request.setPassword("password123");
        request.setOtp("000000");
        request.setRole(Role.CITIZEN);
        return authService.register(request);
    }

    private static DetectionApiResponse eligibleResponse() {
        return new DetectionApiResponse(
                true, true, "MANUAL_PRICING_REQUIRED",
                "13 waste items detected", "COLLECTOR_SETS_PRICE", 1800,
                "https://cdn.example.com/a.jpg",
                new DetectionApiResponse.Model("waste-detector-v1", "YOLOv8 Medium", "2026.08.08", 1700),
                new DetectionApiResponse.Quality("MEDIUM", new BigDecimal("0.58")),
                new DetectionApiResponse.Summary(13),
                List.of(new DetectionApiResponse.Material("PET Bottle", "PLASTIC", "DRY", "BLUE",
                        true, 13, new BigDecimal("25"), new BigDecimal("0.39"),
                        new BigDecimal("9.75"), 65, new BigDecimal("1.95"))),
                new DetectionApiResponse.Offer("INR", new BigDecimal("8.29"), new BigDecimal("9.75"),
                        new BigDecimal("11.21"), "PENDING_COLLECTOR_CONFIRMATION", "COLLECTOR"),
                new DetectionApiResponse.WasteAnalysis(100),
                new DetectionApiResponse.Environment(new BigDecimal("1.95"), new BigDecimal("0.39")),
                new DetectionApiResponse.Recommendation("BLUE", null, true),
                65, "13 PET Bottles detected.");
    }

    private static DetectionApiResponse ineligibleResponse() {
        return new DetectionApiResponse(
                true, false, "NO_WASTE_DETECTED",
                "No garbage detected. The image shows person.", "RECLICK_IMAGE", 900,
                null,
                new DetectionApiResponse.Model("waste-detector-v1", "YOLOv8 Medium", "2026.08.08", 850),
                new DetectionApiResponse.Quality("NONE", BigDecimal.ZERO),
                new DetectionApiResponse.Summary(0),
                List.of(),
                new DetectionApiResponse.Offer("INR", BigDecimal.ZERO, BigDecimal.ZERO,
                        BigDecimal.ZERO, "UNAVAILABLE", "COLLECTOR"),
                new DetectionApiResponse.WasteAnalysis(0),
                new DetectionApiResponse.Environment(BigDecimal.ZERO, BigDecimal.ZERO),
                new DetectionApiResponse.Recommendation(null, null, false),
                0, "No garbage detected in the image.");
    }

    private HttpEntity<MultiValueMap<String, Object>> upload(String contentType, byte[] bytes, boolean auth) {
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        HttpHeaders partHeaders = new HttpHeaders();
        partHeaders.setContentType(MediaType.parseMediaType(contentType));
        ByteArrayResource resource = new ByteArrayResource(bytes) {
            @Override
            public String getFilename() {
                return "waste.jpg";
            }
        };
        body.add("image", new HttpEntity<>(resource, partHeaders));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        if (auth) {
            headers.setBearerAuth(token);
        }
        return new HttpEntity<>(body, headers);
    }

    private HttpEntity<MultiValueMap<String, Object>> jpegUpload() {
        return upload("image/jpeg", new byte[]{1, 2, 3, 4}, true);
    }

    private ResponseEntity<Map> scan() {
        return rest.postForEntity("/api/v1/detections", jpegUpload(), Map.class);
    }

    private HttpEntity<Void> authGet() {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        return new HttpEntity<>(headers);
    }

    @Test
    void scanRequiresAuthentication() {
        ResponseEntity<String> response = rest.postForEntity("/api/v1/detections",
                upload("image/jpeg", new byte[]{1, 2, 3}, false), String.class);
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    void historyRequiresAuthentication() {
        assertEquals(HttpStatus.UNAUTHORIZED,
                rest.getForEntity("/api/v1/detections", String.class).getStatusCode());
    }

    @Test
    void scanStoresDetectionAndReturnsPayload() {
        when(detectionClient.detect(any())).thenReturn(eligibleResponse());

        ResponseEntity<Map> response = scan();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        Map<?, ?> body = response.getBody();
        assertNotNull(body);
        assertEquals(true, body.get("eligible"));
        assertEquals("MANUAL_PRICING_REQUIRED", body.get("status"));
        assertEquals(13, body.get("totalObjects"));
        assertEquals(65, body.get("totalRewardPoints"));
        assertNotNull(body.get("id"));

        assertEquals(1, detectionRepository.count());
    }

    @Test
    void scanPersistsMaterialRows() {
        when(detectionClient.detect(any())).thenReturn(eligibleResponse());
        scan();

        List<UUID> ids = detectionRepository.findAll().stream().map(Detection::getId).toList();
        Detection stored = detectionRepository.findByIdIn(ids).get(0);
        assertEquals(1, stored.getMaterials().size());
        assertEquals("PET Bottle", stored.getMaterials().get(0).getMaterial());
        assertEquals(13, stored.getMaterials().get(0).getCount());
        assertEquals(0, new BigDecimal("9.75").compareTo(stored.getMaterials().get(0).getEstimatedValue()));
        assertEquals("BLUE", stored.getPrimaryBin());
        assertEquals("waste-detector-v1", stored.getModelId());
    }

    @Test
    void eligibleScanQuotesPointsButCreditsNothingYet() {
        when(detectionClient.detect(any())).thenReturn(eligibleResponse());

        ResponseEntity<Map> response = scan();

        assertEquals(65, response.getBody().get("totalRewardPoints"),
                "the scan still reports what the waste is worth");
        assertEquals(false, response.getBody().get("pointsAwarded"));
        assertEquals(0, response.getBody().get("userPointsBalance"));
        assertEquals(0, userRepository.findById(user.getId()).orElseThrow().getPoints(),
                "points are only credited when a collector completes the pickup");
    }

    @Test
    void scanningRepeatedlyCreditsNothing() {
        when(detectionClient.detect(any())).thenReturn(eligibleResponse());

        for (int i = 0; i < 5; i++) {
            scan();
        }

        assertEquals(0, userRepository.findById(user.getId()).orElseThrow().getPoints(),
                "five scans with no pickup must not move the balance");
    }

    @Test
    void ineligibleScanStoresButAwardsNothing() {
        when(detectionClient.detect(any())).thenReturn(ineligibleResponse());

        ResponseEntity<Map> response = scan();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(false, response.getBody().get("eligible"));
        assertEquals("RECLICK_IMAGE", response.getBody().get("actionRequired"));
        assertEquals(false, response.getBody().get("pointsAwarded"));
        assertEquals(0, userRepository.findById(user.getId()).orElseThrow().getPoints());
        assertEquals(1, detectionRepository.count());
    }

    @Test
    void rejectsMissingImagePart() {
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("wrongName", "x");
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        headers.setBearerAuth(token);

        ResponseEntity<String> response = rest.postForEntity("/api/v1/detections",
                new HttpEntity<>(body, headers), String.class);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(0, detectionRepository.count());
    }

    @Test
    void rejectsNonImageUpload() {
        ResponseEntity<String> response = rest.postForEntity("/api/v1/detections",
                upload("text/plain", "not an image".getBytes(), true), String.class);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(0, detectionRepository.count());
    }

    @Test
    void returnsServiceUnavailableWhenPythonIsDown() {
        when(detectionClient.detect(any()))
                .thenThrow(new ApiException("Detection service is unavailable. Please try again.", 503));

        ResponseEntity<String> response = rest.postForEntity("/api/v1/detections",
                jpegUpload(), String.class);

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertEquals(0, detectionRepository.count());
    }

    @Test
    void historyReturnsScansNewestFirstWithTotals() {
        when(detectionClient.detect(any())).thenReturn(eligibleResponse());
        scan();
        when(detectionClient.detect(any())).thenReturn(ineligibleResponse());
        scan();

        ResponseEntity<Map> response = rest.exchange("/api/v1/detections", HttpMethod.GET,
                authGet(), Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        Map<?, ?> body = response.getBody();
        List<?> items = (List<?>) body.get("items");
        assertEquals(2, items.size());
        assertEquals("NO_WASTE_DETECTED", ((Map<?, ?>) items.get(0)).get("status"));
        assertEquals(2L, ((Number) body.get("totalItems")).longValue());

        Map<?, ?> totals = (Map<?, ?>) body.get("totals");
        assertEquals(2, totals.get("scans"));
        assertEquals(13, totals.get("objects"));
        assertEquals(0, totals.get("rewardPoints"),
                "rewardPoints counts what has actually been credited, and no pickup has "
                        + "completed yet");
    }

    @Test
    void historyIsScopedToTheAuthenticatedUser() {
        when(detectionClient.detect(any())).thenReturn(eligibleResponse());
        scan();

        User other = register("other-" + UUID.randomUUID() + "@example.com");
        String otherToken = authService.buildResponse(other).accessToken();
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(otherToken);

        ResponseEntity<Map> response = rest.exchange("/api/v1/detections", HttpMethod.GET,
                new HttpEntity<>(headers), Map.class);

        assertEquals(0, ((List<?>) response.getBody().get("items")).size());
        assertEquals(0, ((Map<?, ?>) response.getBody().get("totals")).get("scans"));
    }

    @Test
    void historyPaginates() {
        when(detectionClient.detect(any())).thenReturn(eligibleResponse());
        scan();
        scan();
        scan();

        ResponseEntity<Map> first = rest.exchange("/api/v1/detections?page=0&size=2",
                HttpMethod.GET, authGet(), Map.class);
        assertEquals(2, ((List<?>) first.getBody().get("items")).size());
        assertEquals(true, first.getBody().get("hasMore"));
        assertEquals(2, first.getBody().get("totalPages"));

        ResponseEntity<Map> second = rest.exchange("/api/v1/detections?page=1&size=2",
                HttpMethod.GET, authGet(), Map.class);
        assertEquals(1, ((List<?>) second.getBody().get("items")).size());
        assertEquals(false, second.getBody().get("hasMore"));
    }
}
