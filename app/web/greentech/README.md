# greentech — web

Landing page plus the two admin consoles, wired to the Java API.

```bash
cp .env.example .env    # VITE_API_BASE_URL, default http://localhost:8080
npm install
npm run dev             # http://localhost:3000
```

## Routes

| Route | Who | What |
| --- | --- | --- |
| `/` | anyone | marketing landing page |
| `/admin/login` | anyone | console sign-in |
| `/admin/municipal` | `MUNICIPAL_ADMIN`, `SUPER_ADMIN` | one municipality |
| `/admin/super` | `SUPER_ADMIN` | the whole platform |

`RequireRole` in `Router.jsx` redirects anyone unauthenticated to `/admin/login`, and sends a
municipal admin who lands on `/admin/super` back to their own console.

## Signing in

Use a seeded admin account from `service/api-java/.env` (`ADMIN_SEED_*`). Citizens, collectors
and recyclers can sign in but get told the console is not for them — the mobile app is.

## How it talks to the API

`src/lib/api.js` is the whole client. It reads `VITE_API_BASE_URL`, attaches the bearer token
from `localStorage`, and clears the session on any 401 so an expired token bounces you to the
login screen rather than showing broken panels.

`src/lib/useApi.js` handles fetch-on-mount plus a manual `reload()`, which is what the create
and disable actions call after they succeed.

**CORS matters.** The API only accepts the origins listed in `APP_CORS_ALLOWED_ORIGINS`. If the
dev server falls back to port 3001 because 3000 is taken, add that origin or the browser blocks
every call while curl keeps working.

## Maps

Both consoles have a **Map** tab backed by Mapbox GL JS, plotting collection points and the
municipal depot each route starts from.

| Console | Sees | Search |
| --- | --- | --- |
| Municipal admin | only their own municipality's points and depot | locality, ward, code |
| Super admin | every municipality | area dropdown **plus** locality / ward / code |

Scoping is enforced **server-side** in `/api/v1/admin/collection-points`, not by filtering in the
browser — a municipal admin's response simply does not contain another municipality's points.

Markers are colour-coded by type (MRF, bin cluster, scrap yard, compost hub), retired points are
greyed and semi-transparent, and depots are dark squares. Colour is never the only signal: every
marker has a popup naming the point, and the legend spells out each colour. Clicking a marker
opens a detail card below the map.

`VITE_MAPBOX_TOKEN` must be set or the map renders a message saying so rather than a blank box.
The map auto-fits to whatever is currently visible, so filtering by area re-frames it.

**mapbox-gl is ~1.8 MB**, so `PointsMap` is lazy-loaded — it only downloads when the Map tab is
opened, keeping it off every other admin screen.

## Panels

`src/admin/panels.jsx` holds the shared, data-driven panels:

- `PeoplePanel` — list, search, create and enable/disable, reused for every role
- `CollectionPointsPanel` — the point network with add and retire
- `MunicipalitiesPanel` — super admin only
- `PricingPanel` — current reward rates, read-only (they are API env vars)

`widgets.jsx`, `charts.jsx` and `AdminShell.jsx` are presentation only and were already here.

## Empty states are real

With a fresh database the charts render empty rather than fake. If a panel says "No detections
yet", nothing has been scanned — that is the truth, not a loading bug.
