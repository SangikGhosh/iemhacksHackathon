package com.iem.admin;

import com.iem.admin.dto.*;
import com.iem.auth.UserRepository;
import com.iem.exception.ApiException;
import com.iem.geo.CollectionPointRepository;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.User;
import com.iem.security.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SUPER_ADMIN')")
public class AdminController {

    private final AdminService adminService;
    private final AdminGeoService adminGeoService;
    private final SystemHealthService systemHealthService;
    private final UserRepository userRepository;
    private final MunicipalityRepository municipalityRepository;
    private final CollectionPointRepository pointRepository;

    public AdminController(AdminService adminService,
                           AdminGeoService adminGeoService,
                           SystemHealthService systemHealthService,
                           UserRepository userRepository,
                           MunicipalityRepository municipalityRepository,
                           CollectionPointRepository pointRepository) {
        this.adminService = adminService;
        this.adminGeoService = adminGeoService;
        this.systemHealthService = systemHealthService;
        this.userRepository = userRepository;
        this.municipalityRepository = municipalityRepository;
        this.pointRepository = pointRepository;
    }

    private User actor(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException("Account not found", 404));
    }

    @GetMapping("/overview")
    public ResponseEntity<OverviewResponse> overview(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(adminService.overview(actor(principal)));
    }

    @GetMapping("/system-health")
    public ResponseEntity<SystemHealthResponse> systemHealth() {
        return ResponseEntity.ok(systemHealthService.check());
    }

    @GetMapping("/users")
    public ResponseEntity<Map<String, Object>> users(@AuthenticationPrincipal UserPrincipal principal,
                                                     @RequestParam(required = false) String role,
                                                     @RequestParam(required = false) String search,
                                                     @RequestParam(defaultValue = "0") int page,
                                                     @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(adminService.users(actor(principal), role, search, page, size));
    }

    @PostMapping("/users")
    public ResponseEntity<AdminUserResponse> createUser(@AuthenticationPrincipal UserPrincipal principal,
                                                        @Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(adminService.createUser(actor(principal), request));
    }

    @PatchMapping("/users/{id}")
    public ResponseEntity<AdminUserResponse> updateUser(@AuthenticationPrincipal UserPrincipal principal,
                                                        @PathVariable UUID id,
                                                        @Valid @RequestBody UpdateUserRequest request) {
        return ResponseEntity.ok(adminService.updateUser(actor(principal), id, request));
    }

    @GetMapping("/collection-points")
    public ResponseEntity<Map<String, Object>> points(
            @AuthenticationPrincipal UserPrincipal principal) {

        User caller = actor(principal);

        List<com.iem.model.CollectionPoint> found =
                caller.getRole() == com.iem.enums.Role.SUPER_ADMIN
                        || caller.getMunicipalityId() == null
                        ? pointRepository.findAllWithMunicipality()
                        : pointRepository.findByMunicipalityIdWithMunicipality(caller.getMunicipalityId());

        List<Map<String, Object>> items = found.stream()
                .map(p -> {
                    Map<String, Object> item = new java.util.LinkedHashMap<>();
                    item.put("id", p.getId());
                    item.put("code", p.getCode());
                    item.put("name", p.getName());
                    item.put("locality", p.getLocality() == null ? "" : p.getLocality());
                    item.put("ward", p.getWard() == null ? "" : p.getWard());
                    item.put("type", p.getType());
                    item.put("lat", p.getLat());
                    item.put("lon", p.getLon());
                    item.put("active", p.isActive());
                    item.put("municipality", p.getMunicipality().getName());
                    item.put("municipalityCode", p.getMunicipality().getCode());
                    item.put("district", p.getMunicipality().getDistrict());
                    return item;
                })
                .toList();

        List<Map<String, Object>> depots = municipalityRepository.findAll().stream()
                .filter(m -> caller.getRole() == com.iem.enums.Role.SUPER_ADMIN
                        || caller.getMunicipalityId() == null
                        || m.getId().equals(caller.getMunicipalityId()))
                .map(m -> Map.<String, Object>of(
                        "code", m.getCode(), "name", m.getDepotName(),
                        "municipality", m.getName(), "district", m.getDistrict(),
                        "lat", m.getDepotLat(), "lon", m.getDepotLon()))
                .toList();

        return ResponseEntity.ok(Map.of(
                "count", items.size(),
                "scope", caller.getRole() == com.iem.enums.Role.SUPER_ADMIN ? "PLATFORM" : "MUNICIPALITY",
                "points", items,
                "depots", depots));
    }

    @PostMapping("/collection-points")
    public ResponseEntity<Map<String, Object>> createPoint(@Valid @RequestBody CollectionPointRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(adminGeoService.createPoint(request));
    }

    @PatchMapping("/collection-points/{id}")
    public ResponseEntity<Map<String, Object>> updatePoint(@PathVariable UUID id,
                                                           @Valid @RequestBody CollectionPointRequest request) {
        return ResponseEntity.ok(adminGeoService.updatePoint(id, request));
    }

    @DeleteMapping("/collection-points/{id}")
    public ResponseEntity<Map<String, String>> deletePoint(@PathVariable UUID id) {
        adminGeoService.deactivatePoint(id);
        return ResponseEntity.ok(Map.of("message", "Collection point deactivated"));
    }

    @GetMapping("/municipalities")
    public ResponseEntity<Map<String, Object>> municipalities() {
        List<Map<String, Object>> items = municipalityRepository.findAll().stream()
                .map(m -> Map.<String, Object>of(
                        "id", m.getId(), "code", m.getCode(), "name", m.getName(),
                        "district", m.getDistrict(), "state", m.getState(),
                        "depotName", m.getDepotName(), "depotLat", m.getDepotLat(),
                        "depotLon", m.getDepotLon(), "active", m.isActive()))
                .toList();
        return ResponseEntity.ok(Map.of("count", items.size(), "municipalities", items));
    }

    @PostMapping("/municipalities")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> createMunicipality(
            @Valid @RequestBody MunicipalityRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(adminGeoService.createMunicipality(request));
    }

    @PatchMapping("/municipalities/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> updateMunicipality(
            @PathVariable UUID id, @RequestBody MunicipalityRequest request) {
        return ResponseEntity.ok(adminGeoService.updateMunicipality(id, request));
    }
}
