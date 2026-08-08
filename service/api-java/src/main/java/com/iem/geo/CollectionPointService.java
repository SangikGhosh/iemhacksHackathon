package com.iem.geo;

import com.iem.exception.ApiException;
import com.iem.geo.dto.CollectionPointResponse;
import com.iem.model.CollectionPoint;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class CollectionPointService {

    private static final Logger log = LoggerFactory.getLogger(CollectionPointService.class);

    private static final double EARTH_RADIUS_KM = 6371.0088;

    private final CollectionPointRepository pointRepository;
    private final MapboxClient mapbox;
    private final int shortlistSize;
    private final double searchRadiusKm;

    public CollectionPointService(CollectionPointRepository pointRepository,
                                  MapboxClient mapbox,
                                  @Value("${geo.shortlist-size:5}") int shortlistSize,
                                  @Value("${geo.search-radius-km:12}") double searchRadiusKm) {
        this.pointRepository = pointRepository;
        this.mapbox = mapbox;
        this.shortlistSize = shortlistSize;
        this.searchRadiusKm = searchRadiusKm;
    }

    public static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    @Transactional(readOnly = true)
    public List<CollectionPointResponse> nearest(double lat, double lon, int limit) {

        validate(lat, lon);

        int wanted = Math.min(Math.max(limit, 1), shortlistSize);

        double latDelta = searchRadiusKm / 111.32;
        double lonDelta = searchRadiusKm / (111.32 * Math.cos(Math.toRadians(lat)));

        List<CollectionPoint> candidates = pointRepository.findInBox(
                lat - latDelta, lat + latDelta, lon - lonDelta, lon + lonDelta);

        if (candidates.isEmpty()) {
            throw new ApiException(
                    "No collection point found near this location. Request a doorstep pickup instead.",
                    404);
        }

        List<CollectionPoint> shortlist = candidates.stream()
                .sorted(Comparator.comparingDouble(p -> haversineKm(lat, lon, p.getLat(), p.getLon())))
                .limit(shortlistSize)
                .toList();

        if (!mapbox.isConfigured()) {
            return shortlist.stream()
                    .limit(wanted)
                    .map(p -> CollectionPointResponse.of(p,
                            round(haversineKm(lat, lon, p.getLat(), p.getLon())), null, null))
                    .toList();
        }

        return rankByRoad(lat, lon, shortlist, wanted);
    }

    private List<CollectionPointResponse> rankByRoad(double lat, double lon,
                                                     List<CollectionPoint> shortlist, int wanted) {

        List<MapboxClient.Point> coords = new ArrayList<>();
        coords.add(new MapboxClient.Point(lat, lon));
        shortlist.forEach(p -> coords.add(new MapboxClient.Point(p.getLat(), p.getLon())));

        MapboxClient.MatrixResponse matrix;
        try {
            matrix = mapbox.matrix(coords);
        } catch (ApiException e) {
            log.warn("Falling back to straight-line ranking: {}", e.getMessage());
            return shortlist.stream()
                    .limit(wanted)
                    .map(p -> CollectionPointResponse.of(p,
                            round(haversineKm(lat, lon, p.getLat(), p.getLon())), null, null))
                    .toList();
        }

        List<Double> durations = matrix.durations().get(0);
        List<Double> distances = matrix.distances().get(0);

        record Scored(CollectionPoint point, Double seconds, Double metres) {
        }

        List<Scored> scored = new ArrayList<>();
        for (int i = 0; i < shortlist.size(); i++) {
            scored.add(new Scored(shortlist.get(i), durations.get(i + 1), distances.get(i + 1)));
        }

        return scored.stream()
                .sorted(Comparator.comparingDouble(s -> s.seconds() == null ? Double.MAX_VALUE : s.seconds()))
                .limit(wanted)
                .map(s -> CollectionPointResponse.of(s.point(),
                        round(haversineKm(lat, lon, s.point().getLat(), s.point().getLon())),
                        s.metres() == null ? null : round(s.metres() / 1000.0),
                        s.seconds() == null ? null : round(s.seconds() / 60.0)))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CollectionPointResponse> all() {
        return pointRepository.findAllActive().stream()
                .map(p -> CollectionPointResponse.of(p, null, null, null))
                .toList();
    }

    @Transactional(readOnly = true)
    public CollectionPoint require(UUID id) {
        return pointRepository.findById(id)
                .filter(CollectionPoint::isActive)
                .orElseThrow(() -> new ApiException("Collection point not found", 404));
    }

    private static void validate(double lat, double lon) {
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
            throw new ApiException("Invalid coordinates", 400);
        }
    }

    private static double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
