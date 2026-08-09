# app/web/greentech — Landing Site & Admin Consoles

React 19 + Vite 8 + Tailwind CSS 4. One build serves two very different things: a public
marketing site with the APK download, and the two administrative consoles that municipal and
platform staff actually work in.

**45 source files · 15 landing components · 2 consoles · 6 panel types**

| | |
| --- | --- |
| 🌐 **Live** | **[www.greenroutehere.tech](https://www.greenroutehere.tech)** |
| 📱 **APK** | [www.greenroutehere.tech/GreenRoute.apk](https://www.greenroutehere.tech/GreenRoute.apk) |
| 🛠 **Consoles** | [/admin/login](https://www.greenroutehere.tech/admin/login) |
| ⚙️ **API** | [console.jotterly.tech](https://console.jotterly.tech/health) |

---

## Contents

- [Routes](#routes)
- [Run](#run)
- [Configuration](#configuration)
- [The landing site](#the-landing-site)
- [The consoles](#the-consoles)
- [Panels](#panels)
- [Maps](#maps)
- [The assistant](#the-assistant)
- [How it talks to the API](#how-it-talks-to-the-api)
- [Deployment](#deployment)
- [Project structure](#project-structure)

---

## Routes

| Path | Renders | Guard |
| --- | --- | --- |
| `/` | Landing site | public |
| `/admin` | redirect → `/admin/login` | — |
| `/admin/login` | Sign-in | redirects away if already an admin |
| `/admin/municipal` | Municipal console | `MUNICIPAL_ADMIN` |
| `/admin/super` | Super-admin console | `SUPER_ADMIN` |
| `*` | Custom 404 | public |

Routing is client-side (`react-router` 7), which is why [`vercel.json`](vercel.json) rewrites
everything to `index.html`. Without that rewrite the host serves files straight off disk, so
`/admin/login` works when clicked but **404s on refresh**, and the custom 404 page can never
render because the bundle is never loaded.

---

## Run

```bash
npm install
cp .env.example .env
npm run dev            # http://localhost:5173
```

| Script | Does |
| --- | --- |
| `npm run dev` | Vite dev server with HMR |
| `npm run build` | production build into `dist/` |
| `npm run preview` | serve the built output locally |
| `npm run lint` | ESLint, including the React Compiler rules |
| `npm run sync:apk` | copy the release APK from the Flutter build into `public/` |

---

## Configuration

Two variables, and the split between them matters.

| File | Read by | Purpose |
| --- | --- | --- |
| `.env` | `npm run dev` | local development, gitignored |
| `.env.production` | `npm run build` | committed — points the built site at the deployed API |

```bash
VITE_API_BASE_URL=https://console.jotterly.tech
VITE_MAPBOX_TOKEN=pk.your-public-token
```

**`VITE_MAPBOX_TOKEN` must be set in the hosting platform's environment.** `.env` is gitignored
and does not exist on a fresh clone, so without it the build succeeds and both consoles render
**empty grey map panels with no error** — which reads as broken map code rather than a missing
variable.

The API URL is not a secret. Vite compiles it into the bundle, so it is visible in DevTools
regardless of where it is configured; the API is protected by JWT auth and CORS, not obscurity.

---

## The landing site

A single scrolling page assembled from 15 components in `src/components/`:

`Hero` · `MissionSection` · `Features` · `ScannerDemo` · `NetworkSection` · `RolesSection` ·
`RoleCards` · `Impact` · `StatsSection` · `TechStack` · `FAQ` · `Footer`

Built on a small primitive set in `src/components/ui/` — `card-spotlight`, `border-beam`,
`marquee`, `number-ticker`, `accordion`, `pill-button` — with `motion` for animation.

`ScannerDemo` walks through a real detection result so a visitor understands the product
without installing anything, and the header carries the APK download.

---

## The consoles

Both are built from the same `AdminShell` — fixed dark sidebar on desktop, slide-over on
mobile, sticky topbar with working search, notifications and a profile menu — and differ only
in which panels they mount and how the API scopes the data.

| | Municipal admin | Super admin |
| --- | --- | --- |
| Scope | one municipality | the whole platform |
| Dashboard | ✓ | ✓ |
| People | create/disable collectors and recyclers | + municipal admins and citizens |
| Collection points | own area | all areas, searchable |
| Municipalities | — | create and edit |
| Pricing | view | view |
| Map | own area | all, with area search |
| System health | — | ✓ live dependency checks |
| Assistant | ✓ scoped | ✓ unscoped |

Sign in at `/admin/login`. Two accounts are seeded on the API's first boot from `ADMIN_SEED_*`;
there is no default password, and unset means no account is created.

Signing out asks for confirmation rather than dropping the session on a stray click.

---

## Panels

`src/admin/panels.jsx` holds the reusable panels both consoles compose:

| Panel | Does |
| --- | --- |
| `PeoplePanel` | search, filter by role, create, enable/disable |
| `CollectionPointsPanel` | list, create, edit, retire |
| `MunicipalitiesPanel` | super admin only — create and edit, with depot coordinates |
| `PricingPanel` | per-material rates, bin colours, marketplace turnover |
| `MapPanel` | Mapbox map of collection points |
| `ConsoleState` | shared loading, error and empty states |

Charts are Recharts, themed through `chart-tokens.js` so the palette matches the design system
rather than Recharts' defaults. The bin-split chart is colour-coded to the real bin colours —
blue, green, red, grey — because a legend of arbitrary colours for a thing that *is* colour
would be perverse.

**Empty states are real.** A fresh database genuinely has no pickups, and the panels say so
rather than rendering a chart of zeroes that looks like a bug.

---

## Maps

`PointsMap.jsx` renders Mapbox GL JS with DOM markers rather than a GeoJSON layer — at a few
hundred points the difference is not measurable, and it keeps the popup and colour logic in one
readable place.

Markers are colour-coded by type (MRF, bin cluster, scrap yard, compost hub), depots are dark
squares, and retired points are faded. The map fits bounds to whatever is plotted.

`mapbox-gl` is **lazy-loaded into its own chunk**. Imported eagerly it added 1.78 MB to the
shared bundle, which every visitor to the landing page would have paid for without ever opening
a console.

Missing token, unreachable Mapbox and a map that fails to initialise each render a specific
message instead of a blank rectangle.

---

## The assistant

`Assistant.jsx` mounts once in `AdminShell`, so both consoles get it. A floating button opens a
panel that talks to `POST /api/v1/chat`.

- Keeps `conversationId` across turns, so follow-ups like *"and break that down by day"* work
- Seeds the empty state from `GET /api/v1/chat/capabilities`, so the suggested prompts are the
  ones this role can actually answer
- Renders `toolsUsed` under each reply — a quiet signal that the number came from a live query
- Hides itself when the server reports `enabled: false`, rather than offering a feature that
  will 503

---

## How it talks to the API

`src/lib/api.js` is the only place that knows about HTTP.

```js
const BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080'
```

- The JWT lives in `localStorage` and is attached as `Authorization: Bearer`
- A `401` clears the session, so an expired token logs you out instead of looping
- Errors are unwrapped into `ApiError` with `status`, so callers branch on the code and show
  the server's own message — those messages are written for end users
- A network failure is reported as *"Cannot reach the API"* rather than an opaque `TypeError`

**The `ngrok-skip-browser-warning` header is only sent to ngrok hosts.** Sending it everywhere
adds it to the CORS preflight, which the API rejects unless it is in its allowed-headers list —
the browser then blocks the request and `fetch` throws, which surfaced as "Cannot reach the
API" against a perfectly healthy server. A genuinely confusing hour.

`useApi.js` wraps loading, error and refetch, and is written to satisfy the React Compiler
lint — no ref access during render, no synchronous `setState` in an effect.

---

## Deployment

Deployed on **Vercel**, root directory `app/web/greentech`, framework preset Vite.

| Domain | |
| --- | --- |
| `www.greenroutehere.tech` | production |
| `greenroutehere.tech` | 308 → www |
| `iemhacks-hackathon.vercel.app` | production alias |

All three, plus preview deployments (`iemhacks-hackathon-*.vercel.app`), are in the API's
`APP_CORS_ALLOWED_ORIGINS`. The API matches origins as **patterns**, because Vercel mints a new
hostname for every preview build and an exact list would reject each one — a CORS rejection
looks exactly like the API being down.

`vercel.json` rewrites all paths to `index.html`. Rewrites are evaluated after the filesystem
check, so `/assets/*`, `/GreenRoute.apk`, images and videos keep serving as themselves.

The APK is served straight from `public/` — refresh it with `npm run sync:apk` after a release
Flutter build.

---

## Project structure

```text
src/
  main.jsx            entry
  Router.jsx          routes and lazy boundaries
  index.css           design tokens: brand/depot scales, border, muted, card
  components/         15 landing sections + ui/ primitives
  pages/NotFound.jsx  custom 404
  admin/
    AdminLogin.jsx    sign-in
    AdminShell.jsx    sidebar, topbar, search, notifications, profile, assistant
    MunicipalAdmin.jsx
    SuperAdmin.jsx
    panels.jsx        the six reusable panels
    PointsMap.jsx     Mapbox, lazy-loaded
    Assistant.jsx     chat widget
    charts.jsx        Recharts wrappers
    widgets.jsx       stat tiles, tables, badges
  lib/
    api.js            every HTTP call
    auth.jsx          provider
    auth-context.js   hook and role helpers
    useApi.js         loading/error/refetch
    site.js           copy and links
```

`auth.jsx` and `auth-context.js` are split because react-refresh requires a module exporting
components to export *only* components — keeping the hook beside the provider broke fast
refresh.
