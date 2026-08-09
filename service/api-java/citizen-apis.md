# Citizen APIs — GreenRoute

Every endpoint a **citizen** app touches, with exact request and response shapes.

All examples below are **real responses captured from a running server**, not invented. Field
names, casing and nesting are exactly what the API returns.

- **Base URL (local):** `http://localhost:8080`
- **Content type:** `application/json` everywhere except the image upload, which is
  `multipart/form-data`
- **Auth:** `Authorization: Bearer <accessToken>` on every endpoint marked 🔒

---

## Table of contents

1. [Conventions](#1-conventions)
2. [Enums the UI must handle](#2-enums-the-ui-must-handle)
3. [The citizen journey](#3-the-citizen-journey)
4. [Auth](#4-auth)
5. [Scan waste](#5-scan-waste-detection)
6. [Pickups](#6-pickups)
7. [Collection points and map](#7-collection-points-and-map)
8. [Marketplace and wallet](#8-marketplace-and-wallet)
9. [Leaderboard](#9-leaderboard)
10. [Assistant chatbot](#10-assistant-chatbot)
11. [Error catalogue](#11-error-catalogue)
12. [Screen to endpoint map](#12-screen-to-endpoint-map)

---

## 1. Conventions

### Authentication

Send the token from login or register on every 🔒 endpoint:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

Tokens last **7 days** (`expiresIn: 604800` seconds). On `401` the app should clear the stored
session and send the user back to login.

Endpoints marked 🌐 are **public** and need no token: `/health`, `/auth/send-otp`,
`/auth/register`, `/auth/login`, `/auth/google`, `/api/v1/collection-points/**`,
`/api/v1/leaderboard`.

> `/api/v1/leaderboard` is public but **behaves better with a token** — it adds a `me` block
> showing the caller's own rank. Send the token whenever you have one.

### Error shape

Every failure returns the same shape, with a human-readable message safe to show the user:

```json
{ "error": "A collector has already accepted this pickup and it can no longer be cancelled." }
```

### Pagination

Any list endpoint takes `?page=0&size=20` and returns:

```json
{
  "items": [],
  "page": 0,
  "size": 20,
  "totalItems": 42,
  "totalPages": 3,
  "hasMore": true
}
```

`page` is **zero-based**. `size` is capped server-side at 100.

### Money, weight and time

| Concept | Type | Notes |
| --- | --- | --- |
| Money | number | Always INR. A `currency` field accompanies it. Render as `INR 96.00`. |
| Weight | number | Kilograms, up to 3 decimals. |
| Timestamps | string | ISO-8601 UTC, e.g. `2026-08-08T16:22:43.206388Z`. Convert to IST for display. |
| IDs | string | UUID v4. |

Nullable fields are common — always null-check before rendering. `imageUrl` in particular is
often `null` (Cloudinary upload is not wired up yet), so **always ship a placeholder image**.

---

## 2. Enums the UI must handle

### `role`

`CITIZEN` · `COLLECTOR` · `RECYCLER` · `MUNICIPAL_ADMIN` · `SUPER_ADMIN`

### `PickupStatus`

| Value | Meaning | Citizen can cancel? |
| --- | --- | --- |
| `REQUESTED` | Waiting for a collector | ✅ Yes |
| `ACCEPTED` | A collector claimed it | ❌ **No — locked** |
| `COMPLETED` | Collected, weighed and paid | ❌ No |
| `CANCELLED` | Called off | ❌ No |

### `PickupMode`

| Value | Meaning | Points per kg |
| --- | --- | --- |
| `DOORSTEP` | Collector comes to the citizen | 5 |
| `DROP_OFF` | Citizen carries it to a collection point | **8** |

Drop-off pays more because it saves the municipality a vehicle trip. Worth surfacing in the UI
as a nudge.

### Detection `status` — drives what the scan screen shows

| Value | Meaning | Suggested UI |
| --- | --- | --- |
| `OK` | Clean detection with a price | Show the offer, enable "Request pickup" |
| `MANUAL_PRICING_REQUIRED` | Detected, but the collector must weigh it | Show the range, note "collector confirms" |
| `LOW_CONFIDENCE` | Model unsure | Show results with a "retake for a better result" hint |
| `NO_WASTE_DETECTED` | Nothing recyclable found | **Retake screen** |

### `actionRequired`

| Value | Meaning |
| --- | --- |
| `RECLICK_IMAGE` | Ask the user to photograph again |
| `COLLECTOR_SETS_PRICE` | Final price comes from the collector's scale |
| `null` | Nothing needed |

### Offer `status`

`ESTIMATED` · `PENDING_COLLECTOR_CONFIRMATION` · `NO_RESALE_VALUE` · `UNAVAILABLE`

### Bin colours

| Bin | Contents |
| --- | --- |
| `BLUE` | Dry recyclables — PET/HDPE bottles, cans, food containers, paper, cardboard, scrap metal |
| `GREEN` | Glass bottles and wet organic waste |
| `RED` | Hazardous — bulbs, batteries, e-waste |
| `GREY` | Non-recyclable rejects — wrappers, textiles, mixed waste |

### Collection point `type`

`MRF` · `BIN_CLUSTER` · `SCRAP_YARD` · `COMPOST_HUB` — roughly 39 of each are seeded across
155 points. Good for map pin colours and a filter chip row.

### `ListingStatus`

`OPEN` · `SOLD` · `CANCELLED`

### Wallet `type` and `reason`

`type`: `CREDIT` · `DEBIT`

`reason`: `LISTING_SOLD` (money in, citizen sold) · `LISTING_PURCHASED` (money out, recycler
bought)

> Only these two reasons exist today — the wallet ledger records **marketplace trades only**.
> A pickup payout is *not* written to the wallet; it lives on the pickup itself as
> `money.finalAmount`. So wallet balance and "money earned from pickups" are two different
> numbers, and a combined "total earnings" figure has to add them yourself.

---

## 3. The citizen journey

```text
register / login
      |
      v
POST /api/v1/detections          photograph the waste
      |                          -> 13 objects, INR 8.29-11.21, +65 points (credited instantly)
      |
      +-- eligible: false -----> retake screen, stop here
      |
      v
choose how to hand it over
      |
      +-- DOORSTEP -----> POST /api/v1/pickups  { mode: "DOORSTEP", address, contactPhone }
      |                        |
      |                        v
      |                   status REQUESTED  (cancellable: true)
      |                        |
      |                   collector accepts -> status ACCEPTED, cancellable: false
      |                        |
      |                   collector weighs  -> status COMPLETED, +20 bonus +5/kg
      |
      +-- DROP_OFF -----> GET /api/v1/collection-points/nearest?lat=&lon=
                               |
                               v
                          POST /api/v1/pickups { mode: "DROP_OFF", collectionPointId }
                               |
                          same lifecycle, but 8 points per kg

separately, at any time:
  POST /api/v1/listings      sell segregated waste to a recycler
  GET  /api/v1/wallet        money in, money out, Green Points
  GET  /api/v1/leaderboard   where the citizen ranks
  POST /api/v1/chat          ask the assistant anything
```

**Points are credited at two moments:** immediately on a successful scan (per material), and
again when a pickup completes (flat bonus + per kg). The scan response returns the new balance
in `userPointsBalance`, so the UI can animate the counter without a refetch.

---

## 4. Auth

### 4.1 Send OTP 🌐

`POST /auth/send-otp`

Step one of registration. The OTP is valid for a short window and is single-use.

**Request**

```json
{ "email": "anil@example.com" }
```

**Response `200`**

```json
{ "message": "OTP sent" }
```

> **Dev note:** when `MAIL_ENABLED=false` in the API's `.env`, no email is sent — the OTP is
> **printed to the API server log** instead. Look for
> `OTP generated for anil@example.com: 957452`. This is how the team works around the Resend
> daily quota, so during development the tester reads the code off the terminal.

---

### 4.2 Register 🌐

`POST /auth/register`

**Request**

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `email` | string | ✅ | valid email |
| `fullName` | string | ✅ | max 100 chars |
| `password` | string | ✅ | **8–72 characters** |
| `otp` | string | ✅ | exactly 6 characters, from step 4.1 |
| `role` | string | — | defaults to `CITIZEN` |

```json
{
  "email": "anil@example.com",
  "fullName": "Anil Citizen",
  "password": "SecurePass123",
  "otp": "957452",
  "role": "CITIZEN"
}
```

**Response `200`**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 604800,
  "user": {
    "id": "644663bf-aeb8-40c2-b624-1cc256233567",
    "email": "anil@example.com",
    "fullName": "Anil Citizen",
    "role": "CITIZEN",
    "points": 0
  }
}
```

**Errors** — `400` invalid or expired OTP · `400` email already in use · `400` password too
short

---

### 4.3 Login 🌐

`POST /auth/login`

**Request**

```json
{ "email": "anil@example.com", "password": "SecurePass123" }
```

**Response `200`** — identical shape to register.

**Errors**

| Status | Message | UI |
| --- | --- | --- |
| `401` | `Invalid credentials` | Inline error under the password field |
| `403` | `This account has been deactivated. Contact your administrator.` | Full-screen message, show the text verbatim |

---

### 4.4 Google sign-in 🌐

`POST /auth/google`

**Request**

```json
{ "idToken": "<google id token>", "role": "CITIZEN" }
```

`role` only applies the first time — it is ignored for an existing account.

**Response `200`** — same shape as login.

---

### 4.5 Current user 🔒

`GET /auth/me`

Call on app launch to validate the stored token and refresh the points balance.

**Response `200`**

```json
{
  "id": "644663bf-aeb8-40c2-b624-1cc256233567",
  "email": "chat.citizen@greentech.local",
  "fullName": "Anil Citizen",
  "role": "CITIZEN",
  "points": 162
}
```

**Errors** — `401` token missing, expired, or belonging to a disabled account.

> This endpoint returns **points only**, not the wallet balance. For money use
> [`GET /api/v1/wallet`](#86-wallet-).

---

## 5. Scan waste (detection)

### 5.1 Scan an image 🔒

`POST /api/v1/detections`

**Content type: `multipart/form-data`** — not JSON.

| Part | Type | Rules |
| --- | --- | --- |
| `image` | file | **max 10 MB**, JPEG / PNG / WEBP / BMP |

```bash
curl -X POST http://localhost:8080/api/v1/detections \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@bin.jpg"
```

**Response `200`** — real capture, 13 bottles in one photo:

```json
{
  "id": "999478d5-a137-4be5-a195-14cf1a502f7a",
  "eligible": true,
  "status": "MANUAL_PRICING_REQUIRED",
  "message": "13 waste items detected across 1 material. Offer up to INR 11.21; the collector will weigh and confirm the final price.",
  "actionRequired": "COLLECTOR_SETS_PRICE",
  "imageUrl": null,
  "totalObjects": 13,
  "totalRewardPoints": 65,
  "pointsAwarded": true,
  "userPointsBalance": 227,
  "offer": {
    "currency": "INR",
    "minimumOffer": 8.29,
    "estimatedOffer": 9.75,
    "maximumOffer": 11.21,
    "status": "PENDING_COLLECTOR_CONFIRMATION",
    "finalPriceSetBy": "COLLECTOR"
  },
  "impact": {
    "estimatedWeightKg": 0.39,
    "carbonSavedKg": 1.95,
    "landfillReducedKg": 0.39,
    "recyclablePercent": 100
  },
  "recommendation": {
    "primaryBin": "BLUE",
    "secondaryBin": null,
    "pickupRecommended": true
  },
  "quality": {
    "detectionQuality": "MEDIUM",
    "averageConfidence": 0.58
  },
  "aiSummary": "13 PET Bottles detected. These are fully recyclable and should be placed in the Blue bin. Estimated total weight is 0.39 kg. Estimated offer is INR 9.75, between INR 8.29 and 11.21. The collector will verify the final weight before payment.",
  "processingTimeMs": 5110,
  "materials": [
    {
      "material": "PET Bottle",
      "category": "PLASTIC",
      "stream": "DRY",
      "bin": "BLUE",
      "recyclable": true,
      "count": 13,
      "pricePerKg": 25,
      "estimatedWeightKg": 0.39,
      "estimatedValue": 9.75,
      "rewardPoints": 65,
      "carbonSavedKg": 1.95
    }
  ],
  "createdAt": "2026-08-08T21:33:57.287665685Z"
}
```

#### Designing the result screen

**Branch on `eligible` first.**

```js
if (!res.eligible) {
  // status is NO_WASTE_DETECTED, actionRequired is RECLICK_IMAGE
  // Show the retake screen. Do NOT offer a pickup.
}
```

When `eligible` is `false` the response is still `200` — it is a valid scan that simply found
nothing. The `message` field is written for display; show it verbatim.

Other things worth surfacing:

- **`aiSummary`** is a ready-made paragraph. It is generated from the detection data by rules,
  not by a language model, so it is always consistent with the numbers beside it.
- **`offer.minimumOffer` … `maximumOffer`** is a range, not a promise. Render it as a range and
  put `finalPriceSetBy: "COLLECTOR"` in small print.
- **`userPointsBalance`** is the balance *after* this scan. Animate from the old value.
- **`processingTimeMs`** was ~5 s here. Show real progress, not a spinner that looks stuck.
- **`quality.detectionQuality`** is `HIGH` / `MEDIUM` / `LOW` — a good place for a subtle
  "try better lighting" nudge on `LOW`.

**Errors**

| Status | Message | Cause |
| --- | --- | --- |
| `400` | `Image file is required` | Empty part |
| `400` | `Unsupported image type, use JPEG, PNG, WEBP or BMP` | Wrong format |
| `413` | `Image too large, max 10MB` | Oversized file |
| `503` | `Detection service is unavailable. Please try again.` | Python service down |

The `503` deserves a dedicated retry state — it means the AI service is down, not that the user
did anything wrong.

---

### 5.2 Scan history 🔒

`GET /api/v1/detections?page=0&size=20`

**Response `200`**

```json
{
  "items": [
    {
      "id": "769a44e0-281e-4567-84d3-44bbb5eeb6c5",
      "imageUrl": null,
      "status": "MANUAL_PRICING_REQUIRED",
      "eligible": true,
      "totalObjects": 13,
      "totalRewardPoints": 65,
      "pointsAwarded": true,
      "currency": "INR",
      "estimatedOffer": 9.75,
      "minimumOffer": 8.29,
      "maximumOffer": 11.21,
      "offerStatus": "PENDING_COLLECTOR_CONFIRMATION",
      "estimatedWeightKg": 0.39,
      "carbonSavedKg": 1.95,
      "primaryBin": "BLUE",
      "pickupRecommended": true,
      "detectionQuality": "MEDIUM",
      "materials": ["PET Bottle x13"],
      "createdAt": "2026-08-08T16:23:02.915683Z"
    }
  ],
  "page": 0,
  "size": 1,
  "totalItems": 2,
  "totalPages": 2,
  "hasMore": true,
  "totals": {
    "scans": 2,
    "objects": 26,
    "rewardPoints": 130,
    "carbonSavedKg": 3.9,
    "estimatedEarnings": 19.5
  }
}
```

`totals` covers the citizen's **entire history**, not just the current page — use it for a
profile or impact header without a second call.

Note that `materials` here is a **flat array of strings** (`"PET Bottle x13"`), unlike the rich
objects in the scan response. It is meant for a one-line summary in a list row.

> ⚠️ **There is no `GET /api/v1/detections/{id}`.** To show a scan detail screen, either keep
> the object returned by the scan call in memory, or find it in the history list by `id`.

---

## 6. Pickups

### 6.1 Request a pickup 🔒

`POST /api/v1/pickups`

**Request**

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `detectionId` | UUID | ✅ | Must be an **eligible** scan owned by the caller |
| `mode` | enum | — | `DOORSTEP` (default) or `DROP_OFF` |
| `collectionPointId` | UUID | **DROP_OFF only** | From the nearest-points call |
| `address` | string | **DOORSTEP only** | max 300 |
| `contactPhone` | string | **DOORSTEP only** | pattern `^[+0-9][0-9 \-]{7,19}$` |
| `landmark` | string | — | max 120 |
| `notes` | string | — | max 300 |
| `latitude` | number | — | Strongly recommended for doorstep |
| `longitude` | number | — | Enables routing and correct municipality assignment |
| `preferredTime` | string | — | ISO-8601 |

**Doorstep**

```json
{
  "detectionId": "618f4dd7-d114-4989-b35e-b37ed5fd0734",
  "mode": "DOORSTEP",
  "address": "14 Belilious Road, Howrah",
  "landmark": "Near Howrah Maidan",
  "contactPhone": "9800000001",
  "latitude": 22.5958,
  "longitude": 88.2636
}
```

**Drop-off**

```json
{
  "detectionId": "618f4dd7-d114-4989-b35e-b37ed5fd0734",
  "mode": "DROP_OFF",
  "collectionPointId": "c0e76555-d88f-4046-9b24-5bb67e391db3"
}
```

For a drop-off the address, landmark and coordinates are **filled in from the collection
point** — do not ask the user for them.

> 📍 **Always send `latitude`/`longitude` on doorstep requests.** They are optional in the
> schema, but without them the pickup cannot be placed on a collector's route, and its
> municipality has to fall back to the citizen's profile.

**Response `201`** — see the full shape in 6.2.

**Errors**

| Status | Message |
| --- | --- |
| `404` | `Scan not found` (wrong id, or not the caller's scan) |
| `400` | `This scan has no waste to collect. Please scan the waste again.` |
| `409` | `A pickup already exists for this scan` |
| `400` | `address is required for a doorstep pickup` |
| `400` | `contactPhone is required for a doorstep pickup` |
| `400` | `collectionPointId is required for a drop-off` |

---

### 6.2 My pickups 🔒

`GET /api/v1/pickups?page=0&size=20`

Returns the pickups the citizen raised. (The same endpoint returns *assigned* pickups when
called by a collector — the server switches on the caller's role.)

**Response `200`**

```json
{
  "items": [
    {
      "id": "d3254be5-154b-4ad1-b7d9-1b07c5e61b9f",
      "detectionId": "618f4dd7-d114-4989-b35e-b37ed5fd0734",
      "status": "COMPLETED",
      "mode": "DOORSTEP",
      "collectionPointId": null,
      "rewardPoints": 32,
      "rewardAwarded": true,
      "cancellable": false,
      "location": {
        "address": "14 Belilious Road, Howrah",
        "landmark": "Near Howrah Maidan",
        "latitude": 22.5958,
        "longitude": 88.2636
      },
      "contact": { "phone": "9800000001", "notes": null },
      "waste": { "totalObjects": 13, "materials": "PET Bottle x13" },
      "money": {
        "currency": "INR",
        "estimatedOffer": 9.75,
        "finalAmount": 96.0,
        "finalWeightKg": 2.4
      },
      "collector": {
        "id": "2a848c42-0e5a-4ad0-b912-a24b9e6eccbd",
        "fullName": "Ravi Collector",
        "email": "chat.collector@greentech.local"
      },
      "citizen": {
        "id": "644663bf-aeb8-40c2-b624-1cc256233567",
        "fullName": "Anil Citizen",
        "email": "chat.citizen@greentech.local"
      },
      "cancelReason": null,
      "cancelledBy": null,
      "collectorNotes": "Mostly PET bottles, well segregated",
      "preferredTime": null,
      "createdAt": "2026-08-08T16:22:43.206388Z",
      "acceptedAt": "2026-08-08T16:22:43.329457Z",
      "completedAt": "2026-08-08T16:22:43.387483Z",
      "cancelledAt": null
    }
  ],
  "page": 0,
  "size": 1,
  "totalItems": 1,
  "totalPages": 1,
  "hasMore": false
}
```

#### Two fields that drive the whole UI

**`cancellable`** is a plain boolean, already computed. **Bind the Cancel button straight to
it.** Do not re-derive it from `status`; the server is the authority and it flips to `false`
the instant a collector accepts.

**`collector`** is `null` until someone accepts. Its arrival is the signal to switch the card
from "Looking for a collector…" to a collector detail block with a call button.

The four timestamps (`createdAt` → `acceptedAt` → `completedAt` / `cancelledAt`) map directly
onto a progress tracker.

**Money before and after:** while `REQUESTED` or `ACCEPTED`, only `estimatedOffer` is set and
`finalWeightKg` holds the *estimated* weight. Once `COMPLETED`, `finalAmount` and
`finalWeightKg` hold the collector's weighed figures. In this real example the estimate was
INR 9.75 but the actual payout was INR 96.00, because photo-based weight estimation is rough.
**Label pre-completion numbers clearly as estimates.**

---

### 6.3 One pickup 🔒

`GET /api/v1/pickups/{id}`

Same object as a list row. Use for a detail screen or to poll for status changes.

**Errors** — `404` `Pickup not found`, also returned when the pickup belongs to someone else.
That is deliberate, so ids cannot be probed.

---

### 6.4 Cancel a pickup 🔒

`POST /api/v1/pickups/{id}/cancel`

**Request** (body optional)

```json
{ "reason": "Not at home today" }
```

**Response `200`** — the pickup with `status: "CANCELLED"` and `cancelledBy: "USER"`.

**Errors**

| Status | Message | UI |
| --- | --- | --- |
| `409` | `A collector has already accepted this pickup and it can no longer be cancelled.` | Show verbatim — this is the rule, not a glitch |
| `409` | `This pickup is already completed` / `cancelled` | Refresh the row |
| `404` | `Pickup not found` | Not the caller's pickup |

> **This is the single most important business rule in the app.** Once a collector accepts, the
> citizen is locked out of cancelling — a collector may already be driving. Hide or disable the
> Cancel button as soon as `cancellable` is `false`, so the user never hits this error by
> surprise.

---

## 7. Collection points and map

### 7.1 Nearest points 🌐

`GET /api/v1/collection-points/nearest?lat=22.5958&lon=88.2636&limit=5`

| Param | Required | Notes |
| --- | --- | --- |
| `lat` | ✅ | −90 … 90 |
| `lon` | ✅ | −180 … 180 |
| `limit` | — | default 5, capped at 5 |

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
  "count": 2,
  "origin": { "lat": 22.5958, "lon": 88.2636 }
}
```

**Results are ordered by real driving time, not straight-line distance.** Look at the real
data: the first point is *further* in a straight line than the second (0.66 km vs 0.42 km) but
much closer by road (1.91 km vs 2.66 km). **Display `roadDistanceKm` and `drivingMinutes`** —
showing `straightLineKm` would make the ordering look broken.

`roadDistanceKm` and `drivingMinutes` are `null` when the routing provider is unreachable. Fall
back to `straightLineKm` with a softer label such as "about 0.7 km away".

**Errors** — `400` `Invalid coordinates` · `404` `No collection point found near this location.
Request a doorstep pickup instead.` The message names the fallback, so offer that button.

---

### 7.2 All points 🌐

`GET /api/v1/collection-points`

Every active point, without distances. For an overview map. 155 points are seeded, so cluster
the markers rather than drawing them all.

---

### 7.3 Municipalities 🌐

`GET /api/v1/collection-points/municipalities`

```json
{
  "count": 4,
  "municipalities": [
    {
      "code": "HMC",
      "name": "Howrah Municipal Corporation",
      "district": "Howrah",
      "state": "West Bengal",
      "depot": {
        "name": "Howrah Municipal Corporation Depot",
        "lat": 22.5892,
        "lon": 88.3103
      }
    }
  ]
}
```

Useful for an area picker or an onboarding "where do you live?" step.

---

## 8. Marketplace and wallet

A citizen **sells**; a recycler **buys**. Both sides use the same endpoints, and the server
switches behaviour on the caller's role.

### 8.1 Create a listing 🔒

`POST /api/v1/listings`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `price` | number | ✅ | **minimum 1** |
| `detectionId` | UUID | — | Attach a scan to auto-fill material, weight and image |
| `material` | string | Required **if no** `detectionId` | max 80 |
| `weightKg` | number | Required **if no** `detectionId` | must be greater than zero |
| `description` | string | — | max 400 |
| `location` | string | — | max 160 |
| `imageUrl` | string | — | max 500; falls back to a placeholder |

**From a scan** — the clean path, since material and weight come from the detection:

```json
{
  "detectionId": "618f4dd7-d114-4989-b35e-b37ed5fd0734",
  "price": 60.00,
  "description": "Clean PET bottles, rinsed",
  "location": "Howrah Maidan"
}
```

**Manual**

```json
{
  "material": "Cardboard",
  "weightKg": 5.0,
  "price": 45.00,
  "description": "Flattened cartons",
  "location": "Salkia"
}
```

**Response `201`** — see 8.3 for the shape.

**Errors** — `404` `Scan not found` · `400` `This scan has no waste to sell` · `409` `This scan
is already listed` · `400` `material is required when no scan is attached` · `400` `weightKg is
required when no scan is attached`

---

### 8.2 Browse open listings 🔒

`GET /api/v1/listings?page=0&size=20`

All `OPEN` listings. A citizen can see the market to judge their own pricing; only a recycler
can actually buy.

---

### 8.3 My listings 🔒

`GET /api/v1/listings/mine?page=0&size=20`

For a citizen this returns **what they listed**. For a recycler, what they bought.

**Response `200`**

```json
{
  "items": [
    {
      "id": "39504b45-308d-432d-bca6-e6c0bf78ad1a",
      "status": "SOLD",
      "material": "Cardboard",
      "weightKg": 5.0,
      "price": 45.0,
      "pricePerKg": 9.0,
      "currency": "INR",
      "description": "Flattened cartons",
      "imageUrl": "https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/accessories-bag.jpg",
      "location": "Salkia",
      "seller": { "id": "644663bf-...", "fullName": "Anil Citizen", "role": "CITIZEN" },
      "buyer": { "id": "e0802b8a-...", "fullName": "Sunil Recycler", "role": "RECYCLER" },
      "mine": true,
      "createdAt": "2026-08-08T21:13:34.905723Z",
      "soldAt": "2026-08-08T21:13:50.163119Z"
    }
  ],
  "page": 0,
  "size": 1,
  "totalItems": 2,
  "totalPages": 2,
  "hasMore": true
}
```

`pricePerKg` is computed server-side — show it, since it is what buyers compare on. `buyer` is
`null` until sold. `mine` marks the caller's own listings in a mixed feed.

---

### 8.4 One listing 🔒

`GET /api/v1/listings/{id}`

Returns a single listing in the same shape as a list row, including the `mine` flag relative to
the caller. Use it for a listing detail screen, or to refresh a card after someone else buys it.

**Errors** — `404` `Listing not found`

---

### 8.5 Withdraw a listing 🔒

`POST /api/v1/listings/{id}/cancel`

**Errors** — `409` `This listing has already been sold` · `409` `This listing is already
withdrawn` · `404` not the caller's listing

---

### 8.6 Wallet 🔒

`GET /api/v1/wallet?page=0&size=20`

The money screen. One call gives balance, lifetime totals, Green Points and the ledger.

**Response `200`**

```json
{
  "balance": 105.0,
  "currency": "INR",
  "totalEarned": 105.0,
  "totalSpent": 0,
  "greenPoints": 162,
  "transactions": [
    {
      "id": "096bd62e-4b85-4e69-b1a2-7b957385dcfd",
      "type": "CREDIT",
      "amount": 45.0,
      "balanceAfter": 105.0,
      "currency": "INR",
      "reason": "LISTING_SOLD",
      "note": "Sold Cardboard to Sunil Recycler",
      "listingId": "39504b45-308d-432d-bca6-e6c0bf78ad1a",
      "createdAt": "2026-08-08T21:13:50.190893Z"
    }
  ],
  "page": 0,
  "size": 2,
  "totalItems": 2,
  "hasMore": false
}
```

The ledger is **append-only** and every row carries `balanceAfter`, so a running-balance column
needs no client-side arithmetic. `note` is written for display. `listingId` deep-links to the
listing.

This is also the **only endpoint returning money and points together** — ideal for a combined
wallet header.

---

## 9. Leaderboard

`GET /api/v1/leaderboard?limit=20` 🌐 *(send the token anyway — it adds `me`)*

```json
{
  "scope": "ALL_TIME",
  "entries": [
    {
      "rank": 1,
      "userId": "644663bf-aeb8-40c2-b624-1cc256233567",
      "fullName": "Anil Citizen",
      "role": "CITIZEN",
      "points": 162,
      "completedPickups": 1,
      "totalWeightKg": 2.4
    }
  ],
  "me": { "rank": 1, "points": 162, "completedPickups": 1, "ahead": 0 },
  "totals": { "citizens": 2, "points": 190, "weightKg": 2.4, "completedPickups": 1 }
}
```

`me` is returned **even when the citizen falls outside the visible page** — pin it as a sticky
footer row. `ahead` is how many people are above them, which makes a good motivator: *"3 people
ahead of you."*

`me` is `null` for an anonymous caller. `totals` gives community impact for a header.

---

## 10. Assistant chatbot

A role-aware assistant. For a citizen it answers questions about **their own** rewards,
payments, pickups, scrap prices and nearby collection points. Every number it quotes comes from
a real query against live data.

### 10.1 Ask 🔒

`POST /api/v1/chat`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `message` | string | ✅ | max 1000 chars |
| `conversationId` | UUID | — | Omit for a new chat; **send it back to keep memory** |
| `latitude` | number | — | Lets it answer "nearest drop-off" without asking |
| `longitude` | number | — | Pair with `latitude` |
| `listingId` | UUID | — | Marks a listing as "on screen" so "this listing" resolves |
| `pickupId` | UUID | — | Same, for a pickup |

```json
{
  "message": "Where is the nearest place I can drop my waste?",
  "latitude": 22.5958,
  "longitude": 88.2636
}
```

**Response `200`**

```json
{
  "conversationId": "3e58d5d2-7ff6-4989-8274-12a7fe79092a",
  "reply": "The nearest place to drop your waste is the Unsani Rd Point 4 scrap yard, located in Ward 37, Howrah. It's approximately 1.91 km away, which should take about 3 minutes to drive.",
  "toolsUsed": ["find_nearest_collection_points"],
  "historyLength": 2
}
```

**Store `conversationId` and send it on every follow-up** — that is what gives the bot memory.
Without it, each message starts a fresh conversation. Follow-ups such as *"and how much is that
worth?"* only work when the id is passed.

`toolsUsed` names the live queries behind the answer. Rendering it in small print, as the admin
console does, is a nice trust signal that the number is real.

**Context fields matter.** Passing `latitude`/`longitude` from a screen that already has them
stops the bot asking for a location. Passing `listingId` makes *"is this a good deal?"* work
with no other text.

### 10.2 What a citizen can ask 🔒

`GET /api/v1/chat/capabilities`

```json
{
  "enabled": true,
  "role": "CITIZEN",
  "tools": [{ "name": "get_my_rewards_summary", "description": "..." }],
  "suggestions": [
    "What is my rewards summary?",
    "Show my payment history",
    "What is a PET bottle worth per kg?",
    "Where is the nearest collection point?",
    "What happened to my last pickup?"
  ]
}
```

Use `suggestions` to fill the empty state with tappable prompt chips. **Check `enabled`** — it
is `false` when the server has no assistant key configured, in which case hide the chat entry
point entirely.

### 10.3 History 🔒

- `GET /api/v1/chat/conversations?limit=20` — recent conversations with `title`,
  `lastMessageAt` and `messageCount`
- `GET /api/v1/chat/conversations/{id}` — full transcript, each item carrying `author`
  (`USER` / `ASSISTANT`), `content`, `toolsUsed` and `createdAt`
- `DELETE /api/v1/chat/conversations/{id}` — delete a conversation

A citizen can only read their own conversations; another user's id returns `404`.

**Errors** — `503` `The assistant is not configured on this server` · `429` rate limited ·
`503` unreachable.

Chat replies take **2–6 seconds** because the assistant runs a live query before answering —
show a typing indicator, not a blocking spinner.

---

## 11. Error catalogue

| Status | When | How the UI should react |
| --- | --- | --- |
| `400` | Validation failure | Inline field errors; the message names the field |
| `401` | Missing or expired token | Clear session, go to login |
| `402` | Wallet balance too low (recycler buying) | Show balance and shortfall |
| `403` | Not allowed, or account disabled | Explain; do not retry |
| `404` | Not found, or not the caller's record | Generic "not found" |
| `409` | Conflict — already accepted, already listed, already sold | **Refetch, then show the message verbatim** |
| `413` | Image over 10 MB | Ask for a smaller photo |
| `415` | Wrong content type | Bug — check `multipart/form-data` on upload |
| `429` | Assistant rate limited | Ask to retry shortly |
| `500` | Server fault | Generic error plus retry |
| `503` | Detection or assistant service down | Dedicated "service unavailable" state with retry |

**`409` deserves special handling.** It nearly always means *someone else changed this while you
were looking at it* — a collector accepted, a recycler bought. The right response is to refetch
the record, then show the server's message, which is written for end users.

Validation errors concatenate field names:

```json
{ "error": "password: size must be between 8 and 72, otp: size must be between 6 and 6" }
```

---

## 12. Screen to endpoint map

| Screen | Endpoints | Notes |
| --- | --- | --- |
| Splash | `GET /auth/me` | Validates the stored token |
| Sign up | `POST /auth/send-otp` → `POST /auth/register` | Two steps; OTP is 6 chars |
| Login | `POST /auth/login`, `POST /auth/google` | |
| Home | `GET /auth/me`, `GET /api/v1/detections?size=3` | `totals` gives the impact header |
| Camera / scan | `POST /api/v1/detections` | multipart; ~5 s; branch on `eligible` |
| Scan result | *(reuse the scan response)* | No detail endpoint exists |
| Choose handover | `GET /api/v1/collection-points/nearest` | Compare 5 pts/kg vs 8 pts/kg |
| Request pickup | `POST /api/v1/pickups` | Send lat/lon |
| My pickups | `GET /api/v1/pickups` | Bind Cancel to `cancellable` |
| Pickup detail | `GET /api/v1/pickups/{id}`, `POST /{id}/cancel` | Timestamps drive the tracker |
| Map | `GET /api/v1/collection-points` | 155 points — cluster them |
| Sell waste | `POST /api/v1/listings` | Prefer `detectionId` |
| My listings | `GET /api/v1/listings/mine`, `POST /{id}/cancel` | |
| Wallet | `GET /api/v1/wallet` | Money **and** points in one call |
| Leaderboard | `GET /api/v1/leaderboard` | Pin `me` as a sticky row |
| Assistant | `POST /api/v1/chat`, `GET /api/v1/chat/capabilities` | Keep `conversationId` |
| Profile | `GET /auth/me`, `GET /api/v1/detections` | |

### Things that will bite you if unnoticed

1. **`imageUrl` is usually `null`** — Cloudinary upload is not wired up. Ship a placeholder.
2. **No `GET /detections/{id}`** — cache the scan response or read from the history list.
3. **`cancellable` is authoritative** — never re-derive it from `status` on the client.
4. **Estimated vs final money** — the estimate came to INR 9.75 and the real payout was
   INR 96.00. Label estimates clearly or users will feel misled.
5. **Nearest points are ranked by road time**, so showing straight-line distance makes the
   order look broken.
6. **Pagination is zero-based.**
7. **Scan and chat are slow** (~5 s and 2–6 s). Design real progress states.
8. **Points land twice** — once on scan, again on pickup completion.
9. **Wallet money and pickup money are separate** — the ledger only records marketplace trades.
