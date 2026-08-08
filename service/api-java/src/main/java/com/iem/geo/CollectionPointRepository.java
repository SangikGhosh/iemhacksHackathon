package com.iem.geo;

import com.iem.model.CollectionPoint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CollectionPointRepository extends JpaRepository<CollectionPoint, UUID> {

    Optional<CollectionPoint> findByCode(String code);

    @Query("""
           select p from CollectionPoint p
             join fetch p.municipality m
            where p.active = true
              and p.lat between :minLat and :maxLat
              and p.lon between :minLon and :maxLon
           """)
    List<CollectionPoint> findInBox(@Param("minLat") double minLat, @Param("maxLat") double maxLat,
                                    @Param("minLon") double minLon, @Param("maxLon") double maxLon);

    @Query("select p from CollectionPoint p join fetch p.municipality m where p.active = true")
    List<CollectionPoint> findAllActive();

    long countByMunicipalityId(UUID municipalityId);
}
