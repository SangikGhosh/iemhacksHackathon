package com.iem.detection;

import com.iem.model.Detection;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface DetectionRepository extends JpaRepository<Detection, UUID> {

    @Query("select d.id from Detection d where d.userId = :userId")
    Page<UUID> findIdsByUserId(@Param("userId") UUID userId, Pageable pageable);

    @EntityGraph(attributePaths = "materials")
    List<Detection> findByIdIn(List<UUID> ids);

    long countByUserId(UUID userId);

    @Query("select coalesce(sum(d.totalObjects), 0) from Detection d where d.userId = :userId")
    long sumObjects(@Param("userId") UUID userId);

    @Query("""
           select coalesce(sum(d.totalRewardPoints), 0) from Detection d
           where d.userId = :userId and d.pointsAwarded = true
           """)
    long sumAwardedPoints(@Param("userId") UUID userId);

    @Query("select coalesce(sum(d.carbonSavedKg), 0) from Detection d where d.userId = :userId")
    BigDecimal sumCarbon(@Param("userId") UUID userId);

    @Query("select coalesce(sum(d.estimatedOffer), 0) from Detection d where d.userId = :userId")
    BigDecimal sumEstimatedOffer(@Param("userId") UUID userId);

    @Query("""
           select d from Detection d
            where d.pointsAwarded = true
              and d.totalRewardPoints > 0
              and not exists (select 1 from Pickup p
                               where p.detectionId = d.id
                                 and p.status = com.iem.enums.PickupStatus.COMPLETED)
           """)
    List<Detection> creditedWithoutACompletedPickup();
}
