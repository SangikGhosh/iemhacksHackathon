package com.iem.admin.dto;

import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class UpdateUserRequest {

    private Boolean active;

    @Size(max = 100)
    private String fullName;

    @Size(max = 20)
    private String phone;

    private UUID municipalityId;
}
