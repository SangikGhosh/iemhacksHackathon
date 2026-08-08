package com.iem.auth;

import com.iem.auth.dto.*;
import com.iem.mail.MailService;
import com.iem.model.User;
import com.iem.security.UserPrincipal;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;
    private final GoogleService googleService;
    private final OtpService otpService;
    private final MailService mailService;
    private final UserRepository userRepository;

    public AuthController(AuthService authService,
                          GoogleService googleService,
                          OtpService otpService,
                          MailService mailService,
                          UserRepository userRepository) {
        this.authService = authService;
        this.googleService = googleService;
        this.otpService = otpService;
        this.mailService = mailService;
        this.userRepository = userRepository;
    }

    @PostMapping("/send-otp")
    public ResponseEntity<?> sendOtp(@Valid @RequestBody OtpRequest request) {
        String otp = otpService.generate(request.getEmail());
        mailService.sendOtpEmail(request.getEmail(), otp);
        return ResponseEntity.ok(Map.of("message", "OTP sent"));
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        otpService.verify(request.getEmail(), request.getOtp());
        User user = authService.register(request);
        otpService.invalidate(request.getEmail());
        mailService.sendWelcomeEmail(user.getEmail(), user.getFullName());
        return ResponseEntity.ok(authService.buildResponse(user));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request,
                                              HttpServletRequest httpRequest) {
        User user = authService.login(request);
        mailService.sendLoginAlertEmail(user.getEmail(), clientIp(httpRequest));
        return ResponseEntity.ok(authService.buildResponse(user));
    }

    @PostMapping("/google")
    public ResponseEntity<AuthResponse> google(@Valid @RequestBody GoogleLoginRequest request,
                                               HttpServletRequest httpRequest) {
        GoogleService.Result result = googleService.loginWithGoogle(request.getIdToken(), request.getRole());
        User user = result.user();

        if (result.created()) {
            mailService.sendWelcomeEmail(user.getEmail(), user.getFullName());
        } else {
            mailService.sendLoginAlertEmail(user.getEmail(), clientIp(httpRequest));
        }

        return ResponseEntity.ok(authService.buildResponse(user));
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> me(@AuthenticationPrincipal UserPrincipal principal) {
        return userRepository.findById(principal.getId())
                .map(user -> ResponseEntity.ok(UserResponse.from(user)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    private static String clientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
