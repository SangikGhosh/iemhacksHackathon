package com.iem.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

@Component
public class JwtService {

    private static final Logger log = LoggerFactory.getLogger(JwtService.class);

    private final SecretKey key;
    private final long expirationMs;

    public JwtService(@Value("${jwt.secret:}") String secret,
                      @Value("${jwt.expirationMs}") long expirationMs) {
        this.key = resolveKey(secret);
        this.expirationMs = expirationMs;
    }

    private static SecretKey resolveKey(String secret) {
        if (secret == null || secret.isBlank()) {
            log.warn("jwt.secret is not set - generating an ephemeral key, tokens will not survive a restart");
            return Jwts.SIG.HS256.key().build();
        }
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret));
    }

    public String generateToken(UUID userId, String role) {
        return Jwts.builder()
                .claims(Map.of("role", role))
                .subject(userId.toString())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expirationMs))
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    public UUID extractUserId(String token) {
        return UUID.fromString(parse(token).getSubject());
    }

    public boolean isValid(String token) {
        try {
            return parse(token).getExpiration().after(new Date());
        } catch (Exception e) {
            return false;
        }
    }

    public long getExpirationSeconds() {
        return expirationMs / 1000;
    }

    private Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
