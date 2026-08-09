# Green Route — mobile app

Flutter client for the Green Route waste-management and circular-economy platform.
One app, three ground-level roles: the **Citizen** who throws waste away, the
**Collector** who picks it up, and the **Recycler** who buys it. It talks to the Spring
service in [`service/api-java`](../../../service/api-java), which in turn calls the
YOLO detection service in [`service/api-python`](../../../service/api-python).

Built for Howrah and North 24 Parganas, West Bengal.

**67 Dart files · 20 routes · 3 roles · Riverpod + go_router**

| | |
| --- | --- |
| 📱 **Install** | **[www.greenroutehere.tech/GreenRoute.apk](https://www.greenroutehere.tech/GreenRoute.apk)** · 21.6 MB, arm64 |
| ⚙️ **Talks to** | [console.jotterly.tech](https://console.jotterly.tech/health) |
| 🌐 **Website** | [www.greenroutehere.tech](https://www.greenroutehere.tech) |

### Installing the APK

Android blocks sideloading by default. On the phone: download the link above, open it, and
when prompted allow **Install unknown apps** for the browser. The build is `arm64-v8a`, which
covers essentially every phone made since 2016; a very old 32-bit device will refuse it.

No configuration is needed — the release build already points at the deployed API, so it works
straight after install.

---

## The idea

Household waste in an Indian city is worth money, but nobody at the household knows
*which* part is worth money, and the people who would pay for it never find out it
exists. So it all goes into one bag and one bin, and a material that a recycler would
have paid for goes to landfill instead.

Green Route closes that gap with a photo.

A citizen photographs their waste. The app identifies every object in it, tells them
which coloured bin each piece belongs in, prices the lot in rupees, and shows the CO₂
they just saved. From that same result they can either call a collector to their door
or walk it to the nearest collection point — whichever they pick, the app credits Green
Points for segregating correctly and pays **more** for the option that saves the
municipality a vehicle trip. Collectors get those requests as a job queue, an optimised
driving route with a load gauge, and a weigh-and-pay step that settles the real amount.
Recyclers get a live market of already-sorted, already-weighed lots they can buy from a
wallet balance.

Nobody is asked to learn a colour code, fill in a form, or guess a price. **The photo
does the classification, the map does the logistics, and the points do the nudging.**

### Three problems it actually solves

| Problem | What the app does |
| --- | --- |
| People do not segregate because it is unrewarded and unverifiable | A photo verifies it, and points are credited server-side per material |
| Collection is unrouted — trucks wander, fuel burns | Requests aggregate into stops and get ordered by real driving time |
| Recyclers cannot source clean, sorted material at small scale | Every listing carries a scan: material, weight, catalogue rate, price |

---

## Feature map

Everything below is built and wired to the live API.

### Scanning and detection

- Capture from **camera or gallery**, downscaled to 1920 px at quality 88, rejected
  above 10 MB before it ever leaves the phone.
- An animated viewfinder and stepped progress overlay run while the image uploads
  (90 s upload timeout, because detection is the slow hop).
- The result breaks into **detected materials, environmental impact, where it goes,**
  and **the offer** — per material: count, bin colour, category, stream, recyclability,
  price per kg, estimated weight, estimated value, reward points, carbon saved.
- **Bin routing** is explicit — Blue (dry recyclables), Green (wet/compostable),
  Red (hazardous), Grey (non-recyclable) — with a primary and secondary bin
  recommendation and a "pickup recommended" flag.
- **Impact block**: estimated weight, CO₂ saved, landfill reduced, recyclable percent.
- **Offer block**: a min–estimate–max range rendered as a position on a bar, plus who
  sets the final price (`SYSTEM` or the collector).
- **Quality gate**: the detection comes back as `OK`, `MANUAL_PRICING_REQUIRED`,
  `NO_WASTE_DETECTED` or `LOW_CONFIDENCE`, with an average-confidence percentage. The
  app uses that status to decide whether to price the lot, hand pricing to the
  collector, or ask for a retake — rather than confidently pricing a blurry photo.
- Points show as **Credited** or **Pending — not credited yet**, and the new balance is
  echoed back into the session.
- Every scan is kept in **history**, paginated, and is what a pickup or a listing is
  later attached to.

### Pickups

- Request off an existing scan; the sheet lists scans not yet spoken for and refuses
  politely when there are none.
- **Two modes.** `DOORSTEP` collects a typed address, landmark, contact phone and
  notes. `DROP_OFF` finds collection points near you and marks the best-value one.
- Live status through `REQUESTED → ACCEPTED → COMPLETED`, with `CANCELLED` as an exit.
  A citizen can cancel while it is still `REQUESTED`; once a collector accepts, the
  cancel button is replaced by an explanation of why it is gone.
- A **detail screen** with a timeline (requested → accepted → collected and paid), the
  materials, the address, the collector, and a map.
- Money is carried as estimated offer versus final settled amount and final weight, so
  the app can show "quoted ₹X, paid ₹Y at Z kg" once the collector closes it out.

### Maps and location

The map layer is `flutter_map` over **Mapbox raster tiles** (`streets-v12`, 512 px @2x,
zoom 4–18), with an OSM/Mapbox attribution chip and drag / pinch / double-tap / fling
interaction that can be locked off for preview cards. Without a token the canvas
degrades to a labelled placeholder instead of a broken grid — everything else keeps
working.

Custom markers, all drawn in [`MapCanvas.dart`](lib/Widget/MapWidgets/MapCanvas.dart):

| Marker | Meaning |
| --- | --- |
| **User dot** | your live position |
| **Point pin** | a collection point, coloured and iconed by type |
| **Sequence pin** | a numbered stop in a collector's route order |
| **Depot pin** | the municipal depot a route starts and ends at |

Collection points come in four types, each with its own colour and icon: **MRF**
(recovery facility, blue), **bin cluster** (green), **scrap yard** (amber), **compost
hub** (violet). Each carries locality, ward, municipality, district, straight-line
distance, road distance and driving minutes — and the app prefers **road distance over
straight-line** whenever the server supplies it, which matters across the Hooghly where
the road can be 1.7× the crow flight.

Routes arrive as an **encoded polyline** and are decoded on-device
([`polyline.dart`](lib/Utils/polyline.dart), the standard Google/Mapbox varint
algorithm). If the server could not produce a geometry, the route falls back to
depot → stops → depot straight lines and the screen says **"Straight-line preview"**
rather than pretending it is a real road path.

Location is handled by [`LocationService`](lib/Service/LocationService.dart), which
distinguishes four failure modes — service off, denied, denied forever, unavailable —
gives each its own sentence, offers a deep link into system settings when the
permission is permanently blocked, and falls back to the last known position before
giving up. Nothing hard-fails on a location refusal: a pickup without coordinates is
still a valid pickup, it just cannot be slotted into a route, and the sheet says so.

Fallback centre is Howrah (22.5892, 88.3103) when there is no fix at all.

### Rewards and gamification

| Action | Reward |
| --- | --- |
| Verified segregation (scan) | per item, by material |
| Pickup completed | +20 Green Points flat |
| Doorstep pickup | +5 points/kg |
| Drop at a collection point | +8 points/kg |

Drop-off pays more because it saves a vehicle trip — the incentive is deliberately
pointed at the cheaper municipal outcome. Everything is credited server-side off the
collector's **weighed** figure, never the client's word.

The **Rewards** screen shows balance, rank, pickups done, CO₂ saved, and a merged
history of every scan and every completed pickup that moved the number. The
**Leaderboard** ranks the community and returns your own rank even when you are off
the visible page.

### Marketplace and wallet

- A citizen creates a **listing** — attach a scan and material, weight, price per kg
  and lot price fill themselves in — then can withdraw it while it is still open.
- A recycler browses the **market**, filters by material, sorts by newest, oldest,
  cheapest lot, dearest lot or heaviest, and buys.
- The buy sheet does the arithmetic up front: lot total, your balance, balance after,
  and **short by** when it cannot be afforded. Buying is instant and irreversible, and
  says so.
- The **wallet** is a real double-entry ledger view: every credit and debit, the reason,
  the running balance after each move, and the linked listing.
- Races are handled: a lot bought a second earlier fails with *"Someone bought this
  first."*

### Collector tools

- **Jobs** — open requests with the citizen's estimated weight and quoted offer.
  Accepting is first-come-first-served against the server, so a job someone else took
  fails with *"Someone got there first."* rather than double-assigning.
- **Route** — everything accepted, ordered for driving: numbered stops, total drive
  time, distance, and a **vehicle load gauge** against capacity. Drop-offs sharing a
  collection point collapse into one stop. Pickups that do not fit the vehicle are
  returned as *deferred* and the screen explains they stay assigned for the next run.
- **My work** — the active queue plus completed history with what was paid.
- **Weigh and complete** — enter the scale weight and the amount paid, with the photo
  estimate shown alongside for comparison and the citizen's projected points computed
  live before confirming.
- **Release** — a collector who cannot make it hands the job back with a reason, and it
  returns to the open pool.

### Assistant

An in-app chat that answers from the signed-in user's **real data**, not a generic
model. It sends the conversation ID, your coordinates when available, and any pickup or
listing in context, then renders which **tools** the assistant used to answer. Prompt
suggestions are role-aware and served by the backend (`/chat/capabilities`) — *"What is
my rewards summary?"*, *"Where is the nearest collection point?"*, *"What happened to
my last pickup?"*. Past conversations and transcripts are retrievable. When the backend
has it disabled the entry point states *"Currently unavailable"* instead of failing.

The recycler's buy sheet reuses the same assistant for a **market check** — *"Is this a
good deal?"* — comparing a lot against catalogue rates.

### Notifications

A 45-second poller that runs only while signed in, re-syncs whenever the app returns to
the foreground, and stops on sign-out. It diffs pickup state against what it last saw
in `shared_preferences` and raises `PICKUP_ACCEPTED`, `PICKUP_COMPLETED`,
`PICKUP_CANCELLED`, `PICKUP_RELEASED`; for collectors it watches the open pool and
raises `JOB_AVAILABLE`. The first run is silent by design — it seeds the baseline
rather than dumping your whole history as "new". History is capped at 60, persists
across launches, and is wiped on sign-out.

### Onboarding, auth and profile

A three-panel onboarding — *sort it right, turn waste into Green Points, pickups that
find you* — shown once and remembered. Splash restores the stored session and routes
to onboarding, auth, or home accordingly. Profile shows name, email and reward points,
with sign-out that clears the token, the notification cache and every cached provider.

---

## How a scan becomes a collection

```text
photo (camera or gallery, ≤10 MB, downscaled to 1920px)
   |
   v  POST /api/v1/detections
detection: materials, bin colour, kg, ₹ range, points, CO₂, confidence
   |
   v  POST /api/v1/pickups        mode = DOORSTEP | DROP_OFF
pickup opens; collectors in the municipality see it
   |
   v  POST /api/v1/pickups/{id}/accept
first collector wins; citizen can no longer cancel
   |
   v  GET /api/v1/routes/my-route
depot -> stops in driving order -> depot, encoded polyline, load vs capacity
   |
   v  POST /api/v1/pickups/{id}/complete   (weight + amount paid)
settled, points credited server-side, notification back to the citizen
   |
   v  POST /api/v1/listings  ->  /listings/{id}/interested
recycler buys the lot; wallet credits the seller, debits the buyer
```

---

## Navigation by role

The app reads the signed-in user's role and swaps its **entire** navigation for it —
tabs, routes and permissions all derive from `Role` in
[`lib/Model/AppUser.dart`](lib/Model/AppUser.dart).

| Role | Tabs | Also reachable |
| --- | --- | --- |
| **Citizen** | Home · Image · Pickup · Settings | rewards, leaderboard, wallet, listings, assistant, notifications, profile, pickup detail |
| **Collector** | Jobs · Route · My work · Settings | scan, nearby yards, assistant, notifications, profile |
| **Recycler** | Market · Purchases · Wallet · Settings | scan, nearby yards, assistant, notifications, profile |

The router does not merely hide tabs — `earnsRewards`, `canRequestPickup` and
`canSellScrap` are enforced as **redirects**, so a collector who deep-links to
`/rewards` lands on `/home` rather than on a disabled screen.

### Citizen screens

| Screen | What it does |
| --- | --- |
| **Home** | Green Points balance, community rank, CO₂ saved, active pickups, quick actions |
| **Image** | Camera or gallery → detection → materials, bins, weight, value, points |
| **Pickup** | Request off a scan, then track it to completion, with a map |
| **Sell waste** | List a segregated lot, withdraw it, see who bought it |
| **Rewards** | Points history per scan and per pickup, and how points add up |
| **Wallet** | Balance and every credit and debit from marketplace sales |
| **Leaderboard** | Community ranking, with your own rank even when off-page |
| **Assistant** | Chat answering from your real pickups, points, payments and location |

---

## Run

```bash
flutter pub get
flutter run
```

Map tiles need a Mapbox token, passed at build time:

```bash
cp dart_define.example.json dart_define.json
flutter run --dart-define-from-file=dart_define.json
```

| Define | Required | Purpose |
| --- | --- | --- |
| `MAPBOX_ACCESS_TOKEN` | for maps | Mapbox public token (`pk.…`). Empty shows a placeholder; everything else still works. |

The API host and Google client ID are compile-time constants in
[`lib/Config/ApiConfig.dart`](lib/Config/ApiConfig.dart) — point `baseUrl` at your
running backend:

| Target | Base URL |
| --- | --- |
| Deployed API (default) | `https://console.jotterly.tech` |
| Android emulator → local backend | `http://10.0.2.2:9000` |
| iOS simulator / desktop → local | `http://localhost:9000` |
| Physical device → local | your machine's LAN IP |

> The default is the deployed API, so a fresh clone runs without a backend. Note the local
> port is **9000**, which is what `service/api-java/.env` sets — not 8080.
>
> Never ship a build pointing at a development tunnel. A tunnel URL stops existing the moment
> the tunnel closes, and an installed app pointing at one is dead on arrival with no way to fix
> it short of a new release.

Timeouts are deliberately tiered: **20 s** for normal calls, **90 s** for the scan
upload, **60 s** for assistant replies. Map defaults and the fallback centre live in
[`lib/Config/MapConfig.dart`](lib/Config/MapConfig.dart).

### Permissions

| Permission | Needed for | If refused |
| --- | --- | --- |
| Camera | scanning waste | gallery still works |
| Photo library | scanning from an existing photo | camera still works |
| Location | nearest points, routing, nearby yards | pickups still work, just unrouted |

---

## Auth

Signup is five steps — email → OTP → name → password → role — because
`POST /auth/register` verifies the OTP and creates the account in one call. A rejected
OTP returns to the code step with the digits cleared; a taken email returns to step one.
The password step has a live checklist rather than a rejection after submit.

Google sign-in is live via `google_sign_in`. The app obtains an **ID token** and posts
it to `POST /auth/google`; the backend verifies the signature and the `aud` claim
against its own `GOOGLE_CLIENT_ID`, so both sides must use the same **Web** OAuth
client ID. Worth knowing:

- **One endpoint does signup and login.** An unknown Google email creates the account;
  a known one signs in. The client cannot tell them apart and does not need to.
- **`role` only applies at creation.** The button sits on the selection screen
  defaulting to `CITIZEN`, so collectors and recyclers must use the email flow.
- **Login methods cannot mix.** A Google-created email rejects password login, and a
  password-created email rejects Google.

The access token lasts 7 days with no refresh token, is stored in `shared_preferences`
alongside a cached user, and is restored on launch. An expired token is discarded and
the user signs in again.

| Screen | Endpoint |
| --- | --- |
| Signup step 1 | `POST /auth/send-otp` |
| Signup step 5 | `POST /auth/register` |
| Login | `POST /auth/login` |
| Google button | `POST /auth/google` |
| Splash / refresh | `GET /auth/me` |

---

## API surface used

All under `/api/v1` unless shown otherwise, all bearer-authenticated except the auth
endpoints.

| Area | Endpoints |
| --- | --- |
| Auth | `/auth/send-otp`, `/auth/register`, `/auth/login`, `/auth/google`, `/auth/me` |
| Detection | `POST /detections` (multipart), `GET /detections` (paged history) |
| Pickups | `POST /pickups`, `GET /pickups`, `GET /pickups/{id}`, `/cancel` |
| Collector | `GET /pickups/available`, `/accept`, `/complete`, `/release`, `GET /routes/my-route` |
| Points | `GET /collection-points`, `/nearest?lat&lon&limit`, `/municipalities` |
| Market | `GET /listings`, `/listings/mine`, `POST /listings`, `/{id}/interested`, `/{id}/cancel` |
| Money | `GET /wallet`, `GET /leaderboard` |
| Assistant | `GET /chat/capabilities`, `POST /chat`, `GET /chat/conversations`, `/conversations/{id}` |

---

## Architecture

```text
lib/
  main.dart                    theme + MaterialApp.router
  Config/
    ApiConfig.dart             base URL, Google client ID, tiered timeouts, headers
    MapConfig.dart             Mapbox token, tile URL, zoom bounds, fallback centre
  Model/                       AppUser/Role, AuthSession, Detection (+materials, offer,
                               impact, recommendation, quality), Pickup (+status, mode,
                               money, party), Listing (+status, sort), Wallet,
                               CollectionPoint (+type, Municipality), CollectorRoute
                               (+depot, stop, polyline), Leaderboard, Chat,
                               AppNotification
  Provider/
    SessionProvider.dart       restore, adopt, refresh, sign out
    SignupProvider.dart        the five-step signup machine
    CitizenProviders.dart      pickups, wallet, leaderboard, detection history,
                               my listings, market, purchases, available jobs, route,
                               notifications poller, signOutAndReset
  Routes/Routes.dart           go_router, auth guard, role guard, 404
  Screen/
    Splash, Onboarding, Auth   first-run gate, selection, login, five-step signup
    Home                       home, scan, pickup, settings (the citizen tabs)
    Pickup                     request sheet, detail with timeline and map
    Collector                  jobs, route, my work, complete/release sheet
    Recycler                   market, purchases, buy sheet, nearby yards
    Marketplace, Wallet        listings, ledger
    Rewards                    points history, leaderboard
    Chat, Notifications, Profile, NotFound
  Service/
    ApiService.dart            every call, multipart upload, typed ApiException
    GoogleAuthService.dart     ID token, typed cancelled/failed exceptions
    LocationService.dart       permission ladder, last-known fallback, settings deep link
    UserService.dart           token + user persistence, expiry check
    ToastService.dart          in-app messages
  Utils/                       AppColors, polyline decoder, avatar helper
  Widget/
    UiKit.dart                 design tokens, buttons, fields, dashed borders, animations
    BottomNavBar.dart          role-driven tabs + the notification watcher lifecycle
    MapWidgets/MapCanvas.dart  tiles, attribution, user dot, point/sequence/depot pins
    ScanWidgets/               source sheet, viewfinder, progress steps, result view
    AuthWidgets/               auth shell, OTP input, password checklist
    CitizenWidgets/            shared citizen cards
```

**State** is `flutter_riverpod`, one `AsyncNotifier` per data domain, all invalidated
together on sign-out. **Routing** is `go_router` with a redirect guard listening to the
session provider. Tabs live in a `PageView` with paging disabled, so switching keeps
each tab's state alive instead of rebuilding it.

**Design system** — a single warm-paper background (`#FCFAF6`), near-black ink, the
CodecPro typeface, and a token set in [`UiKit.dart`](lib/Widget/UiKit.dart): ink /
secondary / tertiary, hairlines, fills, green, danger, amber, plus two shared durations
and one easing curve so every animation in the app moves the same way. Haptics fire on
tab changes. Currency and weight formatting are centralised (`rupees()`,
`kilograms()`), so ₹ and kg read identically everywhere.

**Error handling** is typed end to end: `ApiException` carries the HTTP status and the
server's message, `LocationException` carries a failure kind and whether settings can
be opened, `GoogleAuthCancelled` is distinguished from `GoogleAuthException` so a user
backing out of the Google sheet is not shown an error.

---

## Build and release

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=dart_define.json
```

`--split-per-abi` produces one APK per architecture instead of a fat binary carrying all of
them. The arm64 output is what gets published:

```text
build/app/outputs/apk/release/app-arm64-v8a-release.apk      ~21.6 MB
```

Publishing it to the website is one command from the web app:

```bash
cd ../../web/greentech && npm run sync:apk
```

That copies the arm64 APK into `public/GreenRoute.apk`, so the next Vercel deploy serves it at
[www.greenroutehere.tech/GreenRoute.apk](https://www.greenroutehere.tech/GreenRoute.apk) with
the correct `application/vnd.android.package-archive` content type.

**Check `ApiConfig.baseUrl` before every release build.** It is a compile-time constant, so a
wrong value cannot be corrected after install — only by shipping a new APK.

The release build is unsigned beyond Flutter's debug-key default, which is fine for sideloading
and a hackathon demo but not for the Play Store; that needs a real keystore and
`android/key.properties`.

---

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `Can't reach the server` | Backend down, or `ApiConfig.baseUrl` points at a host the device cannot see — an emulator alias or a stale tunnel URL. |
| Map shows "Map needs a Mapbox token" | `MAPBOX_ACCESS_TOKEN` not passed at build time. |
| Route shows "Straight-line preview" | The server returned no polyline geometry — usually a missing or rate-limited Mapbox token on the backend. |
| Google button missing | `ApiConfig.googleServerClientId` is empty. |
| `Invalid Google token` | App and backend are on different client IDs, or the wrong type — both need the **Web** one. |
| OTP email never arrives | `RESEND_API_KEY` unset in the backend `.env`, or `MAIL_ENABLED=false` (the OTP is printed in the backend terminal instead). |
| Pickup sheet warns about routing | Location denied — the pickup still works, it just cannot join a collector route. |
| No drop-off points found | You are outside the seeded municipalities; choose doorstep instead. |
| Scan says "Collector sets the price" | Detection returned `MANUAL_PRICING_REQUIRED` — the material is recognised but not confidently priceable from a photo. |
| Signed out on every launch | Token expired (7 days) or the backend's `JWT_SECRET` changed. |

---

## Known limits

- Notifications are **polled every 45 seconds**, not pushed — no FCM/APNs yet, so a
  status change can be up to 45 s stale and nothing arrives while the app is killed.
- Weight before collection is **estimated from the photo**, not measured, which is why
  the collector's scale sets the final price on any mixed or multi-item pickup.
- The detection model is **COCO-pretrained**, so cans, wrappers, bulbs and batteries
  are invisible until trained weights are supplied to the Python service.
- The wallet is a **dummy ledger** — no payment gateway is integrated; it exists so the
  circular-economy loop is demonstrable end to end.
- Route optimisation is **per collector**, ordering stops they already accepted, and is
  capped at 24 stops plus the depot by Mapbox's Matrix limit. It is not fleet-wide
  dispatch.
- `ApiConfig` values are **compile-time constants**, so pointing at a different backend
  means editing the file and rebuilding.

