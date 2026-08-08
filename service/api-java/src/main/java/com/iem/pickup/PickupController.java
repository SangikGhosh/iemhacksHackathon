package com.iem.pickup;

import com.iem.pickup.dto.*;
import com.iem.security.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/pickups")
public class PickupController {

    private final PickupService pickupService;

    public PickupController(PickupService pickupService) {
        this.pickupService = pickupService;
    }

    @PostMapping
    public ResponseEntity<PickupResponse> create(@AuthenticationPrincipal UserPrincipal principal,
                                                 @Valid @RequestBody CreatePickupRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(pickupService.create(principal.getId(), request));
    }

    @GetMapping
    public ResponseEntity<PickupListResponse> mine(@AuthenticationPrincipal UserPrincipal principal,
                                                   @RequestParam(defaultValue = "0") int page,
                                                   @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(
                pickupService.mine(principal.getId(), principal.getRole(), page, size));
    }

    @GetMapping("/available")
    @PreAuthorize("hasRole('COLLECTOR')")
    public ResponseEntity<PickupListResponse> available(@RequestParam(defaultValue = "0") int page,
                                                        @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(pickupService.available(page, size));
    }

    @GetMapping("/{id}")
    public ResponseEntity<PickupResponse> get(@AuthenticationPrincipal UserPrincipal principal,
                                              @PathVariable UUID id) {
        return ResponseEntity.ok(pickupService.get(principal.getId(), principal.getRole(), id));
    }

    @PostMapping("/{id}/accept")
    @PreAuthorize("hasRole('COLLECTOR')")
    public ResponseEntity<PickupResponse> accept(@AuthenticationPrincipal UserPrincipal principal,
                                                 @PathVariable UUID id) {
        return ResponseEntity.ok(pickupService.accept(principal.getId(), id));
    }

    @PostMapping("/{id}/complete")
    @PreAuthorize("hasRole('COLLECTOR')")
    public ResponseEntity<PickupResponse> complete(@AuthenticationPrincipal UserPrincipal principal,
                                                   @PathVariable UUID id,
                                                   @Valid @RequestBody CompletePickupRequest request) {
        return ResponseEntity.ok(pickupService.complete(principal.getId(), id, request));
    }

    @PostMapping("/{id}/release")
    @PreAuthorize("hasRole('COLLECTOR')")
    public ResponseEntity<PickupResponse> release(@AuthenticationPrincipal UserPrincipal principal,
                                                  @PathVariable UUID id,
                                                  @RequestBody(required = false) CancelPickupRequest request) {
        return ResponseEntity.ok(pickupService.releaseByCollector(principal.getId(), id, request));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<PickupResponse> cancel(@AuthenticationPrincipal UserPrincipal principal,
                                                 @PathVariable UUID id,
                                                 @RequestBody(required = false) CancelPickupRequest request) {
        return ResponseEntity.ok(pickupService.cancelByUser(principal.getId(), id, request));
    }
}
