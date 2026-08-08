package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.UserRepository;
import com.iem.auth.dto.RegisterRequest;
import com.iem.detection.DetectionRepository;
import com.iem.enums.Role;
import com.iem.geo.CollectionPointRepository;
import com.iem.model.CollectionPoint;
import com.iem.model.Detection;
import com.iem.model.User;
import com.iem.pickup.PickupRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class LeaderboardTests {

    @Autowired private TestRestTemplate rest;
    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private DetectionRepository detectionRepository;
    @Autowired private PickupRepository pickupRepository;
    @Autowired private CollectionPointRepository pointRepository;

    private User citizen;
    private String citizenToken;
    private String collectorToken;

    @BeforeEach
    void setUp() {
        pickupRepository.deleteAll();
        detectionRepository.deleteAll();
        userRepository.deleteAll();
        citizen = register("lb-citizen", Role.CITIZEN);
        citizenToken = authService.buildResponse(citizen).accessToken();
        collectorToken = authService.buildResponse(register("lb-collector", Role.COLLECTOR)).accessToken();
    }

    private User register(String prefix, Role role) {
        RegisterRequest r = new RegisterRequest();
        r.setEmail(prefix + "-" + UUID.randomUUID() + "@example.com");
        r.setFullName(prefix);
        r.setPassword("password123");
        r.setOtp("000000");
        r.setRole(Role.CITIZEN);
        User u = authService.register(r);
        u.setRole(role);
        return userRepository.save(u);
    }

    private HttpHeaders auth(String token) {
        HttpHeaders h = new HttpHeaders();
        h.setBearerAuth(token);
        h.setContentType(MediaType.APPLICATION_JSON);
        return h;
    }

    private UUID detection(UUID userId, BigDecimal weight) {
        Detection d = new Detection();
        d.setUserId(userId);
        d.setStatus("OK");
        d.setEligible(true);
        d.setTotalObjects(5);
        d.setCurrency("INR");
        d.setEstimatedOffer(new BigDecimal("9.75"));
        d.setEstimatedWeightKg(weight);
        return detectionRepository.save(d).getId();
    }

    private String completePickup(UUID userId, String token, BigDecimal weight, BigDecimal finalWeight) {
        CollectionPoint point = pointRepository.findAllActive().get(0);
        String id = (String) rest.postForEntity("/api/v1/pickups",
                new HttpEntity<>(Map.of("detectionId", detection(userId, weight).toString(),
                        "mode", "DROP_OFF", "collectionPointId", point.getId().toString()),
                        auth(token)), Map.class).getBody().get("id");
        rest.exchange("/api/v1/pickups/" + id + "/accept", HttpMethod.POST,
                new HttpEntity<>(Map.of(), auth(collectorToken)), Map.class);
        rest.exchange("/api/v1/pickups/" + id + "/complete", HttpMethod.POST,
                new HttpEntity<>(Map.of("finalWeightKg", finalWeight, "finalAmount", 10),
                        auth(collectorToken)), Map.class);
        return id;
    }

    @Test
    void completionAddsTheGreenPointsBonus() {
        int before = userRepository.findById(citizen.getId()).orElseThrow().getPoints();

        completePickup(citizen.getId(), citizenToken, new BigDecimal("1.0"), new BigDecimal("1.0"));

        int after = userRepository.findById(citizen.getId()).orElseThrow().getPoints();
        assertEquals(before + 28, after, "20 bonus + 1 kg x 8 drop-off rate");
    }

    @Test
    void bonusAppliesEvenWithZeroWeight() {
        int before = userRepository.findById(citizen.getId()).orElseThrow().getPoints();
        completePickup(citizen.getId(), citizenToken, BigDecimal.ZERO, BigDecimal.ZERO);
        int after = userRepository.findById(citizen.getId()).orElseThrow().getPoints();
        assertEquals(before + 20, after, "the flat completion bonus still applies");
    }

    @Test
    void leaderboardIsPublicAndRanksByPoints() {
        User rival = register("rival", Role.CITIZEN);
        String rivalToken = authService.buildResponse(rival).accessToken();

        completePickup(citizen.getId(), citizenToken, new BigDecimal("5.0"), new BigDecimal("5.0"));
        completePickup(rival.getId(), rivalToken, new BigDecimal("1.0"), new BigDecimal("1.0"));

        ResponseEntity<Map> response = rest.getForEntity("/api/v1/leaderboard", Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        List<?> entries = (List<?>) response.getBody().get("entries");
        assertTrue(entries.size() >= 2);

        Map<?, ?> first = (Map<?, ?>) entries.get(0);
        Map<?, ?> second = (Map<?, ?>) entries.get(1);
        assertEquals(1, first.get("rank"));
        assertEquals(2, second.get("rank"));
        assertTrue((Integer) first.get("points") >= (Integer) second.get("points"),
                "ranked by points descending");
        assertEquals(1, ((Number) first.get("completedPickups")).intValue());
    }

    @Test
    void leaderboardIncludesMyRankWhenAuthenticated() {
        completePickup(citizen.getId(), citizenToken, new BigDecimal("2.0"), new BigDecimal("2.0"));

        ResponseEntity<Map> response = rest.exchange("/api/v1/leaderboard", HttpMethod.GET,
                new HttpEntity<>(auth(citizenToken)), Map.class);

        Map<?, ?> me = (Map<?, ?>) response.getBody().get("me");
        assertNotNull(me, "an authenticated caller gets their own rank");
        assertEquals(1, me.get("rank"));
        assertEquals(36, me.get("points"), "20 bonus + 2 kg x 8");
        assertEquals(1, ((Number) me.get("completedPickups")).intValue());
    }

    @Test
    void anonymousLeaderboardHasNoMeBlock() {
        ResponseEntity<Map> response = rest.getForEntity("/api/v1/leaderboard", Map.class);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNull(response.getBody().get("me"));
    }

    @Test
    void totalsAggregateAcrossEveryone() {
        User rival = register("rival2", Role.CITIZEN);
        completePickup(citizen.getId(), citizenToken, new BigDecimal("3.0"), new BigDecimal("3.0"));
        completePickup(rival.getId(), authService.buildResponse(rival).accessToken(),
                new BigDecimal("2.0"), new BigDecimal("2.0"));

        ResponseEntity<Map> response = rest.getForEntity("/api/v1/leaderboard", Map.class);
        Map<?, ?> totals = (Map<?, ?>) response.getBody().get("totals");

        assertEquals(2, ((Number) totals.get("citizens")).intValue());
        assertEquals(2, ((Number) totals.get("completedPickups")).intValue());
        assertEquals(5.0, ((Number) totals.get("weightKg")).doubleValue(), 0.001);
    }

    @Test
    void limitIsClamped() {
        ResponseEntity<Map> response = rest.getForEntity("/api/v1/leaderboard?limit=9999", Map.class);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(((List<?>) response.getBody().get("entries")).size() <= 100);
    }
}
