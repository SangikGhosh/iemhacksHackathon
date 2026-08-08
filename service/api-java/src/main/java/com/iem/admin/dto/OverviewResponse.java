package com.iem.admin.dto;

import java.math.BigDecimal;
import java.util.List;

public record OverviewResponse(
        String scope,
        String municipalityName,
        Stats stats,
        List<TrendPoint> trend,
        List<Slice> binSplit,
        List<Slice> roleSplit,
        List<MaterialRow> topMaterials,
        List<Slice> pickupStatus,
        Marketplace marketplace
) {

    public record Stats(
            long totalScans, long totalObjects, long citizens, long collectors, long recyclers,
            long pickupsRequested, long pickupsCompleted, BigDecimal wasteDivertedKg,
            BigDecimal carbonSavedKg, long pointsIssued, long collectionPoints,
            BigDecimal marketplaceValue) {
    }

    public record TrendPoint(String day, long scans, long pickups) {
    }

    public record Slice(String label, long value) {
    }

    public record MaterialRow(String material, long count, BigDecimal weightKg, BigDecimal value) {
    }

    public record Marketplace(long openListings, long soldListings, BigDecimal tradedValue) {
    }
}
