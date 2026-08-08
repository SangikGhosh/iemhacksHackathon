package com.iem.market;

import com.iem.enums.ListingStatus;
import com.iem.model.Listing;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.UUID;

public interface ListingRepository extends JpaRepository<Listing, UUID> {

    Page<Listing> findByStatus(ListingStatus status, Pageable pageable);

    Page<Listing> findBySellerId(UUID sellerId, Pageable pageable);

    Page<Listing> findByBuyerId(UUID buyerId, Pageable pageable);

    boolean existsByDetectionIdAndStatus(UUID detectionId, ListingStatus status);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
           update Listing l
              set l.buyerId = :buyerId,
                  l.status = com.iem.enums.ListingStatus.SOLD,
                  l.soldAt = :soldAt
            where l.id = :id
              and l.status = com.iem.enums.ListingStatus.OPEN
              and l.buyerId is null
           """)
    int claim(@Param("id") UUID id, @Param("buyerId") UUID buyerId, @Param("soldAt") Instant soldAt);
}
