# Marketplace & Purchase System — GreenTech

The circular-economy half of the platform: a citizen sells segregated waste, a recycler buys it,
and money moves between in-app wallets in one transaction.

> *"Connect recyclers/scrap dealers with households and businesses **directly**."*
> — IEMHACKS Track 04, `IEMH4-GT-01`

Every response below is a **real capture from a running server**. Field names, casing and
nesting are exactly what the API returns.

- **Base URL (local):** `http://localhost:8080`
- **Auth:** `Authorization: Bearer <accessToken>` on every endpoint here — none are public
- **Companion docs:** [`citizen-apis.md`](citizen-apis.md) · [`collector-apis.md`](collector-apis.md) · [`recycler-apis.md`](recycler-apis.md)

---

## Table of contents

1. [What changed in this release](#1-what-changed-in-this-release)
2. [The model, the three flows and worked examples](#2-the-model)
3. [Who can do what](#3-who-can-do-what)
4. [Listing lifecycle](#4-listing-lifecycle)
5. [Create a listing](#5-create-a-listing)
6. [Browse](#6-browse)
7. [One listing](#7-one-listing)
8. [Buy](#8-buy)
9. [My listings and purchases](#9-my-listings-and-purchases)
10. [Withdraw a listing](#10-withdraw-a-listing)
11. [Wallet](#11-wallet)
12. [Error catalogue](#12-error-catalogue)
13. [Building the screens](#13-building-the-screens)

---

## 1. What changed in this release

Three changes. **Two are new refusals, one is a new query capability.** No response shape
changed, so existing screens keep working.

### 1.1 Waste can no longer be sold twice (new `409`)

Previously a citizen could have a collector pick up their waste **and** sell the same scan on
the marketplace. Both paths paid out. That is now blocked in both directions:

| You try to… | …while the scan is | Result |
| --- | --- | --- |
| `POST /api/v1/listings` with a `detectionId` | attached to a live pickup | **409** `This scan is already going to a collector. Cancel the pickup first if you would rather sell it.` |
| `POST /api/v1/pickups` | listed `OPEN` or already `SOLD` | **409** `This scan is listed on the marketplace. Withdraw the listing first if you would rather a collector took it.` |

Both are **reversible**. Cancelling the pickup frees the scan to be sold; withdrawing the
listing frees it to be collected. Verified live in both directions.

A listing with **no `detectionId`** (free-form material + weight) is unaffected — there is no
scan to cross-check.

### 1.2 Browse now filters and sorts (new optional params)

`GET /api/v1/listings` accepts two optional query parameters. Omit both and behaviour is
byte-identical to before.

| Param | Values | Default |
| --- | --- | --- |
| `material` | any substring, case-insensitive | no filter |
| `sort` | `newest` · `oldest` · `price_asc` · `price_desc` · `weight_desc` | `newest` |

An unrecognised `sort` returns **400** rather than being silently ignored.

### 1.3 An unaffordable purchase is refused (new `402`)

A recycler whose balance is below the price gets **402** and the listing **stays `OPEN`**.
Previously the buy went through and drove the wallet negative.

---

## 2. The model

Two separate routes for waste. **A scan takes one or the other, never both.**

```text
                    ┌─────────────────────────────────────────┐
   citizen scans ──►│  route A: municipal collection          │
                    │  POST /api/v1/pickups                   │
                    │  collector comes, weighs, pays cash     │
                    │  citizen earns Green Points             │
                    └─────────────────────────────────────────┘
                    ┌─────────────────────────────────────────┐
                    │  route B: direct sale (this document)   │
                    │  POST /api/v1/listings                  │
                    │  recycler buys, wallet → wallet         │
                    │  no collector, no points                │
                    └─────────────────────────────────────────┘
```

Route B is the "connect households with recyclers **directly**" requirement — a household
reaches a recycler with no broker chain in between.

**Money and points are separate systems.** The wallet records *only* marketplace trades. A
pickup's `finalAmount` is settled in cash between collector and citizen and never enters the
ledger. Green Points come only from a completed pickup, never from a sale.

### The third flow: a collector selling what they aggregated

A collector who has completed pickups physically holds that waste. They can list it like any
other seller — and this is deliberate, because the brief names **waste-pickers** as target
beneficiaries. Routing alone does not pay them; selling what they gather does.

```text
   citizen ──(route A: pickup, cash + points)──► collector ──(route B: listing)──► recycler
```

This does **not** contradict "directly" — a household can always sell straight to a recycler.
The collector path is additive, and it is where the collection economics work: buy small
quantities from many households, aggregate, sell one bigger lot at a better rate.

A collector must list **free-form** (`material` + `weightKg` + `price`, no `detectionId`),
because:

- `create()` rejects a `detectionId` that is not the caller's own scan — the scan belongs to the
  citizen, and
- the cross-path guard (§1.1) blocks any scan that already has a pickup.

That is the correct shape anyway: they are selling one aggregated lot, not one household's
photograph.

---

### Worked example A — citizen sells direct to a recycler

Real capture, end to end:

```text
1. citizen   POST /api/v1/listings
             {"material":"Scrap Metal","weightKg":15.0,"price":675.00,
              "description":"Mixed steel offcuts","location":"Salkia"}
             → 201  status OPEN, pricePerKg 45.0

2. recycler  GET  /api/v1/listings?material=Scrap
             → 1 item, seller.role CITIZEN, buyer null, mine false

3. collector POST /api/v1/listings/{id}/interested        (wrong role)
             → 403  "You do not have permission to perform this action"

   citizen   POST /api/v1/listings/{id}/interested        (own listing)
             → 403

4. recycler  POST /api/v1/listings/{id}/interested
             → 200  SOLD | Anil Citizen → Meera Recycler

             seller wallet   185.00 →  860.00   (+675)
             buyer  wallet  9902.00 → 9227.00   (−675)

5. recycler  POST /api/v1/listings/{id}/interested        (again)
             → 409  "Another recycler has already taken this listing"

6. recycler  GET  /api/v1/listings?material=Scrap
             → 0 items — sold stock leaves the feed
```

### Worked example B — collector aggregates a route, then sells

Real capture, end to end:

```text
0. collector has 7 completed pickups = 13.58 kg of PET in hand,
   paid out to each household in cash at completion

1. collector POST /api/v1/listings                        (free-form, NO detectionId)
             {"material":"PET Bottle","weightKg":13.580,"price":340.00,
              "description":"Aggregated route collection, sorted and baled",
              "location":"HMC Depot"}
             → 201  seller.role COLLECTOR, pricePerKg 25.04

2. recycler  GET  /api/v1/listings?material=PET&sort=weight_desc
             → COLLECTOR  PET Bottle  13.58 kg  INR 340.00 = 25.04/kg

3. recycler  POST /api/v1/listings/{id}/interested
             → 200  SOLD | Ravi Collector (COLLECTOR) → Meera Recycler (RECYCLER)

             collector wallet    23.00 →  363.00   (+340)
             recycler  wallet  9150.00 → 8810.00   (−340)
```

The recycler's buying flow is **identical** in both examples — same endpoint, same response
shape. The only difference visible to them is `seller.role`.

### Worked example C — the same waste cannot go both ways

Real capture of the guards from §1.1:

```text
1. citizen   POST /api/v1/detections            → scan a4cd4f44…
2. citizen   POST /api/v1/pickups {detectionId} → 201, pickup created
3. citizen   POST /api/v1/listings {detectionId}
             → 409  "This scan is already going to a collector.
                     Cancel the pickup first if you would rather sell it."

4. citizen   POST /api/v1/pickups/{id}/cancel   → CANCELLED
5. citizen   POST /api/v1/listings {detectionId} → 201  ✔ freed

6. citizen   POST /api/v1/pickups {detectionId}
             → 409  "This scan is listed on the marketplace.
                     Withdraw the listing first if you would rather a collector took it."

7. citizen   POST /api/v1/listings/{id}/cancel  → CANCELLED
8. citizen   POST /api/v1/pickups {detectionId} → 201  ✔ freed
```

Committed in one direction, blocked in the other, and always reversible.

---

## 3. Who can do what

Verified with real tokens for each role, not read off annotations.

| Action | Citizen | Collector | Recycler |
| --- | --- | --- | --- |
| Create a listing | ✅ | ✅ | ✅ |
| Browse / view | ✅ | ✅ | ✅ |
| Withdraw own listing | ✅ | ✅ | ✅ |
| **Buy** (`/interested`) | ❌ 403 | ❌ 403 | ✅ **only role that can** |
| Wallet | ✅ | ✅ | ✅ |

Anyone can sell — citizen, collector or recycler. **Only a recycler can buy.** A recycler cannot
buy their **own** listing (403).

A collector selling is a first-class case, not a loophole: verified live, a collector token
created a listing (`201`, `seller.role: "COLLECTOR"`) and a recycler bought it (`200`). See
[worked example B](#the-third-flow-a-collector-selling-what-they-aggregated).

> A citizen or collector calling `/interested` gets `You do not have permission to perform this
> action` — the role check fires first. A *recycler* buying their own listing gets the more
> specific `You cannot buy your own listing`.

---

## 4. Listing lifecycle

```text
        POST /listings
              │
              ▼
           ┌──────┐   POST /listings/{id}/interested   ┌──────┐
           │ OPEN │ ─────────────────────────────────► │ SOLD │  terminal
           └──────┘   (recycler, atomic, pays now)     └──────┘
              │
              │ POST /listings/{id}/cancel  (seller)
              ▼
        ┌───────────┐
        │ CANCELLED │  terminal — frees the scan for collection
        └───────────┘
```

`SOLD` and `CANCELLED` are both terminal. There is no un-buy and no re-open.

---

## 5. Create a listing

`POST /api/v1/listings` 🔒 — any signed-in role

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `price` | number | ✅ | **minimum 1**, total for the lot |
| `detectionId` | UUID | — | Auto-fills material, weight, image and description from the scan |
| `material` | string | ✅ **if no** `detectionId` | max 80 |
| `weightKg` | number | ✅ **if no** `detectionId` | must be > 0 |
| `description` | string | — | max 400 |
| `location` | string | — | max 160, free text — **not** coordinates |
| `imageUrl` | string | — | max 500; falls back to a placeholder |

**From a scan** — preferred, since material and weight come from the detection:

```json
{
  "detectionId": "a4cd4f44-f618-48aa-bda0-22e19e49471b",
  "price": 150.00,
  "description": "clean PET",
  "location": "Howrah Maidan"
}
```

**Free-form:**

```json
{
  "material": "Cardboard",
  "weightKg": 8.0,
  "price": 72.00,
  "description": "Flattened cartons",
  "location": "Salkia"
}
```

**Response `201`** — the listing object (see §6 for the full shape).

**Errors**

| Status | Message |
| --- | --- |
| `400` | `material is required when no scan is attached` |
| `400` | `weightKg is required when no scan is attached` / `weightKg must be greater than zero` |
| `400` | `This scan has no waste to sell` (scan came back `eligible: false`) |
| `404` | `Scan not found` — wrong id, or not the caller's scan |
| `409` | `This scan is already listed` |
| `409` | **new** `This scan is already going to a collector. Cancel the pickup first…` |

> **Set `price` from `pricePerKg`, not the other way round.** Sellers think in "₹9 a kilo";
> the API stores a total. Let the user enter a rate, multiply by `weightKg`, and send the
> product. The response echoes `pricePerKg` so you can confirm it back to them.

---

## 6. Browse

`GET /api/v1/listings?page=0&size=20&material=&sort=` 🔒

Returns **only `OPEN`** listings. Sold and withdrawn stock disappears from this feed — verified
live: buying a listing dropped the open count for that material from 1 to 0.

| Param | Default | Notes |
| --- | --- | --- |
| `page` | 0 | zero-based |
| `size` | 20 | capped at 100 |
| `material` | — | **new** — substring, case-insensitive. `?material=card` matches `Cardboard` |
| `sort` | `newest` | **new** — `newest`, `oldest`, `price_asc`, `price_desc`, `weight_desc` |

**Response `200`**

```json
{
  "items": [
    {
      "id": "d65b58d0-0dec-4a89-a8fe-0de736eec5cf",
      "status": "OPEN",
      "material": "Cardboard",
      "weightKg": 8.0,
      "price": 72.0,
      "pricePerKg": 9.0,
      "currency": "INR",
      "description": "Flattened cartons",
      "imageUrl": "https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/accessories-bag.jpg",
      "location": "Salkia",
      "seller": {
        "id": "644663bf-aeb8-40c2-b624-1cc256233567",
        "fullName": "Anil Citizen",
        "role": "CITIZEN"
      },
      "buyer": null,
      "mine": false,
      "createdAt": "2026-08-09T00:14:26.167633Z",
      "soldAt": null
    }
  ],
  "page": 0,
  "size": 1,
  "totalItems": 3,
  "totalPages": 3,
  "hasMore": true
}
```

### Designing the card

- **`pricePerKg` is the decision number.** Computed server-side (`price ÷ weightKg`, 2 dp).
  Make it larger than `price` — `INR 675` means nothing until you know it is `INR 45/kg`.
- **`mine`** means *"you are the seller"*. Badge or hide those rows — buying returns `403`.
- **`buyer`** is `null` on every row here by definition.
- **`imageUrl`** falls back to a placeholder, so it is rarely null — still guard it.
- **`location`** is free text a human typed. There is **no distance and no map pin** for a
  listing; do not promise one.
- **`seller.role`** can be `CITIZEN`, `COLLECTOR` or `RECYCLER`.

**Fetch the wallet alongside this feed** so unaffordable rows can be disabled before the user
taps and eats a `402`.

**Errors** — `400` `Unknown sort: cheapest. Use newest, oldest, price_asc, price_desc or
weight_desc`

---

## 7. One listing

`GET /api/v1/listings/{id}` 🔒

Same object as a browse row, with `mine` computed for the caller. Any status — use it for the
detail screen, and **re-check `status` immediately before showing a Buy button**; it is the
cheapest way to catch stock someone else already took.

**Errors** — `404` `Listing not found`

---

## 8. Buy

`POST /api/v1/listings/{id}/interested` 🔒 **recycler only** · no request body

> **Despite the name this is a purchase, not an enquiry.** It moves money and marks the listing
> `SOLD`. Label the button **Buy**, and confirm before calling it.

**Response `200`**

```json
{
  "id": "bd99deea-7523-4483-8d6f-1061d7812162",
  "status": "SOLD",
  "material": "Scrap Metal",
  "weightKg": 15.0,
  "price": 675.0,
  "pricePerKg": 45.0,
  "currency": "INR",
  "seller": { "id": "644663bf-…", "fullName": "Anil Citizen", "role": "CITIZEN" },
  "buyer": { "id": "25a722fa-…", "fullName": "Meera Recycler", "role": "RECYCLER" },
  "mine": false,
  "createdAt": "2026-08-09T00:14:26.167633Z",
  "soldAt": "2026-08-09T00:14:46.940801Z"
}
```

### What happens, in one transaction

1. **Affordability is checked first** — an unaffordable buy stops before the listing is touched.
2. **The listing is claimed** with a conditional `UPDATE … WHERE status = 'OPEN' AND buyer_id IS
   NULL`. Exactly one caller can win.
3. **Seller credited, buyer debited** the full `price`, each writing one wallet ledger row.
4. `status → SOLD`, `buyer` and `soldAt` set.

Any failure rolls the whole thing back. There is no state where money moved but the listing did
not sell.

Verified live — seller `185.00 → 860.00`, buyer `9902.00 → 9227.00`, for a `675.00` lot.

**Errors**

| Status | Message | What it means |
| --- | --- | --- |
| **`402`** | `Your wallet balance is 9227.00 INR, which is not enough for this listing at 14227.00 INR` | **Recoverable — listing stays `OPEN`** |
| `409` | `Another recycler has already taken this listing` | Lost the race |
| `409` | `This listing was withdrawn` | Seller pulled it |
| `403` | `You cannot buy your own listing` | `mine: true` |
| `403` | `You do not have permission to perform this action` | Caller is not a recycler |
| `404` | `Listing not found` | |

### Design for losing the race

Buying is first-come-first-served. Two recyclers tapping the same listing produce one `200` and
one `409`.

1. Never optimistically mark a listing bought before the `200` lands.
2. On `409` show something soft — *"Someone bought this first"* — remove the card, refresh.
3. Disable the button while the request is in flight so a double-tap cannot fire twice.

### The 402 is the one to design well

It is the only error carrying real numbers. Parse or display it directly, show the shortfall,
and offer a top-up path. The listing is untouched, so a retry after funding succeeds.

### After the purchase — what you can read back

The buy response **is** the full `SOLD` object, so a confirmation screen needs no second call.
Beyond that:

| Endpoint | Gives you |
| --- | --- |
| `GET /api/v1/listings/mine` | Everything this recycler has bought |
| `GET /api/v1/listings/{id}` | That one listing in any status, with `buyer` and `soldAt` |
| `GET /api/v1/wallet` | The `LISTING_PURCHASED` ledger row, with `listingId` to deep-link back |

There is **no separate purchase or order resource** — a purchase *is* the listing, with
`status: "SOLD"` and `buyer` filled in. Do not look for `/api/v1/orders`; it does not exist.

There is also no delivery, escrow or dispute step. Money moves at the instant of purchase, and
handover of the physical waste happens off-platform between the two parties.

---

## 9. My listings and purchases

`GET /api/v1/listings/mine?page=0&size=20` 🔒

**The server switches on the caller's role:**

| Caller | Returns |
| --- | --- |
| Recycler | what they **bought** |
| Anyone else | what they **listed** |

> ⚠️ **`mine` is `false` on a recycler's purchases.** The flag means "you are the seller", so on
> a purchases screen every row reads `false`. Never use it to decide what to render there.

A recycler who also sells will **not** see their own listings here — only purchases. To show
both, call `GET /api/v1/listings` and filter client-side on `seller.id === me.id`.

---

## 10. Withdraw a listing

`POST /api/v1/listings/{id}/cancel` 🔒 — seller only

**Response `200`** — the listing with `status: "CANCELLED"`.

This also **frees the attached scan for collection again** — verified live: after withdrawing,
`POST /api/v1/pickups` for the same scan returned `201`.

**Errors** — `409` `This listing has already been sold` · `409` `This listing is already
withdrawn` · `404` not the caller's listing

---

## 11. Wallet

`GET /api/v1/wallet?page=0&size=20` 🔒

Balance, lifetime totals, Green Points and the ledger in one call.

```json
{
  "balance": 9227.0,
  "currency": "INR",
  "totalEarned": 0,
  "totalSpent": 833.0,
  "greenPoints": 0,
  "transactions": [
    {
      "id": "288a99f5-1330-444f-9866-161052744d71",
      "type": "DEBIT",
      "amount": 675.0,
      "balanceAfter": 9227.0,
      "currency": "INR",
      "reason": "LISTING_PURCHASED",
      "note": "Bought Scrap Metal from Anil Citizen",
      "listingId": "bd99deea-7523-4483-8d6f-1061d7812162",
      "createdAt": "2026-08-09T00:14:46.940801Z"
    }
  ],
  "page": 0,
  "size": 1,
  "totalItems": 4,
  "hasMore": true
}
```

The ledger is **append-only**, newest first, and every row carries `balanceAfter` — a running
balance column needs no client-side arithmetic.

| Field | Meaning |
| --- | --- |
| `type` | `CREDIT` (in) or `DEBIT` (out) |
| `reason` | `LISTING_SOLD` or `LISTING_PURCHASED` — **the only two that exist** |
| `note` | Display-ready, e.g. `"Bought Scrap Metal from Anil Citizen"` |
| `listingId` | Deep-link back to the listing |
| `greenPoints` | From completed pickups — unrelated to trading |

**Recyclers start with a seeded balance** (`RECYCLER_STARTING_BALANCE`, default `10000`) so
trading works without a payment gateway. Applied whether they self-register or an admin creates
the account.

---

## 12. Error catalogue

| Status | When | UI response |
| --- | --- | --- |
| `400` | Validation, or unknown `sort` | Inline field error |
| `401` | Missing or expired token | Clear session, go to login |
| **`402`** | Balance below price | **Show balance + shortfall, offer top-up, allow retry** |
| `403` | Not a recycler, or buying own listing | Hide/badge the Buy button |
| `404` | Listing or scan not found | Refresh the feed |
| `409` | Already taken, withdrawn, sold, or **cross-path conflict** | **Refetch, then show the message verbatim** |

**`409` almost always means the world moved while a screen was open** — someone bought it, or
the same scan is committed to the other route. Refetch, then show the server's message; they
are written for end users and name the fix ("Cancel the pickup first…").

---

## 13. Building the screens

| Screen | Endpoints | Notes |
| --- | --- | --- |
| Market feed | `GET /listings`, `GET /wallet` | Lead with `pricePerKg`; disable unaffordable rows |
| Filter bar | `GET /listings?material=&sort=` | **new** — no client-side filtering needed |
| Listing detail | `GET /listings/{id}` | Re-check `status` before enabling Buy |
| "Is this worth it?" | `POST /api/v1/chat` + `listingId` | Assistant compares ask vs catalogue rate |
| Buy confirmation | `POST /listings/{id}/interested` | Irreversible — confirm, then disable while in flight |
| Sell | `POST /listings` | Prefer `detectionId`; enter a rate, send `rate × weight` |
| My listings / purchases | `GET /listings/mine` | Role-dependent; `mine` is `false` on purchases |
| Wallet | `GET /wallet` | Money **and** points in one call |

### Things that will bite you if unnoticed

1. **`/interested` is a purchase.** Money moves instantly. Call the button "Buy".
2. **`402` leaves the listing `OPEN`** — fully recoverable, so offer top-up and retry.
3. **`mine` is `false` on your own purchases.** It means "you are the seller".
4. **`/listings/mine` returns purchases only** for a recycler.
5. **Buying is first-come-first-served** — treat `409` as a normal outcome, not an error.
6. **`pricePerKg` is what buyers compare on**, not `price`.
7. **`location` is free text** — no coordinates, no distance, no map pin.
8. **A scan is committed to one route.** Selling blocks collection and vice versa, until the
   other side is cancelled.
9. **The wallet is marketplace-only.** Pickup cash never appears in it.
10. **Sold and cancelled are terminal.** No un-buy, no re-open.
