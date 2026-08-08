package com.iem.geo.dto;

import com.iem.model.CollectionPoint;

import java.util.UUID;

public record CollectionPointResponse(
        UUID id,
        String code,
        String name,
        String locality,
        String ward,
        String type,
        double lat,
        double lon,
        String municipality,
        String district,
        Double straightLineKm,
        Double roadDistanceKm,
        Double drivingMinutes
) {

    public static CollectionPointResponse of(CollectionPoint p, Double straightLineKm,
                                             Double roadKm, Double minutes) {
        return new CollectionPointResponse(
                p.getId(), p.getCode(), p.getName(), p.getLocality(), p.getWard(), p.getType(),
                p.getLat(), p.getLon(),
                p.getMunicipality().getName(), p.getMunicipality().getDistrict(),
                straightLineKm, roadKm, minutes);
    }
}
