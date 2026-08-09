export const site = {
  name: "GreenRoute",
  name: "GreenRoute",
  tagline: "Scan it. Sort it. Get paid for it.",
  description:
    "A community waste-management and circular-economy platform. Citizens scan their waste, AI identifies and prices it, and a collector is dispatched — or they drop it at the nearest marked point. Everyone earns points for segregating correctly.",

  hackathon: {
    event: "IEMHACKS 4.0",
    track: "Track 04",
    code: "IEMH4-GT-01",
    theme: "Community Waste Management & Circular Economy",
  },

  region: {
    districts: ["Howrah", "North 24 Parganas"],
    state: "West Bengal",
    label: "Howrah & North 24 Parganas, West Bengal",
  },

  links: {
    apk: "/GreenRoute.apk",
    apk: "/GreenRoute.apk",
    demo: "#how-it-works",
    superAdmin: "/admin/super",
    municipalAdmin: "/admin/municipal",
    github: "#",
    docs: "#tech",
    email: "mailto:team@GreenRoute.example",
    email: "mailto:team@GreenRoute.example",
    twitter: "#",
    linkedin: "#",
    instagram: "#",
  },
}

/* -------------------------------------------------------------------------- */
/* Headline metrics — all measured, all cited                                  */
/* -------------------------------------------------------------------------- */

export const heroStats = [
  { value: 155, suffix: "", label: "Collection points seeded" },
  { value: 20, suffix: "", label: "REST endpoints" },
  { value: 16, suffix: "", label: "Waste categories" },
  { value: 57, suffix: "", label: "Backend tests passing" },
]

export const impactStats = [
  {
    value: 13,
    suffix: "",
    label: "Objects detected",
    caption: "From one real photo of a full bin",
  },
  {
    value: 2.4,
    suffix: "s",
    decimals: 1,
    label: "Round trip, both services",
    caption: "Almost all of it YOLO inference",
  },
  {
    value: 33,
    suffix: " km",
    label: "Route returned in 1.1s",
    caption: "6 stops across Howrah, 128 min",
  },
  {
    value: 0,
    suffix: "",
    /* "500s" uppercases into something that reads like a quantity, so the
       label says server errors instead. */
    label: "Server errors under probing",
    caption: "16 malformed or out-of-order requests, zero 500s",
  },
]

/* -------------------------------------------------------------------------- */
/* How a scan becomes a collection — the flow from the root README             */
/* -------------------------------------------------------------------------- */

export const pipeline = [
  {
    step: "01",
    title: "Take a photo of your waste",
    detail:
      "Open the app and point the camera at whatever you are throwing out. Nothing to fill in and no category to guess at — the photo is the whole thing.",
    note: "One photo, no forms",
    actor: "You",
  },
  {
    step: "02",
    title: "The app works out what it is",
    detail:
      "It recognises the material and counts how many pieces there are. A photo of one full bin came back as 13 plastic bottles, around 0.39 kg, in about two seconds.",
    note: "About 2 seconds",
    actor: "The app",
  },
  {
    step: "03",
    title: "You see the bin, the price and the points",
    detail:
      "Straight away you are told which coloured bin it belongs in, roughly what it is worth and how many reward points you have earned. Those 13 bottles came to about ₹9.",
    note: "Around ₹9 for 13 bottles",
    actor: "The app",
  },
  {
    step: "04",
    title: "Choose doorstep or drop-off",
    detail:
      "Have a collector come to your door, or carry it to the nearest collection point yourself. The app ranks nearby points by how long they actually take to reach, not by distance on a map.",
    note: "Drop-off earns more points",
    actor: "You",
  },
  {
    step: "05",
    title: "A collector takes the job",
    detail:
      "Doorstep requests go to every collector in the area at once, and the first to accept is on their way. Once someone has claimed your pickup, nobody else can take it.",
    note: "First to accept wins",
    actor: "Collector",
  },
  {
    step: "06",
    title: "It is weighed and you are paid",
    detail:
      "The collector weighs the waste in front of you and that weight sets the final price. Your points are added the moment the pickup is marked complete.",
    note: "Final price from the scale",
    actor: "Collector",
  },
]

/* -------------------------------------------------------------------------- */
/* Detection — what the scanner actually returns                               */
/* -------------------------------------------------------------------------- */

export const scanResult = {
  status: "MANUAL_PRICING_REQUIRED",
  eligible: true,
  totalObjects: 13,
  material: "PET Bottle",
  count: 13,
  bin: "BLUE",
  category: "PLASTIC",
  stream: "DRY",
  pricePerKg: 25,
  estimatedWeightKg: 0.39,
  minimumOffer: 8.29,
  estimatedOffer: 9.75,
  maximumOffer: 11.21,
  rewardPoints: 65,
  carbonSavedKg: 1.95,
  averageConfidence: 0.58,
  detectionQuality: "MEDIUM",
  processingTimeMs: 1800,
  finalPriceSetBy: "COLLECTOR",
  aiSummary:
    "13 PET Bottles detected. These are fully recyclable and should be placed in the Blue bin. Estimated total weight is 0.39 kg. The collector will verify the final weight before payment.",
}

export const detectionStatuses = [
  {
    status: "OK",
    eligible: true,
    meaning: "One material, confident, five items or fewer — the system stands behind the price.",
    tone: "ok",
  },
  {
    status: "MANUAL_PRICING_REQUIRED",
    eligible: true,
    meaning: "Real waste, but mixed or many items — the collector confirms the price on the scale.",
    tone: "ok",
  },
  {
    status: "NO_WASTE_DETECTED",
    eligible: false,
    meaning: "Person, animal or empty scene. Show the message, reopen the camera.",
    tone: "bad",
  },
  {
    status: "LOW_CONFIDENCE",
    eligible: false,
    meaning: "Too blurry or too far away for any detection to clear its floor.",
    tone: "bad",
  },
]

export const bins = [
  {
    name: "Blue",
    key: "BLUE",
    stream: "Dry",
    color: "var(--bin-blue)",
    materials: ["PET Bottle", "HDPE Bottle", "Aluminium Can", "Paper", "Cardboard", "Scrap Metal", "Food Container", "Plastic Cup"],
  },
  {
    name: "Green",
    key: "GREEN",
    stream: "Wet",
    color: "var(--bin-green)",
    materials: ["Organic Waste", "Glass Bottle"],
  },
  {
    name: "Red",
    key: "RED",
    stream: "Hazardous",
    color: "var(--bin-red)",
    materials: ["Battery", "Light Bulb", "E-Waste"],
  },
  {
    name: "Grey",
    key: "GREY",
    stream: "Dry",
    color: "var(--bin-grey)",
    materials: ["Plastic Wrapper", "Textile", "Mixed Waste"],
  },
]

/** The 16 categories, with the price and unit weight the pricing engine uses. */
export const wasteTypes = [
  { label: "PET Bottle", bin: "BLUE", price: 25, weight: 0.03, recyclable: true },
  { label: "HDPE Bottle", bin: "BLUE", price: 30, weight: 0.05, recyclable: true },
  { label: "Glass Bottle", bin: "GREEN", price: 2, weight: 0.4, recyclable: true },
  { label: "Aluminium Can", bin: "BLUE", price: 120, weight: 0.015, recyclable: true },
  { label: "E-Waste", bin: "RED", price: 60, weight: 1.5, recyclable: true },
  { label: "Scrap Metal", bin: "BLUE", price: 30, weight: 0.2, recyclable: true },
  { label: "Paper", bin: "BLUE", price: 12, weight: 0.2, recyclable: true },
  { label: "Cardboard", bin: "BLUE", price: 8, weight: 0.3, recyclable: true },
  { label: "Battery", bin: "RED", price: 30, weight: 0.05, recyclable: true },
  { label: "Food Container", bin: "BLUE", price: 15, weight: 0.02, recyclable: true },
  { label: "Plastic Cup", bin: "BLUE", price: 10, weight: 0.01, recyclable: true },
  { label: "Textile", bin: "GREY", price: 5, weight: 0.3, recyclable: false },
  { label: "Plastic Wrapper", bin: "GREY", price: 0, weight: 0.01, recyclable: false },
  { label: "Light Bulb", bin: "RED", price: 0, weight: 0.05, recyclable: false },
  { label: "Organic Waste", bin: "GREEN", price: 0, weight: 0.15, recyclable: false },
  { label: "Mixed Waste", bin: "GREY", price: 0, weight: 0.1, recyclable: false },
]

/* -------------------------------------------------------------------------- */
/* Platform capabilities                                                       */
/* -------------------------------------------------------------------------- */

export const features = [
  {
    icon: "ScanLine",
    title: "One-shot waste detection",
    description:
      "YOLOv8m at 1280 px maps detections onto 16 waste categories, each with a bin colour, price per kg, reward points and carbon saved. Image size — not confidence — turned out to be the biggest lever: 640 → 1280 px took the reference bin from 2 detections to 6.",
    tag: "Python · FastAPI",
  },
  {
    icon: "ShieldCheck",
    title: "Per-class confidence floors",
    description:
      "A grey plastic jug reads as a donut at 0.35 and library shelves read as books. Raising the global floor to 0.45 removes the donut but costs three real bottles, so unreliable COCO classes get their own floor instead.",
    tag: "Tuned on real photos",
  },
  {
    icon: "Users",
    title: "Five roles, one token",
    description:
      "Citizen, Collector, Recycler, Municipal Admin and Super Admin. Only the first three can be self-assigned at signup — the two admin roles return 403 and must be set directly in the database.",
    tag: "JWT · Google OAuth",
  },
  {
    icon: "Zap",
    title: "Race-proof acceptance",
    description:
      "A single atomic UPDATE … WHERE status = 'REQUESTED'. The read-then-write version passed every sequential test and then returned 200 to all six collectors tapping at once — five would have driven to claimed waste.",
    tag: "Verified 6-way",
  },
  {
    icon: "Route",
    title: "Road time, not straight lines",
    description:
      "A haversine shortlist in Postgres, then the top five ranked by real driving duration. Across the Hooghly the road runs up to 1.7× the straight line, so the nearest point on a map is frequently not the nearest to drive to.",
    tag: "Mapbox Matrix",
  },
  {
    icon: "Boxes",
    title: "Stop aggregation",
    description:
      "Drop-offs sharing a collection point collapse into one stop — six requests become a two-stop route. Capacity is enforced by weight, not item count, and anything that will not fit comes back in deferredPickupIds.",
    tag: "80 kg vehicle",
  },
  {
    icon: "Coins",
    title: "Points that reward the right thing",
    description:
      "Drop-off pays 8 points/kg against doorstep's 5, because it saves the municipality a vehicle trip. Scan points are per item rather than per kg, so a banana peel worth ₹0 still earns credit for correct segregation.",
    tag: "Server-side only",
  },
  {
    icon: "History",
    title: "History that scales",
    description:
      "Totals come from aggregate SQL across the user's entire history, so a profile screen is one call rather than walking every page. Paging the ids first avoids Hibernate loading every row into memory to paginate in Java.",
    tag: "HHH90003004 avoided",
  },
]

export const featureChecklist = [
  "Email OTP signup with a 10-minute TTL",
  "Google OAuth — one endpoint for signup and login",
  "Scan history, paginated and scoped to the caller",
  "Doorstep and drop-off collection modes",
  "Cancellation locked once a collector accepts",
  "Release hands a pickup back without cancelling it",
  "155 collection points across 4 municipalities",
  "Encoded polyline returned with every route",
  "Estimate and reality stored side by side",
  "Transactional welcome, OTP and sign-in-alert mail",
  "Ineligible scans still stored as a complete record",
  "Bounding boxes in the original image's coordinates",
]

/* -------------------------------------------------------------------------- */
/* Pickup lifecycle                                                            */
/* -------------------------------------------------------------------------- */

export const pickupStates = [
  {
    status: "REQUESTED",
    meaning: "Waiting in the open feed",
    actor: "Citizen may cancel · any collector may accept",
    tone: "amber",
  },
  {
    status: "ACCEPTED",
    meaning: "Claimed by a collector",
    actor: "That collector may complete or release",
    tone: "blue",
  },
  {
    status: "COMPLETED",
    meaning: "Collected, final weight and amount recorded",
    actor: "Terminal",
    tone: "green",
  },
  {
    status: "CANCELLED",
    meaning: "Withdrawn before acceptance",
    actor: "Terminal — but the scan can be re-requested",
    tone: "grey",
  },
]

export const collectionModes = [
  {
    mode: "DOORSTEP",
    title: "Doorstep",
    rate: 5,
    unit: "points / kg",
    description:
      "A collector drives to the address. Every registered collector is notified at once, and the first to accept wins.",
  },
  {
    mode: "DROP_OFF",
    title: "Drop-off",
    rate: 8,
    unit: "points / kg",
    description:
      "The citizen carries waste to a marked point. It pays more because it saves the municipality an entire vehicle trip.",
  },
]

/* -------------------------------------------------------------------------- */
/* Municipalities — the seeded network                                         */
/* -------------------------------------------------------------------------- */

export const municipalities = [
  { code: "HMC", name: "Howrah Municipal Corporation", district: "Howrah", points: 100 },
  { code: "BMC", name: "Bidhannagar Municipal Corporation", district: "North 24 Parganas", points: 30 },
  { code: "BRK", name: "Barrackpore Municipality", district: "North 24 Parganas", points: 25 },
  { code: "ULB", name: "Uluberia Municipality", district: "Howrah", points: 0, depotOnly: true },
]

export const localities = [
  "Shibpur", "Salkia", "Bally", "Liluah", "Belur",
  "Santragachi", "Tikiapara", "Salt Lake", "Barrackpore",
]

/* -------------------------------------------------------------------------- */
/* Stack                                                                       */
/* -------------------------------------------------------------------------- */

export const stack = [
  {
    layer: "Mobile",
    name: "Flutter",
    detail: "Riverpod state, go_router with an auth guard, shared_preferences session",
    items: ["Android", "iOS"],
  },
  {
    layer: "Web",
    name: "React + Vite",
    detail: "This portfolio and both admin consoles, styled with Tailwind v4",
    items: ["React 19", "Tailwind 4"],
  },
  {
    layer: "API",
    name: "Spring Boot 3.5",
    detail: "Java 17, JWT auth, 20 endpoints, the system of record for users and points",
    items: ["Java 17", "Hibernate"],
  },
  {
    layer: "Detection",
    name: "FastAPI + YOLOv8m",
    detail: "25.9M parameters, pretrained on COCO, no LLM anywhere in the detection path",
    items: ["Ultralytics", "Python"],
  },
  {
    layer: "Data",
    name: "PostgreSQL",
    detail: "Detections, materials, pickups, municipalities and collection points",
    items: ["Postgres", "Hikari"],
  },
  {
    layer: "Services",
    name: "Mapbox · Cloudinary · Resend",
    detail: "Road matrices and directions, image hosting, transactional mail",
    items: ["Matrix API", "Directions"],
  },
]

/* -------------------------------------------------------------------------- */
/* Honesty — the limitations section, kept verbatim in spirit                  */
/* -------------------------------------------------------------------------- */

export const limitations = [
  {
    title: "We did not train the model",
    body: "Detection is YOLOv8 pretrained on COCO. Training a waste detector from scratch was not realistic in the time available, so the recognition layer was made swappable — drop trained weights at app/weights/best.pt and the API contract does not change.",
  },
  {
    title: "COCO has no class for cans or wrappers",
    body: "Cans, wrappers, light bulbs, batteries and cardboard are invisible until trained weights are supplied. No confidence threshold can make a network emit a class it has no output neuron for.",
  },
  {
    title: "Weight is assumed, not measured",
    body: "A 250 ml bottle and a 2 L jug both count as 30 g. That is exactly why finalPriceSetBy flips to COLLECTOR on any mixed or multi-item scan — the scale decides what actually gets paid.",
  },
  {
    title: "Collection points are seeded demo data",
    body: "155 points generated by geocoding real localities through Mapbox and validated against district bounds. They are not an official municipal bin register, and we say so when asked.",
  },
  {
    title: "Routing is per collector, not fleet-wide",
    body: "my-route orders the stops a collector has already accepted. It is not dispatch. Mapbox Matrix caps at 25 coordinates, so a route is capped at 24 stops plus the depot.",
  },
]

export const faqs = [
  {
    question: "Did you train your own detection model?",
    answer:
      "No, and we would rather say so plainly. Detection uses YOLOv8 Medium pretrained on COCO — 25.9M parameters, trained by Ultralytics on roughly 118k hand-annotated photos. Training a waste detector from scratch was not realistic in a hackathon, so we made the recognition layer swappable and put the engineering into the domain layer: material taxonomy, bin routing, weight-based pricing and the confidence rules that catch what the model gets wrong. Drop trained weights in and the API contract does not change.",
  },
  {
    question: "Is there an LLM anywhere in this?",
    answer:
      "Not in the detection path. The aiSummary field is four conditional string concatenations — no API call, no model, no network. It is instant, free, works offline and cannot hallucinate a number that contradicts the JSON beside it. The content comes from a real CNN's detections; the sentence is templated.",
  },
  {
    question: "How accurate is the price?",
    answer:
      "The vision model contributes only the count. It cannot see whether a bottle is 250 ml or 2 L, whether it is empty or full, or how thick the plastic is. So the real error is not the ±15% band — it is the unit-weight assumption. That is why the final price is set by the collector's scale on any mixed or multi-item scan. The quote sets expectations; the scale decides payment.",
  },
  {
    question: "Why rank collection points by driving time instead of distance?",
    answer:
      "Because across the Hooghly the road runs up to 1.7× the straight line. Measured on real seeded data, a point 1.32 km away in a straight line is 2.25 km by road, and the nearest point on a map is frequently not the nearest to drive to. Ranking on haversine alone sends people to the wrong bank of the river. A haversine shortlist narrows candidates in Postgres, then Mapbox Matrix ranks the top five by real duration.",
  },
  {
    question: "What stops two collectors claiming the same pickup?",
    answer:
      "Acceptance is a single atomic UPDATE … WHERE status = 'REQUESTED' AND collector_id IS NULL. Whoever the database applies first wins; everyone else affects zero rows and gets a 409. This matters — the read-then-write version passed every sequential test and then returned 200 to all six collectors tapping at the same instant.",
  },
  {
    question: "Can a citizen cancel after a collector is on the way?",
    answer:
      "No. Cancellation is only allowed while the status is REQUESTED, because once a collector accepts they may already be travelling. If the collector genuinely cannot make it they call release instead, which returns the pickup to the open feed so the citizen keeps their request rather than being dropped.",
  },
  {
    question: "Why does drop-off pay more than doorstep?",
    answer:
      "8 points per kg against 5, because carrying waste to a marked point saves the municipality an entire vehicle trip. Both rates are environment-tunable, and points are credited on completion using the collector's weighed figure when available — never the client's word.",
  },
  {
    question: "Are the collection points real?",
    answer:
      "They are seeded demo data, generated by geocoding real localities — Shibpur, Salkia, Bally, Liluah, Belur, Santragachi, Tikiapara, Salt Lake and Barrackpore — through the Mapbox Geocoding API, then validated to fall inside district bounds. They are not an official municipal bin register. One thing we learned the hard way: geocoding administrative names is unreliable, since \"Howrah Municipal Corporation\" resolves to a town in Maharashtra. Locality names resolve correctly.",
  },
]

/* -------------------------------------------------------------------------- */
/* Admin console demo data — presentation only, no backend is wired up         */
/* -------------------------------------------------------------------------- */

export const adminRoles = [
  {
    key: "super",
    title: "Super Admin",
    href: "/admin/super",
    scope: "Every municipality, every user, every service",
    blurb:
      "Platform-wide health: service uptime, model version, role management and the seed register across all four municipalities.",
  },
  {
    key: "municipal",
    title: "Municipal Admin",
    href: "/admin/municipal",
    scope: "One municipality and its depot",
    blurb:
      "Ward-level operations: live pickups, collector fleet, collection-point register and diversion against target.",
  },
]

