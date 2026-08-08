package com.iem.pickup.dto;

import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CancelPickupRequest {

    @Size(max = 200)
    private String reason;
}
