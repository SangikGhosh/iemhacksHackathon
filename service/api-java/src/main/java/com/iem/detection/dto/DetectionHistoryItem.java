package com.iem.detection.dto;

import com.iem.model.Detection;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record DetectionHistoryItem(
        UUID id,
        String imageUrl,
        String status,
        boolean eligible,
        int totalObjects,
        int totalRewardPoints,
        boolean pointsAwarded,
        String currency,
        BigDecimal estimatedOffer,
        BigDecimal minimumOffer,
        BigDecimal maximumOffer,
        String offerStatus,
        BigDecimal estimatedWeightKg,
        BigDecimal carbonSavedKg,
        String primaryBin,
        boolean pickupRecommended,
        String detectionQuality,
        List<String> materials,
        Instant createdAt
) {

    public static DetectionHistoryItem from(Detection d) {
        return new DetectionHistoryItem(
                d.getId(),
                d.getImageUrl(),
                d.getStatus(),
                d.isEligible(),
                d.getTotalObjects(),
                d.getTotalRewardPoints(),
                d.isPointsAwarded(),
                d.getCurrency(),
                d.getEstimatedOffer(),
                d.getMinimumOffer(),
                d.getMaximumOffer(),
                d.getOfferStatus(),
                d.getEstimatedWeightKg(),
                d.getCarbonSavedKg(),
                d.getPrimaryBin(),
                d.isPickupRecommended(),
                d.getDetectionQuality(),
                d.getMaterials().stream().map(m -> m.getMaterial() + " x" + m.getCount()).toList(),
                d.getCreatedAt()
        );
    }
}
