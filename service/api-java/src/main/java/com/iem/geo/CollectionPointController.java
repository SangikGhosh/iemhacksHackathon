package com.iem.geo;

import com.iem.geo.dto.CollectionPointResponse;
import com.iem.model.Municipality;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/collection-points")
public class CollectionPointController {

    private final CollectionPointService collectionPointService;
    private final MunicipalityRepository municipalityRepository;

    public CollectionPointController(CollectionPointService collectionPointService,
                                     MunicipalityRepository municipalityRepository) {
        this.collectionPointService = collectionPointService;
        this.municipalityRepository = municipalityRepository;
    }

    @GetMapping("/nearest")
    public ResponseEntity<Map<String, Object>> nearest(@RequestParam double lat,
                                                       @RequestParam double lon,
                                                       @RequestParam(defaultValue = "5") int limit) {
        List<CollectionPointResponse> points = collectionPointService.nearest(lat, lon, limit);
        return ResponseEntity.ok(Map.of(
                "origin", Map.of("lat", lat, "lon", lon),
                "count", points.size(),
                "points", points));
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> all() {
        List<CollectionPointResponse> points = collectionPointService.all();
        return ResponseEntity.ok(Map.of("count", points.size(), "points", points));
    }

    @GetMapping("/municipalities")
    public ResponseEntity<Map<String, Object>> municipalities() {
        List<Map<String, Object>> items = municipalityRepository.findByActiveTrue().stream()
                .map(m -> Map.<String, Object>of(
                        "code", m.getCode(),
                        "name", m.getName(),
                        "district", m.getDistrict(),
                        "state", m.getState(),
                        "depot", Map.of("name", m.getDepotName(),
                                "lat", m.getDepotLat(), "lon", m.getDepotLon())))
                .toList();
        return ResponseEntity.ok(Map.of("count", items.size(), "municipalities", items));
    }
}
