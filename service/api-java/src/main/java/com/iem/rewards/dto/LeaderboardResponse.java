package com.iem.rewards.dto;

import java.math.BigDecimal;
import java.util.List;

public record LeaderboardResponse(
        String scope,
        List<Entry> entries,
        Me me,
        Totals totals
) {

    public record Entry(int rank, String userId, String fullName, String role,
                        int points, long completedPickups, BigDecimal totalWeightKg) {
    }

    public record Me(int rank, int points, long completedPickups, long ahead) {
    }

    public record Totals(long citizens, long points, BigDecimal weightKg, long completedPickups) {
    }
}
