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
@Table(name = "municipalities", uniqueConstraints =
        @UniqueConstraint(name = "uk_municipalities_code", columnNames = "code"))
public class Municipality {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(nullable = false, length = 20)
    private String code;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false, length = 60)
    private String district;

    @Column(nullable = false, length = 60)
    private String state;

    @Column(nullable = false, length = 160)
    private String depotName;

    @Column(nullable = false)
    private double depotLat;

    @Column(nullable = false)
    private double depotLon;

    @Column(nullable = false)
    private boolean active = true;
}
