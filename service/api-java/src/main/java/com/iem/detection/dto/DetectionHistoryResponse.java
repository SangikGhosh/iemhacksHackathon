package com.iem.detection.dto;

import java.math.BigDecimal;
import java.util.List;

public record DetectionHistoryResponse(
        List<DetectionHistoryItem> items,
        int page,
        int size,
        long totalItems,
        int totalPages,
        boolean hasMore,
        Totals totals
) {

    public record Totals(int scans, int objects, int rewardPoints,
                         BigDecimal carbonSavedKg, BigDecimal estimatedEarnings) {
    }
}
