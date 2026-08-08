package com.iem.model;

import com.iem.enums.AuthProvider;
import com.iem.enums.Role;
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
@Table(name = "users", indexes = {
        @Index(name = "idx_users_email", columnList = "email")
})
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String fullName;

    private String password;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role = Role.CITIZEN;

    @Column(nullable = false)
    private int points;

    @Column(precision = 12, scale = 2, nullable = false)
    private BigDecimal walletBalance = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AuthProvider provider = AuthProvider.LOCAL;

    private String providerId;

    @Column(nullable = false)
    private boolean emailVerified;

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "municipality_id")
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID municipalityId;

    @Column(name = "created_by")
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID createdBy;

    @Column(length = 20)
    private String phone;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
