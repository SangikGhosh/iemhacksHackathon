package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.UserRepository;
import com.iem.auth.dto.RegisterRequest;
import com.iem.chat.AnalyticsCatalog;
import com.iem.chat.AnalyticsService;
import com.iem.chat.ChatMessageRepository;
import com.iem.chat.ToolRegistry;
import com.iem.enums.ChatAuthor;
import com.iem.enums.Role;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.ChatMessage;
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
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class ChatApiTests {

    @Autowired private TestRestTemplate rest;
    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private ChatMessageRepository messageRepository;
    @Autowired private ToolRegistry registry;
    @Autowired private MunicipalityRepository municipalityRepository;
    @Autowired private AnalyticsService analyticsService;

    private String citizenToken;
    private String superToken;
    private String municipalToken;
    private UUID citizenId;

    @BeforeEach
    void setUp() {
        User superAdmin = adminAccount("superadmin@greentech.local", Role.SUPER_ADMIN);
        User municipalAdmin = adminAccount("hmc.admin@greentech.local", Role.MUNICIPAL_ADMIN);
        User citizen = register("chat-citizen", Role.CITIZEN);

        superToken = authService.buildResponse(superAdmin).accessToken();
        municipalToken = authService.buildResponse(municipalAdmin).accessToken();
        citizenToken = authService.buildResponse(citizen).accessToken();
        citizenId = citizen.getId();
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

    private User register(String prefix, Role role) {
        RegisterRequest r = new RegisterRequest();
        r.setEmail(prefix + "-" + UUID.randomUUID() + "@example.com");
        r.setFullName(prefix);
        r.setPassword("password123");
        r.setOtp("000000");
        r.setRole(role);
        return authService.register(r);
    }

    private HttpHeaders auth(String token) {
        HttpHeaders h = new HttpHeaders();
        h.setBearerAuth(token);
        h.setContentType(MediaType.APPLICATION_JSON);
        return h;
    }

    @SuppressWarnings("rawtypes")
    private ResponseEntity<Map> capabilities(String token) {
        return rest.exchange("/api/v1/chat/capabilities", HttpMethod.GET,
                new HttpEntity<>(auth(token)), Map.class);
    }

    @Test
    void chatRequiresAuthentication() {
        ResponseEntity<Map> response = rest.exchange("/api/v1/chat", HttpMethod.POST,
                new HttpEntity<>(Map.of("message", "hello")), Map.class);
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    void capabilitiesRequiresAuthentication() {
        ResponseEntity<Map> response = rest.exchange("/api/v1/chat/capabilities", HttpMethod.GET,
                HttpEntity.EMPTY, Map.class);
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    @SuppressWarnings("unchecked")
    void citizenNeverSeesAdminTools() {
        ResponseEntity<Map> response = capabilities(citizenToken);
        assertEquals(HttpStatus.OK, response.getStatusCode());

        List<Map<String, String>> tools = (List<Map<String, String>>) response.getBody().get("tools");
        Set<String> names = Set.copyOf(tools.stream().map(t -> t.get("name")).toList());

        assertFalse(names.contains("query_analytics"));
        assertFalse(names.contains("get_operations_snapshot"));
        assertFalse(names.contains("find_people"));
        assertFalse(names.contains("get_municipalities"));
        assertTrue(names.contains("get_my_rewards_summary"));
        assertTrue(names.contains("get_my_wallet_summary"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void municipalAdminGetsAnalyticsButNotMunicipalityDirectory() {
        List<Map<String, String>> tools =
                (List<Map<String, String>>) capabilities(municipalToken).getBody().get("tools");
        Set<String> names = Set.copyOf(tools.stream().map(t -> t.get("name")).toList());

        assertTrue(names.contains("query_analytics"));
        assertTrue(names.contains("find_people"));
        assertFalse(names.contains("get_municipalities"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void superAdminGetsEverything() {
        List<Map<String, String>> tools =
                (List<Map<String, String>>) capabilities(superToken).getBody().get("tools");
        Set<String> names = Set.copyOf(tools.stream().map(t -> t.get("name")).toList());

        assertTrue(names.contains("query_analytics"));
        assertTrue(names.contains("get_municipalities"));
        assertTrue(names.contains("get_operations_snapshot"));
    }

    @Test
    void registryRefusesToResolveAToolTheRoleDoesNotOwn() {
        assertNull(registry.resolve(Role.CITIZEN, "query_analytics"));
        assertNull(registry.resolve(Role.COLLECTOR, "get_municipalities"));
        assertNull(registry.resolve(Role.MUNICIPAL_ADMIN, "get_municipalities"));
        assertNotNull(registry.resolve(Role.SUPER_ADMIN, "query_analytics"));
        assertNotNull(registry.resolve(Role.CITIZEN, "get_my_rewards_summary"));
    }

    @Test
    void everyRoleHasAtLeastOneTool() {
        for (Role role : Role.values()) {
            assertFalse(registry.forRole(role).isEmpty(), role + " has no tools");
        }
    }

    @Test
    void assistantReportsDisabledWhenNoApiKeyIsConfigured() {
        Map body = capabilities(citizenToken).getBody();
        assertEquals(Boolean.FALSE, body.get("enabled"));
        assertEquals("CITIZEN", body.get("role"));
    }

    @Test
    void askingWithoutAnApiKeyFailsCleanlyRatherThanCrashing() {
        ResponseEntity<Map> response = rest.exchange("/api/v1/chat", HttpMethod.POST,
                new HttpEntity<>(Map.of("message", "what are my points?"), auth(citizenToken)),
                Map.class);
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertNotNull(response.getBody().get("error"));
    }

    @Test
    void blankMessageIsRejected() {
        ResponseEntity<Map> response = rest.exchange("/api/v1/chat", HttpMethod.POST,
                new HttpEntity<>(Map.of("message", "   "), auth(citizenToken)), Map.class);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    }

    @Test
    void oneUserCannotReadAnotherUsersConversation() {
        UUID conversationId = UUID.randomUUID();

        ChatMessage message = new ChatMessage();
        message.setConversationId(conversationId);
        message.setUserId(citizenId);
        message.setAuthor(ChatAuthor.USER);
        message.setContent("my private question");
        messageRepository.save(message);

        ResponseEntity<Map> own = rest.exchange("/api/v1/chat/conversations/" + conversationId,
                HttpMethod.GET, new HttpEntity<>(auth(citizenToken)), Map.class);
        assertEquals(HttpStatus.OK, own.getStatusCode());

        ResponseEntity<Map> other = rest.exchange("/api/v1/chat/conversations/" + conversationId,
                HttpMethod.GET, new HttpEntity<>(auth(superToken)), Map.class);
        assertEquals(HttpStatus.NOT_FOUND, other.getStatusCode());
    }

    @Test
    void postingIntoSomeoneElsesConversationIsRejected() {
        UUID conversationId = UUID.randomUUID();

        ChatMessage message = new ChatMessage();
        message.setConversationId(conversationId);
        message.setUserId(citizenId);
        message.setAuthor(ChatAuthor.USER);
        message.setContent("mine");
        messageRepository.save(message);

        ResponseEntity<Map> response = rest.exchange("/api/v1/chat", HttpMethod.POST,
                new HttpEntity<>(Map.of("message", "steal", "conversationId", conversationId.toString()),
                        auth(superToken)), Map.class);
        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
    }

    @Test
    void analyticsRejectsAnUnknownMetric() {
        assertThrows(RuntimeException.class,
                () -> analyticsService.run("drop table users", "none", "today", null, 10));
    }

    @Test
    void analyticsRejectsADimensionTheMetricDoesNotSupport() {
        assertThrows(RuntimeException.class,
                () -> analyticsService.run("scans", "bin", "today", null, 10));
    }

    @Test
    void everyCatalogueMetricActuallyRuns() {
        for (String metric : AnalyticsCatalog.metricKeys()) {
            Map<String, Object> result = analyticsService.run(metric, "none", "all_time", null, 10);
            assertEquals(metric, result.get("metric"), metric + " did not run");
            assertNotNull(result.get("value"), metric + " returned no value");
        }
    }

    @Test
    void everySupportedDimensionActuallyRuns() {
        for (String metric : AnalyticsCatalog.metricKeys()) {
            for (AnalyticsCatalog.Dimension dimension
                    : AnalyticsCatalog.METRICS.get(metric).dimensions().keySet()) {
                Map<String, Object> result = analyticsService.run(
                        metric, dimension.name(), "all_time", null, 10);
                assertNotNull(result.get("breakdown"),
                        metric + " grouped by " + dimension + " returned no breakdown");
            }
        }
    }

    @Test
    void everyPeriodResolves() {
        for (String period : AnalyticsService.periods()) {
            assertNotNull(AnalyticsService.resolve(period).label(), period + " did not resolve");
        }
        assertThrows(RuntimeException.class, () -> AnalyticsService.resolve("last_century"));
    }

    @Test
    void municipalScopeIsAppliedToAnalytics() {
        UUID scope = UUID.randomUUID();
        Map<String, Object> scoped = analyticsService.run("scans", "none", "all_time", scope, 10);
        assertEquals("your municipality", scoped.get("scope"));

        Map<String, Object> platform = analyticsService.run("scans", "none", "all_time", null, 10);
        assertEquals("platform", platform.get("scope"));
    }
}
