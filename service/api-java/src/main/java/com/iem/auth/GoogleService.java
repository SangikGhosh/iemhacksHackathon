package com.iem.auth;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.iem.enums.AuthProvider;
import com.iem.enums.Role;
import com.iem.exception.ApiException;
import com.iem.model.User;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;

@Service
public class GoogleService {

    public record Result(User user, boolean created) {
    }

    private final UserRepository userRepository;
    private final String clientId;
    private GoogleIdTokenVerifier verifier;

    public GoogleService(UserRepository userRepository,
                         @Value("${google.client-id}") String clientId) {
        this.userRepository = userRepository;
        this.clientId = clientId;
    }

    @PostConstruct
    void init() {
        try {
            this.verifier = new GoogleIdTokenVerifier.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(),
                    GsonFactory.getDefaultInstance())
                    .setAudience(Collections.singletonList(clientId))
                    .build();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to initialize Google token verifier", e);
        }
    }

    @Transactional
    public Result loginWithGoogle(String idTokenString, Role requestedRole) {

        GoogleIdToken idToken;
        try {
            idToken = verifier.verify(idTokenString);
        } catch (Exception e) {
            throw new ApiException("Failed to verify Google token", 400);
        }

        if (idToken == null) {
            throw new ApiException("Invalid Google token", 400);
        }

        GoogleIdToken.Payload payload = idToken.getPayload();

        if (!Boolean.TRUE.equals(payload.getEmailVerified())) {
            throw new ApiException("Google email is not verified", 400);
        }

        String email = payload.getEmail().toLowerCase();
        String name = (String) payload.get("name");

        return userRepository.findByEmail(email)
                .map(existing -> {
                    if (existing.getProvider() != AuthProvider.GOOGLE) {
                        throw new ApiException("Account already exists with a different login method", 400);
                    }
                    if (!existing.isActive()) {
                        throw new ApiException(
                                "This account has been deactivated. Contact your administrator.", 403);
                    }
                    return new Result(existing, false);
                })
                .orElseGet(() -> new Result(create(email, payload.getSubject(), name, requestedRole), true));
    }

    private User create(String email, String googleId, String name, Role requestedRole) {
        User user = new User();
        user.setEmail(email);
        user.setFullName(name == null || name.isBlank() ? email.split("@")[0] : name);
        user.setRole(AuthService.resolveRole(requestedRole));
        user.setProvider(AuthProvider.GOOGLE);
        user.setProviderId(googleId);
        user.setEmailVerified(true);
        return userRepository.save(user);
    }
}
