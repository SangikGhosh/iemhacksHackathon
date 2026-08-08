package com.iem;

import com.iem.auth.dto.LoginRequest;
import com.iem.auth.dto.RegisterRequest;
import com.iem.auth.AuthService;
import com.iem.auth.OtpService;
import com.iem.enums.Role;
import com.iem.model.User;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class ApiApplicationTests {

    @Autowired
    private AuthService authService;

    @Autowired
    private OtpService otpService;

    @Test
    void contextLoads() {
    }

    @Test
    void registerThenLogin() {
        RegisterRequest register = new RegisterRequest();
        register.setEmail("John@Gmail.com");
        register.setFullName("John Doe");
        register.setPassword("password123");
        register.setOtp(otpService.generate("John@Gmail.com"));
        register.setRole(Role.CITIZEN);

        otpService.verify(register.getEmail(), register.getOtp());
        User created = authService.register(register);

        assertEquals("john@gmail.com", created.getEmail());
        assertEquals(Role.CITIZEN, created.getRole());
        assertEquals(0, created.getPoints());

        LoginRequest login = new LoginRequest();
        login.setEmail("john@gmail.com");
        login.setPassword("password123");

        User loggedIn = authService.login(login);
        assertEquals(created.getId(), loggedIn.getId());
        assertNotNull(authService.buildResponse(loggedIn).accessToken());
    }
}
