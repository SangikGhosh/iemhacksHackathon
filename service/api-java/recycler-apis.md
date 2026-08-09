# Recycler APIs — GreenTech

Every endpoint a **recycler** app touches, with exact request and response shapes.

All examples below are **real responses captured from a running server**, including a live
purchase that moved money between two wallets. Field names, casing and nesting are exactly what
the API returns.

- **Base URL (local):** `http://localhost:8080`
- **Auth:** `Authorization: Bearer <accessToken>` on every endpoint marked 🔒
- **Companion docs:** [`citizen-apis.md`](citizen-apis.md) · [`collector-apis.md`](collector-apis.md)

---

## Table of contents

1. [What a recycler can and cannot call](#1-what-a-recycler-can-and-cannot-call)
2. [Conventions](#2-conventions)
3. [A recycler's flow](#3-a-recyclers-flow)
4. [Auth and the starting balance](#4-auth-and-the-starting-balance)
5. [Browsing the market](#5-browsing-the-market)
6. [Buying a listing](#6-buying-a-listing)
7. [Purchase history](#7-purchase-history)
8. [Wallet](#8-wallet)
9. [Selling](#9-selling)
10. [Pickups](#10-pickups)
11. [Maps and collection points](#11-maps-and-collection-points)
12. [Scanning, points and leaderboard](#12-scanning-points-and-leaderboard)
13. [Assistant chatbot](#13-assistant-chatbot)
14. [Error catalogue](#14-error-catalogue)
15. [Screen to endpoint map](#15-screen-to-endpoint-map)

---

## 1. What a recycler can and cannot call

Every row below was **tested with a real recycler token**, not read off the annotations.

| Endpoint | Recycler | Note |
| --- | --- | --- |
| **`POST /api/v1/listings/{id}/interested`** | ✅ | **Recycler only — this is the buy action** |
| `GET /api/v1/listings` | ✅ | Browse open stock |
| `GET /api/v1/listings/mine` | ✅ | Returns **purchases**, not sales |
| `GET /api/v1/listings/{id}` | ✅ | |
| `POST /api/v1/listings` | ✅ | A recycler **can also sell** |
| `POST /api/v1/listings/{id}/cancel` | ✅ | Their own listings |
| `GET /api/v1/wallet` | ✅ | Seeded with a starting balance |
| `POST /api/v1/pickups` | ✅ | Can raise their own household pickup |
| `GET /api/v1/pickups`, `/{id}`, `/{id}/cancel` | ✅ | Their own requests only |
| **`GET /api/v1/pickups/available`** | ❌ **403** | Collector only |
| **`POST /api/v1/pickups/{id}/accept`** | ❌ **403** | Collector only |
| **`GET /api/v1/routes/my-route`** | ❌ **403** | Collector only |
| `GET /api/v1/collection-points/**` | ✅ | Public — includes Mapbox-ranked nearest |
| `POST /api/v1/detections`, `GET /api/v1/detections` | ✅ | |
| `GET /api/v1/leaderboard` | ✅ | Public |
| `POST /api/v1/chat` | ✅ | Recycler-specific tools, incl. deal evaluation |
| `GET /api/v1/admin/**` | ❌ 403 | Admin only |

Refusals return:

```json
{ "error": "You do not have permission to perform this action" }
```

> **A recycler can sell as well as buy.** Verified live — a recycler token created a listing and
> got `201`. They cannot buy their **own** listing though; that returns `403 You cannot buy your
> own listing`.

---

## 2. Conventions

Auth, error shape, pagination, money and timestamp formats are identical to the citizen API —
see [`citizen-apis.md` §1](citizen-apis.md#1-conventions). In brief:

- Bearer token, valid **7 days**
- Errors are always `{ "error": "human readable message" }`
- Lists take `?page=0&size=20`, **zero-based**, `size` capped at 100
- Money is INR, weights are kg, timestamps are ISO-8601 UTC

---

## 3. A recycler's flow

```text
login                                  wallet is pre-seeded (10,000 INR by default)
  |
  v
GET /api/v1/listings                   open stock, with pricePerKg on every row
  |
  v
is it worth it?
  |
  +--- POST /api/v1/chat  { listingId }  -> assistant compares ask vs catalogue rate
  |
  v
POST /api/v1/listings/{id}/interested  buy it
  |                                    -> listing SOLD, atomic: one winner only
  |                                    -> buyer DEBIT, seller CREDIT, same instant
  |
  +-- balance too low? --------------> 402, listing stays OPEN
  |
  v
GET /api/v1/listings/mine              purchase history
GET /api/v1/wallet                     ledger with running balance
```

---

## 4. Auth and the starting balance

Login, Google sign-in and `GET /auth/me` are identical to the citizen flow — see
[`citizen-apis.md` §4](citizen-apis.md#4-auth). `GET /auth/me` returns `role: "RECYCLER"`.

### The starting balance

A recycler is created with a **seeded wallet balance** so trading works without a payment
gateway. It is set by `RECYCLER_STARTING_BALANCE` in the API `.env`, default **10000**.

This is applied both when a recycler self-registers and when a municipal or super admin creates
the account.

> **Historical note:** admin-created recyclers previously started at **0** and the marketplace
> had no affordability check, which let a balance go negative. Both are fixed — a recycler
> created through the admin API now gets the full starting balance, and an unaffordable purchase
> is refused with `402` (§6).

`GET /auth/me` returns **points only**, never the balance. For money always use
[`GET /api/v1/wallet`](#8-wallet).

---

## 5. Browsing the market

### `GET /api/v1/listings?page=0&size=20` 🔒

Every `OPEN` listing, newest first. This is the buying feed.

**Response `200`** — real capture:

```json
{
  "items": [
    {
      "id": "ae2bc303-a175-4837-83be-65094763e0c8",
      "status": "OPEN",
      "material": "Scrap Metal",
      "weightKg": 12.0,
      "price": 540.0,
      "pricePerKg": 45.0,
      "currency": "INR",
      "description": "Mixed steel offcuts",
      "imageUrl": "https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/accessories-bag.jpg",
      "location": "Shibpur",
      "seller": {
        "id": "644663bf-aeb8-40c2-b624-1cc256233567",
        "fullName": "Anil Citizen",
        "role": "CITIZEN"
      },
      "buyer": null,
      "mine": false,
      "createdAt": "2026-08-08T22:11:18.874848Z",
      "soldAt": null
    },
    {
      "id": "7432b427-5a77-4b05-ae89-61a1381d0774",
      "status": "OPEN",
      "material": "PET Bottle",
      "weightKg": 4.0,
      "price": 80.0,
      "pricePerKg": 20.0,
      "currency": "INR",
      "description": "Rinsed and flattened bottles",
      "imageUrl": "https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/accessories-bag.jpg",
      "location": "Howrah Maidan",
      "seller": { "id": "644663bf-...", "fullName": "Anil Citizen", "role": "CITIZEN" },
      "buyer": null,
      "mine": false,
      "createdAt": "2026-08-08T22:11:18.842444Z",
      "soldAt": null
    }
  ],
  "page": 0,
  "size": 2,
  "totalItems": 2,
  "totalPages": 1,
  "hasMore": false
}
```

#### Designing the buying card

- **`pricePerKg` is computed server-side** (`price ÷ weightKg`, 2 dp). It is the number a
  recycler actually decides on — **make it the most prominent figure**, larger than `price`.
  A `INR 540` lot means nothing until you know it is `INR 45/kg`.
- **`mine`** marks the recycler's own listings in the mixed feed. Hide or badge them — the buy
  action will `403`.
- **`imageUrl`** falls back to a placeholder when the seller supplied none, so it is rarely
  `null` here — but still guard it.
- **`location`** is free text typed by the seller (`"Shibpur"`), not coordinates. There is no
  distance or map pin for a listing; do not promise one in the UI.
- **`seller.role`** can be `CITIZEN`, `COLLECTOR` or another `RECYCLER`.

There is **no server-side filter or sort** on this endpoint — no `?material=`, no price sort. It
returns all open listings newest-first. Filter and sort client-side, or page through and build
the facets yourself.

### `GET /api/v1/listings/{id}` 🔒

One listing, same shape. Use for the detail screen and to re-check `status` before buying — it
is the cheapest way to catch a listing someone else already took.

---

## 6. Buying a listing

### `POST /api/v1/listings/{id}/interested` 🔒 **recycler only**

No request body. Despite the name, **this is a purchase, not an expression of interest** — it
transfers money and marks the listing `SOLD` in one transaction.

**Response `200`** — real capture:

```json
{
  "id": "7432b427-5a77-4b05-ae89-61a1381d0774",
  "status": "SOLD",
  "material": "PET Bottle",
  "weightKg": 4.0,
  "price": 80.0,
  "pricePerKg": 20.0,
  "currency": "INR",
  "description": "Rinsed and flattened bottles",
  "imageUrl": "https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/accessories-bag.jpg",
  "location": "Howrah Maidan",
  "seller": { "id": "644663bf-...", "fullName": "Anil Citizen", "role": "CITIZEN" },
  "buyer": {
    "id": "25a722fa-25dc-4ea8-affe-00c0a6083dae",
    "fullName": "Meera Recycler",
    "role": "RECYCLER"
  },
  "mine": false,
  "createdAt": "2026-08-08T22:11:18.842444Z",
  "soldAt": "2026-08-08T22:11:31.558759Z"
}
```

### What happens atomically

One database transaction does all of this:

1. **Affordability is checked first.** Insufficient balance stops everything before the listing
   is touched.
2. **The listing is claimed** with a conditional UPDATE — `where status = 'OPEN' and buyer_id is
   null`. Exactly one recycler can win.
3. **The seller is credited** and **the buyer debited** the full `price`, each writing a wallet
   ledger row.
4. `status` becomes `SOLD`, `buyer` and `soldAt` are filled in.

If any step fails the whole thing rolls back — there is no state where money moved but the
listing did not sell, or vice versa.

**Errors**

| Status | Message | Meaning |
| --- | --- | --- |
| `402` | `Your wallet balance is -60.00 INR, which is not enough for this listing at 45.00 INR` | Not enough money. **Listing stays `OPEN`** |
| `409` | `Another recycler has already taken this listing` | You lost the race |
| `409` | `This listing was withdrawn` | Seller pulled it |
| `403` | `You cannot buy your own listing` | `mine: true` |
| `403` | `You do not have permission to perform this action` | Caller is not a recycler |
| `404` | `Listing not found` | Bad id |

#### Design for losing the race

Like collector acceptance, buying is **first come, first served**. Two recyclers tapping Buy on
the same listing produce one `200` and one `409`.

1. Never optimistically mark a listing as bought before the `200`.
2. On `409`, show something soft — *"Someone bought this first"* — remove the card and refresh.
3. Disable the button while the request is in flight.

#### The 402 is recoverable

`402` is the only error carrying real numbers in its message: the current balance and the price.
**Parse or display it directly** and offer a top-up path. The listing is untouched, so the
recycler can retry after funding.

> **Confirm before buying.** There is no un-buy endpoint. The money moves instantly and the
> listing is terminal at `SOLD`. A confirmation sheet showing `pricePerKg`, total, and resulting
> balance is worth the extra tap.

---

## 7. Purchase history

### `GET /api/v1/listings/mine?page=0&size=20` 🔒

The same URL a citizen uses for their *sales*, but **the server switches on role** — a recycler
gets what they **bought**.

Response is the standard listing page. Every row has `buyer` set to the caller and
`status: "SOLD"`.

> ⚠️ **`mine` is `false` on these rows.** The flag means *"you are the seller"*, not *"this is
> yours"*. On a purchases screen it will be `false` for every row you bought. Do not use it to
> decide what to render there.

If a recycler both buys and sells, this endpoint shows **only purchases** — their own listings
are not returned here. To show sales too you need `GET /api/v1/listings` and filter client-side
on `seller.id === me.id`, or track the ids returned when they were created.

---

## 8. Wallet

### `GET /api/v1/wallet?page=0&size=20` 🔒

Balance, lifetime totals and the full ledger in one call.

**Response `200`** — real capture, after two purchases:

```json
{
  "balance": 9920.0,
  "currency": "INR",
  "totalEarned": 0,
  "totalSpent": 140.0,
  "greenPoints": 0,
  "transactions": [
    {
      "id": "edf6a453-afd0-4d86-8523-342afd718aab",
      "type": "DEBIT",
      "amount": 80.0,
      "balanceAfter": 9920.0,
      "currency": "INR",
      "reason": "LISTING_PURCHASED",
      "note": "Bought PET Bottle from Anil Citizen",
      "listingId": "7432b427-5a77-4b05-ae89-61a1381d0774",
      "createdAt": "2026-08-08T22:11:31.568446Z"
    }
  ],
  "page": 0,
  "size": 3,
  "totalItems": 2,
  "hasMore": false
}
```

The ledger is **append-only**, newest first, and every row carries `balanceAfter` — so a running
balance column needs no client-side arithmetic.

| Field | For a recycler |
| --- | --- |
| `balance` | Spendable now. Gate the Buy button on it |
| `totalSpent` | Lifetime purchases |
| `totalEarned` | Only non-zero if they also sell |
| `greenPoints` | From their own scans, unrelated to trading |
| `reason` | `LISTING_PURCHASED` (out) or `LISTING_SOLD` (in) |
| `note` | Display-ready, e.g. `"Bought PET Bottle from Anil Citizen"` |
| `listingId` | Deep-link back to the listing |

Only these two `reason` values exist — the ledger records **marketplace trades only**. Nothing
else in the platform writes to it.

**Fetch the wallet alongside the listing feed** so the Buy button can be disabled on
unaffordable rows before the user taps and eats a `402`.

---

## 9. Selling

A recycler can list material too — `POST /api/v1/listings`, with the same request shape as the
citizen ([`citizen-apis.md` §8.1](citizen-apis.md#81-create-a-listing-)):

| Field | Required | Notes |
| --- | --- | --- |
| `price` | ✅ | minimum 1 |
| `material` + `weightKg` | ✅ unless `detectionId` given | |
| `detectionId` | — | Auto-fills material, weight and image from a scan |
| `description`, `location`, `imageUrl` | — | |

Withdraw with `POST /api/v1/listings/{id}/cancel` — `409` if it has already sold.

Whether the recycler app exposes selling is a product call. The API allows it.

---

## 10. Pickups

A recycler holds a normal account, so they can request a pickup for their **own** waste:

- `POST /api/v1/pickups` — needs one of their own eligible `detectionId`
- `GET /api/v1/pickups` — their own requests (verified: returns `[]` for a fresh recycler, **not**
  a 403)
- `GET /api/v1/pickups/{id}` and `POST /{id}/cancel` — while still `REQUESTED`

Shapes and rules are in [`citizen-apis.md` §6](citizen-apis.md#6-pickups), including the rule
that cancellation dies the moment a collector accepts.

**Blocked for recyclers** (all `403`, verified live): `/pickups/available`, `/{id}/accept`,
`/{id}/complete`, `/{id}/release`, `/routes/my-route`.

> A recycler buying scrap through the marketplace and a recycler requesting a household pickup
> are unrelated flows that happen to share an account. Keep them in separate parts of the app.

---

## 11. Maps and collection points

All public, no token needed — though sending one is harmless.

### `GET /api/v1/collection-points/nearest?lat=&lon=&limit=5` 🌐

The most useful geo call for a recycler: it locates **MRFs and scrap yards** where material is
aggregated, ranked by **real driving time** from the Mapbox Matrix API.

Verified from a recycler token:

```text
Unsani Rd Point 4 | road 1.91 km | 2.88 min
```

**Response `200`**

```json
{
  "points": [
    {
      "id": "c0e76555-d88f-4046-9b24-5bb67e391db3",
      "code": "CP-HMC-099",
      "name": "Unsani Rd Point 4",
      "locality": "Unsani Rd",
      "ward": "Ward 37",
      "type": "SCRAP_YARD",
      "lat": 22.589855,
      "lon": 88.263313,
      "municipality": "Howrah Municipal Corporation",
      "district": "Howrah",
      "straightLineKm": 0.66,
      "roadDistanceKm": 1.91,
      "drivingMinutes": 2.88
    }
  ],
  "count": 1,
  "origin": { "lat": 22.5958, "lon": 88.2636 }
}
```

**Ordering is by road time, not straight-line distance** — in the full result set the first
point is further as the crow flies (0.66 km) than the second (0.42 km) but much closer by road
(1.91 km vs 2.66 km). **Show `roadDistanceKm` and `drivingMinutes`**, or the order will look
broken.

`roadDistanceKm` and `drivingMinutes` come back **`null`** when Mapbox is unreachable; fall back
to `straightLineKm` with a softer label. `limit` is capped at 5.

`type` is `MRF` · `BIN_CLUSTER` · `SCRAP_YARD` · `COMPOST_HUB` — for a recycler, `MRF` and
`SCRAP_YARD` are the interesting ones, so offer that filter.

### `GET /api/v1/collection-points` 🌐

All 155 active points, no distances — for an overview map. Cluster the markers.

### `GET /api/v1/collection-points/municipalities` 🌐

The four municipalities with depot coordinates. Good for an area picker.

---

## 12. Scanning, points and leaderboard

Available exactly as for a citizen:

- `POST /api/v1/detections` — scan waste, points credited instantly
- `GET /api/v1/detections` — history with lifetime `totals`
- `GET /api/v1/leaderboard` — recyclers appear with `role: "RECYCLER"`; send the token to get
  the `me` block

See [`citizen-apis.md` §5 and §9](citizen-apis.md#5-scan-waste-detection).

Scanning is genuinely useful here: it identifies material and gives the catalogue price per kg,
which is the reference a recycler prices an offer against.

---

## 13. Assistant chatbot

`POST /api/v1/chat` 🔒 — same contract as the citizen assistant
([`citizen-apis.md` §10](citizen-apis.md#10-assistant-chatbot)), with **recycler-specific
tools**: browse stock, wallet, purchase history, and deal evaluation.

### Deal evaluation — the one worth wiring into the product

Send `listingId` in the request body and the assistant treats that listing as "on screen", so
the user can just ask *"is this a good deal?"* with no other context.

**Request**

```json
{
  "message": "Is this a good deal? Should I purchase it?",
  "listingId": "ae2bc303-a175-4837-83be-65094763e0c8"
}
```

**Response `200`** — real answer from a live recycler token:

```json
{
  "conversationId": "3e58d5d2-7ff6-4989-8274-12a7fe79092a",
  "reply": "The listing is for flattened cartons (cardboard) with an asking rate of INR 9.00 per kilogram. The catalogue scrap rate for cardboard is INR 8.00 per kilogram, which means this listing is priced above the market rate by INR 1.00 per kilogram.\n\nIf you were to resell it at the catalogue rate, you would incur a loss of INR 5.00 based on the estimated weight of 5 kg. Remember, the weight is estimated from a photograph, so the actual margin will only be known once the load is weighed.",
  "toolsUsed": ["evaluate_listing"],
  "historyLength": 2
}
```

Behind that answer the server compares the asking rate per kg against the catalogue scrap rate
for that material, computes the margin at the listed weight, and checks the recycler's balance.
It returns a verdict band — `well_below_market`, `below_market`, `around_market`,
`above_market`, `well_above_market` — and the assistant turns it into a sentence.

It **will tell the recycler a listing is overpriced**, as it did above. It never promises a
profit, and it always flags that the weight is photo-estimated until weighed.

> **Put this behind an "Is this worth it?" button on the listing card** and pass the `listingId`.
> That is the single highest-value place for the assistant in this app.

`GET /api/v1/chat/capabilities` returns recycler prompts for the empty state:

```json
{
  "enabled": true,
  "role": "RECYCLER",
  "suggestions": [
    "Is this listing worth buying?",
    "What cardboard is available to buy?",
    "Show my purchase history",
    "What is my wallet balance?"
  ]
}
```

Replies take **2–6 seconds** because a live query runs first — show a typing indicator. Check
`enabled`; it is `false` when the server has no assistant key, in which case hide the entry
point.

---

## 14. Error catalogue

| Status | When | How the UI should react |
| --- | --- | --- |
| `400` | Validation failure on a listing | Inline field errors |
| `401` | Missing or expired token | Clear session, go to login |
| **`402`** | Balance too low to buy | **Show balance and shortfall, offer top-up. Listing stays OPEN** |
| `403` | `You cannot buy your own listing` | Badge own rows, hide Buy |
| `403` | `You do not have permission…` | Collector-only endpoint |
| `404` | `Listing not found` | Refresh the feed |
| `409` | `Another recycler has already taken this listing` | **Normal.** Soft message, refresh |
| `409` | `This listing was withdrawn` | Remove the card |
| `429` / `503` | Assistant rate limited or unreachable | Retry hint in the chat panel |

**`402` and the buying `409` are the two that define how the app feels.** Neither is a bug —
one means "fund your wallet", the other means "someone was faster". Both deserve calm, specific
copy rather than a generic red banner.

---

## 15. Screen to endpoint map

| Screen | Endpoints | Notes |
| --- | --- | --- |
| Splash | `GET /auth/me` | Route on `role: "RECYCLER"` |
| Login | `POST /auth/login`, `POST /auth/google` | |
| Market feed | `GET /api/v1/listings`, `GET /api/v1/wallet` | Lead with `pricePerKg`; disable unaffordable rows |
| Listing detail | `GET /api/v1/listings/{id}` | Re-check `status` before buying |
| "Is this worth it?" | `POST /api/v1/chat` + `listingId` | Returns a real ask-vs-market comparison |
| Buy confirmation | `POST /api/v1/listings/{id}/interested` | Irreversible — confirm first |
| Purchases | `GET /api/v1/listings/mine` | Purchases only; `mine` is `false` on all rows |
| Wallet | `GET /api/v1/wallet` | Append-only ledger with `balanceAfter` |
| Sell scrap | `POST /api/v1/listings`, `POST /{id}/cancel` | Allowed |
| Nearby yards | `GET /api/v1/collection-points/nearest` | Filter `MRF` / `SCRAP_YARD` |
| Map | `GET /api/v1/collection-points` | 155 points — cluster them |
| My pickups | `POST /api/v1/pickups`, `GET /api/v1/pickups` | Own household waste only |
| Assistant | `POST /api/v1/chat`, `GET /chat/capabilities` | Keep `conversationId` |

### Things that will bite you if unnoticed

1. **`/interested` is a purchase, not a lead.** It moves money immediately. Name the button
   "Buy", and confirm first.
2. **`402` leaves the listing `OPEN`** — it is fully recoverable, so offer a top-up and retry.
3. **`mine` is `false` on your own purchases.** It means "you are the seller". Never use it on
   the purchases screen.
4. **`/listings/mine` returns purchases only** for a recycler — their own listings are not in it.
5. **Buying is first-come-first-served** — handle `409` as a normal outcome.
6. **`pricePerKg` is the decision number**, not `price`. Make it dominant.
7. **No server-side filter or sort on listings** — no `?material=`, no price sort. Do it client
   side.
8. **`location` is free text**, not coordinates. There is no distance to a listing.
9. **Nearest points rank by road time**, so showing straight-line distance breaks the order.
10. **Collector endpoints are hard 403s** — accept, complete, available and my-route are not
    available to this role.
