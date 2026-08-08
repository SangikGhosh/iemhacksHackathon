package com.iem.market;

import com.iem.auth.UserRepository;
import com.iem.detection.DetectionRepository;
import com.iem.enums.ListingStatus;
import com.iem.enums.Role;
import com.iem.enums.TransactionType;
import com.iem.exception.ApiException;
import com.iem.market.dto.*;
import com.iem.model.Detection;
import com.iem.model.Listing;
import com.iem.model.User;
import com.iem.model.WalletTransaction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MarketplaceService {

    private static final Logger log = LoggerFactory.getLogger(MarketplaceService.class);

    private static final String REASON_SOLD = "LISTING_SOLD";
    private static final String REASON_PURCHASED = "LISTING_PURCHASED";

    private final ListingRepository listingRepository;
    private final WalletTransactionRepository transactionRepository;
    private final DetectionRepository detectionRepository;
    private final UserRepository userRepository;
    private final String fallbackImage;

    public MarketplaceService(ListingRepository listingRepository,
                              WalletTransactionRepository transactionRepository,
                              DetectionRepository detectionRepository,
                              UserRepository userRepository,
                              @Value("${market.fallback-image:}") String fallbackImage) {
        this.listingRepository = listingRepository;
        this.transactionRepository = transactionRepository;
        this.detectionRepository = detectionRepository;
        this.userRepository = userRepository;
        this.fallbackImage = fallbackImage;
    }

    @Transactional
    public ListingResponse create(UUID sellerId, CreateListingRequest request) {

        Listing listing = new Listing();
        listing.setSellerId(sellerId);
        listing.setStatus(ListingStatus.OPEN);
        listing.setPrice(request.getPrice());
        listing.setDescription(request.getDescription());
        listing.setLocation(request.getLocation());
        listing.setImageUrl(request.getImageUrl());

        if (request.getDetectionId() != null) {
            Detection detection = detectionRepository.findById(request.getDetectionId())
                    .orElseThrow(() -> new ApiException("Scan not found", 404));

            if (!detection.getUserId().equals(sellerId)) {
                throw new ApiException("Scan not found", 404);
            }
            if (!detection.isEligible()) {
                throw new ApiException("This scan has no waste to sell", 400);
            }
            if (listingRepository.existsByDetectionIdAndStatus(detection.getId(), ListingStatus.OPEN)) {
                throw new ApiException("This scan is already listed", 409);
            }

            listing.setDetectionId(detection.getId());
            listing.setMaterial(request.getMaterial() != null ? request.getMaterial()
                    : materialOf(detection));
            listing.setWeightKg(request.getWeightKg() != null ? request.getWeightKg()
                    : detection.getEstimatedWeightKg());
            listing.setCurrency(detection.getCurrency() == null ? "INR" : detection.getCurrency());
            if (listing.getImageUrl() == null) {
                listing.setImageUrl(detection.getImageUrl());
            }
            if (listing.getDescription() == null) {
                listing.setDescription(detection.getAiSummary());
            }
        } else {
            if (request.getMaterial() == null || request.getMaterial().isBlank()) {
                throw new ApiException("material is required when no scan is attached", 400);
            }
            if (request.getWeightKg() == null) {
                throw new ApiException("weightKg is required when no scan is attached", 400);
            }
            listing.setMaterial(request.getMaterial().trim());
            listing.setWeightKg(request.getWeightKg());
            listing.setCurrency("INR");
        }

        if (listing.getWeightKg() == null || listing.getWeightKg().signum() <= 0) {
            throw new ApiException("weightKg must be greater than zero", 400);
        }

        if (listing.getImageUrl() == null && !fallbackImage.isBlank()) {
            listing.setImageUrl(fallbackImage);
        }

        listingRepository.save(listing);
        log.info("Listing {} created by {}: {} {} kg for {} {}", listing.getId(), sellerId,
                listing.getMaterial(), listing.getWeightKg(), listing.getCurrency(), listing.getPrice());

        return toResponse(listing, sellerId);
    }

    @Transactional
    public ListingResponse expressInterest(UUID buyerId, UUID listingId) {

        Listing listing = load(listingId);

        if (listing.getSellerId().equals(buyerId)) {
            throw new ApiException("You cannot buy your own listing", 403);
        }
        if (listing.getStatus() == ListingStatus.CANCELLED) {
            throw new ApiException("This listing was withdrawn", 409);
        }

        User buyer = userRepository.findById(buyerId)
                .orElseThrow(() -> new ApiException("Buyer not found", 404));

        if (buyer.getWalletBalance().compareTo(listing.getPrice()) < 0) {
            throw new ApiException("Your wallet balance is "
                    + buyer.getWalletBalance() + " " + listing.getCurrency()
                    + ", which is not enough for this listing at "
                    + listing.getPrice() + " " + listing.getCurrency(), 402);
        }

        if (listingRepository.claim(listingId, buyerId, Instant.now()) == 0) {
            throw new ApiException("Another recycler has already taken this listing", 409);
        }

        Listing sold = load(listingId);

        User seller = userRepository.findById(sold.getSellerId())
                .orElseThrow(() -> new ApiException("Seller no longer exists", 404));

        credit(seller, sold.getPrice(), REASON_SOLD, sold,
                "Sold " + sold.getMaterial() + " to " + buyer.getFullName());
        debit(buyer, sold.getPrice(), REASON_PURCHASED, sold,
                "Bought " + sold.getMaterial() + " from " + seller.getFullName());

        log.info("Listing {} sold to {} for {} {}", sold.getId(), buyerId,
                sold.getCurrency(), sold.getPrice());

        return toResponse(sold, buyerId);
    }

    @Transactional
    public ListingResponse cancel(UUID sellerId, UUID listingId) {

        Listing listing = load(listingId);

        if (!listing.getSellerId().equals(sellerId)) {
            throw new ApiException("Listing not found", 404);
        }
        if (listing.getStatus() == ListingStatus.SOLD) {
            throw new ApiException("This listing has already been sold", 409);
        }
        if (listing.getStatus() == ListingStatus.CANCELLED) {
            throw new ApiException("This listing is already withdrawn", 409);
        }

        listing.setStatus(ListingStatus.CANCELLED);
        listing.setCancelledAt(Instant.now());

        return toResponse(listing, sellerId);
    }

    @Transactional(readOnly = true)
    public ListingListResponse browse(UUID viewerId, int page, int size) {
        PageRequest pageable = pageable(page, size);
        return toList(listingRepository.findByStatus(ListingStatus.OPEN, pageable), viewerId, pageable);
    }

    @Transactional(readOnly = true)
    public ListingListResponse mine(UUID viewerId, Role role, int page, int size) {
        PageRequest pageable = pageable(page, size);
        Page<Listing> results = role == Role.RECYCLER
                ? listingRepository.findByBuyerId(viewerId, pageable)
                : listingRepository.findBySellerId(viewerId, pageable);
        return toList(results, viewerId, pageable);
    }

    @Transactional(readOnly = true)
    public ListingResponse get(UUID viewerId, UUID listingId) {
        return toResponse(load(listingId), viewerId);
    }

    @Transactional(readOnly = true)
    public WalletResponse wallet(UUID userId, int page, int size) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException("User not found", 404));

        PageRequest pageable = pageable(page, size);
        Page<WalletTransaction> results = transactionRepository.findByUserId(userId, pageable);

        return new WalletResponse(
                user.getWalletBalance(),
                "INR",
                transactionRepository.totalCredited(userId),
                transactionRepository.totalDebited(userId),
                user.getPoints(),
                results.getContent().stream().map(WalletResponse.Entry::from).toList(),
                pageable.getPageNumber(),
                pageable.getPageSize(),
                results.getTotalElements(),
                results.hasNext());
    }

    private void credit(User user, BigDecimal amount, String reason, Listing listing, String note) {
        user.setWalletBalance(user.getWalletBalance().add(amount));
        userRepository.save(user);
        record(user, TransactionType.CREDIT, amount, reason, listing, note);
    }

    private void debit(User user, BigDecimal amount, String reason, Listing listing, String note) {
        user.setWalletBalance(user.getWalletBalance().subtract(amount));
        userRepository.save(user);
        record(user, TransactionType.DEBIT, amount, reason, listing, note);
    }

    private void record(User user, TransactionType type, BigDecimal amount, String reason,
                        Listing listing, String note) {
        WalletTransaction transaction = new WalletTransaction();
        transaction.setUserId(user.getId());
        transaction.setType(type);
        transaction.setAmount(amount);
        transaction.setBalanceAfter(user.getWalletBalance());
        transaction.setCurrency(listing.getCurrency());
        transaction.setReason(reason);
        transaction.setNote(note);
        transaction.setListingId(listing.getId());
        transaction.setCounterpartyId(type == TransactionType.CREDIT
                ? listing.getBuyerId() : listing.getSellerId());
        transactionRepository.save(transaction);
    }

    private Listing load(UUID id) {
        return listingRepository.findById(id)
                .orElseThrow(() -> new ApiException("Listing not found", 404));
    }

    private PageRequest pageable(int page, int size) {
        return PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100),
                Sort.by(Sort.Direction.DESC, "createdAt"));
    }

    private ListingListResponse toList(Page<Listing> results, UUID viewerId, PageRequest pageable) {
        Map<UUID, User> people = people(results.getContent());
        List<ListingResponse> items = results.getContent().stream()
                .map(l -> ListingResponse.from(l, party(people.get(l.getSellerId())),
                        party(people.get(l.getBuyerId())), viewerId))
                .toList();
        return new ListingListResponse(items, pageable.getPageNumber(), pageable.getPageSize(),
                results.getTotalElements(), results.getTotalPages(), results.hasNext());
    }

    private Map<UUID, User> people(List<Listing> listings) {
        List<UUID> ids = listings.stream()
                .flatMap(l -> java.util.stream.Stream.of(l.getSellerId(), l.getBuyerId()))
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
        return ids.isEmpty() ? Map.of()
                : userRepository.findAllById(ids).stream()
                        .collect(Collectors.toMap(User::getId, u -> u));
    }

    private ListingResponse toResponse(Listing listing, UUID viewerId) {
        User seller = userRepository.findById(listing.getSellerId()).orElse(null);
        User buyer = listing.getBuyerId() == null ? null
                : userRepository.findById(listing.getBuyerId()).orElse(null);
        return ListingResponse.from(listing, party(seller), party(buyer), viewerId);
    }

    private ListingResponse.Party party(User user) {
        return user == null ? null
                : new ListingResponse.Party(user.getId(), user.getFullName(),
                        user.getRole() == null ? null : user.getRole().name());
    }

    private String materialOf(Detection detection) {
        String summary = detection.getMaterials().stream()
                .map(m -> m.getMaterial() + " x" + m.getCount())
                .collect(Collectors.joining(", "));
        if (summary.isBlank()) {
            return "Mixed Waste";
        }
        return summary.length() <= 80 ? summary : summary.substring(0, 80);
    }
}
