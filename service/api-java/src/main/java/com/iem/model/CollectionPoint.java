package com.iem.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

@Getter
@Setter
@Entity
@NoArgsConstructor
@Table(name = "collection_points",
        uniqueConstraints = @UniqueConstraint(name = "uk_collection_points_code", columnNames = "code"),
        indexes = {
                @Index(name = "idx_points_municipality", columnList = "municipality_id"),
                @Index(name = "idx_points_latlon", columnList = "lat, lon")
        })
public class CollectionPoint {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(nullable = false, length = 30)
    private String code;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "municipality_id", nullable = false)
    private Municipality municipality;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(length = 120)
    private String locality;

    @Column(length = 40)
    private String ward;

    @Column(nullable = false, length = 30)
    private String type;

    @Column(nullable = false)
    private double lat;

    @Column(nullable = false)
    private double lon;

    @Column(nullable = false)
    private boolean active = true;
}
