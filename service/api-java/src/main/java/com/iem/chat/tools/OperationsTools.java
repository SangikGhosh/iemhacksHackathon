package com.iem.chat.tools;

import com.iem.chat.*;
import com.iem.enums.ListingStatus;
import com.iem.enums.PickupStatus;
import com.iem.enums.Role;
import com.iem.exception.ApiException;
import com.iem.market.ListingRepository;
import com.iem.model.Listing;
import com.iem.model.Pickup;
import com.iem.pickup.PickupRepository;
import com.iem.routing.RouteService;
import com.iem.routing.dto.RouteResponse;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static com.iem.chat.tools.UserTools.clamp;

@Component
public class OperationsTools implements ToolSet {

    private final ToolSchema schema;
    private final PickupRepository pickupRepository;
    private final ListingRepository listingRepository;
    private final RouteService routeService;
    private final PriceCatalog priceCatalog;

    public OperationsTools(ToolSchema schema,
                           PickupRepository pickupRepository,
                           ListingRepository listingRepository,
                           RouteService routeService,
                           PriceCatalog priceCatalog) {
        this.schema = schema;
        this.pickupRepository = pickupRepository;
        this.listingRepository = listingRepository;
        this.routeService = routeService;
        this.priceCatalog = priceCatalog;
    }

    @Override
    public List<ChatTool> tools() {
        return List.of(availablePickups(), myRoute(), browseListings(), evaluateListing(), myTrades());
    }

    private ChatTool availablePickups() {
        return new ChatTool.Simple(
                "get_available_pickups",
                "Unassigned pickup requests a collector can still accept, newest first",
                COLLECTOR,
                schema.object().integer("limit", "How many to return, 1 to 20").build(),
                (ctx, args) -> {
                    int limit = clamp(args.path("limit").asInt(5), 1, 20);

                    List<Pickup> open = pickupRepository.findByStatusAndCollectorIdIsNull(
                                    PickupStatus.REQUESTED,
                                    PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "createdAt")))
                            .getContent();

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("count", open.size());
                    out.put("pickups", open.stream().map(UserTools::pickupRow).toList());
                    out.put("note", "Acceptance is first come first served. Once you accept, "
                            + "the citizen can no longer cancel.");
                    return out;
                });
    }

    private ChatTool myRoute() {
        return new ChatTool.Simple(
                "get_my_route",
                "The optimised collection route for the signed-in collector: depot, ordered "
                        + "stops, planned load against vehicle capacity, distance and drive time",
                COLLECTOR,
                schema.empty(),
                (ctx, args) -> {
                    try {
                        RouteResponse route = routeService.planFor(ctx.userId(), null);

                        Map<String, Object> out = new LinkedHashMap<>();
                        out.put("depot", route.depot().name());
                        out.put("totalStops", route.totalStops());
                        out.put("totalRequests", route.totalRequests());
                        out.put("plannedLoadKg", route.plannedLoadKg());
                        out.put("vehicleCapacityKg", route.vehicleCapacityKg());
                        out.put("distanceKm", route.distanceKm());
                        out.put("durationMinutes", route.durationMinutes());
                        out.put("deferredPickups", route.deferredPickupIds().size());
                        out.put("stops", route.stops().stream().map(s -> {
                            Map<String, Object> row = new LinkedHashMap<>();
                            row.put("sequence", s.sequence());
                            row.put("type", s.type());
                            row.put("address", s.address());
                            row.put("pickupCount", s.pickupCount());
                            row.put("weightKg", s.weightKg());
                            return row;
                        }).toList());
                        return out;

                    } catch (ApiException e) {
                        return Map.of("error", e.getMessage());
                    }
                });
    }

    private ChatTool browseListings() {
        return new ChatTool.Simple(
                "browse_marketplace_listings",
                "Open marketplace listings a recycler can buy, with price, weight and the "
                        + "implied rate per kg",
                RECYCLER,
                schema.object()
                        .string("material", "Optional material filter, for example 'PET Bottle'")
                        .integer("limit", "How many to return, 1 to 20")
                        .build(),
                (ctx, args) -> {
                    int limit = clamp(args.path("limit").asInt(5), 1, 20);
                    String material = args.path("material").asText("").trim();

                    List<Listing> open = listingRepository.findByStatus(ListingStatus.OPEN,
                                    PageRequest.of(0, 50, Sort.by(Sort.Direction.DESC, "createdAt")))
                            .getContent();

                    List<Map<String, Object>> rows = open.stream()
                            .filter(l -> material.isEmpty()
                                    || l.getMaterial().toLowerCase().contains(material.toLowerCase()))
                            .limit(limit)
                            .map(this::listingRow)
                            .toList();

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("count", rows.size());
                    out.put("listings", rows);
                    out.put("walletBalance", ctx.user().getWalletBalance());
                    return out;
                });
    }

    private ChatTool evaluateListing() {
        return new ChatTool.Simple(
                "evaluate_listing",
                "Assess whether a marketplace listing is priced well. Compares the asking rate "
                        + "per kg against the catalogue scrap rate for that material and against "
                        + "what the recycler can afford. Use this for 'is this a good deal' or "
                        + "'should I buy this' questions",
                RECYCLER,
                schema.object()
                        .string("listing_id", "The listing UUID. Omit to use the listing the "
                                + "user currently has open in the app")
                        .build(),
                (ctx, args) -> {
                    UUID id = resolveListingId(args.path("listing_id").asText(null), ctx.listingId());
                    if (id == null) {
                        return Map.of("error",
                                "No listing was specified and none is open in the app. "
                                        + "Ask which listing they mean.");
                    }

                    Listing listing = listingRepository.findById(id).orElse(null);
                    if (listing == null) {
                        return Map.of("error", "That listing does not exist");
                    }

                    Map<String, Object> out = new LinkedHashMap<>(listingRow(listing));

                    BigDecimal askPerKg = perKg(listing);
                    List<PriceCatalog.Entry> matches = priceCatalog.search(listing.getMaterial());

                    if (!matches.isEmpty() && askPerKg != null) {
                        PriceCatalog.Entry reference = matches.get(0);
                        BigDecimal market = BigDecimal.valueOf(reference.pricePerKg());
                        out.put("catalogueRatePerKg", market);

                        if (market.signum() > 0) {
                            BigDecimal ratio = askPerKg.divide(market, 3, RoundingMode.HALF_UP);
                            out.put("askVersusCatalogue", ratio);
                            out.put("verdict", verdict(ratio));
                            out.put("marginIfResoldAtCatalogue",
                                    market.subtract(askPerKg)
                                            .multiply(listing.getWeightKg())
                                            .setScale(2, RoundingMode.HALF_UP));
                        } else {
                            out.put("verdict", "no_market_rate");
                            out.put("note", reference.label()
                                    + " has no scrap value in the catalogue, so this is a "
                                    + "disposal cost rather than a resale opportunity.");
                        }
                        out.put("recyclable", reference.recyclable());
                    } else {
                        out.put("verdict", "unknown_material");
                    }

                    BigDecimal balance = ctx.user().getWalletBalance();
                    out.put("yourWalletBalance", balance);
                    out.put("affordable", balance.compareTo(listing.getPrice()) >= 0);
                    out.put("status", listing.getStatus().name());
                    out.put("guidance",
                            "Present the numbers and the trade-off. Do not promise a profit: "
                                    + "weights are estimated from the photo until the load is weighed.");
                    return out;
                });
    }

    private ChatTool myTrades() {
        return new ChatTool.Simple(
                "get_my_marketplace_activity",
                "Marketplace history for the signed-in user: what a citizen listed and sold, "
                        + "or what a recycler bought",
                TRADERS,
                schema.object().integer("limit", "How many to return, 1 to 20").build(),
                (ctx, args) -> {
                    int limit = clamp(args.path("limit").asInt(5), 1, 20);
                    var page = PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "createdAt"));

                    List<Listing> listings = ctx.role() == Role.RECYCLER
                            ? listingRepository.findByBuyerId(ctx.userId(), page).getContent()
                            : listingRepository.findBySellerId(ctx.userId(), page).getContent();

                    BigDecimal total = listings.stream()
                            .filter(l -> l.getStatus() == ListingStatus.SOLD)
                            .map(Listing::getPrice)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);

                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("perspective", ctx.role() == Role.RECYCLER ? "purchases" : "sales");
                    out.put("count", listings.size());
                    out.put("settledValue", total);
                    out.put("listings", listings.stream().map(this::listingRow).toList());
                    return out;
                });
    }

    private Map<String, Object> listingRow(Listing l) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", l.getId());
        row.put("material", l.getMaterial());
        row.put("weightKg", l.getWeightKg());
        row.put("price", l.getPrice());
        row.put("currency", l.getCurrency());
        row.put("askPerKg", perKg(l));
        row.put("description", l.getDescription());
        row.put("location", l.getLocation());
        row.put("status", l.getStatus().name());
        row.put("listedAt", l.getCreatedAt());
        row.put("soldAt", l.getSoldAt());
        return row;
    }

    private static BigDecimal perKg(Listing l) {
        if (l.getWeightKg() == null || l.getWeightKg().signum() <= 0) {
            return null;
        }
        return l.getPrice().divide(l.getWeightKg(), 2, RoundingMode.HALF_UP);
    }

    private static String verdict(BigDecimal ratio) {
        double r = ratio.doubleValue();
        if (r <= 0.7) {
            return "well_below_market";
        }
        if (r <= 0.95) {
            return "below_market";
        }
        if (r <= 1.1) {
            return "around_market";
        }
        if (r <= 1.4) {
            return "above_market";
        }
        return "well_above_market";
    }

    private static UUID resolveListingId(String fromArgs, UUID fromContext) {
        if (fromArgs != null && !fromArgs.isBlank()) {
            try {
                return UUID.fromString(fromArgs.trim());
            } catch (IllegalArgumentException e) {
                return fromContext;
            }
        }
        return fromContext;
    }
}
