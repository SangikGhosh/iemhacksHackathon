package com.iem.market.dto;

import com.iem.enums.TransactionType;
import com.iem.model.WalletTransaction;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record WalletResponse(
        BigDecimal balance,
        String currency,
        BigDecimal totalEarned,
        BigDecimal totalSpent,
        int greenPoints,
        List<Entry> transactions,
        int page,
        int size,
        long totalItems,
        boolean hasMore
) {

    public record Entry(UUID id, TransactionType type, BigDecimal amount, BigDecimal balanceAfter,
                        String currency, String reason, String note, UUID listingId,
                        Instant createdAt) {

        public static Entry from(WalletTransaction t) {
            return new Entry(t.getId(), t.getType(), t.getAmount(), t.getBalanceAfter(),
                    t.getCurrency(), t.getReason(), t.getNote(), t.getListingId(), t.getCreatedAt());
        }
    }
}
