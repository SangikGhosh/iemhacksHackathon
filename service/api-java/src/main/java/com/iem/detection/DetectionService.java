package com.iem.detection;

import com.iem.auth.UserRepository;
import com.iem.detection.dto.*;
import com.iem.exception.ApiException;
import com.iem.model.Detection;
import com.iem.model.DetectionMaterial;
import com.iem.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class DetectionService {

    private static final Logger log = LoggerFactory.getLogger(DetectionService.class);

    private static final long MAX_IMAGE_BYTES = 10L * 1024 * 1024;
    private static final Set<String> ALLOWED_TYPES =
            Set.of("image/jpeg", "image/jpg", "image/png", "image/webp", "image/bmp");

    private final DetectionClient client;
    private final DetectionRepository detectionRepository;
    private final UserRepository userRepository;

    public DetectionService(DetectionClient client,
                            DetectionRepository detectionRepository,
                            UserRepository userRepository) {
        this.client = client;
        this.detectionRepository = detectionRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public DetectionResponse scan(UUID userId, MultipartFile image) {

        validate(image);

        DetectionApiResponse result = client.detect(image);

        Detection detection = toEntity(userId, result);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException("User not found", 404));

        Integer balance = user.getPoints();

        if (detection.isEligible() && detection.getTotalRewardPoints() > 0) {
            user.setPoints(user.getPoints() + detection.getTotalRewardPoints());
            userRepository.save(user);
            detection.setPointsAwarded(true);
            balance = user.getPoints();
            log.info("Awarded {} points to user {} for detection",
                    detection.getTotalRewardPoints(), userId);
        }

        detectionRepository.save(detection);

        return DetectionResponse.from(detection, result.message(), balance);
    }

    @Transactional(readOnly = true)
    public DetectionHistoryResponse history(UUID userId, int page, int size) {

        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);

        Page<UUID> ids = detectionRepository.findIdsByUserId(userId,
                PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt")));

        Map<UUID, Detection> loaded = detectionRepository.findByIdIn(ids.getContent()).stream()
                .collect(Collectors.toMap(Detection::getId, d -> d));

        List<DetectionHistoryItem> items = ids.getContent().stream()
                .map(loaded::get)
                .filter(Objects::nonNull)
                .map(DetectionHistoryItem::from)
                .toList();

        return new DetectionHistoryResponse(
                items,
                safePage,
                safeSize,
                ids.getTotalElements(),
                ids.getTotalPages(),
                ids.hasNext(),
                totals(userId)
        );
    }

    private DetectionHistoryResponse.Totals totals(UUID userId) {
        return new DetectionHistoryResponse.Totals(
                (int) detectionRepository.countByUserId(userId),
                (int) detectionRepository.sumObjects(userId),
                (int) detectionRepository.sumAwardedPoints(userId),
                detectionRepository.sumCarbon(userId),
                detectionRepository.sumEstimatedOffer(userId)
        );
    }

    private void validate(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            throw new ApiException("Image file is required", 400);
        }

        if (image.getSize() > MAX_IMAGE_BYTES) {
            throw new ApiException("Image too large, max 10MB", 413);
        }

        String contentType = image.getContentType();
        if (contentType == null || !ALLOWED_TYPES.contains(contentType.toLowerCase())) {
            throw new ApiException("Unsupported image type, use JPEG, PNG, WEBP or BMP", 400);
        }
    }

    private Detection toEntity(UUID userId, DetectionApiResponse r) {

        Detection d = new Detection();
        d.setUserId(userId);
        d.setImageUrl(r.imageUrl());
        d.setStatus(r.status());
        d.setEligible(r.eligible());
        d.setActionRequired(r.actionRequired());
        d.setTotalObjects(r.summary() == null || r.summary().totalObjects() == null
                ? 0 : r.summary().totalObjects());
        d.setTotalRewardPoints(r.totalRewardPoints() == null ? 0 : r.totalRewardPoints());
        d.setProcessingTimeMs(r.processingTimeMs());
        d.setAiSummary(trim(r.aiSummary(), 1000));

        if (r.model() != null) {
            d.setModelId(r.model().modelId());
        }

        if (r.quality() != null) {
            d.setDetectionQuality(r.quality().detectionQuality());
            d.setAverageConfidence(r.quality().averageConfidence());
        }

        if (r.offer() != null) {
            d.setCurrency(r.offer().currency());
            d.setMinimumOffer(r.offer().minimumOffer());
            d.setEstimatedOffer(r.offer().estimatedOffer());
            d.setMaximumOffer(r.offer().maximumOffer());
            d.setOfferStatus(r.offer().status());
            d.setFinalPriceSetBy(r.offer().finalPriceSetBy());
        }

        if (r.environment() != null) {
            d.setCarbonSavedKg(r.environment().carbonSavedKg());
            d.setLandfillReducedKg(r.environment().landfillReducedKg());
            d.setEstimatedWeightKg(r.environment().landfillReducedKg());
        }

        if (r.wasteAnalysis() != null) {
            d.setRecyclablePercent(r.wasteAnalysis().recyclable());
        }

        if (r.recommendation() != null) {
            d.setPrimaryBin(r.recommendation().primaryBin());
            d.setSecondaryBin(r.recommendation().secondaryBin());
            d.setPickupRecommended(Boolean.TRUE.equals(r.recommendation().pickupRecommended()));
        }

        if (r.materials() != null) {
            r.materials().forEach(m -> d.addMaterial(toMaterial(m)));
        }

        return d;
    }

    private DetectionMaterial toMaterial(DetectionApiResponse.Material m) {
        DetectionMaterial entity = new DetectionMaterial();
        entity.setMaterial(m.material());
        entity.setCategory(m.category());
        entity.setStream(m.stream());
        entity.setBin(m.bin());
        entity.setCount(m.count() == null ? 0 : m.count());
        entity.setPricePerKg(m.pricePerKg());
        entity.setEstimatedWeightKg(m.estimatedWeightKg());
        entity.setEstimatedValue(m.estimatedValue());
        entity.setRewardPoints(m.rewardPoints() == null ? 0 : m.rewardPoints());
        entity.setCarbonSavedKg(m.carbonSavedKg());
        entity.setRecyclable(Boolean.TRUE.equals(m.recyclable()));
        return entity;
    }

    private static String trim(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }
}
