package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.UserRepository;
import com.iem.auth.dto.RegisterRequest;
import com.iem.enums.Role;
import com.iem.geo.CollectionPointRepository;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AdminApiTests {

    @Autowired private TestRestTemplate rest;
    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private MunicipalityRepository municipalityRepository;
    @Autowired private CollectionPointRepository pointRepository;

    private String superToken;
    private String municipalToken;
    private String citizenToken;

    @BeforeEach
    void setUp() {
        User superAdmin = adminAccount("superadmin@greentech.local", Role.SUPER_ADMIN);
        User municipalAdmin = adminAccount("hmc.admin@greentech.local", Role.MUNICIPAL_ADMIN);

        superToken = authService.buildResponse(superAdmin).accessToken();
        municipalToken = authService.buildResponse(municipalAdmin).accessToken();
        citizenToken = authService.buildResponse(register("admin-citizen")).accessToken();
    }

    /**
     * The seeder creates these on boot, but several other test classes call
     * userRepository.deleteAll() in their own setUp and every class shares one Spring context
     * and one H2 database. Whether the seeded rows still exist therefore depends on class
     * execution order, which surefire does not guarantee and which differs between a laptop
     * and CI. Recreating them here makes this class independent of that order.
     */
    private User adminAccount(String email, Role role) {
        return userRepository.findByEmail(email).orElseGet(() -> {
            User user = new User();
            user.setEmail(email);
            user.setFullName(role == Role.SUPER_ADMIN ? "Platform Super Admin" : "Municipal Admin");
            user.setPassword("{noop}not-used-in-tests");
            user.setRole(role);
            user.setEmailVerified(true);
            user.setActive(true);
            if (role == Role.MUNICIPAL_ADMIN) {
                municipalityRepository.findByCode("HMC")
                        .ifPresent(m -> user.setMunicipalityId(m.getId()));
            }
            return userRepository.save(user);
        });
    }

    private User register(String prefix) {
        RegisterRequest r = new RegisterRequest();
        r.setEmail(prefix + "-" + UUID.randomUUID() + "@example.com");
        r.setFullName(prefix);
        r.setPassword("password123");
        r.setOtp("000000");
        r.setRole(Role.CITIZEN);
        return authService.register(r);
    }

    private HttpHeaders auth(String token) {
        HttpHeaders h = new HttpHeaders();
        h.setBearerAuth(token);
        h.setContentType(MediaType.APPLICATION_JSON);
        return h;
    }

    private ResponseEntity<Map> get(String path, String token) {
        return rest.exchange(path, HttpMethod.GET, new HttpEntity<>(auth(token)), Map.class);
    }

    private ResponseEntity<Map> post(String path, String token, Object body) {
        return rest.exchange(path, HttpMethod.POST, new HttpEntity<>(body, auth(token)), Map.class);
    }

    @Test
    void bothAdminAccountsAreSeeded() {
        User superAdmin = userRepository.findByEmail("superadmin@greentech.local").orElseThrow();
        User municipal = userRepository.findByEmail("hmc.admin@greentech.local").orElseThrow();

        assertEquals(Role.SUPER_ADMIN, superAdmin.getRole());
        assertEquals(Role.MUNICIPAL_ADMIN, municipal.getRole());
        assertNotNull(municipal.getMunicipalityId(), "municipal admin is bound to HMC");
        assertEquals(municipalityRepository.findByCode("HMC").orElseThrow().getId(),
                municipal.getMunicipalityId());
    }

    @Test
    void citizensAreLockedOutOfAdmin() {
        assertEquals(HttpStatus.FORBIDDEN, get("/api/v1/admin/overview", citizenToken).getStatusCode());
        assertEquals(HttpStatus.FORBIDDEN, get("/api/v1/admin/users", citizenToken).getStatusCode());
        assertEquals(HttpStatus.UNAUTHORIZED,
                rest.getForEntity("/api/v1/admin/overview", String.class).getStatusCode());
    }

    @Test
    void overviewReturnsStatsAndCharts() {
        ResponseEntity<Map> response = get("/api/v1/admin/overview", municipalToken);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        Map<?, ?> body = response.getBody();
        assertEquals("MUNICIPALITY", body.get("scope"));
        assertNotNull(body.get("stats"));
        assertEquals(14, ((List<?>) body.get("trend")).size(), "14 day trend");
        assertNotNull(body.get("roleSplit"));
        assertNotNull(body.get("marketplace"));

        Map<?, ?> stats = (Map<?, ?>) body.get("stats");
        assertTrue(((Number) stats.get("collectionPoints")).longValue() >= 150);
    }

    @Test
    void superAdminScopeDiffers() {
        assertEquals("PLATFORM", get("/api/v1/admin/overview", superToken).getBody().get("scope"));
    }

    @Test
    void municipalAdminCreatesACollector() {
        String email = "collector-" + UUID.randomUUID() + "@example.com";

        ResponseEntity<Map> response = post("/api/v1/admin/users", municipalToken,
                Map.of("email", email, "fullName", "New Collector",
                        "password", "password123", "role", "COLLECTOR", "phone", "+919876543210"));

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertEquals("COLLECTOR", response.getBody().get("role"));
        assertEquals(true, response.getBody().get("active"));
        assertNotNull(response.getBody().get("municipalityId"), "inherits the admin's municipality");

        User created = userRepository.findByEmail(email).orElseThrow();
        assertTrue(created.isEmailVerified(), "admin-created accounts skip OTP");
    }

    @Test
    void municipalAdminCannotCreateAnotherAdmin() {
        ResponseEntity<Map> response = post("/api/v1/admin/users", municipalToken,
                Map.of("email", "x-" + UUID.randomUUID() + "@example.com", "fullName", "Nope",
                        "password", "password123", "role", "MUNICIPAL_ADMIN"));
        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
    }

    @Test
    void superAdminCanCreateAMunicipalAdmin() {
        ResponseEntity<Map> response = post("/api/v1/admin/users", superToken,
                Map.of("email", "ma-" + UUID.randomUUID() + "@example.com", "fullName", "New MA",
                        "password", "password123", "role", "MUNICIPAL_ADMIN"));
        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertEquals("MUNICIPAL_ADMIN", response.getBody().get("role"));
    }

    @Test
    void duplicateEmailIsRejected() {
        ResponseEntity<Map> response = post("/api/v1/admin/users", superToken,
                Map.of("email", "superadmin@greentech.local", "fullName", "Dup",
                        "password", "password123", "role", "COLLECTOR"));
        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
    }

    @Test
    void deactivatingAUserBlocksTheirToken() {
        String email = "deact-" + UUID.randomUUID() + "@example.com";
        String id = (String) post("/api/v1/admin/users", municipalToken,
                Map.of("email", email, "fullName", "Temp", "password", "password123",
                        "role", "COLLECTOR")).getBody().get("id");

        String token = authService.buildResponse(userRepository.findByEmail(email).orElseThrow())
                .accessToken();
        assertEquals(HttpStatus.OK, get("/auth/me", token).getStatusCode());

        ResponseEntity<Map> patched = rest.exchange("/api/v1/admin/users/" + id, HttpMethod.PATCH,
                new HttpEntity<>(Map.of("active", false), auth(municipalToken)), Map.class);
        assertEquals(false, patched.getBody().get("active"));

        assertEquals(HttpStatus.UNAUTHORIZED, get("/auth/me", token).getStatusCode(),
                "a deactivated account cannot use an existing token");

        ResponseEntity<String> login = rest.postForEntity("/auth/login",
                Map.of("email", email, "password", "password123"), String.class);
        assertEquals(HttpStatus.FORBIDDEN, login.getStatusCode(),
                "a deactivated account cannot log in again either");
    }

    @Test
    void usersCanBeFilteredAndSearched() {
        post("/api/v1/admin/users", municipalToken,
                Map.of("email", "findme-" + UUID.randomUUID() + "@example.com",
                        "fullName", "Findable Collector", "password", "password123",
                        "role", "COLLECTOR"));

        ResponseEntity<Map> byRole = get("/api/v1/admin/users?role=COLLECTOR", superToken);
        assertEquals(HttpStatus.OK, byRole.getStatusCode());
        assertTrue(((List<?>) byRole.getBody().get("items")).size() >= 1);

        ResponseEntity<Map> bySearch = get("/api/v1/admin/users?search=Findable", superToken);
        assertEquals(1, ((List<?>) bySearch.getBody().get("items")).size());

        assertEquals(HttpStatus.BAD_REQUEST,
                get("/api/v1/admin/users?role=WIZARD", superToken).getStatusCode());
    }

    @Test
    void adminCanCreateAndDeactivateACollectionPoint() {
        long before = pointRepository.count();

        ResponseEntity<Map> created = post("/api/v1/admin/collection-points", municipalToken,
                Map.of("municipalityCode", "HMC", "name", "Test Point", "locality", "Shibpur",
                        "ward", "Ward 9", "type", "BIN_CLUSTER", "lat", 22.5671, "lon", 88.2977));

        assertEquals(HttpStatus.CREATED, created.getStatusCode());
        assertEquals(before + 1, pointRepository.count());
        String id = String.valueOf(created.getBody().get("id"));

        ResponseEntity<Map> patched = rest.exchange("/api/v1/admin/collection-points/" + id,
                HttpMethod.PATCH, new HttpEntity<>(Map.of("name", "Renamed Point",
                        "lat", 22.57, "lon", 88.30), auth(municipalToken)), Map.class);
        assertEquals("Renamed Point", patched.getBody().get("name"));

        rest.exchange("/api/v1/admin/collection-points/" + id, HttpMethod.DELETE,
                new HttpEntity<>(auth(municipalToken)), Map.class);
        assertFalse(pointRepository.findById(UUID.fromString(id)).orElseThrow().isActive());
    }

    @Test
    void onlySuperAdminManagesMunicipalities() {
        Map<String, Object> body = Map.of("code", "TST" + System.nanoTime() % 1000,
                "name", "Test Municipality", "district", "Howrah",
                "depotLat", 22.60, "depotLon", 88.31);

        assertEquals(HttpStatus.FORBIDDEN,
                post("/api/v1/admin/municipalities", municipalToken, body).getStatusCode());

        ResponseEntity<Map> created = post("/api/v1/admin/municipalities", superToken, body);
        assertEquals(HttpStatus.CREATED, created.getStatusCode());
        assertNotNull(created.getBody().get("id"));
    }

    @Test
    void bothAdminsCanReadMunicipalitiesAndPoints() {
        assertEquals(HttpStatus.OK, get("/api/v1/admin/municipalities", municipalToken).getStatusCode());
        assertEquals(HttpStatus.OK, get("/api/v1/admin/collection-points", municipalToken).getStatusCode());
        assertTrue(((Number) get("/api/v1/admin/collection-points", superToken)
                .getBody().get("count")).intValue() >= 150);
    }
}
