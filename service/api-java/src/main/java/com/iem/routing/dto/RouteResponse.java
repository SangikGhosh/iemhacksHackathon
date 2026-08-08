package com.iem.routing.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record RouteResponse(
        Depot depot,
        List<RouteStop> stops,
        int totalRequests,
        int totalStops,
        BigDecimal plannedLoadKg,
        BigDecimal vehicleCapacityKg,
        List<UUID> deferredPickupIds,
        Double distanceKm,
        Double durationMinutes,
        String geometry
) {

    public record Depot(String municipalityCode, String name, double lat, double lon) {
    }

    public record RouteStop(
            int sequence,
            String type,
            UUID collectionPointId,
            List<UUID> pickupIds,
            String address,
            double lat,
            double lon,
            int pickupCount,
            BigDecimal weightKg
    ) {
    }
}
