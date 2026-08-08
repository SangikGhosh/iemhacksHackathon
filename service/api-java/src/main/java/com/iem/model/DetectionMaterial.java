package com.iem.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@Entity
@NoArgsConstructor
@Table(name = "detection_materials", indexes = {
        @Index(name = "idx_detection_materials_detection", columnList = "detection_id")
})
public class DetectionMaterial {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "detection_id", nullable = false)
    private Detection detection;

    @Column(nullable = false, length = 60)
    private String material;

    @Column(length = 40)
    private String category;

    @Column(length = 20)
    private String stream;

    @Column(name = "bin_colour", length = 10)
    private String bin;

    @Column(nullable = false)
    private int count;

    @Column(precision = 10, scale = 2)
    private BigDecimal pricePerKg;

    @Column(precision = 10, scale = 3)
    private BigDecimal estimatedWeightKg;

    @Column(precision = 10, scale = 2)
    private BigDecimal estimatedValue;

    @Column(nullable = false)
    private int rewardPoints;

    @Column(precision = 10, scale = 3)
    private BigDecimal carbonSavedKg;

    @Column(nullable = false)
    private boolean recyclable;
}
