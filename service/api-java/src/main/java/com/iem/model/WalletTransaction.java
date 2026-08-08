package com.iem.model;

import com.iem.enums.TransactionType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Entity
@NoArgsConstructor
@Table(name = "wallet_transactions", indexes = {
        @Index(name = "idx_wallet_user_created", columnList = "user_id, created_at")
})
public class WalletTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private TransactionType type;

    @Column(precision = 12, scale = 2, nullable = false)
    private BigDecimal amount;

    @Column(precision = 12, scale = 2, nullable = false)
    private BigDecimal balanceAfter;

    @Column(nullable = false, length = 8)
    private String currency = "INR";

    @Column(nullable = false, length = 40)
    private String reason;

    @Column(length = 200)
    private String note;

    @Column(name = "listing_id")
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID listingId;

    @Column(name = "counterparty_id")
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID counterpartyId;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
