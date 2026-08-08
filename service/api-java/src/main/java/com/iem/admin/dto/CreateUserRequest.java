package com.iem.admin.dto;

import com.iem.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class CreateUserRequest {

    @NotBlank
    @Email
    private String email;

    @NotBlank
    @Size(max = 100)
    private String fullName;

    @NotBlank
    @Size(min = 8, max = 72)
    private String password;

    @NotNull
    private Role role;

    @Size(max = 20)
    private String phone;

    private UUID municipalityId;
}
