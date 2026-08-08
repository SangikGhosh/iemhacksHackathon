package com.iem.model;

import com.iem.enums.ListingStatus;
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
@Table(name = "listings", indexes = {
        @Index(name = "idx_listings_status", columnList = "status, created_at"),
        @Index(name = "idx_listings_seller", columnList = "seller_id, created_at"),
        @Index(name = "idx_listings_buyer", columnList = "buyer_id, created_at")
})
public class Listing {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(name = "seller_id", nullable = false)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID sellerId;

    @Column(name = "buyer_id")
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID buyerId;

    @Column(name = "detection_id")
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID detectionId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ListingStatus status = ListingStatus.OPEN;

    @Column(nullable = false, length = 80)
    private String material;

    @Column(precision = 10, scale = 3, nullable = false)
    private BigDecimal weightKg;

    @Column(precision = 10, scale = 2, nullable = false)
    private BigDecimal price;

    @Column(nullable = false, length = 8)
    private String currency = "INR";

    @Column(length = 400)
    private String description;

    @Column(length = 500)
    private String imageUrl;

    @Column(length = 160)
    private String location;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    private Instant soldAt;

    private Instant cancelledAt;

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
