package com.iem.pickup;

import com.iem.enums.PickupStatus;
import com.iem.model.Pickup;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.UUID;

public interface PickupRepository extends JpaRepository<Pickup, UUID> {

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
           update Pickup p
              set p.collectorId = :collectorId,
                  p.status = com.iem.enums.PickupStatus.ACCEPTED,
                  p.acceptedAt = :acceptedAt,
                  p.cancelledBy = null,
                  p.cancelReason = null
            where p.id = :id
              and p.status = com.iem.enums.PickupStatus.REQUESTED
              and p.collectorId is null
           """)
    int claim(@Param("id") UUID id,
              @Param("collectorId") UUID collectorId,
              @Param("acceptedAt") Instant acceptedAt);

    boolean existsByDetectionIdAndStatusNot(UUID detectionId, PickupStatus status);

    Page<Pickup> findByUserId(UUID userId, Pageable pageable);

    Page<Pickup> findByCollectorId(UUID collectorId, Pageable pageable);

    Page<Pickup> findByStatusAndCollectorIdIsNull(PickupStatus status, Pageable pageable);
}
