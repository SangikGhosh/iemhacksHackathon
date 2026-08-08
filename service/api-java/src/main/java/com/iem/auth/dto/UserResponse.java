package com.iem.auth.dto;

import com.iem.enums.Role;
import com.iem.model.User;

import java.util.UUID;

public record UserResponse(UUID id, String email, String fullName, Role role, int points) {

    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getEmail(), user.getFullName(),
                user.getRole(), user.getPoints());
    }
}
