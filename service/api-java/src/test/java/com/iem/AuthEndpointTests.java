package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.dto.AuthResponse;
import com.iem.auth.dto.RegisterRequest;
import com.iem.enums.Role;
import com.iem.model.User;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AuthEndpointTests {

    @Autowired
    private TestRestTemplate rest;

    @Autowired
    private AuthService authService;

    @Test
    void healthIsPublic() {
        assertEquals(HttpStatus.OK, rest.getForEntity("/health", String.class).getStatusCode());
    }

    @Test
    void meRequiresToken() {
        assertEquals(HttpStatus.UNAUTHORIZED, rest.getForEntity("/auth/me", String.class).getStatusCode());
    }

    @Test
    void loginRejectsUnknownUser() {
        ResponseEntity<String> response = rest.postForEntity("/auth/login",
                Map.of("email", "nobody@example.com", "password", "password123"), String.class);
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    void meReturnsProfileForValidToken() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("collector@example.com");
        request.setFullName("Ravi Kumar");
        request.setPassword("password123");
        request.setOtp("000000");
        request.setRole(Role.COLLECTOR);

        User user = authService.register(request);
        AuthResponse auth = authService.buildResponse(user);

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(auth.accessToken());

        ResponseEntity<Map> response = rest.exchange("/auth/me", HttpMethod.GET,
                new HttpEntity<>(headers), Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("collector@example.com", response.getBody().get("email"));
        assertEquals("Ravi Kumar", response.getBody().get("fullName"));
        assertEquals("COLLECTOR", response.getBody().get("role"));
        assertEquals(0, response.getBody().get("points"));
        assertNotNull(response.getBody().get("id"));
    }
}
