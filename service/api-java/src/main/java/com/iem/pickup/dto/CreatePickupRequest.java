package com.iem.pickup.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
public class CreatePickupRequest {

    @NotNull
    private UUID detectionId;

    @NotBlank
    @Size(max = 300)
    private String address;

    @Size(max = 120)
    private String landmark;

    @NotBlank
    @Pattern(regexp = "^[+0-9][0-9 \\-]{7,19}$", message = "must be a valid phone number")
    private String contactPhone;

    @Size(max = 300)
    private String notes;

    private Double latitude;

    private Double longitude;

    private Instant preferredTime;
}
