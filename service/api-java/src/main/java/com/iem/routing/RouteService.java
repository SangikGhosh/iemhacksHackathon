package com.iem.routing;

import com.iem.enums.PickupStatus;
import com.iem.exception.ApiException;
import com.iem.geo.MapboxClient;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.Municipality;
import com.iem.model.Pickup;
import com.iem.pickup.PickupRepository;
import com.iem.routing.dto.RouteResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class RouteService {

    private static final Logger log = LoggerFactory.getLogger(RouteService.class);

    private final PickupRepository pickupRepository;
    private final MunicipalityRepository municipalityRepository;
    private final MapboxClient mapbox;
    private final BigDecimal vehicleCapacityKg;

    public RouteService(PickupRepository pickupRepository,
                        MunicipalityRepository municipalityRepository,
                        MapboxClient mapbox,
                        @Value("${routing.vehicle-capacity-kg:80}") BigDecimal vehicleCapacityKg) {
        this.pickupRepository = pickupRepository;
        this.municipalityRepository = municipalityRepository;
        this.mapbox = mapbox;
        this.vehicleCapacityKg = vehicleCapacityKg;
    }

    private record Stop(String key, double lat, double lon, List<Pickup> pickups) {

        BigDecimal weightKg() {
            return pickups.stream()
                    .map(p -> p.getEstimatedWeightKg() == null ? BigDecimal.ZERO : p.getEstimatedWeightKg())
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
        }
    }

    @Transactional(readOnly = true)
    public RouteResponse planFor(UUID collectorId, String municipalityCode) {

        List<Pickup> accepted = pickupRepository
                .findByCollectorId(collectorId, PageRequest.of(0, 200,
                        Sort.by(Sort.Direction.ASC, "createdAt")))
                .getContent().stream()
                .filter(p -> p.getStatus() == PickupStatus.ACCEPTED)
                .filter(p -> p.getLatitude() != null && p.getLongitude() != null)
                .toList();

        if (accepted.isEmpty()) {
            throw new ApiException(
                    "You have no accepted pickups with a location to build a route from", 404);
        }

        Municipality depot = resolveDepot(municipalityCode, accepted);

        List<Stop> stops = aggregate(accepted);

        List<Stop> planned = new ArrayList<>();
        List<Pickup> deferred = new ArrayList<>();
        BigDecimal load = BigDecimal.ZERO;

        for (Stop stop : stops) {
            BigDecimal next = load.add(stop.weightKg());
            if (next.compareTo(vehicleCapacityKg) > 0 && !planned.isEmpty()) {
                deferred.addAll(stop.pickups());
                continue;
            }
            planned.add(stop);
            load = next;
        }

        if (planned.size() > MapboxClient.MATRIX_MAX_COORDS - 1) {
            List<Stop> trimmed = planned.subList(0, MapboxClient.MATRIX_MAX_COORDS - 1);
            planned.subList(MapboxClient.MATRIX_MAX_COORDS - 1, planned.size())
                    .forEach(s -> deferred.addAll(s.pickups()));
            planned = new ArrayList<>(trimmed);
            log.info("Route trimmed to {} stops for the Mapbox matrix limit",
                    MapboxClient.MATRIX_MAX_COORDS - 1);
        }

        List<Stop> ordered = optimise(depot, planned);

        return build(depot, ordered, deferred, load, accepted.size());
    }

    private Municipality resolveDepot(String municipalityCode, List<Pickup> accepted) {

        if (municipalityCode != null && !municipalityCode.isBlank()) {
            return municipalityRepository.findByCode(municipalityCode.toUpperCase())
                    .orElseThrow(() -> new ApiException("Unknown municipality code", 404));
        }

        UUID fromPickup = accepted.stream()
                .map(Pickup::getMunicipalityId)
                .filter(java.util.Objects::nonNull)
                .findFirst()
                .orElse(null);

        if (fromPickup != null) {
            return municipalityRepository.findById(fromPickup)
                    .orElseThrow(() -> new ApiException("Depot not found", 404));
        }

        return municipalityRepository.findByActiveTrue().stream()
                .findFirst()
                .orElseThrow(() -> new ApiException(
                        "No municipality depot is configured. Pass municipalityCode.", 400));
    }

    private List<Stop> aggregate(List<Pickup> pickups) {

        Map<String, List<Pickup>> grouped = new LinkedHashMap<>();

        for (Pickup p : pickups) {
            String key = p.getCollectionPointId() != null
                    ? "point:" + p.getCollectionPointId()
                    : "pickup:" + p.getId();
            grouped.computeIfAbsent(key, k -> new ArrayList<>()).add(p);
        }

        return grouped.entrySet().stream()
                .map(e -> {
                    Pickup first = e.getValue().get(0);
                    return new Stop(e.getKey(), first.getLatitude(), first.getLongitude(), e.getValue());
                })
                .toList();
    }

    private List<Stop> optimise(Municipality depot, List<Stop> stops) {

        if (stops.size() <= 1 || !mapbox.isConfigured()) {
            return stops;
        }

        List<MapboxClient.Point> coords = new ArrayList<>();
        coords.add(new MapboxClient.Point(depot.getDepotLat(), depot.getDepotLon()));
        stops.forEach(s -> coords.add(new MapboxClient.Point(s.lat(), s.lon())));

        double[][] cost;
        try {
            MapboxClient.MatrixResponse matrix = mapbox.matrix(coords);
            cost = toMatrix(matrix.durations(), coords.size());
        } catch (ApiException e) {
            log.warn("Matrix unavailable, ordering by straight-line distance: {}", e.getMessage());
            return stops.stream()
                    .sorted(Comparator.comparingDouble(s ->
                            com.iem.geo.CollectionPointService.haversineKm(
                                    depot.getDepotLat(), depot.getDepotLon(), s.lat(), s.lon())))
                    .toList();
        }

        int[] order = nearestNeighbour(cost, stops.size());
        order = twoOpt(order, cost);

        List<Stop> result = new ArrayList<>();
        for (int index : order) {
            result.add(stops.get(index - 1));
        }
        return result;
    }

    private static double[][] toMatrix(List<List<Double>> raw, int size) {
        double[][] cost = new double[size][size];
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                Double value = raw.get(i).get(j);
                cost[i][j] = value == null ? Double.MAX_VALUE / 4 : value;
            }
        }
        return cost;
    }

    private static int[] nearestNeighbour(double[][] cost, int stopCount) {
        boolean[] visited = new boolean[stopCount + 1];
        int[] order = new int[stopCount];
        int current = 0;

        for (int step = 0; step < stopCount; step++) {
            int best = -1;
            double bestCost = Double.MAX_VALUE;
            for (int candidate = 1; candidate <= stopCount; candidate++) {
                if (!visited[candidate] && cost[current][candidate] < bestCost) {
                    bestCost = cost[current][candidate];
                    best = candidate;
                }
            }
            visited[best] = true;
            order[step] = best;
            current = best;
        }
        return order;
    }

    private static int[] twoOpt(int[] order, double[][] cost) {
        int n = order.length;
        if (n < 3) {
            return order;
        }
        int[] best = order.clone();
        boolean improved = true;
        int guard = 0;

        while (improved && guard++ < 50) {
            improved = false;
            for (int i = 0; i < n - 1; i++) {
                for (int k = i + 1; k < n; k++) {
                    int[] candidate = best.clone();
                    for (int a = i, b = k; a < b; a++, b--) {
                        int tmp = candidate[a];
                        candidate[a] = candidate[b];
                        candidate[b] = tmp;
                    }
                    if (length(candidate, cost) + 1e-6 < length(best, cost)) {
                        best = candidate;
                        improved = true;
                    }
                }
            }
        }
        return best;
    }

    private static double length(int[] order, double[][] cost) {
        double total = cost[0][order[0]];
        for (int i = 0; i < order.length - 1; i++) {
            total += cost[order[i]][order[i + 1]];
        }
        return total + cost[order[order.length - 1]][0];
    }

    private RouteResponse build(Municipality depot, List<Stop> ordered, List<Pickup> deferred,
                                BigDecimal load, int totalRequests) {

        List<RouteResponse.RouteStop> stops = new ArrayList<>();
        int sequence = 1;
        for (Stop stop : ordered) {
            Pickup first = stop.pickups().get(0);
            stops.add(new RouteResponse.RouteStop(
                    sequence++,
                    first.getCollectionPointId() != null ? "DROP_OFF_POINT" : "DOORSTEP",
                    first.getCollectionPointId(),
                    stop.pickups().stream().map(Pickup::getId).toList(),
                    first.getAddress(),
                    stop.lat(),
                    stop.lon(),
                    stop.pickups().size(),
                    stop.weightKg()));
        }

        Double distanceKm = null;
        Double durationMinutes = null;
        String geometry = null;

        if (mapbox.isConfigured() && !ordered.isEmpty()) {
            List<MapboxClient.Point> path = new ArrayList<>();
            path.add(new MapboxClient.Point(depot.getDepotLat(), depot.getDepotLon()));
            ordered.forEach(s -> path.add(new MapboxClient.Point(s.lat(), s.lon())));
            path.add(new MapboxClient.Point(depot.getDepotLat(), depot.getDepotLon()));

            try {
                MapboxClient.DirectionsResponse directions = mapbox.directions(path);
                MapboxClient.DirectionsResponse.Route route = directions.routes().get(0);
                distanceKm = Math.round(route.distance() / 10.0) / 100.0;
                durationMinutes = Math.round(route.duration() / 6.0) / 10.0;
                geometry = route.geometry();
            } catch (ApiException e) {
                log.warn("Directions unavailable: {}", e.getMessage());
            }
        }

        return new RouteResponse(
                new RouteResponse.Depot(depot.getCode(), depot.getDepotName(),
                        depot.getDepotLat(), depot.getDepotLon()),
                stops,
                totalRequests,
                stops.size(),
                load,
                vehicleCapacityKg,
                deferred.stream().map(Pickup::getId).toList(),
                distanceKm,
                durationMinutes,
                geometry);
    }
}
