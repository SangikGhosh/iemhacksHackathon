package com.iem.market.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
public class CreateListingRequest {

    private UUID detectionId;

    @Size(max = 80)
    private String material;

    @DecimalMin(value = "0.001", message = "must be greater than zero")
    private BigDecimal weightKg;

    @NotNull
    @DecimalMin(value = "1.0", message = "must be at least 1")
    private BigDecimal price;

    @Size(max = 400)
    private String description;

    @Size(max = 160)
    private String location;

    @Size(max = 500)
    private String imageUrl;
}
