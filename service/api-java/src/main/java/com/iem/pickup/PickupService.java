package com.iem.pickup;

import com.iem.auth.UserRepository;
import com.iem.detection.DetectionRepository;
import com.iem.enums.PickupMode;
import com.iem.enums.PickupStatus;
import com.iem.geo.CollectionPointService;
import com.iem.model.CollectionPoint;
import com.iem.enums.Role;
import com.iem.exception.ApiException;
import com.iem.mail.MailService;
import com.iem.model.Detection;
import com.iem.model.Pickup;
import com.iem.model.User;
import com.iem.pickup.dto.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class PickupService {

    private static final Logger log = LoggerFactory.getLogger(PickupService.class);

    private static final String BY_USER = "USER";

    private final PickupRepository pickupRepository;
    private final DetectionRepository detectionRepository;
    private final UserRepository userRepository;
    private final MailService mailService;
    private final CollectionPointService collectionPointService;
    private final int doorstepPointsPerKg;
    private final int dropOffPointsPerKg;
    private final int completionBonus;

    public PickupService(PickupRepository pickupRepository,
                         DetectionRepository detectionRepository,
                         UserRepository userRepository,
                         MailService mailService,
                         CollectionPointService collectionPointService,
                         @org.springframework.beans.factory.annotation.Value("${rewards.doorstep-points-per-kg:5}") int doorstepPointsPerKg,
                         @org.springframework.beans.factory.annotation.Value("${rewards.dropoff-points-per-kg:8}") int dropOffPointsPerKg,
                         @org.springframework.beans.factory.annotation.Value("${rewards.completion-bonus:20}") int completionBonus) {
        this.pickupRepository = pickupRepository;
        this.detectionRepository = detectionRepository;
        this.userRepository = userRepository;
        this.mailService = mailService;
        this.collectionPointService = collectionPointService;
        this.doorstepPointsPerKg = doorstepPointsPerKg;
        this.dropOffPointsPerKg = dropOffPointsPerKg;
        this.completionBonus = completionBonus;
    }

    @Transactional
    public PickupResponse create(UUID userId, CreatePickupRequest request) {

        Detection detection = detectionRepository.findById(request.getDetectionId())
                .orElseThrow(() -> new ApiException("Scan not found", 404));

        if (!detection.getUserId().equals(userId)) {
            throw new ApiException("Scan not found", 404);
        }

        if (!detection.isEligible()) {
            throw new ApiException(
                    "This scan has no waste to collect. Please scan the waste again.", 400);
        }

        if (pickupRepository.existsByDetectionIdAndStatusNot(detection.getId(), PickupStatus.CANCELLED)) {
            throw new ApiException("A pickup already exists for this scan", 409);
        }

        PickupMode mode = request.getMode() == null ? PickupMode.DOORSTEP : request.getMode();

        Pickup pickup = new Pickup();
        pickup.setDetectionId(detection.getId());
        pickup.setUserId(userId);
        pickup.setStatus(PickupStatus.REQUESTED);
        pickup.setMode(mode);
        pickup.setNotes(request.getNotes());
        pickup.setPreferredTime(request.getPreferredTime());
        pickup.setCurrency(detection.getCurrency());
        pickup.setEstimatedOffer(detection.getEstimatedOffer());
        pickup.setTotalObjects(detection.getTotalObjects());
        pickup.setMaterialSummary(materialSummary(detection));
        pickup.setEstimatedWeightKg(detection.getEstimatedWeightKg());

        if (mode == PickupMode.DROP_OFF) {
            if (request.getCollectionPointId() == null) {
                throw new ApiException("collectionPointId is required for a drop-off", 400);
            }
            CollectionPoint point = collectionPointService.require(request.getCollectionPointId());
            pickup.setCollectionPointId(point.getId());
            pickup.setMunicipalityId(point.getMunicipality().getId());
            pickup.setAddress(point.getName() + ", " + point.getLocality());
            pickup.setLandmark(point.getWard());
            pickup.setLatitude(point.getLat());
            pickup.setLongitude(point.getLon());
            pickup.setContactPhone(request.getContactPhone() == null
                    ? null : request.getContactPhone().trim());
        } else {
            if (request.getAddress() == null || request.getAddress().isBlank()) {
                throw new ApiException("address is required for a doorstep pickup", 400);
            }
            if (request.getContactPhone() == null || request.getContactPhone().isBlank()) {
                throw new ApiException("contactPhone is required for a doorstep pickup", 400);
            }
            pickup.setAddress(request.getAddress().trim());
            pickup.setLandmark(request.getLandmark());
            pickup.setContactPhone(request.getContactPhone().trim());
            pickup.setLatitude(request.getLatitude());
            pickup.setLongitude(request.getLongitude());
        }

        pickup.setRewardPoints(rewardFor(mode, pickup.getEstimatedWeightKg()));

        pickupRepository.save(pickup);

        notifyCollectors(pickup);

        return toResponse(pickup);
    }

    @Transactional
    public PickupResponse accept(UUID collectorId, UUID pickupId) {

        Pickup existing = load(pickupId);

        if (existing.getUserId().equals(collectorId)) {
            throw new ApiException("You cannot accept your own pickup request", 403);
        }

        if (pickupRepository.claim(pickupId, collectorId, Instant.now()) == 0) {
            Pickup current = load(pickupId);
            if (current.getStatus() == PickupStatus.CANCELLED) {
                throw new ApiException("This pickup was cancelled", 409);
            }
            throw new ApiException("This pickup has already been accepted by another collector", 409);
        }

        Pickup pickup = load(pickupId);

        userRepository.findById(pickup.getUserId()).ifPresent(citizen ->
                userRepository.findById(collectorId).ifPresent(collector ->
                        mailService.sendPickupAcceptedEmail(citizen.getEmail(),
                                collector.getFullName(), pickup.getAddress())));

        return toResponse(pickup);
    }

    @Transactional
    public PickupResponse complete(UUID collectorId, UUID pickupId, CompletePickupRequest request) {

        Pickup pickup = load(pickupId);

        if (pickup.getStatus() != PickupStatus.ACCEPTED) {
            throw new ApiException("Only an accepted pickup can be completed", 409);
        }

        if (pickup.getCollectorId() == null || !pickup.getCollectorId().equals(collectorId)) {
            throw new ApiException("This pickup is not assigned to you", 403);
        }

        pickup.setStatus(PickupStatus.COMPLETED);
        pickup.setCompletedAt(Instant.now());
        pickup.setFinalWeightKg(request.getFinalWeightKg());
        pickup.setFinalAmount(request.getFinalAmount());
        pickup.setCollectorNotes(request.getCollectorNotes());

        awardReward(pickup, request.getFinalWeightKg());

        return toResponse(pickup);
    }

    @Transactional
    public PickupResponse cancelByUser(UUID userId, UUID pickupId, CancelPickupRequest request) {

        Pickup pickup = load(pickupId);

        if (!pickup.getUserId().equals(userId)) {
            throw new ApiException("Pickup not found", 404);
        }

        if (pickup.getStatus() == PickupStatus.ACCEPTED) {
            throw new ApiException(
                    "A collector has already accepted this pickup and it can no longer be cancelled.",
                    409);
        }

        if (pickup.getStatus() != PickupStatus.REQUESTED) {
            throw new ApiException("This pickup is already " + pickup.getStatus().name().toLowerCase(), 409);
        }

        pickup.setStatus(PickupStatus.CANCELLED);
        pickup.setCancelledAt(Instant.now());
        pickup.setCancelledBy(BY_USER);
        pickup.setCancelReason(request == null ? null : request.getReason());

        return toResponse(pickup);
    }

    @Transactional
    public PickupResponse releaseByCollector(UUID collectorId, UUID pickupId, CancelPickupRequest request) {

        Pickup pickup = load(pickupId);

        if (pickup.getStatus() != PickupStatus.ACCEPTED) {
            throw new ApiException("Only an accepted pickup can be released", 409);
        }

        if (pickup.getCollectorId() == null || !pickup.getCollectorId().equals(collectorId)) {
            throw new ApiException("This pickup is not assigned to you", 403);
        }

        pickup.setCollectorId(null);
        pickup.setStatus(PickupStatus.REQUESTED);
        pickup.setAcceptedAt(null);
        pickup.setCollectorNotes(request == null ? null : request.getReason());

        return toResponse(pickup);
    }

    @Transactional(readOnly = true)
    public PickupResponse get(UUID actorId, Role role, UUID pickupId) {

        Pickup pickup = load(pickupId);

        boolean owner = pickup.getUserId().equals(actorId);
        boolean assigned = actorId.equals(pickup.getCollectorId());
        boolean collectorViewingOpen = role == Role.COLLECTOR
                && pickup.getStatus() == PickupStatus.REQUESTED;
        boolean admin = role == Role.MUNICIPAL_ADMIN || role == Role.SUPER_ADMIN;

        if (!owner && !assigned && !collectorViewingOpen && !admin) {
            throw new ApiException("Pickup not found", 404);
        }

        return toResponse(pickup);
    }

    @Transactional(readOnly = true)
    public PickupListResponse mine(UUID actorId, Role role, int page, int size) {
        PageRequest pageable = pageable(page, size);
        Page<Pickup> results = role == Role.COLLECTOR
                ? pickupRepository.findByCollectorId(actorId, pageable)
                : pickupRepository.findByUserId(actorId, pageable);
        return toList(results, pageable);
    }

    @Transactional(readOnly = true)
    public PickupListResponse available(int page, int size) {
        PageRequest pageable = pageable(page, size);
        Page<Pickup> results = pickupRepository
                .findByStatusAndCollectorIdIsNull(PickupStatus.REQUESTED, pageable);
        return toList(results, pageable);
    }

    private PageRequest pageable(int page, int size) {
        return PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100),
                Sort.by(Sort.Direction.DESC, "createdAt"));
    }

    private PickupListResponse toList(Page<Pickup> results, PageRequest pageable) {
        Map<UUID, User> people = loadPeople(results.getContent());
        List<PickupResponse> items = results.getContent().stream()
                .map(p -> PickupResponse.from(p, party(people.get(p.getUserId())),
                        party(people.get(p.getCollectorId()))))
                .toList();
        return new PickupListResponse(items, pageable.getPageNumber(), pageable.getPageSize(),
                results.getTotalElements(), results.getTotalPages(), results.hasNext());
    }

    private Map<UUID, User> loadPeople(List<Pickup> pickups) {
        List<UUID> ids = pickups.stream()
                .flatMap(p -> java.util.stream.Stream.of(p.getUserId(), p.getCollectorId()))
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
        if (ids.isEmpty()) {
            return Map.of();
        }
        return userRepository.findAllById(ids).stream()
                .collect(Collectors.toMap(User::getId, u -> u));
    }

    private Pickup load(UUID pickupId) {
        return pickupRepository.findById(pickupId)
                .orElseThrow(() -> new ApiException("Pickup not found", 404));
    }

    private PickupResponse toResponse(Pickup pickup) {
        User citizen = userRepository.findById(pickup.getUserId()).orElse(null);
        User collector = pickup.getCollectorId() == null ? null
                : userRepository.findById(pickup.getCollectorId()).orElse(null);
        return PickupResponse.from(pickup, party(citizen), party(collector));
    }

    private PickupResponse.Party party(User user) {
        return user == null ? null
                : new PickupResponse.Party(user.getId(), user.getFullName(), user.getEmail());
    }

    private int rewardFor(PickupMode mode, BigDecimal weightKg) {
        if (weightKg == null || weightKg.signum() <= 0) {
            return 0;
        }
        int rate = mode == PickupMode.DROP_OFF ? dropOffPointsPerKg : doorstepPointsPerKg;
        return weightKg.multiply(BigDecimal.valueOf(rate))
                .setScale(0, RoundingMode.HALF_UP)
                .intValue();
    }

    private void awardReward(Pickup pickup, BigDecimal finalWeightKg) {
        if (pickup.isRewardAwarded()) {
            return;
        }
        BigDecimal weight = finalWeightKg != null && finalWeightKg.signum() > 0
                ? finalWeightKg
                : pickup.getEstimatedWeightKg();

        int points = rewardFor(pickup.getMode(), weight) + completionBonus;
        pickup.setRewardPoints(points);

        if (points <= 0) {
            return;
        }

        userRepository.findById(pickup.getUserId()).ifPresent(user -> {
            user.setPoints(user.getPoints() + points);
            userRepository.save(user);
            pickup.setRewardAwarded(true);
            log.info("Awarded {} green points to user {} for a completed {} pickup "
                            + "({} bonus + weight)",
                    points, pickup.getUserId(), pickup.getMode(), completionBonus);
        });
    }

    private String materialSummary(Detection detection) {
        String summary = detection.getMaterials().stream()
                .map(m -> m.getMaterial() + " x" + m.getCount())
                .collect(Collectors.joining(", "));
        return summary.length() <= 200 ? summary : summary.substring(0, 200);
    }

    private void notifyCollectors(Pickup pickup) {
        List<User> collectors = userRepository.findByRole(Role.COLLECTOR);
        if (collectors.isEmpty()) {
            log.info("Pickup {} created but no collectors are registered", pickup.getId());
            return;
        }
        log.info("Notifying {} collectors about pickup {}", collectors.size(), pickup.getId());
        collectors.forEach(collector -> mailService.sendPickupAvailableEmail(
                collector.getEmail(), pickup.getAddress(), pickup.getMaterialSummary(),
                pickup.getCurrency(), pickup.getEstimatedOffer()));
    }
}
