package com.iem.pickup.dto;

import com.iem.enums.PickupStatus;
import com.iem.model.Pickup;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record PickupResponse(
        UUID id,
        UUID detectionId,
        PickupStatus status,
        boolean cancellable,
        Location location,
        Contact contact,
        Waste waste,
        Money money,
        Party collector,
        Party citizen,
        String cancelReason,
        String cancelledBy,
        String collectorNotes,
        Instant preferredTime,
        Instant createdAt,
        Instant acceptedAt,
        Instant completedAt,
        Instant cancelledAt
) {

    public record Location(String address, String landmark, Double latitude, Double longitude) {
    }

    public record Contact(String phone, String notes) {
    }

    public record Waste(int totalObjects, String materials) {
    }

    public record Money(String currency, BigDecimal estimatedOffer,
                        BigDecimal finalAmount, BigDecimal finalWeightKg) {
    }

    public record Party(UUID id, String fullName, String email) {
    }

    public static PickupResponse from(Pickup p, Party citizen, Party collector) {
        return new PickupResponse(
                p.getId(),
                p.getDetectionId(),
                p.getStatus(),
                p.getStatus() == PickupStatus.REQUESTED,
                new Location(p.getAddress(), p.getLandmark(), p.getLatitude(), p.getLongitude()),
                new Contact(p.getContactPhone(), p.getNotes()),
                new Waste(p.getTotalObjects(), p.getMaterialSummary()),
                new Money(p.getCurrency(), p.getEstimatedOffer(),
                        p.getFinalAmount(), p.getFinalWeightKg()),
                collector,
                citizen,
                p.getCancelReason(),
                p.getCancelledBy(),
                p.getCollectorNotes(),
                p.getPreferredTime(),
                p.getCreatedAt(),
                p.getAcceptedAt(),
                p.getCompletedAt(),
                p.getCancelledAt()
        );
    }
}
