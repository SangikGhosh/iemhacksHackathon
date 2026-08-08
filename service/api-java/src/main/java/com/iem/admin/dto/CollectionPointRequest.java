package com.iem.admin.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class CollectionPointRequest {

    private UUID municipalityId;

    @Size(max = 20)
    private String municipalityCode;

    @NotBlank
    @Size(max = 160)
    private String name;

    @Size(max = 120)
    private String locality;

    @Size(max = 40)
    private String ward;

    @Size(max = 30)
    private String type;

    @NotNull
    @DecimalMin("-90.0")
    @DecimalMax("90.0")
    private Double lat;

    @NotNull
    @DecimalMin("-180.0")
    @DecimalMax("180.0")
    private Double lon;

    private Boolean active;
}
