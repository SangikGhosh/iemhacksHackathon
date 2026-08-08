# Collector

**Role:** `COLLECTOR` · **Created by:** Municipal Admin · **Cannot self-register**

Picks waste up from citizens and collection points, weighs it, pays, and closes the job.

---

## Tasks

| # | Task | API | Status |
| --- | --- | --- | --- |
| 1 | Log in | `POST /auth/login` | Done |
| 2 | See pickups waiting for a collector | `GET /api/v1/pickups/available` | Done |
| 3 | Accept a request | `POST /api/v1/pickups/{id}/accept` | Done |
| 4 | Reject / hand one back after accepting | `POST /api/v1/pickups/{id}/release` | Done |
| 5 | Get an optimised route with a map line | `GET /api/v1/routes/my-route` | Done |
| 6 | Weigh the waste and set the final price | `POST /api/v1/pickups/{id}/complete` | Done |
| 7 | See their own assigned pickups | `GET /api/v1/pickups` | Done |
| 8 | See one pickup in detail | `GET /api/v1/pickups/{id}` | Done |

### Rules that apply

- Acceptance is **first come, first served** — an atomic claim, so if several collectors tap at
  the same instant exactly one wins and the rest get `409`.
- A collector **cannot accept their own** pickup request (`403`).
- Only the **assigned** collector may complete or release (`403` otherwise).
- A pickup that was never accepted cannot be completed (`409`).
- Once accepted, **the citizen can no longer cancel** — which is why `/release` exists.

### Routing

`GET /api/v1/routes/my-route` returns depot → stops → depot. Drop-offs sharing a collection
point collapse into **one stop**, the load is capped at `VEHICLE_CAPACITY_KG` (80 kg) by weight,
and anything that does not fit comes back in `deferredPickupIds`. The response carries an
encoded polyline for Mapbox to draw.

---

## Not built yet

| Task | Note |
| --- | --- |
| Live GPS tracking of the vehicle | No `location` write endpoint; the app would POST its position |
| Push notification on a new pickup | Currently email + polling `/available` |
| Proof of collection photo | No upload on `/complete` |
| Collector earnings / payout ledger | Money currently only moves in the marketplace wallet |
| Shift start/end | No attendance model |
