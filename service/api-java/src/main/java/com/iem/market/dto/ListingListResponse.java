package com.iem.market.dto;

import java.util.List;

public record ListingListResponse(
        List<ListingResponse> items,
        int page,
        int size,
        long totalItems,
        int totalPages,
        boolean hasMore
) {
}
