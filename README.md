# GreenRoute — Community Waste Management & Circular Economy Platform

**IEMHACKS 4.0 · Track 04 · `IEMH4-GT-01`**

A citizen photographs their waste. A vision model identifies it, prices it, and says which bin
it belongs in. They then either call a collector to their door or drop it at the nearest marked
point — routes are optimised against real road data — or sell it directly to a recycler.
Everyone earns Green Points for segregating correctly.

Built for **Howrah** and **North 24 Parganas**, West Bengal.

---

## Live

| | |
| --- | --- |
| 🌐 **Website** | **[www.greenroutehere.tech](https://www.greenroutehere.tech)** |
| 📱 **Android APK** | **[www.greenroutehere.tech/GreenRoute.apk](https://www.greenroutehere.tech/GreenRoute.apk)** · 21.6 MB |
| 🛠 **Admin consoles** | [www.greenroutehere.tech/admin/login](https://www.greenroutehere.tech/admin/login) |
| ⚙️ **API** | [console.jotterly.tech](https://console.jotterly.tech/health) |

The API runs on an Oracle Cloud ARM VM behind nginx with a Let's Encrypt certificate. The
detection service is deliberately **not** exposed — it has no authentication of its own and is
reachable only by the Java API over a private container network.

---

## Contents

- [What it does](#what-it-does)
- [The four surfaces](#the-four-surfaces)
- [How a scan becomes a collection](#how-a-scan-becomes-a-collection)
- [Technology](#technology)
- [Architecture](#architecture)
- [Incentives](#incentives)
- [The assistant](#the-assistant)
- [DevOps](#devops)
- [Running it locally](#running-it-locally)
- [Documentation](#documentation)
- [Honest limitations](#honest-limitations)

---

## What it does

The brief asks for five things. Here is where each one lives.

| Requirement | Where it is implemented |
| --- | --- |
| Citizens log and verify correct segregation | Photo → YOLOv8m → 16 material types with bin colour, price and points |
| Optimise collection vehicle routes | Mapbox Matrix + nearest-neighbour + 2-opt, capacity-aware, real polyline |
| Reward citizens who segregate correctly | Green Points credited **only** when a collector completes the pickup |
| Connect recyclers with households directly | Marketplace with an atomic purchase and a wallet ledger |
| Municipal dashboard for efficiency and carbon | Two React consoles over 45 REST endpoints, plus a natural-language assistant |

---

## The four surfaces

```text
┌──────────────────────┐   ┌──────────────────────┐
│  Flutter mobile app  │   │   React web app      │
│  citizen · collector │   │   landing + two      │
│  · recycler          │   │   admin consoles     │
└──────────┬───────────┘   └──────────┬───────────┘
           │        HTTPS             │
           └────────────┬─────────────┘
                        ▼
           ┌────────────────────────────┐
           │   api-java (Spring Boot)   │  auth · pickups · routing
           │   45 endpoints, 9 tables   │  marketplace · wallet · admin
           └─────────┬──────────────────┘  assistant (17 tools)
                     │ private network
                     ▼
           ┌────────────────────────────┐
           │  api-python (FastAPI)      │  YOLOv8m · 16 waste types
           │  detection & pricing       │  75 label rules · Cloudinary
           └────────────────────────────┘
                     │
              PostgreSQL · Mapbox · Resend · OpenRouter
```

---

## How a scan becomes a collection

```text
citizen photographs waste
        │
        ▼
POST /api/v1/detections            (Java, JWT required)
        │  forwards the image over the private network
        ▼
POST /api/v1/detect                (Python, YOLOv8m at 1280px)
        │  13 objects · PET Bottle ×13 · INR 8.29–11.21 · 0.39 kg
        ▼
stored against the user — points are quoted, NOT yet credited
        │
        ▼
POST /api/v1/pickups   mode = DOORSTEP | DROP_OFF
        │                        │
        │                        └─► nearest collection point, ranked by road time
        ▼
collectors notified → first to accept wins → citizen can no longer cancel
        │
        ▼
GET /api/v1/routes/my-route        depot → optimised stops → depot + polyline
        │
        ▼
collector weighs and pays → Green Points credited, once
```

Alternatively the citizen skips collection entirely and sells to a recycler through the
marketplace. **A scan can take one route or the other, never both** — the two paths are
mutually exclusive and enforced server-side.

---

## Technology

### Backend — `api-java`

Java 17 · Spring Boot 3.5.11 · Spring Security · Spring Data JPA · PostgreSQL 16 · Hibernate ·
JJWT 0.12.5 · BCrypt · Google API Client · Resend · Mapbox Directions & Matrix · JUnit 5 · H2

**109 source files · 45 endpoints · 9 entities · 139 tests**

### Detection — `api-python`

Python 3.12 · FastAPI · Uvicorn · Ultralytics YOLOv8m · PyTorch (CPU) · Pillow · Cloudinary

**13 source files · 16 waste types · 75 label-mapping rules**

### Web — `app/web/greentech`

React 19 · Vite 8 · Tailwind CSS 4 · React Router 7 · Recharts · Mapbox GL JS · Motion ·
lucide-react

**45 source files · landing page + municipal and super-admin consoles**

### Mobile — `app/mobile/greentech`

Flutter · Dart · Riverpod 3 · go_router 17 · google_sign_in · flutter_map · geolocator ·
image_picker · shared_preferences

**67 Dart files · 20 routes · citizen, collector and recycler flows**

### Infrastructure

Docker · Docker Compose · GitHub Actions · Docker Hub · nginx · Let's Encrypt ·
Oracle Cloud (ARM64) · Vercel

---

## Architecture

**Why two services.** Detection needs PyTorch and 2.5 GB of dependencies; the business API
needs none of that. Splitting them means the Java image is 505 MB and restarts in seconds,
while the model service can be scaled or replaced without touching auth, payments or routing.
The recognition layer is swappable — dropping trained weights at `app/weights/best.pt` needs no
code change.

**Race safety.** Two operations can be contended, and both are single atomic conditional
updates rather than read-then-write:

```sql
-- a collector claiming a pickup
UPDATE pickups SET collector_id = ?, status = 'ACCEPTED'
 WHERE id = ? AND status = 'REQUESTED' AND collector_id IS NULL
```

Verified under load: six collectors accepting the same pickup produced exactly **one 200 and
five 409s**. The marketplace purchase uses the same pattern, plus a balance check that runs
before the listing is touched, so an unaffordable purchase leaves it buyable.

**Two-stage nearest search.** A haversine shortlist, then re-ranked by the Mapbox Matrix API.
This is not decoration: across the Hooghly the road distance is 1.4–1.7× the straight line, and
ranking genuinely reorders the result. Live example — the closest point by air (0.66 km) is
*further* by road (1.91 km) than one 0.42 km away (2.66 km).

---

## Incentives

| Action | Reward |
| --- | --- |
| Verified segregation (scan) | per item, by material — **quoted, credited later** |
| Pickup completed | **+20 Green Points** flat |
| Doorstep pickup | +5 points/kg |
| Drop at a collection point | **+8 points/kg** |

Drop-off pays more because it saves the municipality a vehicle trip.

**Points are credited only when a collector completes the pickup.** Scanning alone credits
nothing — otherwise the same photograph could be farmed indefinitely. The scan's value is held
against the detection and released on completion, so material still matters, but only for waste
actually handed over.

`GET /api/v1/leaderboard` ranks everyone by points — public, plain SQL, and it returns your own
rank even when you are off the visible page.

---

## The assistant

Every role gets a chatbot that answers from **live data**, not a document index.

It uses **tool calling, not RAG**. A question like "what is my wallet balance" is a row in
Postgres, not a passage to retrieve — and embedding user rows would be stale, imprecise at
arithmetic, and unable to enforce per-user access. Each tool runs through the same JWT-scoped
service the REST API uses, so authorisation is correct by construction.

**17 tools, filtered by role.** A citizen is offered 8, a super admin 12. The registry never
sends an admin tool's schema to a citizen, and refuses to execute one even if asked.

For administrators there is a `query_analytics` tool over a whitelisted metric and dimension
registry — 18 metrics × 7 dimensions × 6 periods — which covers open-ended questions without
ever letting a model write SQL.

```text
Q: "Compare waste diverted by municipality"      → grouped aggregate, scoped to their area
Q: "Is this listing worth buying?"               → ask vs catalogue rate, margin, verdict
Q: "Where is the nearest place to drop this?"    → road-time ranked collection points
```

---

## DevOps

### Pipeline

```text
push to main
   │
   ├─ path touches service/api-java/**    ─► api-java workflow
   │     credential scan → 139 tests → JAR → multi-arch image → Docker Hub
   │
   ├─ path touches service/api-python/**  ─► api-python workflow
   │     credential scan → compile → build → container smoke test → Docker Hub
   │
   └─ either succeeds ─► Deploy workflow
         scp compose → write env from secrets → pull → up -d → wait for health
```

**Path filters** mean a mobile-asset commit does not trigger a ten-minute PyTorch rebuild.

**A credential scan runs first in both workflows** — before anything is built or published,
because deleting a commit does not un-leak a key. It matches OpenRouter, Resend and Mapbox
formats plus private-key blocks, and is tested to catch a planted key without false-positiving
on the tree.

**The Python image builds on a native ARM64 runner.** The deployment target is an aarch64
Oracle VM; cross-compiling PyTorch under QEMU takes ~40 minutes and times out.

### Images

| Image | Size | Platforms | Notes |
| --- | --- | --- | --- |
| `greentech-api-java` | 505 MB | amd64 + arm64 | multi-stage Maven → JRE 17, non-root, `MaxRAMPercentage=75` |
| `greentech-api-python` | 2.57 GB | arm64 | CPU-only torch, headless OpenCV, **YOLO weights baked in at build** |

Baking the weights matters: otherwise Ultralytics downloads 50 MB on first request, so the
first scan in production stalls on a GitHub fetch.

### Production topology

```text
internet ──HTTPS──► nginx (Let's Encrypt)
                      │  console.jotterly.tech  →  127.0.0.1:9798
                      ▼
              ┌────────────────┐   compose network   ┌──────────────────┐
              │  api-java      │ ──────────────────► │   api-python     │
              │  :9798         │  api-python:8000    │   :9799 (private)│
              └───────┬────────┘                     └──────────────────┘
                      │ host.docker.internal
                      ▼
              PostgreSQL 14 on the host
```

PostgreSQL listens on loopback **and the Docker bridge only** — never `0.0.0.0` — with a
`pg_hba` rule scoped to `172.16.0.0/12` and a matching iptables rule. Health checks gate
startup order: Java will not accept traffic until the detection service reports healthy.

Deploy is idempotent, prunes old layers (the Python image is multi-GB), and fails loudly if an
environment file is missing rather than starting a service that will crash.

---

## Running it locally

Three terminals. The detection service must be up before scanning works.

```bash
# 1 — detection
cd service/api-python
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
cp .env.example .env
.venv/bin/uvicorn app.main:app --port 8000

# 2 — api
cd service/api-java
cp .env.example .env      # JWT_SECRET, GOOGLE_CLIENT_ID, RESEND_API_KEY, MAPBOX_TOKEN, DB
createdb greentech
mvn spring-boot:run

# 3 — web
cd app/web/greentech
cp .env.example .env      # VITE_API_BASE_URL, VITE_MAPBOX_TOKEN
npm install && npm run dev
```

Set `MAIL_ENABLED=false` to work without spending the Resend quota — OTPs are printed to the
API log instead of emailed.

**Or run both backends in containers:**

```bash
docker compose up -d      # java on 9798, python on 9799
```

PostgreSQL must accept connections from the Docker bridge; see the comments in
[`docker-compose.yml`](docker-compose.yml).

---

## Documentation

| Document | Covers |
| --- | --- |
| **[service/api-java/README.md](service/api-java/README.md)** | Spring Boot service, database, routing, security, Docker |
| **[service/api-python/README.md](service/api-python/README.md)** | Detection model, pricing rules, tuning, Docker |
| **[app/web/greentech/README.md](app/web/greentech/README.md)** | React app, admin consoles, deployment |
| **[app/mobile/greentech/README.md](app/mobile/greentech/README.md)** | Flutter app, every screen and flow |
| **[service/api-java/citizen-apis.md](service/api-java/citizen-apis.md)** | Every citizen endpoint, with real captured responses |
| **[service/api-java/collector-apis.md](service/api-java/collector-apis.md)** | Collector endpoints, routing, acceptance semantics |
| **[service/api-java/recycler-apis.md](service/api-java/recycler-apis.md)** | Recycler endpoints, buying, wallet |
| **[service/api-java/marketplace.md](service/api-java/marketplace.md)** | Marketplace and purchase system in full |
| **[tasks/](tasks/README.md)** | Per-role capability matrix — built vs open |
| **[service/api-java/docs/openapi.yml](service/api-java/docs/openapi.yml)** | OpenAPI spec, importable into Postman |

The four API guides contain **responses captured from a running server**, not hand-written
examples.

---

## Tests

```bash
cd service/api-java && mvn test        # 139 tests
```

Covering the pickup race under concurrency, the marketplace claim and balance guard, the
cross-path exclusivity rules, reward arithmetic, role-scoped chat tools, every analytics metric
and dimension combination, and the historical-data backfill.

Verified live against real PostgreSQL, a real Resend account, a real Mapbox account, real
Cloudinary and a real photo of a full waste bin: **13 objects detected, 3 pickups aggregated
into an optimised 25.54 km route, a marketplace sale moving money between two wallets.**

---

## Honest limitations

- **Collection points are seeded demonstration data**, generated by geocoding real localities.
  They are not an official municipal bin register.
- **COCO has no class for cans, wrappers, light bulbs or batteries**, so those are invisible
  until trained weights are supplied. A cartoon can still register as a "remote".
- **Weight is assumed, not measured** — a 250 ml bottle and a 2 L jug both count as 30 g, which
  is exactly why the collector's scale sets the final price.
- **Route optimisation is per collector**, ordering stops they have already accepted. It is not
  fleet-wide dispatch.
- **Mapbox Matrix caps at 25 coordinates**, so a route is capped at 24 stops plus the depot.
- **The wallet is a ledger, not a payment gateway.** No real money moves.
- **There is no rate limiting on `/auth/login`**, so the API is exposed to unlimited password
  guessing. Known, and the first thing to add.
