package com.iem.market.dto;

import com.iem.enums.ListingStatus;
import com.iem.model.Listing;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ListingResponse(
        UUID id,
        ListingStatus status,
        String material,
        BigDecimal weightKg,
        BigDecimal price,
        BigDecimal pricePerKg,
        String currency,
        String description,
        String imageUrl,
        String location,
        Party seller,
        Party buyer,
        boolean mine,
        Instant createdAt,
        Instant soldAt
) {

    public record Party(UUID id, String fullName, String role) {
    }

    public static ListingResponse from(Listing l, Party seller, Party buyer, UUID viewerId) {
        BigDecimal perKg = l.getWeightKg() == null || l.getWeightKg().signum() <= 0
                ? null
                : l.getPrice().divide(l.getWeightKg(), 2, java.math.RoundingMode.HALF_UP);
        return new ListingResponse(
                l.getId(), l.getStatus(), l.getMaterial(), l.getWeightKg(), l.getPrice(), perKg,
                l.getCurrency(), l.getDescription(), l.getImageUrl(), l.getLocation(),
                seller, buyer, l.getSellerId().equals(viewerId),
                l.getCreatedAt(), l.getSoldAt());
    }
}
