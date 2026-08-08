package com.iem.detection.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;
import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record DetectionApiResponse(
        boolean success,
        boolean eligible,
        String status,
        String message,
        String actionRequired,
        Integer processingTimeMs,
        String imageUrl,
        Model model,
        Quality quality,
        Summary summary,
        List<Material> materials,
        Offer offer,
        WasteAnalysis wasteAnalysis,
        Environment environment,
        Recommendation recommendation,
        Integer totalRewardPoints,
        String aiSummary
) {

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Model(String modelId, String name, String weightsVersion, Integer inferenceTimeMs) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Quality(String detectionQuality, BigDecimal averageConfidence) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Summary(Integer totalObjects) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Material(
            String material,
            String category,
            String stream,
            String bin,
            Boolean recyclable,
            Integer count,
            BigDecimal pricePerKg,
            BigDecimal estimatedWeightKg,
            BigDecimal estimatedValue,
            Integer rewardPoints,
            BigDecimal carbonSavedKg
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Offer(
            String currency,
            BigDecimal minimumOffer,
            BigDecimal estimatedOffer,
            BigDecimal maximumOffer,
            String status,
            String finalPriceSetBy
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WasteAnalysis(Integer recyclable) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Environment(BigDecimal carbonSavedKg, BigDecimal landfillReducedKg) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Recommendation(String primaryBin, String secondaryBin, Boolean pickupRecommended) {
    }
}
