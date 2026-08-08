package com.iem.chat.tools;

import com.fasterxml.jackson.databind.JsonNode;
import com.iem.chat.*;
import com.iem.detection.DetectionRepository;
import com.iem.enums.PickupStatus;
import com.iem.exception.ApiException;
import com.iem.geo.CollectionPointService;
import com.iem.market.WalletTransactionRepository;
import com.iem.model.Pickup;
import com.iem.model.WalletTransaction;
import com.iem.pickup.PickupRepository;
import com.iem.rewards.LeaderboardRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class UserTools implements ToolSet {

    private final ToolSchema schema;
    private final LeaderboardRepository leaderboardRepository;
    private final WalletTransactionRepository walletRepository;
    private final PickupRepository pickupRepository;
    private final DetectionRepository detectionRepository;
    private final CollectionPointService collectionPointService;
    private final PriceCatalog priceCatalog;
    private final int completionBonus;
    private final int doorstepPerKg;
    private final int dropoffPerKg;

    public UserTools(ToolSchema schema,
                     LeaderboardRepository leaderboardRepository,
                     WalletTransactionRepository walletRepository,
                     PickupRepository pickupRepository,
                     DetectionRepository detectionRepository,
                     CollectionPointService collectionPointService,
                     PriceCatalog priceCatalog,
                     @Value("${rewards.completion-bonus:20}") int completionBonus,
                     @Value("${rewards.doorstep-points-per-kg:5}") int doorstepPerKg,
                     @Value("${rewards.dropoff-points-per-kg:8}") int dropoffPerKg) {
        this.schema = schema;
        this.leaderboardRepository = leaderboardRepository;
        this.walletRepository = walletRepository;
        this.pickupRepository = pickupRepository;
        this.detectionRepository = detectionRepository;
        this.collectionPointService = collectionPointService;
        this.priceCatalog = priceCatalog;
        this.completionBonus = completionBonus;
        this.doorstepPerKg = doorstepPerKg;
        this.dropoffPerKg = dropoffPerKg;
    }

    @Override
    public List<ChatTool> tools() {
        return List.of(rewardsSummary(), walletSummary(), myPickups(), priceLookup(),
                nearestPoints(), scanSummary(), leaderboard());
    }

    private ChatTool rewardsSummary() {
        return new ChatTool.Simple(
                "get_my_rewards_summary",
                "Green Points balance, leaderboard rank, completed pickups and total waste "
                        + "recycled for the signed-in user, plus how points are earned",
                EVERYONE,
                schema.empty(),
                (ctx, args) -> {
                    int points = ctx.user().getPoints();
                    long rank = leaderboardRepository.countAhead(points) + 1;
                    long scoring = leaderboardRepository.countScoring();
                    long completed = leaderboardRepository.completedFor(ctx.userId());

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("greenPoints", points);
                    out.put("rank", points > 0 ? rank : null);
                    out.put("citizensWithPoints", scoring);
                    out.put("completedPickups", completed);
                    out.put("scans", detectionRepository.countByUserId(ctx.userId()));
                    out.put("objectsScanned", detectionRepository.sumObjects(ctx.userId()));
                    out.put("pointsFromScans", detectionRepository.sumAwardedPoints(ctx.userId()));
                    out.put("earningRules", Map.of(
                            "pickupCompletionBonus", completionBonus,
                            "doorstepPointsPerKg", doorstepPerKg,
                            "dropOffPointsPerKg", dropoffPerKg,
                            "note", "Dropping waste at a collection point earns more than a "
                                    + "doorstep pickup because it saves a vehicle trip"));
                    return out;
                });
    }

    private ChatTool walletSummary() {
        return new ChatTool.Simple(
                "get_my_wallet_summary",
                "Wallet balance, lifetime money in and out, and the most recent transactions "
                        + "for the signed-in user. Use for any payment or earnings question",
                EVERYONE,
                schema.object()
                        .integer("limit", "How many recent transactions to return, 1 to 20")
                        .build(),
                (ctx, args) -> {
                    int limit = clamp(args.path("limit").asInt(5), 1, 20);

                    List<WalletTransaction> recent = walletRepository.findByUserId(
                                    ctx.userId(),
                                    PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "createdAt")))
                            .getContent();

                    List<Map<String, Object>> items = new ArrayList<>();
                    for (WalletTransaction t : recent) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("type", t.getType().name());
                        row.put("amount", t.getAmount());
                        row.put("reason", t.getReason());
                        row.put("note", t.getNote());
                        row.put("balanceAfter", t.getBalanceAfter());
                        row.put("at", t.getCreatedAt());
                        items.add(row);
                    }

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("balance", ctx.user().getWalletBalance());
                    out.put("currency", "INR");
                    out.put("totalCredited", walletRepository.totalCredited(ctx.userId()));
                    out.put("totalDebited", walletRepository.totalDebited(ctx.userId()));
                    out.put("recentTransactions", items);
                    return out;
                });
    }

    private ChatTool myPickups() {
        return new ChatTool.Simple(
                "get_my_pickups",
                "Pickup requests belonging to the signed-in user. Citizens see the pickups they "
                        + "raised, collectors see the ones assigned to them",
                EVERYONE,
                schema.object()
                        .enumeration("status", "Filter by pickup status",
                                List.of("REQUESTED", "ACCEPTED", "COMPLETED", "CANCELLED", "ANY"))
                        .integer("limit", "How many to return, 1 to 20")
                        .build(),
                (ctx, args) -> {
                    int limit = clamp(args.path("limit").asInt(5), 1, 20);
                    String status = args.path("status").asText("ANY");

                    var page = PageRequest.of(0, 50, Sort.by(Sort.Direction.DESC, "createdAt"));
                    List<Pickup> pickups = ctx.role() == com.iem.enums.Role.COLLECTOR
                            ? pickupRepository.findByCollectorId(ctx.userId(), page).getContent()
                            : pickupRepository.findByUserId(ctx.userId(), page).getContent();

                    List<Map<String, Object>> items = pickups.stream()
                            .filter(p -> "ANY".equalsIgnoreCase(status)
                                    || p.getStatus().name().equalsIgnoreCase(status))
                            .limit(limit)
                            .map(UserTools::pickupRow)
                            .toList();

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("count", items.size());
                    out.put("pickups", items);
                    if (items.isEmpty()) {
                        out.put("note", "No pickups matched. The citizen may not have raised one yet.");
                    }
                    return out;
                });
    }

    private ChatTool priceLookup() {
        return new ChatTool.Simple(
                "get_material_price",
                "Scrap rate per kg, bin colour, reward points and typical unit weight for a "
                        + "waste material such as PET bottle, aluminium can, cardboard or glass",
                EVERYONE,
                schema.object()
                        .string("material", "Material name, for example 'pet bottle' or 'aluminium can'. "
                                + "Leave empty to list every material")
                        .integer("quantity", "Optional number of items, to estimate a total payout")
                        .build(),
                (ctx, args) -> {
                    String material = args.path("material").asText("");
                    List<PriceCatalog.Entry> matches = priceCatalog.search(material);

                    if (!priceCatalog.isAvailable()) {
                        return Map.of("error",
                                "The price catalogue is served by the detection service, which is "
                                        + "not reachable right now.");
                    }
                    if (matches.isEmpty()) {
                        return Map.of(
                                "error", "No material called '" + material + "' is in the catalogue",
                                "available", priceCatalog.all().values().stream()
                                        .map(PriceCatalog.Entry::label).sorted().toList());
                    }

                    int quantity = args.path("quantity").asInt(0);
                    List<Map<String, Object>> rows = new ArrayList<>();

                    for (PriceCatalog.Entry e : matches.stream().limit(20).toList()) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("material", e.label());
                        row.put("pricePerKg", e.pricePerKg());
                        row.put("currency", "INR");
                        row.put("bin", e.bin());
                        row.put("recyclable", e.recyclable());
                        row.put("rewardPointsPerItem", e.rewardPoints());
                        row.put("typicalUnitWeightKg", e.unitWeightKg());
                        row.put("carbonSavedKgPerItem", e.carbonSavedKg());
                        if (quantity > 0) {
                            double weight = e.unitWeightKg() * quantity;
                            row.put("forQuantity", quantity);
                            row.put("estimatedWeightKg", round(weight));
                            row.put("estimatedPayout", round(weight * e.pricePerKg()));
                        }
                        rows.add(row);
                    }

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("matches", rows);
                    out.put("pricingNote",
                            "Rates are indicative. A single item is worth very little because it "
                                    + "weighs grams; the collector's weighed figure sets the final amount.");
                    return out;
                });
    }

    private ChatTool nearestPoints() {
        return new ChatTool.Simple(
                "find_nearest_collection_points",
                "Nearest waste collection points, drop-off bins, scrap yards and compost hubs, "
                        + "ranked by real driving time. Needs the user's coordinates",
                EVERYONE,
                schema.object()
                        .number("latitude", "Latitude of the user. Omit if the app already supplied it")
                        .number("longitude", "Longitude of the user. Omit if the app already supplied it")
                        .integer("limit", "How many points to return, 1 to 5")
                        .build(),
                (ctx, args) -> {
                    Double lat = args.hasNonNull("latitude") ? args.get("latitude").asDouble() : ctx.latitude();
                    Double lon = args.hasNonNull("longitude") ? args.get("longitude").asDouble() : ctx.longitude();

                    if (lat == null || lon == null) {
                        return Map.of("error",
                                "I need your location to do that. Ask the user to share their "
                                        + "location, or to name their area so they can search the map.");
                    }

                    int limit = clamp(args.path("limit").asInt(3), 1, 5);

                    try {
                        var points = collectionPointService.nearest(lat, lon, limit);
                        return Map.of("count", points.size(), "points", points);
                    } catch (ApiException e) {
                        return Map.of("error", e.getMessage());
                    }
                });
    }

    private ChatTool scanSummary() {
        return new ChatTool.Simple(
                "get_my_scan_summary",
                "Lifetime scanning totals for the signed-in user: scans, objects recognised, "
                        + "carbon saved and the indicative value of everything they scanned",
                EVERYONE,
                schema.empty(),
                (ctx, args) -> {
                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("scans", detectionRepository.countByUserId(ctx.userId()));
                    out.put("objectsRecognised", detectionRepository.sumObjects(ctx.userId()));
                    out.put("pointsEarnedFromScans", detectionRepository.sumAwardedPoints(ctx.userId()));
                    out.put("carbonSavedKg", detectionRepository.sumCarbon(ctx.userId()));
                    out.put("indicativeValue", detectionRepository.sumEstimatedOffer(ctx.userId()));
                    out.put("currency", "INR");
                    return out;
                });
    }

    private ChatTool leaderboard() {
        return new ChatTool.Simple(
                "get_leaderboard",
                "The Green Points leaderboard, the top recyclers on the platform",
                EVERYONE,
                schema.object().integer("limit", "How many to return, 1 to 20").build(),
                (ctx, args) -> {
                    int limit = clamp(args.path("limit").asInt(5), 1, 20);
                    List<Object[]> rows = leaderboardRepository.topByPoints(PageRequest.of(0, limit));

                    List<Map<String, Object>> items = new ArrayList<>();
                    int position = 1;
                    for (Object[] r : rows) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("rank", position++);
                        row.put("name", r[1]);
                        row.put("role", String.valueOf(r[2]));
                        row.put("points", r[3]);
                        row.put("completedPickups", r[4]);
                        row.put("weightKg", r[5]);
                        items.add(row);
                    }

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("leaders", items);
                    out.put("yourPoints", ctx.user().getPoints());
                    out.put("yourRank", ctx.user().getPoints() > 0
                            ? leaderboardRepository.countAhead(ctx.user().getPoints()) + 1
                            : null);
                    return out;
                });
    }

    static Map<String, Object> pickupRow(Pickup p) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", p.getId());
        row.put("status", p.getStatus().name());
        row.put("mode", p.getMode().name());
        row.put("materials", p.getMaterialSummary());
        row.put("objects", p.getTotalObjects());
        row.put("weightKg", p.getStatus() == PickupStatus.COMPLETED
                ? p.getFinalWeightKg() : p.getEstimatedWeightKg());
        row.put("amount", p.getStatus() == PickupStatus.COMPLETED
                ? p.getFinalAmount() : p.getEstimatedOffer());
        row.put("rewardPoints", p.getRewardPoints());
        row.put("address", p.getAddress());
        row.put("requestedAt", p.getCreatedAt());
        row.put("acceptedAt", p.getAcceptedAt());
        row.put("completedAt", p.getCompletedAt());
        if (p.getStatus() == PickupStatus.CANCELLED) {
            row.put("cancelledBy", p.getCancelledBy());
            row.put("cancelReason", p.getCancelReason());
        }
        return row;
    }

    static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    static BigDecimal round(double value) {
        return BigDecimal.valueOf(Math.round(value * 100.0) / 100.0);
    }
}
