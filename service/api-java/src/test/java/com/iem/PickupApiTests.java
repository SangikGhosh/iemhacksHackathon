package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.UserRepository;
import com.iem.auth.dto.RegisterRequest;
import com.iem.detection.DetectionRepository;
import com.iem.enums.PickupStatus;
import com.iem.enums.Role;
import com.iem.model.Detection;
import com.iem.model.DetectionMaterial;
import com.iem.model.User;
import com.iem.pickup.PickupRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.http.HttpStatusCode;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class PickupApiTests {

    @Autowired
    private TestRestTemplate rest;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DetectionRepository detectionRepository;

    @Autowired
    private PickupRepository pickupRepository;

    private User citizen;
    private String citizenToken;
    private String collectorToken;
    private String otherCollectorToken;
    private UUID detectionId;

    @BeforeEach
    void setUp() {
        pickupRepository.deleteAll();
        detectionRepository.deleteAll();
        userRepository.deleteAll();

        citizen = register("citizen", Role.CITIZEN);
        citizenToken = authService.buildResponse(citizen).accessToken();
        collectorToken = authService.buildResponse(register("collector", Role.COLLECTOR)).accessToken();
        otherCollectorToken = authService.buildResponse(register("collector2", Role.COLLECTOR)).accessToken();

        detectionId = storeDetection(citizen.getId(), true);
    }

    private User register(String prefix, Role role) {
        RegisterRequest request = new RegisterRequest();
        request.setEmail(prefix + "-" + UUID.randomUUID() + "@example.com");
        request.setFullName(prefix.toUpperCase());
        request.setPassword("password123");
        request.setOtp("000000");
        request.setRole(Role.CITIZEN);
        User user = authService.register(request);
        user.setRole(role);
        return userRepository.save(user);
    }

    private UUID storeDetection(UUID userId, boolean eligible) {
        Detection d = new Detection();
        d.setUserId(userId);
        d.setStatus(eligible ? "MANUAL_PRICING_REQUIRED" : "NO_WASTE_DETECTED");
        d.setEligible(eligible);
        d.setTotalObjects(eligible ? 13 : 0);
        d.setTotalRewardPoints(eligible ? 65 : 0);
        d.setCurrency("INR");
        d.setEstimatedOffer(new BigDecimal("9.75"));
        if (eligible) {
            DetectionMaterial m = new DetectionMaterial();
            m.setMaterial("PET Bottle");
            m.setCount(13);
            m.setRewardPoints(65);
            m.setRecyclable(true);
            d.addMaterial(m);
        }
        return detectionRepository.save(d).getId();
    }

    private HttpHeaders auth(String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }

    private ResponseEntity<Map> createPickup(String token, UUID detection) {
        Map<String, Object> body = Map.of(
                "detectionId", detection.toString(),
                "address", "12 Park Street, Kolkata",
                "contactPhone", "+919876543210",
                "landmark", "Near the metro gate",
                "notes", "Ring the bell twice");
        return rest.postForEntity("/api/v1/pickups", new HttpEntity<>(body, auth(token)), Map.class);
    }

    private ResponseEntity<Map> post(String path, String token, Object body) {
        return rest.exchange(path, HttpMethod.POST,
                new HttpEntity<>(body == null ? Map.of() : body, auth(token)), Map.class);
    }

    private ResponseEntity<Map> get(String path, String token) {
        return rest.exchange(path, HttpMethod.GET, new HttpEntity<>(auth(token)), Map.class);
    }

    private UUID createAndGetId() {
        return UUID.fromString((String) createPickup(citizenToken, detectionId).getBody().get("id"));
    }

    @Test
    void requiresAuthentication() {
        assertEquals(HttpStatus.UNAUTHORIZED,
                rest.getForEntity("/api/v1/pickups", String.class).getStatusCode());
        assertEquals(HttpStatus.UNAUTHORIZED,
                rest.postForEntity("/api/v1/pickups", null, String.class).getStatusCode());
    }

    @Test
    void citizenCreatesPickupFromScan() {
        ResponseEntity<Map> response = createPickup(citizenToken, detectionId);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        Map<?, ?> body = response.getBody();
        assertEquals("REQUESTED", body.get("status"));
        assertEquals(true, body.get("cancellable"));
        assertNull(body.get("collector"));
        assertEquals("PET Bottle x13", ((Map<?, ?>) body.get("waste")).get("materials"));
        assertEquals(13, ((Map<?, ?>) body.get("waste")).get("totalObjects"));
        assertEquals(1, pickupRepository.count());
    }

    @Test
    void cannotCreatePickupForIneligibleScan() {
        UUID ineligible = storeDetection(citizen.getId(), false);
        ResponseEntity<Map> response = createPickup(citizenToken, ineligible);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(0, pickupRepository.count());
    }

    @Test
    void cannotCreatePickupForAnotherUsersScan() {
        User stranger = register("stranger", Role.CITIZEN);
        UUID theirs = storeDetection(stranger.getId(), true);
        assertEquals(HttpStatus.NOT_FOUND, createPickup(citizenToken, theirs).getStatusCode());
    }

    @Test
    void cannotCreateTwoPickupsForOneScan() {
        createPickup(citizenToken, detectionId);
        assertEquals(HttpStatus.CONFLICT, createPickup(citizenToken, detectionId).getStatusCode());
    }

    @Test
    void canRequestAgainAfterCancelling() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/cancel", citizenToken, null);

        ResponseEntity<Map> again = createPickup(citizenToken, detectionId);

        assertEquals(HttpStatus.CREATED, again.getStatusCode());
        assertEquals("REQUESTED", again.getBody().get("status"));
        assertEquals(2, pickupRepository.count());
    }

    @Test
    void collectorSeesAvailablePickups() {
        createPickup(citizenToken, detectionId);

        ResponseEntity<Map> response = get("/api/v1/pickups/available", collectorToken);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, ((java.util.List<?>) response.getBody().get("items")).size());
    }

    @Test
    void citizenCannotSeeAvailablePickupsFeed() {
        assertEquals(HttpStatus.FORBIDDEN,
                get("/api/v1/pickups/available", citizenToken).getStatusCode());
    }

    @Test
    void collectorAcceptsPickup() {
        UUID id = createAndGetId();

        ResponseEntity<Map> response = post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("ACCEPTED", response.getBody().get("status"));
        assertEquals(false, response.getBody().get("cancellable"));
        assertNotNull(response.getBody().get("collector"));
        assertNotNull(response.getBody().get("acceptedAt"));
    }

    @Test
    void acceptedPickupLeavesTheAvailableFeed() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        ResponseEntity<Map> feed = get("/api/v1/pickups/available", otherCollectorToken);
        assertEquals(0, ((java.util.List<?>) feed.getBody().get("items")).size());
    }

    @Test
    void secondCollectorCannotAcceptTheSamePickup() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        ResponseEntity<Map> second = post("/api/v1/pickups/" + id + "/accept", otherCollectorToken, null);
        assertEquals(HttpStatus.CONFLICT, second.getStatusCode());
    }

    @Test
    void citizenCanCancelBeforeAcceptance() {
        UUID id = createAndGetId();

        ResponseEntity<Map> response = post("/api/v1/pickups/" + id + "/cancel", citizenToken,
                Map.of("reason", "Changed my mind"));

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("CANCELLED", response.getBody().get("status"));
        assertEquals("USER", response.getBody().get("cancelledBy"));
        assertEquals("Changed my mind", response.getBody().get("cancelReason"));
    }

    @Test
    void citizenCannotCancelOnceAccepted() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        ResponseEntity<Map> response = post("/api/v1/pickups/" + id + "/cancel", citizenToken, null);

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertEquals(PickupStatus.ACCEPTED,
                pickupRepository.findById(id).orElseThrow().getStatus());
    }

    @Test
    void collectorCompletesPickupWithFinalAmount() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        ResponseEntity<Map> response = post("/api/v1/pickups/" + id + "/complete", collectorToken,
                Map.of("finalWeightKg", 0.5, "finalAmount", 12.5, "collectorNotes", "Weighed on site"));

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("COMPLETED", response.getBody().get("status"));
        Map<?, ?> money = (Map<?, ?>) response.getBody().get("money");
        assertEquals(12.5, ((Number) money.get("finalAmount")).doubleValue());
        assertEquals(0.5, ((Number) money.get("finalWeightKg")).doubleValue());
        assertNotNull(response.getBody().get("completedAt"));
    }

    @Test
    void collectorCannotCompleteSomeoneElsesPickup() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        ResponseEntity<Map> response = post("/api/v1/pickups/" + id + "/complete", otherCollectorToken,
                Map.of("finalWeightKg", 1, "finalAmount", 20));

        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
    }

    @Test
    void cannotCompleteAPickupThatWasNeverAccepted() {
        UUID id = createAndGetId();
        ResponseEntity<Map> response = post("/api/v1/pickups/" + id + "/complete", collectorToken,
                Map.of("finalWeightKg", 1, "finalAmount", 20));
        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
    }

    @Test
    void cannotReleaseAPickupThatWasNeverAccepted() {
        UUID id = createAndGetId();
        assertEquals(HttpStatus.CONFLICT,
                post("/api/v1/pickups/" + id + "/release", collectorToken, null).getStatusCode());
    }

    @Test
    void collectorCanReleaseAcceptedPickupBackToTheFeed() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        ResponseEntity<Map> response = post("/api/v1/pickups/" + id + "/release", collectorToken,
                Map.of("reason", "Vehicle broke down"));

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("REQUESTED", response.getBody().get("status"));
        assertNull(response.getBody().get("collector"));

        ResponseEntity<Map> feed = get("/api/v1/pickups/available", otherCollectorToken);
        assertEquals(1, ((java.util.List<?>) feed.getBody().get("items")).size());
    }

    @Test
    void concurrentAcceptsGiveExactlyOneWinner() throws Exception {
        UUID id = createAndGetId();
        int contenders = 6;

        java.util.List<String> tokens = new java.util.ArrayList<>();
        for (int i = 0; i < contenders; i++) {
            tokens.add(authService.buildResponse(register("racer" + i, Role.COLLECTOR)).accessToken());
        }

        java.util.concurrent.CountDownLatch start = new java.util.concurrent.CountDownLatch(1);
        java.util.concurrent.ExecutorService pool =
                java.util.concurrent.Executors.newFixedThreadPool(contenders);
        java.util.List<java.util.concurrent.Future<HttpStatusCode>> results = new java.util.ArrayList<>();

        for (String token : tokens) {
            results.add(pool.submit(() -> {
                start.await();
                return rest.exchange("/api/v1/pickups/" + id + "/accept", HttpMethod.POST,
                        new HttpEntity<>(Map.of(), auth(token)), Map.class).getStatusCode();
            }));
        }
        start.countDown();

        int accepted = 0;
        int rejected = 0;
        for (java.util.concurrent.Future<HttpStatusCode> r : results) {
            HttpStatusCode code = r.get();
            if (code == HttpStatus.OK) accepted++;
            else if (code == HttpStatus.CONFLICT) rejected++;
        }
        pool.shutdown();

        assertEquals(1, accepted, "exactly one collector must win the race");
        assertEquals(contenders - 1, rejected, "everyone else must get 409");
        assertEquals(PickupStatus.ACCEPTED, pickupRepository.findById(id).orElseThrow().getStatus());
    }

    @Test
    void collectorCannotAcceptTheirOwnPickup() {
        User collector = register("selfdealer", Role.COLLECTOR);
        String token = authService.buildResponse(collector).accessToken();
        UUID ownDetection = storeDetection(collector.getId(), true);

        Map<String, Object> body = Map.of("detectionId", ownDetection.toString(),
                "address", "Own house", "contactPhone", "+919876543210");
        UUID id = UUID.fromString((String) rest.postForEntity("/api/v1/pickups",
                new HttpEntity<>(body, auth(token)), Map.class).getBody().get("id"));

        assertEquals(HttpStatus.FORBIDDEN,
                post("/api/v1/pickups/" + id + "/accept", token, null).getStatusCode());
    }

    @Test
    void releaseDoesNotMarkThePickupAsCancelled() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        ResponseEntity<Map> released = post("/api/v1/pickups/" + id + "/release", collectorToken,
                Map.of("reason", "Vehicle broke down"));

        assertEquals("REQUESTED", released.getBody().get("status"));
        assertNull(released.getBody().get("cancelledBy"));
        assertNull(released.getBody().get("cancelReason"));
        assertNull(released.getBody().get("cancelledAt"));
    }

    @Test
    void historyIsScopedByRole() {
        UUID id = createAndGetId();
        post("/api/v1/pickups/" + id + "/accept", collectorToken, null);

        ResponseEntity<Map> citizenHistory = get("/api/v1/pickups", citizenToken);
        assertEquals(1, ((java.util.List<?>) citizenHistory.getBody().get("items")).size());

        ResponseEntity<Map> collectorHistory = get("/api/v1/pickups", collectorToken);
        assertEquals(1, ((java.util.List<?>) collectorHistory.getBody().get("items")).size());

        ResponseEntity<Map> otherHistory = get("/api/v1/pickups", otherCollectorToken);
        assertEquals(0, ((java.util.List<?>) otherHistory.getBody().get("items")).size());
    }

    @Test
    void strangerCannotReadAnotherUsersPickup() {
        UUID id = createAndGetId();
        String strangerToken = authService.buildResponse(register("nosy", Role.CITIZEN)).accessToken();

        assertEquals(HttpStatus.NOT_FOUND,
                get("/api/v1/pickups/" + id, strangerToken).getStatusCode());
        assertEquals(HttpStatus.OK, get("/api/v1/pickups/" + id, citizenToken).getStatusCode());
    }

    @Test
    void validationRejectsBadInput() {
        Map<String, Object> body = Map.of(
                "detectionId", detectionId.toString(),
                "address", "",
                "contactPhone", "not-a-phone");
        ResponseEntity<Map> response = rest.postForEntity("/api/v1/pickups",
                new HttpEntity<>(body, auth(citizenToken)), Map.class);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(0, pickupRepository.count());
    }

    private int points() {
        return userRepository.findById(citizen.getId()).orElseThrow().getPoints();
    }

    private void completeAsCollector(UUID pickupId, double weightKg) {
        post("/api/v1/pickups/" + pickupId + "/accept", collectorToken, null);
        post("/api/v1/pickups/" + pickupId + "/complete", collectorToken,
                Map.of("finalWeightKg", weightKg, "finalAmount", 96.0));
    }

    @Test
    void nothingIsCreditedUntilACollectorCompletesThePickup() {
        assertEquals(0, points(), "a stored scan on its own credits nothing");

        UUID pickup = createAndGetId();
        assertEquals(0, points(), "requesting a pickup credits nothing either");

        post("/api/v1/pickups/" + pickup + "/accept", collectorToken, null);
        assertEquals(0, points(), "acceptance is not completion");

        post("/api/v1/pickups/" + pickup + "/complete", collectorToken,
                Map.of("finalWeightKg", 3.2, "finalAmount", 128.0));

        assertEquals(101, points(),
                "20 completion bonus + 3.2 kg at 5 points/kg doorstep + 65 from the scan");
    }

    @Test
    void aCancelledPickupCreditsNothingAndTheScanCanStillEarnLater() {
        UUID first = createAndGetId();
        post("/api/v1/pickups/" + first + "/cancel", citizenToken, Map.of("reason", "not home"));

        assertEquals(0, points(), "a cancelled pickup must not credit the scan");

        UUID second = createAndGetId();
        completeAsCollector(second, 2.0);

        assertEquals(95, points(),
                "20 bonus + 2 kg at 5 points/kg + the 65 the scan was always worth");
    }

    @Test
    void aSecondCompletionCannotCreditTheScanTwice() {
        UUID pickup = createAndGetId();
        completeAsCollector(pickup, 2.0);
        int afterFirst = points();

        ResponseEntity<Map> repeat = post("/api/v1/pickups/" + pickup + "/complete",
                collectorToken, Map.of("finalWeightKg", 2.0, "finalAmount", 96.0));

        assertEquals(HttpStatus.CONFLICT, repeat.getStatusCode());
        assertEquals(afterFirst, points(), "a repeated completion must not credit again");
    }

    @Test
    void twoScansOnlyEarnForTheOneThatIsActuallyCollected() {
        UUID collected = createAndGetId();
        storeDetection(citizen.getId(), true);

        completeAsCollector(collected, 2.0);

        assertEquals(95, points(),
                "the second scan was never handed over, so it earns nothing");
    }
}
