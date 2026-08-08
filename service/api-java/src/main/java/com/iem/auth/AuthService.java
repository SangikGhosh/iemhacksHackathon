package com.iem.auth;

import com.iem.auth.dto.AuthResponse;
import com.iem.auth.dto.LoginRequest;
import com.iem.auth.dto.RegisterRequest;
import com.iem.auth.dto.UserResponse;
import com.iem.enums.AuthProvider;
import com.iem.enums.Role;
import com.iem.exception.ApiException;
import com.iem.model.User;
import com.iem.security.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public User register(RegisterRequest request) {

        String email = normalize(request.getEmail());

        if (userRepository.existsByEmail(email)) {
            throw new ApiException("Email already in use", 400);
        }

        User user = new User();
        user.setEmail(email);
        user.setFullName(request.getFullName().trim());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setRole(resolveRole(request.getRole()));
        user.setProvider(AuthProvider.LOCAL);
        user.setEmailVerified(true);

        return userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public User login(LoginRequest request) {

        User user = userRepository.findByEmail(normalize(request.getEmail()))
                .orElseThrow(() -> new ApiException("Invalid credentials", 401));

        if (user.getProvider() != AuthProvider.LOCAL || user.getPassword() == null) {
            throw new ApiException("Please use " + user.getProvider() + " to log in", 400);
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new ApiException("Invalid credentials", 401);
        }

        return user;
    }

    public AuthResponse buildResponse(User user) {
        return new AuthResponse(
                jwtService.generateToken(user.getId(), user.getRole().name()),
                "Bearer",
                jwtService.getExpirationSeconds(),
                UserResponse.from(user)
        );
    }

    public static Role resolveRole(Role requested) {
        if (requested == null) {
            return Role.CITIZEN;
        }
        if (requested == Role.MUNICIPAL_ADMIN || requested == Role.SUPER_ADMIN) {
            throw new ApiException("This role cannot be self-assigned", 403);
        }
        return requested;
    }

    private static String normalize(String email) {
        return email.trim().toLowerCase();
    }
}
