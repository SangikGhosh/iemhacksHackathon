package com.iem.market;

import com.iem.market.dto.CreateListingRequest;
import com.iem.market.dto.ListingListResponse;
import com.iem.market.dto.ListingResponse;
import com.iem.market.dto.WalletResponse;
import com.iem.security.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class MarketplaceController {

    private final MarketplaceService marketplaceService;

    public MarketplaceController(MarketplaceService marketplaceService) {
        this.marketplaceService = marketplaceService;
    }

    @PostMapping("/listings")
    public ResponseEntity<ListingResponse> create(@AuthenticationPrincipal UserPrincipal principal,
                                                  @Valid @RequestBody CreateListingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(marketplaceService.create(principal.getId(), request));
    }

    @GetMapping("/listings")
    public ResponseEntity<ListingListResponse> browse(@AuthenticationPrincipal UserPrincipal principal,
                                                      @RequestParam(defaultValue = "0") int page,
                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(marketplaceService.browse(principal.getId(), page, size));
    }

    @GetMapping("/listings/mine")
    public ResponseEntity<ListingListResponse> mine(@AuthenticationPrincipal UserPrincipal principal,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(
                marketplaceService.mine(principal.getId(), principal.getRole(), page, size));
    }

    @GetMapping("/listings/{id}")
    public ResponseEntity<ListingResponse> get(@AuthenticationPrincipal UserPrincipal principal,
                                               @PathVariable UUID id) {
        return ResponseEntity.ok(marketplaceService.get(principal.getId(), id));
    }

    @PostMapping("/listings/{id}/interested")
    @PreAuthorize("hasRole('RECYCLER')")
    public ResponseEntity<ListingResponse> interested(@AuthenticationPrincipal UserPrincipal principal,
                                                      @PathVariable UUID id) {
        return ResponseEntity.ok(marketplaceService.expressInterest(principal.getId(), id));
    }

    @PostMapping("/listings/{id}/cancel")
    public ResponseEntity<ListingResponse> cancel(@AuthenticationPrincipal UserPrincipal principal,
                                                  @PathVariable UUID id) {
        return ResponseEntity.ok(marketplaceService.cancel(principal.getId(), id));
    }

    @GetMapping("/wallet")
    public ResponseEntity<WalletResponse> wallet(@AuthenticationPrincipal UserPrincipal principal,
                                                 @RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(marketplaceService.wallet(principal.getId(), page, size));
    }
}
