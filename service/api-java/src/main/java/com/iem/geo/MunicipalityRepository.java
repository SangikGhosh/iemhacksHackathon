package com.iem.geo;

import com.iem.model.Municipality;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MunicipalityRepository extends JpaRepository<Municipality, UUID> {

    Optional<Municipality> findByCode(String code);

    List<Municipality> findByActiveTrue();
}
