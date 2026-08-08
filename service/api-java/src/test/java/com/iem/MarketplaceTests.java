package com.iem;

import com.iem.auth.AuthService;
import com.iem.auth.UserRepository;
import com.iem.auth.dto.RegisterRequest;
import com.iem.detection.DetectionRepository;
import com.iem.enums.ListingStatus;
import com.iem.enums.Role;
import com.iem.market.ListingRepository;
import com.iem.market.WalletTransactionRepository;
import com.iem.model.Detection;
import com.iem.model.DetectionMaterial;
import com.iem.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class MarketplaceTests {

    @Autowired private TestRestTemplate rest;
    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private DetectionRepository detectionRepository;
    @Autowired private ListingRepository listingRepository;
    @Autowired private WalletTransactionRepository transactionRepository;

    private User citizen;
    private User recycler;
    private String citizenToken;
    private String recyclerToken;

    @BeforeEach
    void setUp() {
        transactionRepository.deleteAll();
        listingRepository.deleteAll();
        detectionRepository.deleteAll();
        userRepository.deleteAll();
        citizen = register("seller", Role.CITIZEN);
        citizenToken = authService.buildResponse(citizen).accessToken();
        recycler = register("recycler", Role.RECYCLER);
        recyclerToken = authService.buildResponse(recycler).accessToken();
    }

    private User register(String prefix, Role role) {
        RegisterRequest r = new RegisterRequest();
        r.setEmail(prefix + "-" + UUID.randomUUID() + "@example.com");
        r.setFullName(prefix);
        r.setPassword("password123");
        r.setOtp("000000");
        r.setRole(role == Role.RECYCLER ? Role.RECYCLER : Role.CITIZEN);
        return authService.register(r);
    }

    private HttpHeaders auth(String token) {
        HttpHeaders h = new HttpHeaders();
        h.setBearerAuth(token);
        h.setContentType(MediaType.APPLICATION_JSON);
        return h;
    }

    private UUID detection() {
        Detection d = new Detection();
        d.setUserId(citizen.getId());
        d.setStatus("OK");
        d.setEligible(true);
        d.setTotalObjects(13);
        d.setCurrency("INR");
        d.setEstimatedWeightKg(new BigDecimal("15.000"));
        d.setImageUrl("https://cdn.example.com/waste.jpg");
        d.setAiSummary("13 PET Bottles detected.");
        DetectionMaterial m = new DetectionMaterial();
        m.setMaterial("PET Bottle");
        m.setCount(13);
        m.setRecyclable(true);
        d.addMaterial(m);
        return detectionRepository.save(d).getId();
    }

    private ResponseEntity<Map> createListing(Map<String, Object> body) {
        return rest.postForEntity("/api/v1/listings",
                new HttpEntity<>(body, auth(citizenToken)), Map.class);
    }

    private ResponseEntity<Map> manualListing() {
        return createListing(Map.of("material", "Plastic", "weightKg", 15.0, "price", 120.0,
                "description", "Clean PET bottles", "location", "Shibpur"));
    }

    @Test
    void marketplaceRequiresAuthentication() {
        assertEquals(HttpStatus.UNAUTHORIZED,
                rest.getForEntity("/api/v1/listings", String.class).getStatusCode());
        assertEquals(HttpStatus.UNAUTHORIZED,
                rest.getForEntity("/api/v1/wallet", String.class).getStatusCode());
    }

    @Test
    void citizenListsWasteManually() {
        ResponseEntity<Map> response = manualListing();

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        Map<?, ?> body = response.getBody();
        assertEquals("OPEN", body.get("status"));
        assertEquals("Plastic", body.get("material"));
        assertEquals(120.0, ((Number) body.get("price")).doubleValue());
        assertEquals(8.0, ((Number) body.get("pricePerKg")).doubleValue(), 0.01);
        assertEquals(true, body.get("mine"));
        assertNotNull(body.get("imageUrl"), "a fallback image is filled in");
    }

    @Test
    void listingFromAScanInheritsImageAndWeight() {
        ResponseEntity<Map> response = createListing(
                Map.of("detectionId", detection().toString(), "price", 200.0));

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        Map<?, ?> body = response.getBody();
        assertEquals("https://cdn.example.com/waste.jpg", body.get("imageUrl"));
        assertEquals(15.0, ((Number) body.get("weightKg")).doubleValue());
        assertEquals("PET Bottle x13", body.get("material"));
        assertEquals("13 PET Bottles detected.", body.get("description"));
    }

    @Test
    void cannotListTheSameScanTwice() {
        UUID d = detection();
        createListing(Map.of("detectionId", d.toString(), "price", 200.0));
        assertEquals(HttpStatus.CONFLICT,
                createListing(Map.of("detectionId", d.toString(), "price", 200.0)).getStatusCode());
    }

    @Test
    void manualListingNeedsMaterialAndWeight() {
        assertEquals(HttpStatus.BAD_REQUEST, createListing(Map.of("price", 120.0)).getStatusCode());
        assertEquals(HttpStatus.BAD_REQUEST,
                createListing(Map.of("material", "Plastic", "price", 120.0)).getStatusCode());
    }

    @Test
    void priceMustBePositive() {
        assertEquals(HttpStatus.BAD_REQUEST, createListing(
                Map.of("material", "Plastic", "weightKg", 5.0, "price", -50.0)).getStatusCode());
    }

    @Test
    void recyclerSeesOpenListingsInTheFeed() {
        manualListing();

        ResponseEntity<Map> feed = rest.exchange("/api/v1/listings", HttpMethod.GET,
                new HttpEntity<>(auth(recyclerToken)), Map.class);

        assertEquals(HttpStatus.OK, feed.getStatusCode());
        List<?> items = (List<?>) feed.getBody().get("items");
        assertEquals(1, items.size());
        assertEquals(false, ((Map<?, ?>) items.get(0)).get("mine"));
    }

    @Test
    void interestedTransfersMoneyBothWays() {
        String id = (String) manualListing().getBody().get("id");

        BigDecimal recyclerBefore = userRepository.findById(recycler.getId()).orElseThrow().getWalletBalance();

        ResponseEntity<Map> response = rest.exchange("/api/v1/listings/" + id + "/interested",
                HttpMethod.POST, new HttpEntity<>(Map.of(), auth(recyclerToken)), Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("SOLD", response.getBody().get("status"));
        assertNotNull(response.getBody().get("buyer"));

        BigDecimal sellerAfter = userRepository.findById(citizen.getId()).orElseThrow().getWalletBalance();
        BigDecimal recyclerAfter = userRepository.findById(recycler.getId()).orElseThrow().getWalletBalance();

        assertEquals(0, new BigDecimal("120.00").compareTo(sellerAfter), "seller credited");
        assertEquals(0, recyclerBefore.subtract(new BigDecimal("120.00")).compareTo(recyclerAfter),
                "recycler debited");
    }

    @Test
    void recyclerStartsWithADummyFloat() {
        assertEquals(0, new BigDecimal("10000.00")
                .compareTo(userRepository.findById(recycler.getId()).orElseThrow().getWalletBalance()));
        assertEquals(0, BigDecimal.ZERO
                .compareTo(userRepository.findById(citizen.getId()).orElseThrow().getWalletBalance()));
    }

    @Test
    void bothSidesGetATransactionRecord() {
        String id = (String) manualListing().getBody().get("id");
        rest.exchange("/api/v1/listings/" + id + "/interested", HttpMethod.POST,
                new HttpEntity<>(Map.of(), auth(recyclerToken)), Map.class);

        ResponseEntity<Map> sellerWallet = rest.exchange("/api/v1/wallet", HttpMethod.GET,
                new HttpEntity<>(auth(citizenToken)), Map.class);
        Map<?, ?> sellerTx = (Map<?, ?>) ((List<?>) sellerWallet.getBody().get("transactions")).get(0);
        assertEquals("CREDIT", sellerTx.get("type"));
        assertEquals("LISTING_SOLD", sellerTx.get("reason"));
        assertEquals(120.0, ((Number) sellerWallet.getBody().get("balance")).doubleValue());
        assertEquals(120.0, ((Number) sellerWallet.getBody().get("totalEarned")).doubleValue());

        ResponseEntity<Map> buyerWallet = rest.exchange("/api/v1/wallet", HttpMethod.GET,
                new HttpEntity<>(auth(recyclerToken)), Map.class);
        Map<?, ?> buyerTx = (Map<?, ?>) ((List<?>) buyerWallet.getBody().get("transactions")).get(0);
        assertEquals("DEBIT", buyerTx.get("type"));
        assertEquals("LISTING_PURCHASED", buyerTx.get("reason"));
        assertEquals(9880.0, ((Number) buyerWallet.getBody().get("balance")).doubleValue());
        assertEquals(120.0, ((Number) buyerWallet.getBody().get("totalSpent")).doubleValue());
    }

    @Test
    void soldListingLeavesTheFeed() {
        String id = (String) manualListing().getBody().get("id");
        rest.exchange("/api/v1/listings/" + id + "/interested", HttpMethod.POST,
                new HttpEntity<>(Map.of(), auth(recyclerToken)), Map.class);

        ResponseEntity<Map> feed = rest.exchange("/api/v1/listings", HttpMethod.GET,
                new HttpEntity<>(auth(recyclerToken)), Map.class);
        assertEquals(0, ((List<?>) feed.getBody().get("items")).size());
    }

    @Test
    void citizenCannotExpressInterest() {
        String id = (String) manualListing().getBody().get("id");
        assertEquals(HttpStatus.FORBIDDEN, rest.exchange("/api/v1/listings/" + id + "/interested",
                HttpMethod.POST, new HttpEntity<>(Map.of(), auth(citizenToken)), Map.class)
                .getStatusCode());
    }

    @Test
    void sellerCannotBuyTheirOwnListing() {
        User sellerRecycler = register("selfdealer", Role.RECYCLER);
        String token = authService.buildResponse(sellerRecycler).accessToken();

        String id = (String) rest.postForEntity("/api/v1/listings",
                new HttpEntity<>(Map.of("material", "Plastic", "weightKg", 5.0, "price", 50.0),
                        auth(token)), Map.class).getBody().get("id");

        assertEquals(HttpStatus.FORBIDDEN, rest.exchange("/api/v1/listings/" + id + "/interested",
                HttpMethod.POST, new HttpEntity<>(Map.of(), auth(token)), Map.class).getStatusCode());
    }

    @Test
    void sellerCanWithdrawAnUnsoldListing() {
        String id = (String) manualListing().getBody().get("id");

        ResponseEntity<Map> response = rest.exchange("/api/v1/listings/" + id + "/cancel",
                HttpMethod.POST, new HttpEntity<>(Map.of(), auth(citizenToken)), Map.class);

        assertEquals("CANCELLED", response.getBody().get("status"));
        assertEquals(HttpStatus.CONFLICT, rest.exchange("/api/v1/listings/" + id + "/interested",
                HttpMethod.POST, new HttpEntity<>(Map.of(), auth(recyclerToken)), Map.class)
                .getStatusCode());
    }

    @Test
    void cannotWithdrawAfterSale() {
        String id = (String) manualListing().getBody().get("id");
        rest.exchange("/api/v1/listings/" + id + "/interested", HttpMethod.POST,
                new HttpEntity<>(Map.of(), auth(recyclerToken)), Map.class);

        assertEquals(HttpStatus.CONFLICT, rest.exchange("/api/v1/listings/" + id + "/cancel",
                HttpMethod.POST, new HttpEntity<>(Map.of(), auth(citizenToken)), Map.class)
                .getStatusCode());
    }

    @Test
    void concurrentInterestGivesExactlyOneBuyer() throws Exception {
        String id = (String) manualListing().getBody().get("id");

        int contenders = 5;
        List<String> tokens = new ArrayList<>();
        for (int i = 0; i < contenders; i++) {
            tokens.add(authService.buildResponse(register("racer" + i, Role.RECYCLER)).accessToken());
        }

        CountDownLatch start = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(contenders);
        List<Future<HttpStatusCode>> results = new ArrayList<>();

        for (String token : tokens) {
            results.add(pool.submit(() -> {
                start.await();
                return rest.exchange("/api/v1/listings/" + id + "/interested", HttpMethod.POST,
                        new HttpEntity<>(Map.of(), auth(token)), Map.class).getStatusCode();
            }));
        }
        start.countDown();

        int ok = 0;
        int conflict = 0;
        for (Future<HttpStatusCode> r : results) {
            HttpStatusCode code = r.get();
            if (code == HttpStatus.OK) ok++;
            else if (code == HttpStatus.CONFLICT) conflict++;
        }
        pool.shutdown();

        assertEquals(1, ok, "exactly one recycler wins");
        assertEquals(contenders - 1, conflict);
        assertEquals(ListingStatus.SOLD, listingRepository.findById(UUID.fromString(id))
                .orElseThrow().getStatus());
        assertEquals(1, transactionRepository.findAll().stream()
                .filter(t -> "LISTING_PURCHASED".equals(t.getReason())).count(),
                "only one debit is recorded");
    }

    @Test
    void mineIsScopedByRole() {
        String id = (String) manualListing().getBody().get("id");
        rest.exchange("/api/v1/listings/" + id + "/interested", HttpMethod.POST,
                new HttpEntity<>(Map.of(), auth(recyclerToken)), Map.class);

        ResponseEntity<Map> sellerView = rest.exchange("/api/v1/listings/mine", HttpMethod.GET,
                new HttpEntity<>(auth(citizenToken)), Map.class);
        assertEquals(1, ((List<?>) sellerView.getBody().get("items")).size());

        ResponseEntity<Map> buyerView = rest.exchange("/api/v1/listings/mine", HttpMethod.GET,
                new HttpEntity<>(auth(recyclerToken)), Map.class);
        assertEquals(1, ((List<?>) buyerView.getBody().get("items")).size());
    }

    @Test
    void walletShowsGreenPointsAlongsideMoney() {
        ResponseEntity<Map> wallet = rest.exchange("/api/v1/wallet", HttpMethod.GET,
                new HttpEntity<>(auth(citizenToken)), Map.class);
        assertEquals(HttpStatus.OK, wallet.getStatusCode());
        assertEquals("INR", wallet.getBody().get("currency"));
        assertNotNull(wallet.getBody().get("greenPoints"));
        assertEquals(0, ((List<?>) wallet.getBody().get("transactions")).size());
    }
}
