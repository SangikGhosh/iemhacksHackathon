package com.iem.admin;

import com.iem.admin.dto.CollectionPointRequest;
import com.iem.admin.dto.MunicipalityRequest;
import com.iem.exception.ApiException;
import com.iem.geo.CollectionPointRepository;
import com.iem.geo.MunicipalityRepository;
import com.iem.model.CollectionPoint;
import com.iem.model.Municipality;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

@Service
public class AdminGeoService {

    private final MunicipalityRepository municipalityRepository;
    private final CollectionPointRepository pointRepository;

    public AdminGeoService(MunicipalityRepository municipalityRepository,
                           CollectionPointRepository pointRepository) {
        this.municipalityRepository = municipalityRepository;
        this.pointRepository = pointRepository;
    }

    @Transactional
    public Map<String, Object> createPoint(CollectionPointRequest request) {

        Municipality municipality = resolve(request.getMunicipalityId(), request.getMunicipalityCode());

        CollectionPoint point = new CollectionPoint();
        point.setCode(nextCode(municipality.getCode()));
        point.setMunicipality(municipality);
        apply(point, request);
        pointRepository.save(point);

        return toMap(point);
    }

    @Transactional
    public Map<String, Object> updatePoint(UUID id, CollectionPointRequest request) {

        CollectionPoint point = pointRepository.findById(id)
                .orElseThrow(() -> new ApiException("Collection point not found", 404));

        if (request.getMunicipalityId() != null || request.getMunicipalityCode() != null) {
            point.setMunicipality(resolve(request.getMunicipalityId(), request.getMunicipalityCode()));
        }
        apply(point, request);
        pointRepository.save(point);

        return toMap(point);
    }

    @Transactional
    public void deactivatePoint(UUID id) {
        CollectionPoint point = pointRepository.findById(id)
                .orElseThrow(() -> new ApiException("Collection point not found", 404));
        point.setActive(false);
        pointRepository.save(point);
    }

    @Transactional
    public Map<String, Object> createMunicipality(MunicipalityRequest request) {

        String code = request.getCode().trim().toUpperCase();
        if (municipalityRepository.findByCode(code).isPresent()) {
            throw new ApiException("A municipality with that code already exists", 409);
        }

        Municipality municipality = new Municipality();
        municipality.setCode(code);
        municipality.setName(request.getName().trim());
        municipality.setDistrict(request.getDistrict().trim());
        municipality.setState(request.getState() == null ? "West Bengal" : request.getState());
        municipality.setDepotName(request.getDepotName() == null
                ? request.getName().trim() + " Depot" : request.getDepotName());
        municipality.setDepotLat(request.getDepotLat());
        municipality.setDepotLon(request.getDepotLon());
        municipality.setActive(request.getActive() == null || request.getActive());
        municipalityRepository.save(municipality);

        return toMap(municipality);
    }

    @Transactional
    public Map<String, Object> updateMunicipality(UUID id, MunicipalityRequest request) {

        Municipality municipality = municipalityRepository.findById(id)
                .orElseThrow(() -> new ApiException("Municipality not found", 404));

        if (request.getName() != null) municipality.setName(request.getName().trim());
        if (request.getDistrict() != null) municipality.setDistrict(request.getDistrict().trim());
        if (request.getState() != null) municipality.setState(request.getState());
        if (request.getDepotName() != null) municipality.setDepotName(request.getDepotName());
        if (request.getDepotLat() != null) municipality.setDepotLat(request.getDepotLat());
        if (request.getDepotLon() != null) municipality.setDepotLon(request.getDepotLon());
        if (request.getActive() != null) municipality.setActive(request.getActive());

        municipalityRepository.save(municipality);
        return toMap(municipality);
    }

    private Municipality resolve(UUID id, String code) {
        if (id != null) {
            return municipalityRepository.findById(id)
                    .orElseThrow(() -> new ApiException("Municipality not found", 404));
        }
        if (code != null && !code.isBlank()) {
            return municipalityRepository.findByCode(code.trim().toUpperCase())
                    .orElseThrow(() -> new ApiException("Municipality not found", 404));
        }
        throw new ApiException("municipalityId or municipalityCode is required", 400);
    }

    private void apply(CollectionPoint point, CollectionPointRequest request) {
        point.setName(request.getName().trim());
        point.setLocality(request.getLocality());
        point.setWard(request.getWard());
        point.setType(request.getType() == null ? "BIN_CLUSTER" : request.getType());
        point.setLat(request.getLat());
        point.setLon(request.getLon());
        if (request.getActive() != null) {
            point.setActive(request.getActive());
        }
    }

    private String nextCode(String municipalityCode) {
        long count = pointRepository.count() + 1;
        String code = String.format("CP-%s-%03d", municipalityCode, count);
        while (pointRepository.findByCode(code).isPresent()) {
            count++;
            code = String.format("CP-%s-%03d", municipalityCode, count);
        }
        return code;
    }

    private Map<String, Object> toMap(CollectionPoint p) {
        return Map.of("id", p.getId(), "code", p.getCode(), "name", p.getName(),
                "locality", p.getLocality() == null ? "" : p.getLocality(),
                "ward", p.getWard() == null ? "" : p.getWard(),
                "type", p.getType(), "lat", p.getLat(), "lon", p.getLon(),
                "active", p.isActive(), "municipality", p.getMunicipality().getName());
    }

    private Map<String, Object> toMap(Municipality m) {
        return Map.of("id", m.getId(), "code", m.getCode(), "name", m.getName(),
                "district", m.getDistrict(), "state", m.getState(),
                "depotName", m.getDepotName(), "depotLat", m.getDepotLat(),
                "depotLon", m.getDepotLon(), "active", m.isActive());
    }
}
