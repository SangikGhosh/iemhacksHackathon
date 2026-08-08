package com.iem.admin;

import com.iem.auth.UserRepository;
import com.iem.enums.AuthProvider;
import com.iem.enums.Role;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.Municipality;
import com.iem.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Component
@Order(20)
public class AdminSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminSeeder.class);

    private final UserRepository userRepository;
    private final MunicipalityRepository municipalityRepository;
    private final PasswordEncoder passwordEncoder;

    private final boolean enabled;
    private final String superEmail;
    private final String superPassword;
    private final String superName;
    private final String municipalEmail;
    private final String municipalPassword;
    private final String municipalName;
    private final String municipalCode;

    public AdminSeeder(UserRepository userRepository,
                       MunicipalityRepository municipalityRepository,
                       PasswordEncoder passwordEncoder,
                       @Value("${admin.seed.enabled:true}") boolean enabled,
                       @Value("${admin.seed.super.email:superadmin@greentech.local}") String superEmail,
                       @Value("${admin.seed.super.password:}") String superPassword,
                       @Value("${admin.seed.super.name:Platform Super Admin}") String superName,
                       @Value("${admin.seed.municipal.email:hmc.admin@greentech.local}") String municipalEmail,
                       @Value("${admin.seed.municipal.password:}") String municipalPassword,
                       @Value("${admin.seed.municipal.name:Howrah Municipal Admin}") String municipalName,
                       @Value("${admin.seed.municipal.code:HMC}") String municipalCode) {
        this.userRepository = userRepository;
        this.municipalityRepository = municipalityRepository;
        this.passwordEncoder = passwordEncoder;
        this.enabled = enabled;
        this.superEmail = superEmail;
        this.superPassword = superPassword;
        this.superName = superName;
        this.municipalEmail = municipalEmail;
        this.municipalPassword = municipalPassword;
        this.municipalName = municipalName;
        this.municipalCode = municipalCode;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {

        if (!enabled) {
            return;
        }

        if (superPassword.isBlank() || municipalPassword.isBlank()) {
            log.warn("Admin seeding skipped - set ADMIN_SEED_SUPER_PASSWORD and "
                    + "ADMIN_SEED_MUNICIPAL_PASSWORD. No default is used on purpose.");
            return;
        }

        UUID municipalityId = municipalityRepository.findByCode(municipalCode)
                .map(Municipality::getId)
                .orElse(null);

        boolean createdSuper = seed(superEmail, superName, superPassword, Role.SUPER_ADMIN, null);
        boolean createdMunicipal = seed(municipalEmail, municipalName, municipalPassword,
                Role.MUNICIPAL_ADMIN, municipalityId);

        if (createdSuper || createdMunicipal) {
            log.info("Admin accounts ready: {} (SUPER_ADMIN), {} (MUNICIPAL_ADMIN for {})",
                    superEmail, municipalEmail, municipalCode);
        }
    }

    private boolean seed(String email, String name, String password, Role role, UUID municipalityId) {

        String normalized = email.trim().toLowerCase();

        if (userRepository.existsByEmail(normalized)) {
            return false;
        }

        User user = new User();
        user.setEmail(normalized);
        user.setFullName(name);
        user.setPassword(passwordEncoder.encode(password));
        user.setRole(role);
        user.setProvider(AuthProvider.LOCAL);
        user.setEmailVerified(true);
        user.setActive(true);
        user.setMunicipalityId(municipalityId);

        userRepository.save(user);
        log.info("Seeded {} account: {}", role, normalized);
        return true;
    }
}
