# GreenRoute — Demo Video Script

**Team Wildcards · IEMHACKS 4.0 · Track 04 (`IEMH4-GT-01`)**

Target runtime **4:50** · ~710 spoken words at ~150 wpm.
Left column = what is on screen. Right column = what is said.
`[ ]` = placeholder to fill before recording.

---

## 1 · Intro & Team — 0:00 → 0:35

| On screen | Voiceover |
| --- | --- |
| Logo animation → title card **GreenRoute**, subtitle *Team Wildcards*. Cut to a 2-second street shot of a mixed waste bin. Then a phone in hand opening the app. | Every day a household throws away a bag of waste that is actually worth money — and nobody in that house knows which part is worth money, or where it should go. So it all goes into one bin, and material a recycler would have paid for ends up in landfill. |
| Team card: four names + photos, **Team Wildcards** lockup held on screen. | We are **Team Wildcards**, and this is **GreenRoute** — a community waste management and circular economy platform built for Howrah and North 24 Parganas. One photo. That is the whole ask from the citizen. Everything after it is automatic. |

> **Cue:** hold the team card for a full 4 seconds so names are readable.

---

## 2 · Web Portfolio & Dashboards — 0:35 → 1:20

| On screen | Voiceover |
| --- | --- |
| Screen recording: scroll the landing page — Hero → Scanner demo → Roles → Impact stats counting up. Slow, smooth scroll. | This is greenroutehere.tech — our public site. It walks you through a real scan result, so you understand the product before you install anything, and the Android app downloads straight from the header. |
| Cut to `/admin/login` → **Municipal console** dashboard. Show the KPI cards, the bin-split chart, the map of collection points. | And this is where the municipality works. The **municipal dashboard** shows waste collected, pickups completed, carbon saved and how the city's waste splits across the blue, green, red and grey bins — colour-coded to the actual bins, not arbitrary chart colours. |
| Click through: People → Collection points → Map panel → Pricing. Quick, one beat each. | Staff onboard collectors and recyclers, manage collection points on a live map, and see the pricing table for every material. |
| Cut to **Super admin** console — municipalities panel, system health panel with green dependency ticks. | The **super admin** sees the entire platform — every municipality, every user, and a live system health view. And both consoles have an assistant: ask a question in plain English, get an answer from live data. |

> **Cue:** for the assistant, type a real question on camera — *"Compare waste diverted by municipality"* — and let the answer render.

---

## 3 · Tech Stack — 1:20 → 1:40

| On screen | Voiceover |
| --- | --- |
| Clean animated stack diagram: **Flutter app + React web → Spring Boot API → YOLOv8 detection service**, with Postgres, Mapbox and Cloudinary hanging off it. Logos fade in as named. | Very quickly, under the hood: a **Flutter** app and a **React** web console, a **Spring Boot** API doing auth, pickups, routing and payments, and a separate **Python** service running a **YOLOv8** vision model for detection. **PostgreSQL** for data, **Mapbox** for real road routing — all containerised, auto-deployed, and live in production right now. |

> **Cue:** keep this section visual-heavy and fast. Nothing else technical appears in the video.

---

## 4 · The Citizen App — 1:40 → 2:55

| On screen | Voiceover |
| --- | --- |
| Phone screen: open app → tap scan → camera viewfinder over a real pile of waste → shutter → progress overlay. | Now the app itself. First role — the **citizen**. |
| Detection result screen scrolling: material list with counts. | You photograph your waste. The app identifies every object in it — sixteen material types — and for each one tells you the **count, the bin colour it belongs in, the price per kilo and the reward points**. |
| Zoom on the bin-routing block — blue / green / red / grey chips. | Blue for dry recyclables, green for wet, red for hazardous, grey for the rest. Nobody has to memorise a colour code. |
| Impact block: weight, CO₂ saved, landfill reduced. Then the offer bar with min–estimate–max. | It shows the **carbon you just saved**, and it prices the lot — a realistic minimum to maximum range, not a fake exact number. If the photo is blurry or it is unsure, it says so and hands pricing to the collector instead of guessing. |
| Two buttons: **Request pickup** / **Drop off**. Tap drop-off → map with nearest points, best-value one highlighted. | From that result you choose. Call a collector to your door — or drop it yourself at the nearest collection point, ranked by **real driving time**, not straight-line distance. Drop-off pays you more, because it saves the city a vehicle trip. |
| Rewards screen: balance, rank, pickups, CO₂. Then leaderboard. | Points are credited when the waste is actually handed over and weighed — so you cannot farm the same photograph. And there is a community leaderboard. |
| Open the **assistant** chat, type *"What happened to my last pickup?"* → answer renders with tool chips. | And every citizen has an **AI assistant** that answers from *your* real data — your wallet, your pickups, your nearest drop point. Not a generic chatbot. Ask it anything about your account and it looks the answer up live. |

---

## 5 · The Collector App — 2:55 → 3:40

| On screen | Voiceover |
| --- | --- |
| Same app, collector login. **Jobs** screen: list of open requests with weight and offer. Tap accept. | Second role — the **collector**. Every citizen request lands here as a job, with the estimated weight and the quoted amount. First to accept it gets it — there is no double-assignment. |
| **Route** screen: map with numbered stops, depot pin, polyline drawn, total distance and drive time, load gauge filling. | Then the app builds the route. Everything they have accepted gets **ordered for driving** — real roads, real time — with total distance, drive time and a **vehicle load gauge**. If a pickup will not fit in the van, it stays assigned for the next run and the app says so. |
| **Weigh and complete** screen: enter scale weight and amount paid, projected points update live. Tap confirm. | At the door they **weigh it on a scale**, enter what they actually paid, and the citizen's points are calculated from that real weight. And if they cannot make a job, they release it back to the pool. |

---

## 6 · The Recycler App — 3:40 → 4:20

| On screen | Voiceover |
| --- | --- |
| Recycler login → **Marketplace** feed. Scroll listings. Apply a material filter, then sort by cheapest. | Third role — the **recycler**. This is the market. Every listing here comes from a scan, so it is already **sorted, already weighed, and already priced** — material, weight, rate per kilo and lot total. Filter by material, sort by price or weight. |
| Tap a listing → buy sheet showing lot total, balance, balance after. Confirm → success. | The buy sheet does the maths before you commit: lot total, your balance, and what is left afterwards. If two people go for the same lot, only one wins — cleanly. |
| **Wallet** screen: ledger of credits and debits with running balance. | The wallet is a full ledger — every credit, every debit, the reason, and the running balance. |
| Open the recycler **assistant**, ask *"Is this listing worth buying?"* → verdict with margin. | And the recycler's **AI assistant** is a buying advisor — ask it whether a lot is worth buying and it compares the asking price against the catalogue rate, works out the margin, and gives you a verdict. It will also find the best-value listings for you. |

---

## 7 · Outro — 4:20 → 4:50

| On screen | Voiceover |
| --- | --- |
| Quick montage, ~1 second each: scan result → route map → marketplace buy → dashboard chart. | So: a citizen photographs their waste and gets paid for sorting it. A collector drives an optimised route instead of wandering. A recycler sources clean material at small scale. And the municipality sees all of it on one dashboard. |
| Full-screen card: **greenroutehere.tech** + APK QR code + **Team Wildcards**. | One loop — closed by a photo. **GreenRoute** is live at greenroutehere.tech, the app is downloadable today, and everything you just saw is running in production. |
| Logo out. | Thank you — from **Team Wildcards**. |

---

## Recording checklist

- **Pace:** ~150 words per minute. If a section runs long, trim the tech stack first — never the app demos.
- **Screen capture:** record the phone at 60fps and slow the scan-processing wait to a 2× speed-up rather than cutting it — the wait is honest.
- **Have ready before recording:** a real bag of mixed waste, a seeded collector account with 3+ accepted pickups so the route has visible stops, a recycler wallet with balance, and at least one open marketplace listing.
- **Assistant shots:** pre-run each question once so the response is warm and renders fast.
- **Audio:** record voiceover separately and lay it over the screen capture; do not narrate live.
- **Fill before recording:** team member names on the team card.
