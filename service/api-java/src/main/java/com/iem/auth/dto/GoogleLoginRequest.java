package com.iem.auth.dto;

import com.iem.enums.Role;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class GoogleLoginRequest {

    @NotBlank
    private String idToken;

    private Role role = Role.CITIZEN;
}
