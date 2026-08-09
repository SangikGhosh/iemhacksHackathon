package com.iem.detection;

import com.iem.auth.UserRepository;
import com.iem.model.Detection;
import com.iem.model.Pickup;
import com.iem.model.User;
import com.iem.pickup.PickupRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
@Order(30)
public class ScanPointsBackfill implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(ScanPointsBackfill.class);

    private final DetectionRepository detectionRepository;
    private final PickupRepository pickupRepository;
    private final UserRepository userRepository;
    private final boolean enabled;
    private final int completionBonus;

    public ScanPointsBackfill(DetectionRepository detectionRepository,
                              PickupRepository pickupRepository,
                              UserRepository userRepository,
                              @Value("${rewards.backfill-scan-points:true}") boolean enabled,
                              @Value("${rewards.completion-bonus:20}") int completionBonus) {
        this.detectionRepository = detectionRepository;
        this.pickupRepository = pickupRepository;
        this.userRepository = userRepository;
        this.enabled = enabled;
        this.completionBonus = completionBonus;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {

        if (!enabled) {
            return;
        }

        reverseUncollectedScans();
        restateCollectedPickups();
    }

    private void restateCollectedPickups() {

        List<Object[]> rows = pickupRepository.awardedBeforeScanPointsMoved(completionBonus);
        if (rows.isEmpty()) {
            return;
        }

        for (Object[] row : rows) {
            Pickup pickup = (Pickup) row[0];
            Detection detection = (Detection) row[1];
            pickup.setRewardPoints(pickup.getRewardPoints() + detection.getTotalRewardPoints());
            pickupRepository.save(pickup);
        }

        log.info("Scan-points backfill: restated {} completed pickups so the points they "
                        + "record include the scan they were paid for. Balances are unchanged "
                        + "because those points were already credited.",
                rows.size());
    }

    private void reverseUncollectedScans() {

        List<Detection> stale = detectionRepository.creditedWithoutACompletedPickup();
        if (stale.isEmpty()) {
            return;
        }

        Map<UUID, Integer> owed = new LinkedHashMap<>();
        for (Detection detection : stale) {
            owed.merge(detection.getUserId(), detection.getTotalRewardPoints(), Integer::sum);
            detection.setPointsAwarded(false);
        }

        int corrected = 0;
        for (Map.Entry<UUID, Integer> entry : owed.entrySet()) {
            User user = userRepository.findById(entry.getKey()).orElse(null);
            if (user == null) {
                continue;
            }
            int reduced = Math.max(0, user.getPoints() - entry.getValue());
            log.info("Reversing {} scan points for {}: {} -> {}",
                    entry.getValue(), user.getEmail(), user.getPoints(), reduced);
            user.setPoints(reduced);
            userRepository.save(user);
            corrected++;
        }

        detectionRepository.saveAll(stale);

        log.info("Scan-points backfill: reversed {} scans across {} accounts. Points are now "
                        + "credited only when a collector completes the pickup.",
                stale.size(), corrected);
    }
}
