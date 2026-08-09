package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.UserRepository;
import com.iem.auth.dto.RegisterRequest;
import com.iem.detection.DetectionRepository;
import com.iem.detection.ScanPointsBackfill;
import com.iem.enums.PickupMode;
import com.iem.enums.PickupStatus;
import com.iem.enums.Role;
import com.iem.model.Detection;
import com.iem.model.Pickup;
import com.iem.model.User;
import com.iem.pickup.PickupRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class ScanPointsBackfillTests {

    @Autowired private ScanPointsBackfill backfill;
    @Autowired private DetectionRepository detectionRepository;
    @Autowired private PickupRepository pickupRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private AuthService authService;

    private User citizen;

    @BeforeEach
    void setUp() {
        pickupRepository.deleteAll();
        detectionRepository.deleteAll();

        RegisterRequest r = new RegisterRequest();
        r.setEmail("backfill-" + UUID.randomUUID() + "@example.com");
        r.setFullName("Backfill Citizen");
        r.setPassword("password123");
        r.setOtp("000000");
        r.setRole(Role.CITIZEN);
        citizen = authService.register(r);
    }

    private Detection storeDetection(int points, boolean awarded) {
        Detection d = new Detection();
        d.setUserId(citizen.getId());
        d.setStatus("MANUAL_PRICING_REQUIRED");
        d.setEligible(true);
        d.setTotalObjects(13);
        d.setTotalRewardPoints(points);
        d.setPointsAwarded(awarded);
        d.setCurrency("INR");
        d.setEstimatedWeightKg(new BigDecimal("0.390"));
        return detectionRepository.save(d);
    }

    private Pickup completedPickupFor(UUID detectionId) {
        return completedPickupFor(detectionId, 101);
    }

    private Pickup completedPickupFor(UUID detectionId, int rewardPoints) {
        Pickup p = new Pickup();
        p.setDetectionId(detectionId);
        p.setUserId(citizen.getId());
        p.setStatus(PickupStatus.COMPLETED);
        p.setMode(PickupMode.DOORSTEP);
        p.setRewardPoints(rewardPoints);
        p.setRewardAwarded(true);
        return pickupRepository.save(p);
    }

    private void setPoints(int points) {
        citizen.setPoints(points);
        userRepository.save(citizen);
    }

    private int points() {
        return userRepository.findById(citizen.getId()).orElseThrow().getPoints();
    }

    @Test
    void anUncollectedScanHasItsPointsTakenBack() {
        Detection stale = storeDetection(65, true);
        setPoints(65);

        backfill.run(null);

        assertEquals(0, points(), "points credited by a scan that was never collected");
        assertFalse(detectionRepository.findById(stale.getId()).orElseThrow().isPointsAwarded(),
                "the scan can still earn later if a collector eventually completes it");
    }

    @Test
    void aScanThatWasActuallyCollectedIsLeftAlone() {
        Detection collected = storeDetection(65, true);
        completedPickupFor(collected.getId());
        setPoints(101);

        backfill.run(null);

        assertEquals(101, points(),
                "old 65-on-scan plus 20+weight equals the new 20+weight+65, so the total "
                        + "was already right and must not be touched");
        assertTrue(detectionRepository.findById(collected.getId()).orElseThrow().isPointsAwarded());
    }

    @Test
    void onlyTheUncollectedPortionIsReversed() {
        Detection collected = storeDetection(65, true);
        completedPickupFor(collected.getId());
        storeDetection(65, true);
        setPoints(166);

        backfill.run(null);

        assertEquals(101, points(), "one scan reversed, the collected one preserved");
    }

    @Test
    void runningItTwiceChangesNothingTheSecondTime() {
        storeDetection(65, true);
        setPoints(65);

        backfill.run(null);
        int afterFirst = points();
        backfill.run(null);

        assertEquals(afterFirst, points(), "the backfill must be safe to run on every boot");
        assertEquals(0, afterFirst);
    }

    @Test
    void aBalanceIsNeverDrivenNegative() {
        storeDetection(65, true);
        setPoints(10);

        backfill.run(null);

        assertEquals(0, points(), "spent or otherwise reduced balances clamp at zero");
    }

    @Test
    void anAlreadyCorrectDatabaseIsUntouched() {
        storeDetection(65, false);
        setPoints(0);

        backfill.run(null);

        assertEquals(0, points());
    }

    @Test
    void aLegacyPickupIsRestatedToIncludeTheScanItWasPaidFor() {
        Detection collected = storeDetection(65, true);
        Pickup legacy = completedPickupFor(collected.getId(), 36);
        setPoints(101);

        backfill.run(null);

        assertEquals(101, pickupRepository.findById(legacy.getId()).orElseThrow().getRewardPoints(),
                "36 recorded + the 65 that was credited separately at scan time");
        assertEquals(101, points(), "the balance was already right and must not move");
    }

    @Test
    void aPickupAwardedUnderTheNewRuleIsNotRestatedAgain() {
        Detection collected = storeDetection(65, true);
        Pickup current = completedPickupFor(collected.getId(), 101);
        setPoints(101);

        backfill.run(null);
        backfill.run(null);

        assertEquals(101, pickupRepository.findById(current.getId()).orElseThrow().getRewardPoints(),
                "already includes the scan points, so it must never be topped up");
        assertEquals(101, points());
    }

    @Test
    void afterTheBackfillEveryBalanceEqualsWhatItsPickupsRecord() {
        Detection collected = storeDetection(65, true);
        completedPickupFor(collected.getId(), 36);
        storeDetection(65, true);
        setPoints(166);

        backfill.run(null);

        int recorded = pickupRepository.findAll().stream()
                .filter(p -> p.getStatus() == PickupStatus.COMPLETED && p.isRewardAwarded())
                .mapToInt(Pickup::getRewardPoints)
                .sum();

        assertEquals(recorded, points(),
                "the ledger and the balance must agree once the backfill has run");
        assertEquals(101, points());
    }
}
