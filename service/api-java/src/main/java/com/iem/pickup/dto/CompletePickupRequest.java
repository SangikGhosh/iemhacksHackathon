package com.iem.pickup.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class CompletePickupRequest {

    @NotNull
    @DecimalMin(value = "0.0", message = "cannot be negative")
    private BigDecimal finalWeightKg;

    @NotNull
    @DecimalMin(value = "0.0", message = "cannot be negative")
    private BigDecimal finalAmount;

    @Size(max = 300)
    private String collectorNotes;
}
