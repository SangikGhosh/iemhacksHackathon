package com.iem.auth;

import com.iem.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final Duration TTL = Duration.ofMinutes(10);

    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    private record Entry(String code, Instant expiresAt) {
    }

    public String generate(String email) {
        purgeExpired();
        String code = String.format("%06d", RANDOM.nextInt(1_000_000));
        store.put(key(email), new Entry(code, Instant.now().plus(TTL)));
        log.info("OTP generated for {}: {}", email, code);
        return code;
    }

    private void purgeExpired() {
        Instant now = Instant.now();
        store.values().removeIf(entry -> entry.expiresAt().isBefore(now));
    }

    public void verify(String email, String code) {
        Entry entry = store.get(key(email));

        if (entry == null || entry.expiresAt().isBefore(Instant.now())) {
            store.remove(key(email));
            throw new ApiException("OTP has expired or was not requested. Please request a new one.", 400);
        }

        if (!entry.code().equals(code)) {
            throw new ApiException("Invalid OTP. Please check the code and try again.", 400);
        }
    }

    public void invalidate(String email) {
        store.remove(key(email));
    }

    private static String key(String email) {
        return email.trim().toLowerCase();
    }
}
