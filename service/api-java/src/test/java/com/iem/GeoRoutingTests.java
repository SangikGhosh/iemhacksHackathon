package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.UserRepository;
import com.iem.auth.dto.RegisterRequest;
import com.iem.detection.DetectionRepository;
import com.iem.enums.Role;
import com.iem.geo.CollectionPointRepository;
import com.iem.geo.CollectionPointService;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.CollectionPoint;
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
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class GeoRoutingTests {

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

    @Autowired
    private CollectionPointRepository pointRepository;

    @Autowired
    private MunicipalityRepository municipalityRepository;

    private User citizen;
    private String citizenToken;
    private String collectorToken;

    @BeforeEach
    void setUp() {
        pickupRepository.deleteAll();
        detectionRepository.deleteAll();
        userRepository.deleteAll();
        citizen = register("geo-citizen", Role.CITIZEN);
        citizenToken = authService.buildResponse(citizen).accessToken();
        collectorToken = authService.buildResponse(register("geo-collector", Role.COLLECTOR)).accessToken();
    }

    private User register(String prefix, Role role) {
        RegisterRequest request = new RegisterRequest();
        request.setEmail(prefix + "-" + UUID.randomUUID() + "@example.com");
        request.setFullName(prefix);
        request.setPassword("password123");
        request.setOtp("000000");
        request.setRole(Role.CITIZEN);
        User user = authService.register(request);
        user.setRole(role);
        return userRepository.save(user);
    }

    private UUID storeDetection(BigDecimal weightKg) {
        Detection d = new Detection();
        d.setUserId(citizen.getId());
        d.setStatus("MANUAL_PRICING_REQUIRED");
        d.setEligible(true);
        d.setTotalObjects(13);
        d.setTotalRewardPoints(65);
        d.setCurrency("INR");
        d.setEstimatedOffer(new BigDecimal("9.75"));
        d.setEstimatedWeightKg(weightKg);
        DetectionMaterial m = new DetectionMaterial();
        m.setMaterial("PET Bottle");
        m.setCount(13);
        m.setRecyclable(true);
        d.addMaterial(m);
        return detectionRepository.save(d).getId();
    }

    private HttpHeaders auth(String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }

    @Test
    void seedLoadedMunicipalitiesAndPoints() {
        assertTrue(municipalityRepository.count() >= 4, "expected the seeded municipalities");
        assertTrue(pointRepository.count() >= 150, "expected the seeded collection points");
        assertTrue(municipalityRepository.findByCode("HMC").isPresent());
    }

    @Test
    void howrahHasAtLeastOneHundredPoints() {
        UUID hmc = municipalityRepository.findByCode("HMC").orElseThrow().getId();
        assertTrue(pointRepository.countByMunicipalityId(hmc) >= 100);
    }

    @Test
    void everySeededPointIsInsideWestBengalBounds() {
        pointRepository.findAllActive().forEach(p -> {
            assertTrue(p.getLat() > 22.3 && p.getLat() < 23.1, "lat out of range: " + p.getCode());
            assertTrue(p.getLon() > 88.0 && p.getLon() < 88.7, "lon out of range: " + p.getCode());
        });
    }

    @Test
    void haversineMatchesAKnownDistance() {
        double km = CollectionPointService.haversineKm(22.5958, 88.2636, 22.5726, 88.3639);
        assertTrue(km > 10 && km < 12, "Howrah to Kolkata should be about 11 km, got " + km);
    }

    @Test
    void nearestReturnsPointsOrderedAndPublic() {
        ResponseEntity<Map> response = rest.getForEntity(
                "/api/v1/collection-points/nearest?lat=22.5671&lon=88.2977&limit=3", Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        List<?> points = (List<?>) response.getBody().get("points");
        assertEquals(3, points.size());

        Map<?, ?> first = (Map<?, ?>) points.get(0);
        assertNotNull(first.get("code"));
        assertNotNull(first.get("straightLineKm"));
        assertEquals("Howrah", first.get("district"));
    }

    @Test
    void nearestRejectsBadCoordinates() {
        assertEquals(HttpStatus.BAD_REQUEST, rest.getForEntity(
                "/api/v1/collection-points/nearest?lat=999&lon=88.3", String.class).getStatusCode());
    }

    @Test
    void nearestReturns404FarFromAnyPoint() {
        assertEquals(HttpStatus.NOT_FOUND, rest.getForEntity(
                "/api/v1/collection-points/nearest?lat=12.97&lon=77.59", String.class).getStatusCode());
    }

    @Test
    void dropOffPickupCopiesThePointAndScoresHigher() {
        CollectionPoint point = pointRepository.findAllActive().get(0);
        UUID detection = storeDetection(new BigDecimal("2.000"));

        ResponseEntity<Map> response = rest.postForEntity("/api/v1/pickups",
                new HttpEntity<>(Map.of("detectionId", detection.toString(),
                        "mode", "DROP_OFF",
                        "collectionPointId", point.getId().toString()), auth(citizenToken)),
                Map.class);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        Map<?, ?> body = response.getBody();
        assertEquals("DROP_OFF", body.get("mode"));
        assertEquals(16, body.get("rewardPoints"), "2 kg at 8 points/kg");
        Map<?, ?> location = (Map<?, ?>) body.get("location");
        assertEquals(point.getLat(), (Double) location.get("latitude"), 0.0001);
    }

    @Test
    void doorstepPickupScoresLower() {
        UUID detection = storeDetection(new BigDecimal("2.000"));

        ResponseEntity<Map> response = rest.postForEntity("/api/v1/pickups",
                new HttpEntity<>(Map.of("detectionId", detection.toString(),
                        "mode", "DOORSTEP",
                        "address", "12 Park Street",
                        "contactPhone", "+919876543210",
                        "latitude", 22.5671, "longitude", 88.2977), auth(citizenToken)),
                Map.class);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertEquals("DOORSTEP", response.getBody().get("mode"));
        assertEquals(10, response.getBody().get("rewardPoints"), "2 kg at 5 points/kg");
    }

    @Test
    void dropOffRequiresAPointAndDoorstepRequiresAnAddress() {
        UUID d1 = storeDetection(new BigDecimal("1.0"));
        assertEquals(HttpStatus.BAD_REQUEST, rest.postForEntity("/api/v1/pickups",
                new HttpEntity<>(Map.of("detectionId", d1.toString(), "mode", "DROP_OFF"),
                        auth(citizenToken)), Map.class).getStatusCode());

        UUID d2 = storeDetection(new BigDecimal("1.0"));
        assertEquals(HttpStatus.BAD_REQUEST, rest.postForEntity("/api/v1/pickups",
                new HttpEntity<>(Map.of("detectionId", d2.toString(), "mode", "DOORSTEP"),
                        auth(citizenToken)), Map.class).getStatusCode());
    }

    @Test
    void routeRequiresCollectorRole() {
        assertEquals(HttpStatus.FORBIDDEN, rest.exchange("/api/v1/routes/my-route",
                HttpMethod.GET, new HttpEntity<>(auth(citizenToken)), String.class).getStatusCode());
    }

    @Test
    void routeIs404WithNoAcceptedPickups() {
        assertEquals(HttpStatus.NOT_FOUND, rest.exchange("/api/v1/routes/my-route",
                HttpMethod.GET, new HttpEntity<>(auth(collectorToken)), String.class).getStatusCode());
    }

    @Test
    void routeAggregatesPickupsAtTheSamePointIntoOneStop() {
        CollectionPoint point = pointRepository.findAllActive().get(0);

        for (int i = 0; i < 3; i++) {
            UUID detection = storeDetection(new BigDecimal("1.500"));
            String id = (String) rest.postForEntity("/api/v1/pickups",
                    new HttpEntity<>(Map.of("detectionId", detection.toString(),
                            "mode", "DROP_OFF",
                            "collectionPointId", point.getId().toString()), auth(citizenToken)),
                    Map.class).getBody().get("id");
            rest.exchange("/api/v1/pickups/" + id + "/accept", HttpMethod.POST,
                    new HttpEntity<>(Map.of(), auth(collectorToken)), Map.class);
        }

        ResponseEntity<Map> route = rest.exchange("/api/v1/routes/my-route", HttpMethod.GET,
                new HttpEntity<>(auth(collectorToken)), Map.class);

        assertEquals(HttpStatus.OK, route.getStatusCode());
        assertEquals(3, route.getBody().get("totalRequests"));
        assertEquals(1, route.getBody().get("totalStops"), "3 drop-offs at one point is 1 stop");

        List<?> stops = (List<?>) route.getBody().get("stops");
        Map<?, ?> stop = (Map<?, ?>) stops.get(0);
        assertEquals(3, stop.get("pickupCount"));
        assertEquals("DROP_OFF_POINT", stop.get("type"));
        assertNotNull(route.getBody().get("depot"));
    }

    @Test
    void routeRespectsVehicleCapacity() {
        List<CollectionPoint> points = pointRepository.findAllActive();

        for (int i = 0; i < 4; i++) {
            UUID detection = storeDetection(new BigDecimal("30.000"));
            String id = (String) rest.postForEntity("/api/v1/pickups",
                    new HttpEntity<>(Map.of("detectionId", detection.toString(),
                            "mode", "DROP_OFF",
                            "collectionPointId", points.get(i).getId().toString()), auth(citizenToken)),
                    Map.class).getBody().get("id");
            rest.exchange("/api/v1/pickups/" + id + "/accept", HttpMethod.POST,
                    new HttpEntity<>(Map.of(), auth(collectorToken)), Map.class);
        }

        ResponseEntity<Map> route = rest.exchange("/api/v1/routes/my-route", HttpMethod.GET,
                new HttpEntity<>(auth(collectorToken)), Map.class);

        assertEquals(4, route.getBody().get("totalRequests"));
        assertEquals(2, route.getBody().get("totalStops"), "80 kg capacity fits two 30 kg stops");
        assertEquals(2, ((List<?>) route.getBody().get("deferredPickupIds")).size());
        assertEquals(60.0, ((Number) route.getBody().get("plannedLoadKg")).doubleValue(), 0.001);
    }

    @Test
    void completingADropOffCreditsWeightBasedPoints() {
        CollectionPoint point = pointRepository.findAllActive().get(0);
        UUID detection = storeDetection(new BigDecimal("2.000"));

        String id = (String) rest.postForEntity("/api/v1/pickups",
                new HttpEntity<>(Map.of("detectionId", detection.toString(),
                        "mode", "DROP_OFF",
                        "collectionPointId", point.getId().toString()), auth(citizenToken)),
                Map.class).getBody().get("id");

        int before = userRepository.findById(citizen.getId()).orElseThrow().getPoints();

        rest.exchange("/api/v1/pickups/" + id + "/accept", HttpMethod.POST,
                new HttpEntity<>(Map.of(), auth(collectorToken)), Map.class);
        rest.exchange("/api/v1/pickups/" + id + "/complete", HttpMethod.POST,
                new HttpEntity<>(Map.of("finalWeightKg", 3.0, "finalAmount", 20.0),
                        auth(collectorToken)), Map.class);

        int after = userRepository.findById(citizen.getId()).orElseThrow().getPoints();
        assertEquals(before + 109, after,
                "20 completion bonus + 3 kg weighed at 8 points/kg + the 65 segregation "
                        + "points the scan was worth, all credited on completion");
    }
}
