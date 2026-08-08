package com.iem.admin;

import com.iem.enums.Role;
import com.iem.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface AdminRepository extends JpaRepository<User, UUID> {

    @Query("""
           select u from User u
            where (:role is null or u.role = :role)
              and (:municipalityId is null or u.municipalityId = :municipalityId)
              and (:search is null or lower(u.fullName) like :search or lower(u.email) like :search)
            order by u.createdAt desc
           """)
    Page<User> search(@Param("role") Role role,
                      @Param("municipalityId") UUID municipalityId,
                      @Param("search") String search,
                      Pageable pageable);

    long countByRole(Role role);

    @Query("select count(d) from Detection d")
    long totalScans();

    @Query("select coalesce(sum(d.totalObjects), 0) from Detection d")
    long totalObjects();

    @Query("select coalesce(sum(d.carbonSavedKg), 0) from Detection d")
    BigDecimal totalCarbon();

    @Query("select coalesce(sum(u.points), 0) from User u")
    long totalPoints();

    @Query("select count(p) from Pickup p")
    long totalPickups();

    @Query("select count(p) from Pickup p where p.status = com.iem.enums.PickupStatus.COMPLETED")
    long completedPickups();

    @Query("""
           select coalesce(sum(coalesce(p.finalWeightKg, p.estimatedWeightKg)), 0) from Pickup p
            where p.status = com.iem.enums.PickupStatus.COMPLETED
           """)
    BigDecimal wasteDiverted();

    @Query("select p.status, count(p) from Pickup p group by p.status")
    List<Object[]> pickupsByStatus();

    @Query("select m.bin, count(m) from DetectionMaterial m group by m.bin")
    List<Object[]> materialsByBin();

    @Query("""
           select m.material, count(m), coalesce(sum(m.estimatedWeightKg), 0),
                  coalesce(sum(m.estimatedValue), 0)
             from DetectionMaterial m
            group by m.material
            order by count(m) desc
           """)
    List<Object[]> topMaterials(Pageable pageable);

    @Query("select u.role, count(u) from User u group by u.role")
    List<Object[]> usersByRole();

    @Query("select count(d) from Detection d where d.createdAt >= :from and d.createdAt < :to")
    long scansBetween(@Param("from") Instant from, @Param("to") Instant to);

    @Query("select count(p) from Pickup p where p.createdAt >= :from and p.createdAt < :to")
    long pickupsBetween(@Param("from") Instant from, @Param("to") Instant to);

    @Query("select count(l) from Listing l where l.status = com.iem.enums.ListingStatus.OPEN")
    long openListings();

    @Query("select count(l) from Listing l where l.status = com.iem.enums.ListingStatus.SOLD")
    long soldListings();

    @Query("""
           select coalesce(sum(l.price), 0) from Listing l
            where l.status = com.iem.enums.ListingStatus.SOLD
           """)
    BigDecimal tradedValue();
}
