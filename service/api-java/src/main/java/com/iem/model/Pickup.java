package com.iem.model;

import com.iem.enums.PickupStatus;
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
@Table(name = "pickups", indexes = {
        @Index(name = "idx_pickups_detection", columnList = "detection_id"),
        @Index(name = "idx_pickups_user_created", columnList = "user_id, created_at"),
        @Index(name = "idx_pickups_collector", columnList = "collector_id, created_at"),
        @Index(name = "idx_pickups_status", columnList = "status, created_at")
})
public class Pickup {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(name = "detection_id", nullable = false)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID detectionId;

    @Column(name = "user_id", nullable = false)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID userId;

    @Column(name = "collector_id")
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID collectorId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PickupStatus status = PickupStatus.REQUESTED;

    @Column(nullable = false, length = 300)
    private String address;

    @Column(length = 120)
    private String landmark;

    @Column(nullable = false, length = 20)
    private String contactPhone;

    @Column(length = 300)
    private String notes;

    private Double latitude;

    private Double longitude;

    private Instant preferredTime;

    @Column(length = 8)
    private String currency;

    @Column(precision = 10, scale = 2)
    private BigDecimal estimatedOffer;

    @Column(precision = 10, scale = 2)
    private BigDecimal finalAmount;

    @Column(precision = 10, scale = 3)
    private BigDecimal finalWeightKg;

    @Column(length = 300)
    private String collectorNotes;

    @Column(length = 200)
    private String cancelReason;

    @Column(length = 20)
    private String cancelledBy;

    private int totalObjects;

    @Column(length = 200)
    private String materialSummary;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    private Instant acceptedAt;

    private Instant completedAt;

    private Instant cancelledAt;

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
