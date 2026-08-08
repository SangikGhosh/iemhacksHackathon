package com.iem.rewards;

import com.iem.model.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface LeaderboardRepository extends JpaRepository<User, UUID> {

    @Query("""
           select u.id, u.fullName, u.role, u.points,
                  (select count(p) from Pickup p
                    where p.userId = u.id and p.status = com.iem.enums.PickupStatus.COMPLETED),
                  (select coalesce(sum(coalesce(p.finalWeightKg, p.estimatedWeightKg)), 0)
                     from Pickup p
                    where p.userId = u.id and p.status = com.iem.enums.PickupStatus.COMPLETED)
             from User u
            where u.points > 0
            order by u.points desc, u.createdAt asc
           """)
    List<Object[]> topByPoints(Pageable pageable);

    @Query("select count(u) from User u where u.points > :points")
    long countAhead(@Param("points") int points);

    @Query("select count(u) from User u where u.points > 0")
    long countScoring();

    @Query("select coalesce(sum(u.points), 0) from User u")
    long totalPoints();

    @Query("""
           select coalesce(sum(coalesce(p.finalWeightKg, p.estimatedWeightKg)), 0)
             from Pickup p where p.status = com.iem.enums.PickupStatus.COMPLETED
           """)
    BigDecimal totalWeightCollected();

    @Query("select count(p) from Pickup p where p.status = com.iem.enums.PickupStatus.COMPLETED")
    long totalCompletedPickups();

    @Query("""
           select count(p) from Pickup p
            where p.userId = :userId and p.status = com.iem.enums.PickupStatus.COMPLETED
           """)
    long completedFor(@Param("userId") UUID userId);
}
