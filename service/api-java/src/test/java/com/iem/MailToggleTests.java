package com.iem;

import com.iem.mail.MailService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = "mail.enabled=false")
class MailToggleTests {

    @Autowired
    private MailService mailService;

    @Test
    void mailIsDisabled() {
        assertFalse(mailService.isEnabled());
    }

    @Test
    void otpSendDoesNotThrowWhenMailIsDisabled() {
        assertDoesNotThrow(() -> mailService.sendOtpEmail("nobody@example.com", "123456"));
    }

    @Test
    void backgroundMailsAreNoOps() {
        assertDoesNotThrow(() -> {
            mailService.sendWelcomeEmail("nobody@example.com", "Nobody");
            mailService.sendLoginAlertEmail("nobody@example.com", "127.0.0.1");
            mailService.sendPickupAvailableEmail("nobody@example.com", "12 Park St",
                    "PET Bottle x13", "INR", new java.math.BigDecimal("9.75"));
            mailService.sendPickupAcceptedEmail("nobody@example.com", "Collector", "12 Park St");
        });
    }
}
