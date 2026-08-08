package com.iem.pickup.dto;

import java.util.List;

public record PickupListResponse(
        List<PickupResponse> items,
        int page,
        int size,
        long totalItems,
        int totalPages,
        boolean hasMore
) {
}
