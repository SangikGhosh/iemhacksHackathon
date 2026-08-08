package com.iem.admin.dto;

import com.iem.enums.Role;
import com.iem.model.User;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record AdminUserResponse(
        UUID id,
        String fullName,
        String email,
        String phone,
        Role role,
        boolean active,
        int points,
        BigDecimal walletBalance,
        UUID municipalityId,
        String municipalityName,
        Instant createdAt
) {

    public static AdminUserResponse from(User u, String municipalityName) {
        return new AdminUserResponse(u.getId(), u.getFullName(), u.getEmail(), u.getPhone(),
                u.getRole(), u.isActive(), u.getPoints(), u.getWalletBalance(),
                u.getMunicipalityId(), municipalityName, u.getCreatedAt());
    }
}
