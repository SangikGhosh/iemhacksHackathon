package com.iem.chat;

import com.iem.enums.Role;
import com.iem.model.User;

import java.util.UUID;

public record ChatContext(User user,
                          UUID listingId,
                          UUID pickupId,
                          Double latitude,
                          Double longitude) {

    public UUID userId() {
        return user.getId();
    }

    public Role role() {
        return user.getRole();
    }

    public UUID municipalityId() {
        return user.getMunicipalityId();
    }

    public boolean isPlatformWide() {
        return user.getRole() == Role.SUPER_ADMIN;
    }

    public UUID scope() {
        return isPlatformWide() ? null : user.getMunicipalityId();
    }
}
