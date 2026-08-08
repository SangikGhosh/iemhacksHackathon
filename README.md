# GreenTech — Community Waste Management & Circular Economy Platform

IEMHACKS 4.0 · Track 04 · `IEMH4-GT-01`

A citizen scans their waste, the AI identifies and prices it, and either a collector is
dispatched to the door or the citizen drops it at the nearest marked point. Routes are
optimised against real road data, and everyone earns points for segregating correctly.

Built for **Howrah** and **North 24 Parganas**, West Bengal.

---

## Repository layout

```text
service/
  api-java/     Spring Boot 3.5 · auth, scan history, pickups, routing   :8080
  api-python/   FastAPI + YOLO · waste detection, pricing, bins          :8000
app/
  mobile/greentech/   Flutter app (Android / iOS)
  web/greentech/      React + Vite + Tailwind — landing page + admin consoles
tasks/
  collector-task/         what each role can do, which API backs it,
  recycler-task/          and what is still open
  municipal-admin-task/
  super-admin-task/
```

Each service has its own README with full API docs:

- **[tasks/](tasks/README.md)** — per-role capability matrix, built vs open
- **[service/api-java/README.md](service/api-java/README.md)** — auth, pickups, routing, admin, database
- **[service/api-python/README.md](service/api-python/README.md)** — detection model, pricing, tuning
- **[service/api-java/docs/openapi.yml](service/api-java/docs/openapi.yml)** — 28 endpoints, importable into Postman

---

## How a scan becomes a collection

```text
citizen photographs waste
        |
        v
POST /api/v1/detections          (Java, JWT)
        |  forwards the image
        v
POST /api/v1/detect              (Python, YOLOv8m)
        |  13 objects, PET Bottle x13, INR 8.29-11.21, 0.39 kg
        v
stored against the user, segregation points credited
        |
        v
POST /api/v1/pickups   mode = DOORSTEP | DROP_OFF
        |                        |
        |                        +--> nearest collection point, ranked by road time
        v
collectors notified -> first to accept wins -> citizen can no longer cancel
        |
        v
GET /api/v1/routes/my-route      depot -> optimised stops -> depot + polyline
        |
        v
collector completes, weighs, pays -> disposal points credited
```

---

## What each part does

### Detection (Python)

YOLOv8m, pretrained on COCO, at 1280 px. Returns detections mapped to 16 waste categories with
bin colour, per-kg price, reward points and carbon saved, plus an `eligible` flag the app uses
to decide whether to ask for a retake.

We did **not** train a model — the recognition layer is swappable, and dropping trained weights
at `app/weights/best.pt` needs no code change. See the api-python README for the honest account
of what COCO can and cannot see.

### Auth, history and pickups (Java)

JWT auth with Google OAuth, five roles, scan history, and the full pickup lifecycle
(`REQUESTED → ACCEPTED → COMPLETED`, with cancellation locked once a collector accepts).
Acceptance is an atomic conditional update, so six collectors tapping at once produce exactly
one winner.

### Maps and routing (Java + Mapbox)

155 seeded collection points and 4 municipal depots. Nearest-point search runs a haversine
shortlist then ranks by **real driving time**, which matters across the Hooghly where the road
is up to 1.7× the straight line. Collector routes aggregate drop-offs sharing a point into one
stop, respect an 80 kg vehicle capacity, and return an encoded polyline.

---

## Running the stack

Three terminals. The Python service must be up before scanning works.

```bash
# 1 — detection
cd service/api-python
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
cp .env.example .env
.venv/bin/uvicorn app.main:app --port 8000

# 2 — api
cd service/api-java
cp .env.example .env        # JWT_SECRET, GOOGLE_CLIENT_ID, RESEND_API_KEY, MAPBOX_TOKEN, DB
# set MAIL_ENABLED=false to work without burning the Resend quota -
# OTPs are then printed in this terminal instead of emailed
createdb greentech
mvn spring-boot:run

# 3 — web (landing + admin consoles)
cd app/web/greentech
cp .env.example .env        # VITE_API_BASE_URL, defaults to :8080
npm install && npm run dev  # then open /admin/login
```

The Java service is the only one exposed publicly. **The Python service has no auth of its
own** — keep it on localhost or a private network.

---

## Incentives

| Action | Reward |
| --- | --- |
| Verified segregation (scan) | per item, by material |
| **Pickup completed** | **+20 Green Points** flat |
| Doorstep pickup | + 5 points/kg |
| Drop at a collection point | + 8 points/kg |

Drop-off pays more because it saves the municipality a vehicle trip. Points are credited
server-side on completion using the collector's weighed figure, never the client's word.

`GET /api/v1/leaderboard` ranks everyone by points — public, plain SQL, and it returns your own
rank when you send a token even if you are off the visible page.

### Admin consoles

Two React dashboards in `app/web/greentech`, both wired to the live API:

| Route | Role | Can do |
| --- | --- | --- |
| `/admin/municipal` | `MUNICIPAL_ADMIN` | dashboard, create/disable collectors and recyclers, manage collection points, view pricing |
| `/admin/super` | `SUPER_ADMIN` | all of the above unscoped, plus create municipalities and municipal admins, leaderboard, service health |

Sign in at `/admin/login`. Two accounts are seeded on first boot — see
`ADMIN_SEED_*` in `service/api-java/.env`. There is no default password: unset means no
account is created.

### Marketplace

A citizen lists segregated waste, a recycler taps **Interested**, and a dummy wallet ledger
moves the money — credit to the seller, debit to the buyer, full payment history for both at
`GET /api/v1/wallet`. No payment gateway is integrated; the ledger exists so the circular-economy
loop is demonstrable end to end.

---

## Tests

```bash
cd service/api-java  && mvn test          # 98 tests
cd service/api-python && .venv/bin/python -m pytest   # or the scripted edge suite
```

Verified live against real PostgreSQL, a real Resend account, a real Mapbox account and a real
photo of a full waste bin: 13 objects detected, 6 requests aggregated to 2 stops, a 33 km route
returned in 1.1 s.

---

## Honest limitations

- **Collection points are seeded demo data**, generated by geocoding real localities. They are
  not an official municipal bin register.
- **COCO has no class for cans, wrappers, light bulbs or batteries**, so those are invisible
  until trained weights are supplied. A cartoon can still register as a "remote" at 0.66
  confidence.
- **Weight is assumed, not measured** — a 250 ml bottle and a 2 L jug both count as 30 g, which
  is why the collector's scale sets the final price on any mixed or multi-item pickup.
- **Route optimisation is per collector**, ordering stops they already accepted. It is not
  fleet-wide dispatch.
- Mapbox Matrix caps at 25 coordinates, so a route is capped at 24 stops plus the depot.
