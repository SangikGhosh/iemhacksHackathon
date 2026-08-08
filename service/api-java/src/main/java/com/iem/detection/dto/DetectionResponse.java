package com.iem.detection.dto;

import com.iem.model.Detection;
import com.iem.model.DetectionMaterial;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record DetectionResponse(
        UUID id,
        boolean eligible,
        String status,
        String message,
        String actionRequired,
        String imageUrl,
        int totalObjects,
        int totalRewardPoints,
        boolean pointsAwarded,
        Integer userPointsBalance,
        Offer offer,
        Impact impact,
        Recommendation recommendation,
        Quality quality,
        String aiSummary,
        Integer processingTimeMs,
        List<MaterialResponse> materials,
        Instant createdAt
) {

    public record Offer(String currency, BigDecimal minimumOffer, BigDecimal estimatedOffer,
                        BigDecimal maximumOffer, String status, String finalPriceSetBy) {
    }

    public record Impact(BigDecimal estimatedWeightKg, BigDecimal carbonSavedKg,
                         BigDecimal landfillReducedKg, Integer recyclablePercent) {
    }

    public record Recommendation(String primaryBin, String secondaryBin, boolean pickupRecommended) {
    }

    public record Quality(String detectionQuality, BigDecimal averageConfidence) {
    }

    public record MaterialResponse(String material, String category, String stream, String bin,
                                   boolean recyclable, int count, BigDecimal pricePerKg,
                                   BigDecimal estimatedWeightKg, BigDecimal estimatedValue,
                                   int rewardPoints, BigDecimal carbonSavedKg) {

        static MaterialResponse from(DetectionMaterial m) {
            return new MaterialResponse(m.getMaterial(), m.getCategory(), m.getStream(), m.getBin(),
                    m.isRecyclable(), m.getCount(), m.getPricePerKg(), m.getEstimatedWeightKg(),
                    m.getEstimatedValue(), m.getRewardPoints(), m.getCarbonSavedKg());
        }
    }

    public static DetectionResponse from(Detection d, String message, Integer userPointsBalance) {
        return new DetectionResponse(
                d.getId(),
                d.isEligible(),
                d.getStatus(),
                message,
                d.getActionRequired(),
                d.getImageUrl(),
                d.getTotalObjects(),
                d.getTotalRewardPoints(),
                d.isPointsAwarded(),
                userPointsBalance,
                new Offer(d.getCurrency(), d.getMinimumOffer(), d.getEstimatedOffer(),
                        d.getMaximumOffer(), d.getOfferStatus(), d.getFinalPriceSetBy()),
                new Impact(d.getEstimatedWeightKg(), d.getCarbonSavedKg(),
                        d.getLandfillReducedKg(), d.getRecyclablePercent()),
                new Recommendation(d.getPrimaryBin(), d.getSecondaryBin(), d.isPickupRecommended()),
                new Quality(d.getDetectionQuality(), d.getAverageConfidence()),
                d.getAiSummary(),
                d.getProcessingTimeMs(),
                d.getMaterials().stream().map(MaterialResponse::from).toList(),
                d.getCreatedAt()
        );
    }
}
