package com.iem.admin;

import com.iem.admin.dto.*;
import com.iem.auth.UserRepository;
import com.iem.enums.Role;
import com.iem.exception.ApiException;
import com.iem.geo.CollectionPointRepository;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.Municipality;
import com.iem.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class AdminService {

    private static final Logger log = LoggerFactory.getLogger(AdminService.class);

    private static final DateTimeFormatter DAY = DateTimeFormatter.ofPattern("dd MMM");

    private static final Set<Role> MUNICIPAL_CAN_CREATE = EnumSet.of(Role.COLLECTOR, Role.RECYCLER);
    private static final Set<Role> SUPER_CAN_CREATE =
            EnumSet.of(Role.COLLECTOR, Role.RECYCLER, Role.MUNICIPAL_ADMIN, Role.CITIZEN);

    private final AdminRepository adminRepository;
    private final UserRepository userRepository;
    private final MunicipalityRepository municipalityRepository;
    private final CollectionPointRepository pointRepository;
    private final PasswordEncoder passwordEncoder;

    public AdminService(AdminRepository adminRepository,
                        UserRepository userRepository,
                        MunicipalityRepository municipalityRepository,
                        CollectionPointRepository pointRepository,
                        PasswordEncoder passwordEncoder) {
        this.adminRepository = adminRepository;
        this.userRepository = userRepository;
        this.municipalityRepository = municipalityRepository;
        this.pointRepository = pointRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public OverviewResponse overview(User actor) {

        Map<Role, Long> byRole = adminRepository.usersByRole().stream()
                .collect(Collectors.toMap(r -> (Role) r[0], r -> ((Number) r[1]).longValue()));

        OverviewResponse.Stats stats = new OverviewResponse.Stats(
                adminRepository.totalScans(),
                adminRepository.totalObjects(),
                byRole.getOrDefault(Role.CITIZEN, 0L),
                byRole.getOrDefault(Role.COLLECTOR, 0L),
                byRole.getOrDefault(Role.RECYCLER, 0L),
                adminRepository.totalPickups(),
                adminRepository.completedPickups(),
                scale(adminRepository.wasteDiverted()),
                scale(adminRepository.totalCarbon()),
                adminRepository.totalPoints(),
                pointRepository.count(),
                scale(adminRepository.tradedValue()));

        return new OverviewResponse(
                actor.getRole() == Role.SUPER_ADMIN ? "PLATFORM" : "MUNICIPALITY",
                municipalityName(actor.getMunicipalityId()),
                stats,
                trend(14),
                slices(adminRepository.materialsByBin()),
                slices(adminRepository.usersByRole()),
                topMaterials(),
                slices(adminRepository.pickupsByStatus()),
                new OverviewResponse.Marketplace(
                        adminRepository.openListings(),
                        adminRepository.soldListings(),
                        scale(adminRepository.tradedValue())));
    }

    private List<OverviewResponse.TrendPoint> trend(int days) {
        List<OverviewResponse.TrendPoint> points = new ArrayList<>();
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        for (int i = days - 1; i >= 0; i--) {
            LocalDate day = today.minusDays(i);
            Instant from = day.atStartOfDay(ZoneOffset.UTC).toInstant();
            Instant to = from.plusSeconds(86400);
            points.add(new OverviewResponse.TrendPoint(day.format(DAY),
                    adminRepository.scansBetween(from, to),
                    adminRepository.pickupsBetween(from, to)));
        }
        return points;
    }

    private List<OverviewResponse.MaterialRow> topMaterials() {
        return adminRepository.topMaterials(PageRequest.of(0, 8)).stream()
                .map(r -> new OverviewResponse.MaterialRow(
                        (String) r[0],
                        ((Number) r[1]).longValue(),
                        scale(r[2]),
                        scale(r[3])))
                .toList();
    }

    private static List<OverviewResponse.Slice> slices(List<Object[]> rows) {
        return rows.stream()
                .filter(r -> r[0] != null)
                .map(r -> new OverviewResponse.Slice(String.valueOf(r[0]), ((Number) r[1]).longValue()))
                .toList();
    }

    @Transactional(readOnly = true)
    public Map<String, Object> users(User actor, String role, String search, int page, int size) {

        Role filter = null;
        if (role != null && !role.isBlank()) {
            try {
                filter = Role.valueOf(role.toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new ApiException("Unknown role: " + role, 400);
            }
        }

        boolean staffRole = filter == Role.COLLECTOR || filter == Role.RECYCLER
                || filter == Role.MUNICIPAL_ADMIN;

        UUID scope = actor.getRole() == Role.SUPER_ADMIN || !staffRole
                ? null
                : actor.getMunicipalityId();
        String term = (search == null || search.isBlank()) ? null : "%" + search.toLowerCase() + "%";

        Page<User> results = adminRepository.search(filter, scope, term,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100)));

        return Map.of(
                "items", results.getContent().stream()
                        .map(u -> AdminUserResponse.from(u, municipalityName(u.getMunicipalityId())))
                        .toList(),
                "page", results.getNumber(),
                "size", results.getSize(),
                "totalItems", results.getTotalElements(),
                "totalPages", results.getTotalPages(),
                "hasMore", results.hasNext());
    }

    @Transactional
    public AdminUserResponse createUser(User actor, CreateUserRequest request) {

        Set<Role> allowed = actor.getRole() == Role.SUPER_ADMIN ? SUPER_CAN_CREATE : MUNICIPAL_CAN_CREATE;

        if (!allowed.contains(request.getRole())) {
            throw new ApiException(
                    actor.getRole().name() + " cannot create a " + request.getRole() + " account", 403);
        }

        String email = request.getEmail().trim().toLowerCase();
        if (userRepository.existsByEmail(email)) {
            throw new ApiException("Email already in use", 409);
        }

        UUID municipalityId = request.getMunicipalityId() != null
                ? request.getMunicipalityId()
                : actor.getMunicipalityId();

        if (municipalityId != null && municipalityRepository.findById(municipalityId).isEmpty()) {
            throw new ApiException("Municipality not found", 404);
        }

        if (actor.getRole() == Role.MUNICIPAL_ADMIN && actor.getMunicipalityId() != null) {
            municipalityId = actor.getMunicipalityId();
        }

        User user = new User();
        user.setEmail(email);
        user.setFullName(request.getFullName().trim());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setRole(request.getRole());
        user.setPhone(request.getPhone());
        user.setMunicipalityId(municipalityId);
        user.setCreatedBy(actor.getId());
        user.setEmailVerified(true);
        user.setActive(true);

        userRepository.save(user);
        log.info("{} {} created a {} account for {}", actor.getRole(), actor.getId(),
                request.getRole(), email);

        return AdminUserResponse.from(user, municipalityName(municipalityId));
    }

    @Transactional
    public AdminUserResponse updateUser(User actor, UUID userId, UpdateUserRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException("User not found", 404));

        if (actor.getRole() == Role.MUNICIPAL_ADMIN) {
            if (!MUNICIPAL_CAN_CREATE.contains(user.getRole())) {
                throw new ApiException("You can only manage collectors and recyclers", 403);
            }
            if (actor.getMunicipalityId() != null
                    && !actor.getMunicipalityId().equals(user.getMunicipalityId())) {
                throw new ApiException("That account belongs to another municipality", 403);
            }
        }

        if (user.getRole() == Role.SUPER_ADMIN && !user.getId().equals(actor.getId())) {
            throw new ApiException("A super admin account cannot be modified from here", 403);
        }

        if (request.getActive() != null) {
            user.setActive(request.getActive());
        }
        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            user.setFullName(request.getFullName().trim());
        }
        if (request.getPhone() != null) {
            user.setPhone(request.getPhone());
        }
        if (request.getMunicipalityId() != null && actor.getRole() == Role.SUPER_ADMIN) {
            user.setMunicipalityId(request.getMunicipalityId());
        }

        userRepository.save(user);
        return AdminUserResponse.from(user, municipalityName(user.getMunicipalityId()));
    }

    private String municipalityName(UUID id) {
        if (id == null) {
            return null;
        }
        return municipalityRepository.findById(id).map(Municipality::getName).orElse(null);
    }

    private static BigDecimal scale(Object value) {
        BigDecimal decimal = value == null ? BigDecimal.ZERO : (BigDecimal) value;
        return decimal.setScale(2, java.math.RoundingMode.HALF_UP);
    }
}
