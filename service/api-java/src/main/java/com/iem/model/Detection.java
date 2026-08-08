package com.iem.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Entity
@NoArgsConstructor
@Table(name = "detections", indexes = {
        @Index(name = "idx_detections_user_created", columnList = "user_id, created_at")
})
public class Detection {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID userId;

    @Column(length = 500)
    private String imageUrl;

    @Column(nullable = false, length = 40)
    private String status;

    @Column(nullable = false)
    private boolean eligible;

    @Column(length = 40)
    private String actionRequired;

    @Column(nullable = false)
    private int totalObjects;

    @Column(nullable = false)
    private int totalRewardPoints;

    @Column(nullable = false)
    private boolean pointsAwarded;

    @Column(length = 8)
    private String currency;

    @Column(precision = 10, scale = 2)
    private BigDecimal minimumOffer;

    @Column(precision = 10, scale = 2)
    private BigDecimal estimatedOffer;

    @Column(precision = 10, scale = 2)
    private BigDecimal maximumOffer;

    @Column(length = 40)
    private String offerStatus;

    @Column(length = 20)
    private String finalPriceSetBy;

    @Column(precision = 10, scale = 3)
    private BigDecimal estimatedWeightKg;

    @Column(precision = 10, scale = 3)
    private BigDecimal carbonSavedKg;

    @Column(precision = 10, scale = 3)
    private BigDecimal landfillReducedKg;

    private Integer recyclablePercent;

    @Column(length = 10)
    private String primaryBin;

    @Column(length = 10)
    private String secondaryBin;

    @Column(nullable = false)
    private boolean pickupRecommended;

    @Column(length = 20)
    private String detectionQuality;

    @Column(precision = 4, scale = 2)
    private BigDecimal averageConfidence;

    private Integer processingTimeMs;

    @Column(length = 60)
    private String modelId;

    @Column(length = 1000)
    private String aiSummary;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @OneToMany(mappedBy = "detection", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<DetectionMaterial> materials = new ArrayList<>();

    public void addMaterial(DetectionMaterial material) {
        material.setDetection(this);
        this.materials.add(material);
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
