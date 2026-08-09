# Collector APIs — GreenTech

Every endpoint a **collector** app touches, with exact request and response shapes.

All examples below are **real responses captured from a running server**, including a live
Mapbox-optimised route across three Howrah addresses. Field names, casing and nesting are
exactly what the API returns.

- **Base URL (local):** `http://localhost:8080`
- **Auth:** `Authorization: Bearer <accessToken>` on every endpoint marked 🔒
- **Companion docs:** [`citizen-apis.md`](citizen-apis.md) · [`recycler-apis.md`](recycler-apis.md)

---

## Table of contents

1. [What a collector can and cannot call](#1-what-a-collector-can-and-cannot-call)
2. [Conventions](#2-conventions)
3. [A collector's day](#3-a-collectors-day)
4. [Auth](#4-auth)
5. [Finding work](#5-finding-work)
6. [Claiming a pickup](#6-claiming-a-pickup)
7. [The optimised route](#7-the-optimised-route)
8. [Completing a pickup](#8-completing-a-pickup)
9. [Releasing a pickup](#9-releasing-a-pickup)
10. [My pickups](#10-my-pickups)
11. [Marketplace and wallet](#11-marketplace-and-wallet)
12. [Scanning, points and leaderboard](#12-scanning-points-and-leaderboard)
13. [Assistant chatbot](#13-assistant-chatbot)
14. [Error catalogue](#14-error-catalogue)
15. [Screen to endpoint map](#15-screen-to-endpoint-map)

---

## 1. What a collector can and cannot call

Every row below was **tested with a real collector token**, not read off the annotations.

| Endpoint | Collector | Note |
| --- | --- | --- |
| `GET /api/v1/pickups/available` | ✅ | **Collector only** |
| `POST /api/v1/pickups/{id}/accept` | ✅ | **Collector only** |
| `POST /api/v1/pickups/{id}/complete` | ✅ | **Collector only** |
| `POST /api/v1/pickups/{id}/release` | ✅ | **Collector only** |
| `GET /api/v1/routes/my-route` | ✅ | **Collector only** |
| `GET /api/v1/pickups` | ✅ | Returns pickups **assigned to them** |
| `GET /api/v1/pickups/{id}` | ✅ | |
| `POST /api/v1/pickups` | ✅ | They can raise their own household pickup |
| `POST /api/v1/pickups/{id}/cancel` | ✅ | Only for pickups they *raised*, not accepted |
| `POST /api/v1/listings` | ✅ | A collector **can sell** on the marketplace |
| `GET /api/v1/listings`, `/mine`, `/{id}` | ✅ | |
| `POST /api/v1/listings/{id}/cancel` | ✅ | Their own listings |
| **`POST /api/v1/listings/{id}/interested`** | ❌ **403** | **Recycler only — a collector cannot buy** |
| `GET /api/v1/wallet` | ✅ | Starts at 0; only marketplace sales credit it |
| `POST /api/v1/detections`, `GET /api/v1/detections` | ✅ | |
| `GET /api/v1/collection-points/**` | ✅ | Public |
| `GET /api/v1/leaderboard` | ✅ | Public |
| `POST /api/v1/chat` | ✅ | Collector-specific tools |
| `GET /api/v1/admin/**` | ❌ 403 | Admin only |

The one refusal returns:

```json
{ "error": "You do not have permission to perform this action" }
```

> **A collector selling on the marketplace is real, not a loophole.** Verified live: a collector
> token created a listing and got `201` with `seller.role: "COLLECTOR"`. Whether you expose it
> in the collector app is a product decision, but the API allows it.

---

## 2. Conventions

Auth, error shape, pagination, money and timestamp formats are identical to the citizen API —
see [`citizen-apis.md` §1](citizen-apis.md#1-conventions). In brief:

- Bearer token, valid **7 days**
- Errors are always `{ "error": "human readable message" }`
- Lists take `?page=0&size=20`, **zero-based**, `size` capped at 100
- Money is INR, weights are kg, timestamps are ISO-8601 UTC

---

## 3. A collector's day

```text
login
  |
  v
GET /api/v1/pickups/available          what is up for grabs
  |
  v
POST /api/v1/pickups/{id}/accept       first come, first served
  |                                    -> winner 200, everyone else 409
  |                                    -> the citizen can no longer cancel
  |
  +--- accept a few more ---+
  |                         |
  v                         v
GET /api/v1/routes/my-route            depot -> optimised stops -> depot
  |                                    real driving order, polyline, load vs capacity
  |
  v
drive the route, at each stop weigh the load
  |
  v
POST /api/v1/pickups/{id}/complete     { finalWeightKg, finalAmount }
  |                                    -> citizen gets 20 bonus + 5/kg (8/kg for drop-off)
  |
  +--- cannot make it? ---> POST /api/v1/pickups/{id}/release
                                       -> back to REQUESTED for another collector
```

---

## 4. Auth

Identical to the citizen flow — `POST /auth/login`, `POST /auth/google`, `GET /auth/me`. See
[`citizen-apis.md` §4](citizen-apis.md#4-auth).

A collector account is normally **created by a municipal admin**, not self-registered, so the
collector app usually only needs login, not the OTP registration flow.

`GET /auth/me` returns `role: "COLLECTOR"` — use it to route to the collector shell on launch.

---

## 5. Finding work

### `GET /api/v1/pickups/available` 🔒 **collector only**

Unassigned pickups anyone can claim, newest first.

| Param | Default | Notes |
| --- | --- | --- |
| `page` | 0 | zero-based |
| `size` | 20 | capped at 100 |

**Response `200`**

```json
{
  "items": [
    {
      "id": "e84e7d6a-737b-4cad-bbeb-a326c34910ea",
      "detectionId": "4d3342ad-ecc1-4542-9fe9-97586ed937b8",
      "status": "REQUESTED",
      "mode": "DOORSTEP",
      "collectionPointId": null,
      "rewardPoints": 2,
      "rewardAwarded": false,
      "cancellable": true,
      "location": {
        "address": "22 Andul Road, Shibpur",
        "landmark": "Near Botanic Garden",
        "latitude": 22.562,
        "longitude": 88.29
      },
      "contact": { "phone": "9800000003", "notes": null },
      "waste": { "totalObjects": 13, "materials": "PET Bottle x13" },
      "money": {
        "currency": "INR",
        "estimatedOffer": 9.75,
        "finalAmount": null,
        "finalWeightKg": 0.39
      },
      "collector": null,
      "citizen": {
        "id": "644663bf-aeb8-40c2-b624-1cc256233567",
        "fullName": "Anil Citizen",
        "email": "chat.citizen@greentech.local"
      },
      "cancelReason": null,
      "cancelledBy": null,
      "collectorNotes": null,
      "preferredTime": null,
      "createdAt": "2026-08-08T22:10:13.365219Z",
      "acceptedAt": null,
      "completedAt": null,
      "cancelledAt": null
    }
  ],
  "page": 0,
  "size": 2,
  "totalItems": 3,
  "totalPages": 2,
  "hasMore": true
}
```

#### What to show on the job card

- **`waste.materials`** (`"PET Bottle x13"`) and **`waste.totalObjects`** — what they are picking
  up. This is the headline.
- **`money.finalWeightKg`** is the **estimated** weight while unaccepted (`0.39` here). It is
  reused as the final weight field after completion, so **label it "est."** until
  `status` is `COMPLETED`.
- **`money.estimatedOffer`** is what the citizen was quoted, not what the collector must pay.
  The collector sets the real figure at completion.
- **`location.latitude`/`longitude`** — plot the job on a map and show distance from the
  collector's current position.
- **`collector` is `null`** on every row here by definition — this list is only unclaimed work.
- **`contact.phone`** is visible before accepting. If that is a privacy concern, mask it in the
  UI until accepted.

> ⚠️ **`rewardPoints` here is a partial estimate.** Before completion it is
> `weight × rate` only — the flat completion bonus is **not** included. In this row 0.39 kg × 5
> = 2. After completion it is recalculated as `finalWeight × rate + 20`. Do not present the
> pre-completion number to the citizen as what they will earn.

**This list is a snapshot.** Another collector may take a job seconds after it renders. Refresh
on pull-to-refresh and on returning to the screen, and handle the `409` in §6 gracefully.

---

## 6. Claiming a pickup

### `POST /api/v1/pickups/{id}/accept` 🔒 **collector only**

No request body.

**Response `200`** — the pickup, now with `status: "ACCEPTED"`, `cancellable: false`,
`acceptedAt` set, and `collector` populated with the caller.

**Errors**

| Status | Message | Meaning |
| --- | --- | --- |
| `409` | `This pickup has already been accepted by another collector` | You lost the race |
| `409` | `This pickup was cancelled` | The citizen pulled it first |
| `403` | `You cannot accept your own pickup request` | Collector raised it themselves |
| `404` | `Pickup not found` | Bad id |

#### Acceptance is atomic — design for losing

Claiming runs as a **single conditional UPDATE** in the database:

```sql
update pickups set collector_id = ?, status = 'ACCEPTED'
 where id = ? and status = 'REQUESTED' and collector_id is null
```

Exactly one caller can match that condition. This was verified under load: **six collectors
tapping Accept on the same pickup produced one `200` and five `409`s** — no double assignment,
no partial state.

For the UI that means:

1. Losing is **normal**, not an error state. Show something soft — *"Someone got there first"* —
   remove the row, and refresh the list.
2. Never optimistically mark a job as yours before the `200` lands.
3. Disable the button while the request is in flight so a double-tap cannot fire twice.

#### Accepting locks the citizen out

The moment this succeeds, the citizen's Cancel button dies — their `cancellable` flips to
`false` and any cancel attempt returns `409`.

> **Only accept what you can actually collect.** A citizen who cannot cancel is relying on the
> collector to turn up, and the only way back is [§9 Release](#9-releasing-a-pickup). Worth a
> confirmation dialog on the Accept button.

---

## 7. The optimised route

### `GET /api/v1/routes/my-route` 🔒 **collector only**

| Param | Required | Notes |
| --- | --- | --- |
| `municipalityCode` | — | e.g. `HMC`. Omit and the depot is inferred from the accepted pickups |

Builds a driving route over **every pickup the collector currently has `ACCEPTED`** that has
coordinates. It starts and ends at the municipality depot.

**Response `200`** — a real three-stop route across Howrah:

```json
{
  "depot": {
    "municipalityCode": "HMC",
    "name": "Howrah Municipal Corporation Depot",
    "lat": 22.5892,
    "lon": 88.3103
  },
  "stops": [
    {
      "sequence": 1,
      "type": "DOORSTEP",
      "collectionPointId": null,
      "pickupIds": ["5ccaf7e8-29a9-4263-8ed2-a252270f4db5"],
      "address": "88 Grand Trunk Road, Salkia",
      "lat": 22.6045,
      "lon": 88.339,
      "pickupCount": 1,
      "weightKg": 0.39
    },
    {
      "sequence": 2,
      "type": "DOORSTEP",
      "collectionPointId": null,
      "pickupIds": ["1c6ea05c-88a4-4201-8743-ad01e9da2e34"],
      "address": "14 Belilious Road, Howrah",
      "lat": 22.5958,
      "lon": 88.2636,
      "pickupCount": 1,
      "weightKg": 0.39
    },
    {
      "sequence": 3,
      "type": "DOORSTEP",
      "collectionPointId": null,
      "pickupIds": ["e84e7d6a-737b-4cad-bbeb-a326c34910ea"],
      "address": "22 Andul Road, Shibpur",
      "lat": 22.562,
      "lon": 88.29,
      "pickupCount": 1,
      "weightKg": 0.39
    }
  ],
  "totalRequests": 3,
  "totalStops": 3,
  "plannedLoadKg": 1.17,
  "vehicleCapacityKg": 80,
  "deferredPickupIds": [],
  "distanceKm": 25.54,
  "durationMinutes": 83.8,
  "geometry": "y}zhCi`_zOo@IsAMPuAZ_AJ_@eCwAgBcAiAk@oBcAgB}@GEuAu@WM_Ai@KEm..."
}
```

### How the route is built

Five things happen server-side, and each shows up in the response:

**1. The depot is resolved.** Explicit `municipalityCode` wins; otherwise it comes from the
first accepted pickup's municipality; otherwise the first active municipality. The route always
begins and ends here.

**2. Drop-offs sharing a collection point merge into one stop.** Five citizens dropping at the
same bin cluster produce **one** stop with five entries in `pickupIds` and `pickupCount: 5`.
That is why `totalRequests` (3) and `totalStops` (3) are separate numbers — they diverge as soon
as drop-offs are involved. **Render `pickupCount` on the stop card**, and expect to collect
several parcels at one address.

**3. Vehicle capacity is enforced.** Stops are added until `plannedLoadKg` would exceed
`vehicleCapacityKg` (80 kg, configurable via `VEHICLE_CAPACITY_KG`). Anything that does not fit
goes to `deferredPickupIds` — still assigned to the collector, just not on this run. **Show a
load gauge** (`plannedLoadKg` / `vehicleCapacityKg`) and a "deferred to the next trip" section
when that array is non-empty.

**4. The order is optimised for real driving time.** The server calls the Mapbox Matrix API for
the full depot-plus-stops travel-time matrix, then runs nearest-neighbour followed by **2-opt**
improvement. Look at the result above: the stops are *not* in the order they were accepted, and
not in distance order from the depot — Salkia first, then Belilious, then Shibpur, because that
is the fastest loop.

**5. A polyline is returned.** `geometry` is an **encoded polyline** (~1,800 characters here)
from the Mapbox Directions API. Decode it with any standard polyline library and draw it on the
map. Do not try to draw straight lines between stops — the polyline follows actual roads.

### Limits and fallbacks

| Situation | Behaviour |
| --- | --- |
| More than 24 stops | Mapbox Matrix caps at **25 coordinates**, so the route is trimmed to 24 stops plus the depot; the rest move to `deferredPickupIds` |
| Mapbox unreachable | Stops fall back to **straight-line order from the depot**; `distanceKm`, `durationMinutes` and `geometry` come back `null` |
| Mapbox token not set | Same fallback, silently |

**Always null-check `distanceKm`, `durationMinutes` and `geometry`.** They are the first things
to disappear when the routing provider has a bad day, and the rest of the route is still
perfectly usable without them.

**Errors**

| Status | Message |
| --- | --- |
| `404` | `You have no accepted pickups with a location to build a route from` |
| `404` | `Unknown municipality code` |
| `400` | `No municipality depot is configured. Pass municipalityCode.` |

That first `404` is the **normal empty state**, not a failure — a collector who has not accepted
anything yet will always see it. Show "Accept some jobs to build a route", not an error.

---

## 8. Completing a pickup

### `POST /api/v1/pickups/{id}/complete` 🔒 **collector only**

The collector weighs the load and settles the price. **This is the moment the citizen's reward
is calculated**, so the numbers matter.

**Request**

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `finalWeightKg` | number | ✅ | ≥ 0, up to 3 decimals |
| `finalAmount` | number | ✅ | ≥ 0, INR |
| `collectorNotes` | string | — | max 300 |

```json
{
  "finalWeightKg": 3.200,
  "finalAmount": 128.00,
  "collectorNotes": "Clean PET, well segregated"
}
```

**Response `200`** — real capture:

```json
{
  "id": "1c6ea05c-88a4-4201-8743-ad01e9da2e34",
  "status": "COMPLETED",
  "rewardPoints": 36,
  "rewardAwarded": true,
  "money": {
    "currency": "INR",
    "estimatedOffer": 9.75,
    "finalAmount": 128.0,
    "finalWeightKg": 3.2
  },
  "collectorNotes": "Clean PET, well segregated",
  "completedAt": "2026-08-08T22:10:50.869206207Z"
}
```

### The points formula

Green Points are credited to the **citizen** the instant this returns:

```text
points = round(finalWeightKg × rate) + completionBonus

rate = 5  for DOORSTEP
rate = 8  for DROP_OFF
completionBonus = 20
```

The example checks out: `3.2 × 5 = 16`, `+ 20` bonus `= 36`. ✅

Note how far the estimate was from reality — the photo suggested `0.39 kg` and `INR 9.75`, the
scale said `3.2 kg` and the collector paid `INR 128.00`. **The weighed figure always wins**;
the estimate is only ever a starting point for conversation.

`rewardAwarded` guards against double-crediting — a repeated completion cannot award twice.

> **Show a confirmation step before submitting.** Completion is irreversible: there is no
> "un-complete" endpoint, points are credited immediately, and the status is terminal. A
> mistyped weight cannot be corrected through the API.

**Errors**

| Status | Message |
| --- | --- |
| `409` | `Only an accepted pickup can be completed` |
| `403` | `This pickup is not assigned to you` |
| `400` | `finalWeightKg: cannot be negative` / `finalAmount: cannot be negative` |
| `404` | `Pickup not found` |

---

## 9. Releasing a pickup

### `POST /api/v1/pickups/{id}/release` 🔒 **collector only**

The way out when a collector accepted something they cannot service. The pickup goes **back into
the open pool** for another collector.

**Request** (body optional)

```json
{ "reason": "Vehicle breakdown" }
```

**Response `200`** — real capture:

```json
{
  "id": "5ccaf7e8-29a9-4263-8ed2-a252270f4db5",
  "status": "REQUESTED",
  "cancellable": true,
  "collector": null,
  "acceptedAt": null,
  "collectorNotes": "Vehicle breakdown"
}
```

Everything is rewound: `status` back to `REQUESTED`, `collector` cleared, `acceptedAt` cleared,
and the citizen's `cancellable` back to `true`.

> ⚠️ **The reason lands in `collectorNotes`, not `cancelReason`.** `cancelReason` stays `null`
> because nothing was cancelled. If you show a "why was this released?" line, read
> `collectorNotes`.

A released pickup **disappears from the collector's own list** (§10), because that list is keyed
on assignment. It reappears in `/available` for everyone.

**Errors**

| Status | Message |
| --- | --- |
| `409` | `Only an accepted pickup can be released` |
| `403` | `This pickup is not assigned to you` |

---

## 10. My pickups

### `GET /api/v1/pickups?page=0&size=20` 🔒

Same URL the citizen uses, but **the server switches on role** — a collector gets the pickups
**assigned to them**, in every state:

```text
totalItems 3
  ACCEPTED   22 Andul Road, Shibpur
  COMPLETED  14 Belilious Road, Howrah
  COMPLETED  14 Belilious Road, Howrah
```

Full object shape is identical to §5. Filter client-side on `status` to build tabs:

| Tab | Filter | Purpose |
| --- | --- | --- |
| Today's jobs | `ACCEPTED` | The work queue — matches the route stops |
| History | `COMPLETED` | Earnings and past collections |

Released pickups are **absent** — they are no longer assigned.

### `GET /api/v1/pickups/{id}` 🔒

One pickup, same shape. Use for the stop detail screen and to re-check status before completing.

---

## 11. Marketplace and wallet

A collector has **partial** marketplace access. Verified live:

| Action | Collector | Result |
| --- | --- | --- |
| Create a listing | ✅ `201` | `seller.role: "COLLECTOR"` |
| Browse / view listings | ✅ | |
| Withdraw own listing | ✅ | |
| **Buy a listing** | ❌ `403` | `You do not have permission to perform this action` |

Shapes are identical to the citizen doc —
see [`citizen-apis.md` §8](citizen-apis.md#8-marketplace-and-wallet).

### `GET /api/v1/wallet` 🔒

```json
{ "balance": 0.0, "currency": "INR", "totalEarned": 0, "totalSpent": 0, "greenPoints": 0, "transactions": [] }
```

A fresh collector is empty, and stays empty in normal use. **This is the single most
misunderstood endpoint for this role**, so to be explicit:

> **Money a collector pays out at a pickup does NOT flow through the wallet.** `finalAmount` is
> recorded on the pickup and settled in cash between collector and citizen. The wallet ledger
> only ever records **marketplace trades**.

So a collector's earnings screen should sum `money.finalAmount` over their `COMPLETED` pickups
from §10 — **not** read the wallet. The wallet is only relevant if they also sell scrap.

---

## 12. Scanning, points and leaderboard

A collector holds a normal account and can use the citizen features for their own household:

- `POST /api/v1/detections` — scan waste, earn points
- `GET /api/v1/detections` — their scan history with lifetime `totals`
- `POST /api/v1/pickups` — raise their *own* pickup (they cannot then accept it: `403`)
- `GET /api/v1/collection-points/nearest?lat=&lon=` — nearest drop-off points, ranked by real
  driving time
- `GET /api/v1/leaderboard` — collectors appear alongside citizens, with `role: "COLLECTOR"`

All shapes are in [`citizen-apis.md`](citizen-apis.md).

`/collection-points/nearest` is worth surfacing in the collector app for a different reason than
the citizen app: it locates **MRFs and scrap yards** where a full vehicle can be unloaded
mid-route.

---

## 13. Assistant chatbot

`POST /api/v1/chat` 🔒 — same contract as the citizen assistant
([`citizen-apis.md` §10](citizen-apis.md#10-assistant-chatbot)), but a collector gets
**collector-specific tools**: open jobs, their assigned work, route summary, load against
capacity, and their collection stats.

`GET /api/v1/chat/capabilities` returns collector prompts to seed the empty state:

```json
{
  "enabled": true,
  "role": "COLLECTOR",
  "suggestions": [
    "What pickups can I accept right now?",
    "What does my route look like today?",
    "How much have I collected this month?",
    "How close am I to vehicle capacity?"
  ]
}
```

Real answers from a live collector token:

> **Q: Show me my completed pickups**
> "You have one completed pickup: Mode Doorstep, Materials 13 PET Bottles, Weight 2.4 kg,
> Amount Earned INR 96.00, Reward Points 32, Address 14 Belilious Road, Howrah."

> **Q: What does my route look like?**
> "It seems you currently have no accepted pickups, so there's no route available to display.
> Please accept some pickup requests to generate a route."

Send `pickupId` in the request body when a job is open on screen, so *"how far is this one?"*
resolves without the user restating it.

Every number the assistant gives comes from a live query — `toolsUsed` in the response names
which one.

---

## 14. Error catalogue

| Status | When | How the UI should react |
| --- | --- | --- |
| `400` | Validation failure on complete | Inline error on the weight/amount field |
| `401` | Missing or expired token | Clear session, go to login |
| `403` | `This pickup is not assigned to you` | Refetch; someone else holds it |
| `403` | `You cannot accept your own pickup request` | Hide Accept on own jobs |
| `403` | `You do not have permission to perform this action` | Buying a listing — not for collectors |
| `404` | `You have no accepted pickups with a location…` | **Empty state, not an error** |
| `409` | `This pickup has already been accepted by another collector` | **Normal.** Soft message, refresh the list |
| `409` | `Only an accepted pickup can be completed` / `released` | Stale screen — refetch |
| `503` | Detection service unavailable | Retry state on the scan screen |

**The two `409`s and the routing `404` are the ones that decide whether the app feels solid.**
None of them is a bug: they mean the world moved on while a screen was open. Refetch and show a
calm message rather than a red error.

---

## 15. Screen to endpoint map

| Screen | Endpoints | Notes |
| --- | --- | --- |
| Splash | `GET /auth/me` | Route on `role: "COLLECTOR"` |
| Login | `POST /auth/login` | Accounts are admin-created; no OTP flow needed |
| Available jobs | `GET /api/v1/pickups/available` | Refresh often; handle 409 on accept |
| Job detail | `GET /api/v1/pickups/{id}`, `POST /{id}/accept` | Confirm before accepting |
| Today's route | `GET /api/v1/routes/my-route` | Decode `geometry`; show load gauge |
| Stop detail | *(reuse the route stop)* | `pickupCount` > 1 means several parcels |
| Complete job | `POST /api/v1/pickups/{id}/complete` | Irreversible — confirm the weight |
| Release job | `POST /api/v1/pickups/{id}/release` | Reason lands in `collectorNotes` |
| My work / history | `GET /api/v1/pickups` | Filter `ACCEPTED` vs `COMPLETED` |
| Earnings | `GET /api/v1/pickups` | Sum `money.finalAmount` — **not** the wallet |
| Sell scrap | `POST /api/v1/listings`, `GET /listings/mine` | Allowed; buying is not |
| Assistant | `POST /api/v1/chat` | Send `pickupId` for on-screen context |

### Things that will bite you if unnoticed

1. **Losing the accept race is normal** — six simultaneous taps give one `200` and five `409`s.
   Design for it.
2. **`rewardPoints` before completion excludes the 20-point bonus.** Do not quote it.
3. **`totalRequests` ≠ `totalStops`** once drop-offs are involved — merged stops carry several
   `pickupIds`.
4. **`geometry`, `distanceKm` and `durationMinutes` can all be `null`** when Mapbox is
   unreachable. The route still works; the map overlay does not.
5. **Route stops are not in acceptance order** — they are 2-opt optimised. Never re-sort them.
6. **Completion is irreversible** and credits points immediately.
7. **The wallet is not the collector's earnings.** Pickup money never enters it.
8. **A route caps at 24 stops** (Mapbox's 25-coordinate matrix limit); the surplus lands in
   `deferredPickupIds`.
9. **Release ≠ cancel.** The reason is stored in `collectorNotes`, and the job returns to the
   open pool.
