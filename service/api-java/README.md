# api-java — GreenRoute Core API

Spring Boot 3.5 / Java 17 / PostgreSQL. The system of record for users, points, pickups,
routing, the marketplace and the assistant. Detection itself lives in the Python service
(`service/api-python`); this service authenticates the caller, forwards the image, stores the
result and decides what it is worth.

**109 source files · 45 endpoints · 9 entities · 139 tests**

Deployed at **[console.jotterly.tech](https://console.jotterly.tech/health)** behind nginx.

---

## Contents

- [Architecture](#architecture)
- [Run](#run)
- [Endpoints](#endpoints)
- [Auth](#auth)
- [Detections](#detections)
- [Pickups](#pickups)
- [Admin console API](#admin-console-api)
- [Marketplace and wallet](#marketplace-and-wallet)
- [Green Points and leaderboard](#green-points-and-leaderboard)
- [Mail switch](#mail-switch)
- [Collection points and maps](#collection-points-and-maps)
- [Route optimisation](#route-optimisation)
- [Database](#database)
- [Points](#points)
- [Assistant](#assistant)
- [Docker](#docker)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Errors](#errors)
- [Testing](#testing)
- [Project structure](#project-structure)

---

## Architecture

```text
mobile / web app
      |
      | JWT
      v
api-java  (:8080)  ── auth, users, points, scan history ──> PostgreSQL
      |
      | multipart, server to server, no auth header
      v
api-python (:8000) ── YOLO detection, pricing, bins ──> Cloudinary
```

The Python service is **never called by the client directly**. It has no auth of its own, so
it must not be exposed publicly — only this service should be able to reach it. In production
put it on a private network or bind it to localhost.

Why this split: detection is CPU-heavy and stateless, auth and history are transactional.
Keeping them apart means the detection service can be restarted, scaled or swapped for a
GPU box without touching user data.

---

## Run

```bash
cp .env.example .env      # fill JWT_SECRET, GOOGLE_CLIENT_ID, RESEND_API_KEY, DB creds
createdb greentech
mvn spring-boot:run
```

`.env` is loaded automatically (spring-dotenv). Schema is created by Hibernate
(`DDL_AUTO=update`); there is no Flyway here, so never set `validate`.

**`update` only ever adds.** It will not drop a `NOT NULL`, a unique constraint or a column.
Both have already bitten this project: making `contact_phone` nullable for drop-offs, and
allowing a scan to be re-requested after cancellation, each needed a manual `ALTER TABLE`
against an existing database. Tests never catch it because H2 runs `create-drop`. On a fresh
database none of this applies.

The Python detection service must be running for `/api/v1/detections` to work:

```bash
cd ../api-python && .venv/bin/uvicorn app.main:app --port 8000
```

If it is down, scans return **503** and nothing is stored. Auth endpoints are unaffected.

---

## Endpoints

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/send-otp` | public | email a 6-digit signup code |
| POST | `/auth/register` | public | verify OTP, create account, return JWT |
| POST | `/auth/login` | public | email + password, return JWT |
| POST | `/auth/google` | public | Google ID token, return JWT |
| GET | `/auth/me` | Bearer | current user profile |
| POST | `/api/v1/detections` | Bearer | scan a waste photo |
| GET | `/api/v1/detections` | Bearer | scan history, paginated |
| POST | `/api/v1/pickups` | Bearer | request a pickup for a scan |
| GET | `/api/v1/pickups` | Bearer | pickup history, scoped by role |
| GET | `/api/v1/pickups/available` | COLLECTOR | open pickups waiting for a collector |
| GET | `/api/v1/pickups/{id}` | Bearer | one pickup |
| POST | `/api/v1/pickups/{id}/accept` | COLLECTOR | claim a pickup |
| POST | `/api/v1/pickups/{id}/complete` | COLLECTOR | record final weight and amount |
| POST | `/api/v1/pickups/{id}/release` | COLLECTOR | hand an accepted pickup back |
| POST | `/api/v1/pickups/{id}/cancel` | Bearer | citizen cancels, only before acceptance |
| GET | `/api/v1/collection-points/nearest` | public | nearest drop-off points by road time |
| GET | `/api/v1/collection-points` | public | all seeded points |
| GET | `/api/v1/collection-points/municipalities` | public | municipalities and depots |
| GET | `/api/v1/routes/my-route` | COLLECTOR | optimised route for accepted pickups |
| GET | `/api/v1/leaderboard` | public | Green Points ranking, `me` block when authenticated |
| POST | `/api/v1/listings` | Bearer | list waste for sale |
| GET | `/api/v1/listings` | Bearer | browse open listings |
| GET | `/api/v1/listings/mine` | Bearer | my listings, or my purchases if RECYCLER |
| GET | `/api/v1/listings/{id}` | Bearer | one listing |
| POST | `/api/v1/listings/{id}/interested` | RECYCLER | buy it |
| POST | `/api/v1/listings/{id}/cancel` | Bearer | seller withdraws |
| GET | `/api/v1/wallet` | Bearer | balance + payment history |
| GET | `/api/v1/admin/overview` | ADMIN | dashboard stats, 14-day trend, charts |
| GET/POST | `/api/v1/admin/users` | ADMIN | list, search, create staff accounts |
| PATCH | `/api/v1/admin/users/{id}` | ADMIN | enable / disable an account |
| GET/POST | `/api/v1/admin/collection-points` | ADMIN | manage the point network, scoped by municipality |
| PATCH/DELETE | `/api/v1/admin/collection-points/{id}` | ADMIN | edit / retire a point |
| GET | `/api/v1/admin/municipalities` | ADMIN | list municipalities |
| POST/PATCH | `/api/v1/admin/municipalities` | SUPER_ADMIN | create / edit a municipality |
| GET | `/health` | public | liveness |

Full spec in [docs/openapi.yml](docs/openapi.yml) — import it into Postman or paste it into
[editor.swagger.io](https://editor.swagger.io).

---

## Auth

JWT access tokens only, 7-day TTL, no refresh tokens. The token carries the user id as `sub`
and the role as a `role` claim; clients should read role and points from the response body
rather than decoding the JWT.

### Roles

```java
CITIZEN, COLLECTOR, RECYCLER, MUNICIPAL_ADMIN, SUPER_ADMIN
```

`role` is optional at signup and defaults to `CITIZEN`. Only `CITIZEN`, `COLLECTOR` and
`RECYCLER` can be self-assigned — the two admin roles return **403** and must be set directly
in the database.

### Auth response

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 604800,
  "user": { "id": "uuid", "email": "john@gmail.com", "fullName": "John Doe",
            "role": "CITIZEN", "points": 120 }
}
```

`GET /auth/me` returns the `user` object alone.

### Mail (Resend)

- **OTP** — sent synchronously by `/auth/send-otp`; a delivery failure returns 502 rather than
  a misleading "sent".
- **Welcome** — after register, and after a first Google sign-in.
- **Sign-in alert** — after every returning login, with time and client IP.

The OTP is also written to the application log so you can test without opening an inbox.
Strip that from `OtpService.generate` before production.

OTPs live in memory with a 10-minute TTL — fine for a single instance, but a restart
invalidates outstanding codes, and two instances behind a load balancer would not share them.

---

## Detections

### POST /api/v1/detections

`multipart/form-data`, one part named `image`. Same body shape as the Python service, with a
JWT on top.

```bash
curl -X POST http://localhost:8080/api/v1/detections \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@bin.jpg"
```

In Postman: Body → form-data → key `image`, switch its type from **Text** to **File**. Do not
set `Content-Type` manually — Postman must generate the multipart boundary.

Response:

```json
{
  "id": "f02283a6-9c35-438b-8f7f-54dfc84e1b4f",
  "eligible": true,
  "status": "MANUAL_PRICING_REQUIRED",
  "message": "13 waste items detected across 1 material. Offer up to INR 11.21; ...",
  "actionRequired": "COLLECTOR_SETS_PRICE",
  "imageUrl": "https://res.cloudinary.com/.../ab12.jpg",
  "totalObjects": 13,
  "totalRewardPoints": 65,
  "pointsAwarded": true,
  "userPointsBalance": 65,
  "offer": { "currency": "INR", "minimumOffer": 8.29, "estimatedOffer": 9.75,
             "maximumOffer": 11.21, "status": "PENDING_COLLECTOR_CONFIRMATION",
             "finalPriceSetBy": "COLLECTOR" },
  "impact": { "estimatedWeightKg": 0.39, "carbonSavedKg": 1.95,
              "landfillReducedKg": 0.39, "recyclablePercent": 100 },
  "recommendation": { "primaryBin": "BLUE", "secondaryBin": null, "pickupRecommended": true },
  "quality": { "detectionQuality": "MEDIUM", "averageConfidence": 0.58 },
  "aiSummary": "13 PET Bottles detected. These are fully recyclable ...",
  "processingTimeMs": 1800,
  "materials": [
    { "material": "PET Bottle", "category": "PLASTIC", "stream": "DRY", "bin": "BLUE",
      "recyclable": true, "count": 13, "pricePerKg": 25, "estimatedWeightKg": 0.39,
      "estimatedValue": 9.75, "rewardPoints": 65, "carbonSavedKg": 1.95 }
  ],
  "createdAt": "2026-08-08T05:36:43Z"
}
```

**Check `eligible` first.** `false` means the photo cannot be submitted — show `message` and
reopen the camera. Everything else is detail.

| status | eligible | meaning |
| --- | --- | --- |
| `OK` | `true` | one material, priced by the system |
| `MANUAL_PRICING_REQUIRED` | `true` | real waste, but the collector confirms the price |
| `NO_WASTE_DETECTED` | `false` | person, animal, empty scene — retake |
| `LOW_CONFIDENCE` | `false` | too blurry or too far — retake |

**Ineligible scans are still stored**, so history is a complete record of what the user tried.
They simply award nothing (`pointsAwarded: false`).

### GET /api/v1/detections

```bash
curl "http://localhost:8080/api/v1/detections?page=0&size=20" -H "Authorization: Bearer $TOKEN"
```

```json
{
  "items": [
    { "id": "...", "status": "OK", "eligible": true, "totalObjects": 2,
      "totalRewardPoints": 40, "pointsAwarded": true, "estimatedOffer": 180.00,
      "primaryBin": "RED", "materials": ["E-Waste x2"], "createdAt": "2026-08-08T05:37:00Z" }
  ],
  "page": 0, "size": 20, "totalItems": 3, "totalPages": 1, "hasMore": false,
  "totals": { "scans": 3, "objects": 15, "rewardPoints": 105,
              "carbonSavedKg": 4.35, "estimatedEarnings": 189.75 }
}
```

Newest first. **Scoped to the caller** — a user can never see another user's scans; the user
id comes from the JWT, never from a parameter.

`totals` is computed with aggregate SQL across the user's **entire** history, not just the
current page, so a profile screen needs one call rather than walking every page. `materials`
is compacted to display labels (`"PET Bottle x13"`) because a history row does not need the
full breakdown.

`size` is clamped to 1–100 and `page` to 0 or above, so a hostile `?size=100000` cannot pull
the table into memory. A non-numeric `?page=abc` returns 400, not 500.

History runs as two queries: one pages the detection ids, the second fetches only that page
with its materials. Fetching a collection and paginating in a single query makes Hibernate
load every matching row into memory and paginate in Java (`HHH90003004`), which is fine at
3 rows and fatal at 10,000.

---

## Pickups

The step after a scan: the citizen asks for the waste to be collected.

### Lifecycle

```text
                    citizen                       collector
                       |                              |
  scan (eligible) -> POST /pickups                    |
                       |                              |
                   REQUESTED  ------ appears in --> /pickups/available
                    /      \                          |
        POST /cancel        \                 POST /{id}/accept
              |              \                        |
          CANCELLED           +------------------> ACCEPTED
              |                                    /       \
   can request again                POST /{id}/release   POST /{id}/complete
   from the same scan                      |                    |
                                       REQUESTED            COMPLETED
```

| status | meaning | who can act |
| --- | --- | --- |
| `REQUESTED` | waiting in the open feed | citizen may cancel, any collector may accept |
| `ACCEPTED` | claimed by a collector | that collector may complete or release |
| `COMPLETED` | collected, final weight and amount recorded | terminal |
| `CANCELLED` | withdrawn before acceptance | terminal, but the scan can be re-requested |

### The cancellation rule

**A citizen can cancel only while the status is `REQUESTED`.** Once a collector accepts, the
collector may already be travelling, so `POST /{id}/cancel` returns **409**:

```json
{ "error": "A collector has already accepted this pickup and it can no longer be cancelled." }
```

The response carries `cancellable` so a client can drive its cancel button from one boolean
instead of comparing status strings.

If a collector genuinely cannot make it, they call `/release` rather than cancelling. The
pickup returns to `REQUESTED` and reappears in the open feed, so the citizen keeps their
request instead of being dropped.

### Concurrency

Acceptance is a single atomic `UPDATE … WHERE status = 'REQUESTED' AND collector_id IS NULL`.
Whoever the database applies first wins; everyone else affects 0 rows and gets **409**.

This matters. A read-then-write version passed every sequential test but, when six collectors
tapped Accept at the same instant, returned **200 to all six** — five of them would have
driven to an address for waste that was already claimed.

### Collector notification

Creating a pickup emails **every registered collector** (`@Async`, so a slow mail provider
never delays the response) and puts it in `GET /api/v1/pickups/available`. Acceptance is
first-come-first-served: the second collector to try gets **409**. When a collector accepts,
the citizen is emailed the collector's name.

For a production deployment you would replace the broadcast email with push notifications
scoped to a service area — the email is a placeholder that demonstrates the flow.

### Request

```bash
curl -X POST http://localhost:8080/api/v1/pickups \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"detectionId":"66dbf633-...","address":"12 Park Street, Kolkata 700016",
       "landmark":"Near metro gate 3","contactPhone":"+919876543210",
       "notes":"Ring the bell twice"}'
```

```json
{
  "id": "…", "detectionId": "…", "status": "REQUESTED", "cancellable": true,
  "location": { "address": "12 Park Street, Kolkata 700016", "landmark": "Near metro gate 3",
                "latitude": null, "longitude": null },
  "contact":  { "phone": "+919876543210", "notes": "Ring the bell twice" },
  "waste":    { "totalObjects": 13, "materials": "PET Bottle x13" },
  "money":    { "currency": "INR", "estimatedOffer": 9.75,
                "finalAmount": null, "finalWeightKg": null },
  "collector": null,
  "citizen": { "id": "…", "fullName": "Citizen One", "email": "citizen@example.com" },
  "createdAt": "2026-08-08T07:04:11Z", "acceptedAt": null,
  "completedAt": null, "cancelledAt": null
}
```

Waste details and the estimated offer are **copied from the scan** at request time, so
changing pricing rules later cannot alter an already-agreed request.

### Rules enforced

- The scan must exist, belong to the caller, and be `eligible` — an ineligible scan is a 400.
- One **active** pickup per scan; a cancelled one frees the scan to be requested again.
- A collector can only complete or release a pickup assigned to them (403 otherwise).
- A pickup that was never accepted cannot be completed (409).
- `GET /{id}` returns **404**, not 403, to a stranger — the existence of a pickup is not leaked.
- A collector cannot accept a pickup they requested themselves (403) — no self-dealing.
- Releasing a pickup is not a cancellation: `cancelledBy`, `cancelReason` and `cancelledAt`
  stay null, because the request is still live.
- State is checked before ownership, so an unaccepted pickup reports 409 "accept it first"
  rather than a misleading 403.

## Admin console API

Everything under `/api/v1/admin` requires `MUNICIPAL_ADMIN` or `SUPER_ADMIN`. A citizen gets
403, an anonymous caller 401.

### Who can create whom

| Actor | Can create |
| --- | --- |
| `MUNICIPAL_ADMIN` | `COLLECTOR`, `RECYCLER` — inside their own municipality only |
| `SUPER_ADMIN` | all of the above, plus `MUNICIPAL_ADMIN` and `CITIZEN`, anywhere |

Nobody can self-register into a privileged role — `/auth/register` is capped at `CITIZEN`,
`COLLECTOR` and `RECYCLER`, and the two admin roles are rejected there with 403. Admin-created
accounts skip OTP (`emailVerified = true`), so staff log in immediately with the password the
admin set.

### Scoping

A municipal admin's **staff** list is filtered to their own `municipality_id`; a super admin sees
everyone. `overview.scope` returns `MUNICIPALITY` or `PLATFORM` accordingly, so one endpoint
serves both consoles.

**Citizens are deliberately not scoped.** They self-register and have no `municipality_id`, so
filtering them by it returned an empty list to every municipal admin. Only `COLLECTOR`,
`RECYCLER` and `MUNICIPAL_ADMIN` are municipality-owned.

`GET /api/v1/admin/collection-points` is scoped the same way and returns `scope`, the points, and
the relevant `depots` — a municipal admin gets their 100 points and one depot, a super admin gets
all 155 and four. Each point carries `municipalityCode` and `district` so the console can offer an
area filter without a second call.

### System health

`GET /api/v1/admin/system-health` checks each dependency **server-side** and returns status plus
latency for the API, PostgreSQL, the Python detection service, Mapbox and Resend. The Python
service is reached server-to-server, so it needs no CORS configuration and stays unexposed to the
browser. A stopped detection service reports `DOWN`, not a guess.

### Disabling an account

`PATCH /api/v1/admin/users/{id}` with `{"active": false}` takes effect **immediately**:

- the existing JWT stops working on the very next request (the filter drops inactive users)
- a fresh `POST /auth/login` returns **403**, not a token

Retiring a collection point is a **soft delete** (`active = false`) so pickups that already
reference it keep their history.

### Seeded admin accounts

`AdminSeeder` runs after the geo seed and creates one super admin and one municipal admin bound
to `HMC`. **There is no default password** — with `ADMIN_SEED_SUPER_PASSWORD` unset the seeder
logs a warning and creates nothing, so a known credential can never ship by accident.

> **Do not use `#` in a password inside `.env`.** It starts a comment and silently truncates the
> value, which produces a "seeded successfully" log followed by a login that always fails.

## Marketplace and wallet

A citizen lists segregated waste, a recycler taps **Interested**, and money moves. There is no
payment rail — the wallet is a **dummy ledger**, which is enough to demonstrate the whole
circular-economy loop without integrating a gateway.

### Listing

Two ways to create one:

```bash
# from a scan - material, weight, image and description are copied across
curl -X POST /api/v1/listings -H "Authorization: Bearer $TOKEN" \
  -d '{"detectionId":"66dbf633-...","price":120,"location":"Shibpur, Howrah"}'

# manual, no scan attached
curl -X POST /api/v1/listings -H "Authorization: Bearer $TOKEN" \
  -d '{"material":"Plastic","weightKg":15,"price":120,"description":"Clean PET bottles"}'
```

```json
{
  "status": "OPEN", "material": "PET Bottle x13", "weightKg": 0.390,
  "price": 120.00, "pricePerKg": 307.69, "currency": "INR",
  "imageUrl": "https://res.cloudinary.com/.../waste.jpg",
  "description": "13 PET Bottles detected. These are fully recyclable ...",
  "seller": { "fullName": "Rina Das", "role": "CITIZEN" },
  "buyer": null, "mine": true
}
```

`pricePerKg` is derived so buyers can compare listings of different sizes. `imageUrl` falls
back to `MARKET_FALLBACK_IMAGE` when the scan has no Cloudinary photo, so a card never renders
blank. One open listing per scan.

### Buying

`POST /api/v1/listings/{id}/interested` — **recyclers only**. One atomic conditional update
claims the listing, so if several recyclers tap at the same instant exactly one gets 200 and
the rest get 409. A seller cannot buy their own listing.

On success, in the same transaction:

```text
listing        -> SOLD, buyer attached, soldAt stamped
seller wallet  -> CREDIT  INR 120  reason LISTING_SOLD
buyer  wallet  -> DEBIT   INR 120  reason LISTING_PURCHASED
```

### Wallet — `GET /api/v1/wallet`

The payment history, and it works for either side. A citizen sees credits, a recycler sees
debits.

```json
{
  "balance": 120.00, "currency": "INR",
  "totalEarned": 120.00, "totalSpent": 0, "greenPoints": 65,
  "transactions": [
    { "type": "CREDIT", "amount": 120.00, "balanceAfter": 120.00,
      "reason": "LISTING_SOLD", "note": "Sold PET Bottle x13 to Kolkata Recyclers" }
  ]
}
```

Every row carries `balanceAfter`, so the ledger is auditable without replaying it. Green Points
are returned next to the money balance so one call powers a profile screen.

**Recyclers start with a dummy float** (`RECYCLER_STARTING_BALANCE`, default 10,000) credited at
registration. Without it a recycler's first purchase would push them negative, which reads as
broken in a demo even though a payables ledger genuinely works that way.

## Green Points and leaderboard

Points are credited **server-side only**. A client can never send a points value.

| When | Award |
| --- | --- |
| Scan verified | per item, by material (segregation reward) |
| Pickup **completed** | **+20 flat bonus** plus weight x mode rate |
| Doorstep rate | 5 points/kg |
| Drop-off rate | 8 points/kg |

The flat bonus lands on completion regardless of weight, so a tiny drop-off is still worth
making. A 2 kg drop-off pays `20 + (2 x 8) = 36`; the same weight at the door pays
`20 + (2 x 5) = 30`.

Weight comes from the collector's scale (`finalWeightKg`) when present, and the scan estimate
otherwise. `reward_awarded` guards against double-crediting if completion is retried.

All three rates are env-tunable: `COMPLETION_BONUS_POINTS`, `DOORSTEP_POINTS_PER_KG`,
`DROPOFF_POINTS_PER_KG`.

### GET /api/v1/leaderboard

Public, so it renders before sign-in. Plain SQL over `users` and `pickups` — no cache, no
scheduled job, nothing to fall out of sync.

```json
{
  "scope": "ALL_TIME",
  "entries": [
    { "rank": 1, "fullName": "Green One", "role": "CITIZEN",
      "points": 191, "completedPickups": 2, "totalWeightKg": 3.000 }
  ],
  "me": { "rank": 3, "points": 89, "completedPickups": 1, "ahead": 2 },
  "totals": { "citizens": 3, "points": 943, "weightKg": 6.000, "completedPickups": 4 }
}
```

Ranked by points descending, ties broken by who signed up first. Send a token and you also get
a `me` block with your own rank **even if you are outside the returned page** — that is a
separate `count(*) where points > yours`, so the client never has to page to find you.
`totals` aggregates everyone, not just the page. `limit` is clamped to 1-100.

## Mail switch

`MAIL_ENABLED` controls whether anything actually reaches Resend.

| Value | Behaviour |
| --- | --- |
| `true` | real emails — OTP, welcome, sign-in alert, pickup available, pickup accepted |
| `false` | **nothing is sent.** Every flow still works; each suppressed mail is logged as `MAIL DISABLED \| would send to ... \| subject: ...` |

With mail off, signup still works end to end because the OTP is printed to the application log:

```text
com.iem.auth.OtpService : OTP generated for green1@example.com: 289903
```

Read the code from your terminal and pass it to `/auth/register`. Critically, `sendOtpEmail`
does **not** throw its usual 502 when mail is disabled, so `/auth/send-otp` returns 200 and the
flow continues.

This exists because Resend's free tier has a daily quota, and hitting it used to block every
signup. Flip to `true` and everything returns to normal with no other change.

## Collection points and maps

Two collection modes. The citizen chooses per request:

| mode | what happens | reward |
| --- | --- | --- |
| `DOORSTEP` | collector drives to the address | **5 points/kg** |
| `DROP_OFF` | citizen carries waste to a marked point | **8 points/kg** |

Drop-off pays more because it saves the municipality a vehicle trip. Rates are env-tunable
(`DOORSTEP_POINTS_PER_KG`, `DROPOFF_POINTS_PER_KG`) and points are credited on **completion**,
using the collector's weighed figure when available and the scan estimate otherwise.

### Seeded data

155 points and 4 depots, loaded on first boot from `src/main/resources/seed/*.csv`. Seeding is
idempotent — restarting imports nothing, appending rows imports only the new ones.

| Code | Municipality | District | Points |
| --- | --- | --- | --- |
| `HMC` | Howrah Municipal Corporation | Howrah | 100 |
| `BMC` | Bidhannagar Municipal Corporation | North 24 Parganas | 30 |
| `BRK` | Barrackpore Municipality | North 24 Parganas | 25 |
| `ULB` | Uluberia Municipality | Howrah | 0 (depot only) |

Points were generated by geocoding **real localities** — Shibpur, Salkia, Bally, Liluah, Belur,
Santragachi, Tikiapara, Salt Lake, Barrackpore and others — through the Mapbox Geocoding API,
then validated to fall inside district bounds. They are **seeded demo data, not an official
municipal bin register**; say so if asked.

One caution learned the hard way: geocoding administrative names is unreliable. *"Howrah
Municipal Corporation"* resolves to a town in Maharashtra. Locality names resolve correctly.

### Nearest point, two stages

```text
user GPS
   |
   v
haversine shortlist inside geo.search-radius-km   (Postgres, no API call)
   |
   v
top 5 -> Mapbox Matrix API -> ranked by driving time
```

Stage 2 is not decoration. Measured on the real data from a point on the Kolkata bank:

```text
CP-HMC-029   straight 1.44 km   road 2.09 km   x1.5
CP-HMC-026   straight 1.32 km   road 2.25 km   x1.7
```

Across the Hooghly the road is up to 1.7x the straight line, and the nearest point in a
straight line is frequently not the nearest to drive to. Ranking on haversine alone sends
people to the wrong bank of the river.

If Mapbox is unreachable the endpoint falls back to straight-line order and returns
`roadDistanceKm: null` rather than failing.

## Route optimisation

`GET /api/v1/routes/my-route` builds **depot to stops to depot** for one collector's accepted
pickups.

```text
accepted pickups
   |
   v
aggregate: drop-offs sharing a point become ONE stop
   |
   v
fill until vehicle capacity (default 80 kg, by weight not item count)
   |
   v
Mapbox Matrix (driving durations) -> nearest-neighbour + 2-opt
   |
   v
Mapbox Directions -> encoded polyline
```

**Stop aggregation is the efficiency story.** Six drop-off requests at two points is a
**2-stop** route, not 6. That ratio — `totalRequests` vs `totalStops` — is the number to put
on a slide.

Capacity is enforced by **weight**, not item count. Anything that does not fit comes back in
`deferredPickupIds` rather than being silently dropped.

### Why not the Mapbox Optimization API

Optimization v1 accepts **12 coordinates** and supports neither vehicle capacity nor multiple
vehicles; v2 with those features is invite-only beta. So the Matrix API supplies real road
durations and the ordering is solved here. Matrix itself accepts 25 coordinates
(10 for `driving-traffic`), so a route is capped at 24 stops plus the depot; beyond that,
stops are deferred and logged.

Measured live on 6 stops across Howrah: **33.09 km, 128 min**, one matrix call plus one
directions call, whole request **1.1 s**.

## Database

Two tables, created automatically by Hibernate.

### detections

One row per uploaded image, whether or not waste was found.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | uuid | pk |
| `user_id` | uuid | indexed with `created_at` |
| `image_url` | varchar(500) | Cloudinary URL, null if upload is off |
| `status` | varchar(40) | `OK`, `MANUAL_PRICING_REQUIRED`, ... |
| `eligible` | boolean | can this scan be submitted |
| `action_required` | varchar(40) | `RECLICK_IMAGE`, `COLLECTOR_SETS_PRICE` |
| `total_objects` | int | |
| `total_reward_points` | int | what the scan was worth |
| `points_awarded` | boolean | whether it was actually credited |
| `currency` | varchar(8) | |
| `minimum_offer` / `estimated_offer` / `maximum_offer` | numeric(10,2) | |
| `offer_status` | varchar(40) | `ESTIMATED`, `PENDING_COLLECTOR_CONFIRMATION`, ... |
| `final_price_set_by` | varchar(20) | `SYSTEM` or `COLLECTOR` |
| `estimated_weight_kg` | numeric(10,3) | |
| `carbon_saved_kg` | numeric(10,3) | |
| `landfill_reduced_kg` | numeric(10,3) | |
| `recyclable_percent` | int | |
| `primary_bin` / `secondary_bin` | varchar(10) | |
| `pickup_recommended` | boolean | |
| `detection_quality` | varchar(20) | `HIGH` / `MEDIUM` / `LOW` / `NONE` |
| `average_confidence` | numeric(4,2) | |
| `processing_time_ms` | int | |
| `model_id` | varchar(60) | which model produced this, for auditing later |
| `ai_summary` | varchar(1000) | |
| `created_at` | timestamptz | |

### detection_materials

One row per material in a scan.

| Column | Type |
| --- | --- |
| `id` | uuid |
| `detection_id` | uuid, fk, indexed |
| `material` | varchar(60) |
| `category` | varchar(40) |
| `stream` | varchar(20) — `DRY` / `WET` / `HAZARDOUS` |
| `bin_colour` | varchar(10) |
| `count` | int |
| `price_per_kg` | numeric(10,2) |
| `estimated_weight_kg` | numeric(10,3) |
| `estimated_value` | numeric(10,2) |
| `reward_points` | int |
| `carbon_saved_kg` | numeric(10,3) |
| `recyclable` | boolean |

### pickups

| Column | Type | Notes |
| --- | --- | --- |
| `id` | uuid | pk |
| `detection_id` | uuid | indexed, **not unique** — a cancelled pickup allows a re-request |
| `user_id` | uuid | the citizen, indexed with `created_at` |
| `collector_id` | uuid | null until accepted, indexed with `created_at` |
| `status` | varchar(20) | `REQUESTED` / `ACCEPTED` / `COMPLETED` / `CANCELLED`, indexed |
| `address` | varchar(300) | |
| `landmark` | varchar(120) | |
| `contact_phone` | varchar(20) | |
| `notes` | varchar(300) | |
| `latitude` / `longitude` | double | optional, for routing later |
| `preferred_time` | timestamptz | optional |
| `currency` | varchar(8) | |
| `estimated_offer` | numeric(10,2) | copied from the scan |
| `final_amount` | numeric(10,2) | what the collector actually paid |
| `final_weight_kg` | numeric(10,3) | what the scale actually said |
| `collector_notes` | varchar(300) | |
| `cancel_reason` | varchar(200) | |
| `cancelled_by` | varchar(20) | `USER` or `COLLECTOR` |
| `mode` | varchar(20) | `DOORSTEP` or `DROP_OFF` |
| `collection_point_id` | uuid | set for drop-offs, indexed |
| `municipality_id` | uuid | which depot this belongs to |
| `estimated_weight_kg` | numeric(10,3) | copied from the scan, drives capacity and reward |
| `reward_points` | int | weight x mode rate |
| `reward_awarded` | boolean | credited on completion |
| `total_objects` | int | copied from the scan |
| `material_summary` | varchar(200) | e.g. `PET Bottle x13` |
| `created_at` / `accepted_at` / `completed_at` / `cancelled_at` | timestamptz | full audit trail |

Estimate and reality are stored side by side (`estimated_offer` vs `final_amount`,
`total_objects` vs `final_weight_kg`), so the gap between what the model predicted and what
the scale said is measurable — that is the data you would use to correct the unit weights in
the Python service.

`detection_id` is deliberately **not** unique. The uniqueness rule is "one *active* pickup per
scan", which a plain unique constraint cannot express; it is enforced in
`PickupService.create` instead.

### listings and wallet_transactions

`listings` holds one row per item for sale (`seller_id`, `buyer_id`, `detection_id`, `status`,
`material`, `weight_kg`, `price`, `currency`, `description`, `image_url`, `location`, plus
`created_at` / `sold_at` / `cancelled_at`), indexed on status, seller and buyer.

`wallet_transactions` is an append-only ledger: `user_id`, `type`, `amount`, **`balance_after`**,
`currency`, `reason`, `note`, `listing_id`, `counterparty_id`, `created_at`. Nothing is ever
updated or deleted, so the history is the source of truth and `users.wallet_balance` is only a
cached running total.

### municipalities and collection_points

`municipalities` holds one depot per municipality (`code`, `name`, `district`, `state`,
`depot_name`, `depot_lat`, `depot_lon`). `collection_points` holds the drop-off points
(`code`, `municipality_id`, `name`, `locality`, `ward`, `type`, `lat`, `lon`, `active`),
indexed on `(lat, lon)` for the bounding-box shortlist.

Both are seeded from CSV and editable later by `MUNICIPAL_ADMIN`.

Only **metadata** is stored — bounding boxes, per-object confidences and `ignoredObjects` are
returned to the caller but not persisted. They are large, and nothing downstream reads them.
If you later want to re-train on real submissions, `image_url` plus the material rows is
enough to rebuild a labelled set.

`points_awarded` is stored separately from `total_reward_points` deliberately: it records what
actually happened rather than what the scan was theoretically worth, which is what a support
query or a points audit needs.

`bin` is mapped to a `bin_colour` column because `bin` is awkward in some SQL tooling.

---

## Points

Points are credited **server-side only**, from the response this service fetched itself.
Never trust a points value sent by the client.

**Scanning quotes points; it does not credit them.** They are released only when a collector
completes the pickup:

```text
scan            → detection.totalRewardPoints = 65, pointsAwarded = false, balance unchanged
request pickup  → still nothing
collector accepts → still nothing
collector completes:
    points = round(finalWeightKg × rate) + completionBonus + detection.totalRewardPoints
           =       3.2 × 5              +        20       +        65                  = 101
```

`rate` is 5/kg doorstep, 8/kg drop-off; the bonus is 20. The scan's share is guarded by
`detection.pointsAwarded`, so a cancelled-then-re-requested pickup still credits exactly once,
and a repeated completion credits nothing.

The earlier behaviour credited on the scan itself, which meant the same photograph could be
submitted repeatedly for points without any waste ever being handed over. Deferring the credit
closes that while keeping the reward material-aware — sorting metal from paper still matters.

`ScanPointsBackfill` runs at startup and repairs databases written under the old rule: it
reverses points for scans that were never collected, and restates completed pickups whose
recorded figure excluded the scan's share. It is idempotent and clamps at zero.

Points come from the material table in the Python service and are **per item, not per kg**, so
they are awarded even when the waste has no resale value. A banana peel is worth INR 0 but
still earns 2 points for correct segregation.

---

## Assistant

A role-aware chatbot at `POST /api/v1/chat`. It answers from **live data** using tool calling —
not RAG.

RAG retrieves text from a document corpus. "What is my wallet balance" is a row in Postgres,
not a passage: embedding user rows would be stale the moment a pickup completes, imprecise at
arithmetic, and — most importantly — vector similarity has no concept of row-level
authorisation, so one user's data could surface for another. Each tool instead runs through the
same JWT-scoped service the REST API uses, so access control is correct by construction.

### Tools by role

| Role | Tools | Notable |
| --- | --- | --- |
| Citizen | 8 | rewards, wallet, pickups, material price, nearest points, leaderboard |
| Collector | 9 | + open jobs, optimised route |
| Recycler | 10 | + browse listings, **evaluate_listing** |
| Municipal admin | 11 | + `query_analytics`, snapshot, people, collection points |
| Super admin | 12 | + municipality directory, all analytics unscoped |

`ToolRegistry.resolve(role, name)` returns `null` for a tool the role does not own, so a
citizen asking the model to "call query_analytics" gets nothing — the schema is never sent, and
execution is refused server-side even if it were.

### query_analytics

Open-ended admin questions ("total transactions today", "compare waste by municipality") are
served by a whitelisted registry rather than letting a model write SQL:

**18 metrics × 7 dimensions × 6 periods.** Metric and dimension come from enums and are looked
up, never interpolated; dates and the municipality scope are bound parameters. A municipal
admin's queries are automatically scoped to their own area.

### Context

The request accepts `listingId`, `pickupId` and coordinates. When present they are described to
the model, so "is this a good deal?" resolves against the listing the user has open without
them restating it.

### Configuration

```properties
llm.api-key=${LLM_API_KEY:}          # OpenAI-compatible; OpenRouter by default
llm.base-url=${LLM_BASE_URL:https://openrouter.ai/api/v1}
llm.model=${LLM_MODEL:openai/gpt-4o-mini}
chat.history-turns=${CHAT_HISTORY_TURNS:10}
chat.max-tool-rounds=${CHAT_MAX_TOOL_ROUNDS:4}
```

Unset the key and `/api/v1/chat/capabilities` reports `enabled: false`, so a client can hide
the entry point rather than showing a feature that 503s. **The test profile pins it empty on
purpose** — otherwise `mvn test` would make real, billed API calls.

Conversation memory is a `chat_messages` table replayed for the last ten turns. Tool results
are re-fetched every turn rather than replayed, so answers always reflect current data.

---

## Docker

Multi-stage, non-root, and the JVM is told about its cgroup limit:

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build   # dependency layer cached separately
FROM eclipse-temurin:17-jre-jammy AS runtime # 505 MB final image
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:InitialRAMPercentage=50 -XX:+ExitOnOutOfMemoryError"
HEALTHCHECK CMD curl -fsS "http://127.0.0.1:${APP_PORT}/health"
```

`MaxRAMPercentage` matters: without it the JVM sizes the heap from the **host's** memory, not
the container limit, and gets OOM-killed under any memory cap.

The Dockerfile builds the JAR itself rather than copying one in, so a published image never
depends on whatever happened to be in `target/` on the machine that built it.

```bash
docker compose up -d      # from the repository root — java 9798, python 9799
```

The compose file overrides `DETECTION_BASE_URL` to `http://api-python:8000` (the service name
on the private network) and `DB_HOST` to `host.docker.internal`, because `.env` is written for
running on the host.

> **PostgreSQL must accept connections from the Docker bridge.** A default install listens on
> `127.0.0.1` only, and the container will get "connection refused" whatever hostname it uses:
>
> ```text
> postgresql.conf : listen_addresses = 'localhost,172.17.0.1'
> pg_hba.conf     : host greentech greentech 172.16.0.0/12 scram-sha-256
> iptables        : -I INPUT 1 -s 172.16.0.0/12 -p tcp --dport 5432 -j ACCEPT
> ```
>
> The iptables rule matches the **subnet**, not the `docker0` interface — Compose creates its
> own bridge, so an interface-scoped rule silently misses it.

---

## Deployment

Pushed to Docker Hub by GitHub Actions and deployed to an Oracle Cloud ARM VM.

```text
push touching service/api-java/**
   │
   ▼
credential scan → mvn test (139) → package → upload JAR
   │
   ▼
buildx → linux/amd64 + linux/arm64 → Docker Hub
   │
   ▼
Deploy workflow → scp compose → write env from secrets → pull → up -d → wait for /health
```

`linux/arm64` is not optional — the target is aarch64. Only the Maven build is emulated and the
output is architecture-independent bytecode, so the cost is minutes.

In production nginx terminates TLS and proxies `console.jotterly.tech` to `127.0.0.1:9798`,
with `client_max_body_size 12m` so 10 MB scan uploads are not rejected at the proxy. Health
checks gate startup order: this service will not accept traffic until detection reports healthy.

---

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `APP_PORT` | 8080 | |
| `DB_HOST` / `DB_PORT` / `DB_NAME` | localhost / 5432 / greentech | or set `DB_URL` directly |
| `DB_USERNAME` / `DB_PASSWORD` | postgres / postgres | |
| `DB_POOL_SIZE` | 20 | Hikari max pool |
| `DDL_AUTO` | update | never `validate` — there is no Flyway here |
| `JWT_SECRET` | *(generated)* | unset means an ephemeral key; tokens die on restart |
| `JWT_EXPIRATION` | 604800000 | 7 days, in ms |
| `GOOGLE_CLIENT_ID` | — | required for `/auth/google` |
| `RESEND_API_KEY` | — | unset means mail fails and OTP returns 502 |
| `RESEND_SENDER_EMAIL` / `RESEND_SENDER_NAME` | — | must be a verified Resend domain |
| `DETECTION_BASE_URL` | `http://localhost:8000` | the Python service |
| `DETECTION_TIMEOUT_SECONDS` | 45 | read timeout; detection takes ~2s warm, more on cold start |
| `MAPBOX_TOKEN` | — | unset means straight-line fallback, no road distances |
| `MAPBOX_PROFILE` | `mapbox/driving` | `driving-traffic` drops the matrix limit to 10 coords |
| `MAPBOX_TIMEOUT_SECONDS` | 15 | read timeout for Matrix and Directions calls |
| `GEO_SEARCH_RADIUS_KM` | 12 | bounding box for the haversine shortlist |
| `GEO_SHORTLIST_SIZE` | 5 | how many candidates go to the Matrix API |
| `GEO_SEED_ENABLED` | true | load the CSV seed on boot |
| `VEHICLE_CAPACITY_KG` | 80 | route capacity, by weight |
| `DOORSTEP_POINTS_PER_KG` | 5 | doorstep reward rate |
| `DROPOFF_POINTS_PER_KG` | 8 | drop-off reward rate |
| `COMPLETION_BONUS_POINTS` | 20 | flat Green Points on pickup completion |
| `MAIL_ENABLED` | true | false suppresses all Resend calls; OTPs go to the log |
| `RECYCLER_STARTING_BALANCE` | 10000 | dummy wallet float given to RECYCLER accounts |
| `MARKET_FALLBACK_IMAGE` | a demo URL | shown when a listing has no scan photo |
| `ADMIN_SEED_ENABLED` | true | create the two admin accounts on boot |
| `ADMIN_SEED_SUPER_EMAIL` | superadmin@greentech.local | |
| `ADMIN_SEED_SUPER_PASSWORD` | — | **unset means no super admin is created** |
| `ADMIN_SEED_MUNICIPAL_EMAIL` | hmc.admin@greentech.local | |
| `ADMIN_SEED_MUNICIPAL_PASSWORD` | — | **unset means no municipal admin is created** |
| `ADMIN_SEED_MUNICIPAL_CODE` | HMC | which municipality that admin runs |
| `MAX_UPLOAD_SIZE` | 10MB | per-file limit |
| `MAX_REQUEST_SIZE` | 12MB | whole multipart request limit |
| `APP_CORS_ALLOWED_ORIGINS` | localhost:3000,5173,8080 | comma-separated |

---

## Errors

Every failure returns `{"error": "<message>"}`.

| Code | When |
| --- | --- |
| 400 | validation failure, missing `image` part, unsupported image type, bad/expired OTP, duplicate email |
| 401 | missing, malformed or expired token; wrong credentials |
| 403 | attempt to self-assign `MUNICIPAL_ADMIN` or `SUPER_ADMIN` |
| 404 | token valid but the account no longer exists |
| 409 | concurrent signup race on the same email |
| 413 | image over 10 MB |
| 415 | wrong content type on a multipart endpoint |
| 502 | OTP email could not be delivered |
| 503 | the Python detection service is unreachable — nothing is stored |

Validation errors join all field messages into one string, e.g.
`"password: size must be between 8 and 72"`.

---

## Testing

```bash
mvn test
```

139 tests, all passing. Auth tests use H2; detection tests mock `DetectionClient` so they do
not need the Python service running.

| Suite | Covers |
| --- | --- |
| `ApiApplicationTests` | context loads, register then login |
| `AuthEndpointTests` | health public, `/auth/me` requires a token, unknown user 401, profile shape |
| `DetectionApiTests` | 13 tests — see below, including that scanning credits nothing |
| `PickupApiTests` | 28 tests — full lifecycle, every guard, a 6-way accept race, and reward arithmetic |
| `GeoRoutingTests` | 15 tests — seed integrity, nearest search, both modes, capacity, aggregation |
| `LeaderboardTests` | 7 tests — bonus, ranking, me block, totals, clamping |
| `MailToggleTests` | 3 tests — disabled mail never throws and never calls Resend |
| `MarketplaceTests` | 27 tests — atomic claim, balance guard, cross-path exclusivity, filter and sort |
| `ChatApiTests` | 18 tests — role-scoped tools, conversation isolation, every analytics metric |
| `ScanPointsBackfillTests` | 9 tests — reversal, idempotency, zero clamp, ledger consistency |
| `MarketplaceTests` | 18 tests — listing, buying, wallet ledger, and a 5-way buy race |
| `AdminApiTests` | 13 tests — seeding, role limits, scoping, deactivation, point and municipality CRUD |

`DetectionApiTests` covers: both endpoints reject anonymous callers; a scan is stored and
returns the payload; material rows persist with correct values; an eligible scan credits
points; an ineligible scan is stored but credits nothing; non-image and missing-part uploads
are rejected without storing; a downed Python service returns 503 without storing; history is
newest-first with correct totals; history is scoped to the authenticated user; pagination
works.

### Verified end to end

Against real PostgreSQL and the real Python service, with a real bin photo — 12/12:

```text
POST no token -> 401              real bin photo -> 200
GET  no token -> 401              13 objects stored
bad token     -> 401              65 points awarded
text file     -> 400              human photo -> not eligible, no points
missing part  -> 400              history totals correct
                                  history scoped to user
                                  /auth/me points synced
```

A round trip through both services with a 13-object photo takes **~2.4s**, almost all of it
YOLO inference.

The pickup flow was verified live against real PostgreSQL — 23/23:

```text
create -> REQUESTED               user cannot cancel once accepted -> 409
waste + offer copied from scan    release -> back to REQUESTED
collector feed shows it           other collector can then claim it
citizen blocked from feed -> 403  wrong collector complete -> 403
duplicate active -> 409           complete -> COMPLETED with final amount
cancel before accept -> OK        history scoped per role (2 / 1 / 0)
re-request after cancel -> 201    401 / 400 / 404 / bad phone all correct
accept -> ACCEPTED                collector notification emails sent
second collector -> 409           6-way concurrent accept -> exactly 1 winner
```

Geo and routing were verified live against the real Mapbox account — 10/10:

```text
6 requests aggregate to 2 stops      drop-off scores more than doorstep
4 pickups on one stop                dropoff without a point -> 400
polyline returned                    nearest is public, no token
depot resolves to Howrah MC          route requires COLLECTOR
doorstep accepted                    155 points seeded
```

A separate probe sweep of 16 malformed or out-of-order requests (bad JSON, non-UUID ids,
negative amounts, oversized fields, double-complete, cancel-after-complete, wrong HTTP verb)
produced **zero 500s**.

---

## Project structure

```text
src/main/java/com/iem/
  auth/            AuthController, AuthService, GoogleService, OtpService, UserRepository, dto/
  detection/       DetectionController, DetectionService, DetectionClient, DetectionRepository, dto/
  security/        SecurityConfig, JwtService, JwtAuthenticationFilter, UserPrincipal
  model/           User, Detection, DetectionMaterial
  mail/            MailService (Resend)
  exception/       ApiException, GlobalExceptionHandler
  health/          HealthController
```

The codebase contains **no comments** by design — names and structure carry the meaning.
