package com.iem.geo;

import com.iem.model.CollectionPoint;
import com.iem.model.Municipality;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class GeoSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(GeoSeeder.class);

    private final MunicipalityRepository municipalityRepository;
    private final CollectionPointRepository pointRepository;
    private final boolean enabled;

    public GeoSeeder(MunicipalityRepository municipalityRepository,
                     CollectionPointRepository pointRepository,
                     @Value("${geo.seed.enabled:true}") boolean enabled) {
        this.municipalityRepository = municipalityRepository;
        this.pointRepository = pointRepository;
        this.enabled = enabled;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {

        if (!enabled) {
            return;
        }

        Map<String, Municipality> municipalities = new HashMap<>();
        int newMunicipalities = 0;

        for (String[] row : read("seed/municipalities.csv")) {
            Municipality existing = municipalityRepository.findByCode(row[0]).orElse(null);
            if (existing == null) {
                Municipality m = new Municipality();
                m.setCode(row[0]);
                m.setName(row[1]);
                m.setDistrict(row[2]);
                m.setState(row[3]);
                m.setDepotName(row[4]);
                m.setDepotLat(Double.parseDouble(row[5]));
                m.setDepotLon(Double.parseDouble(row[6]));
                existing = municipalityRepository.save(m);
                newMunicipalities++;
            }
            municipalities.put(row[0], existing);
        }

        int newPoints = 0;
        for (String[] row : read("seed/collection_points.csv")) {
            if (pointRepository.findByCode(row[0]).isPresent()) {
                continue;
            }
            Municipality municipality = municipalities.get(row[1]);
            if (municipality == null) {
                continue;
            }
            CollectionPoint p = new CollectionPoint();
            p.setCode(row[0]);
            p.setMunicipality(municipality);
            p.setName(row[2]);
            p.setLocality(row[3]);
            p.setWard(row[4]);
            p.setType(row[5]);
            p.setLat(Double.parseDouble(row[6]));
            p.setLon(Double.parseDouble(row[7]));
            pointRepository.save(p);
            newPoints++;
        }

        if (newMunicipalities > 0 || newPoints > 0) {
            log.info("Seeded {} municipalities and {} collection points", newMunicipalities, newPoints);
        } else {
            log.info("Geo seed already present: {} municipalities, {} collection points",
                    municipalityRepository.count(), pointRepository.count());
        }
    }

    private List<String[]> read(String path) {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(new ClassPathResource(path).getInputStream(), StandardCharsets.UTF_8))) {
            return reader.lines()
                    .skip(1)
                    .filter(line -> !line.isBlank())
                    .map(line -> line.split(",", -1))
                    .toList();
        } catch (Exception e) {
            log.error("Could not read seed file {}: {}", path, e.getMessage());
            return List.of();
        }
    }
}
