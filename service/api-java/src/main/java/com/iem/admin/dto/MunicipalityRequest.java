package com.iem.admin.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MunicipalityRequest {

    @NotBlank
    @Size(max = 20)
    private String code;

    @NotBlank
    @Size(max = 120)
    private String name;

    @NotBlank
    @Size(max = 60)
    private String district;

    @Size(max = 60)
    private String state;

    @Size(max = 160)
    private String depotName;

    @NotNull
    @DecimalMin("-90.0")
    @DecimalMax("90.0")
    private Double depotLat;

    @NotNull
    @DecimalMin("-180.0")
    @DecimalMax("180.0")
    private Double depotLon;

    private Boolean active;
}
