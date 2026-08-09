export const site = {
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
    demo: "#how-it-works",
    superAdmin: "/admin/super",
    municipalAdmin: "/admin/municipal",
    github: "#",
    docs: "#tech",
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
    title: "One photo is all it takes",
    description:
      "Point the camera at whatever you are throwing out. The app names the material, tells you which coloured bin it belongs in, what it is worth per kilo and the points you will earn — across 16 kinds of everyday waste.",
    tag: "No forms to fill in",
  },
  {
    icon: "ShieldCheck",
    title: "It says when it is not sure",
    description:
      "A photo taken too far away or in poor light gets sent back with a message asking for another, instead of turning into a confident wrong answer. You are never quoted a price the app could not really see.",
    tag: "No confident guesses",
  },
  {
    icon: "Users",
    title: "One account, whichever role you are",
    description:
      "Sign up as a household, a collector or a recycler using an email address or your Google account. Municipal staff accounts are issued by the municipality itself, so nobody can hand themselves admin access.",
    tag: "Email or Google",
  },
  {
    icon: "Zap",
    title: "Your pickup is claimed only once",
    description:
      "When several collectors tap accept at the same moment, exactly one of them gets the job. Nobody drives across town to waste that somebody else has already taken.",
    tag: "Tested with six at once",
  },
  {
    icon: "Route",
    title: "Nearest by time, not by map distance",
    description:
      "Collection points are ranked by how long they actually take to reach. Across the Hooghly the road can run nearly twice the straight-line distance, so the closest dot on a map is often not the closest place to go.",
    tag: "Real road times",
  },
  {
    icon: "Boxes",
    title: "Fewer trips for the same waste",
    description:
      "Drop-offs left at the same collection point are grouped into a single stop, so six requests can become a two-stop round. A vehicle is filled by weight, and anything that will not fit is kept for the next run.",
    tag: "Six requests, two stops",
  },
  {
    icon: "Coins",
    title: "Points that reward sorting, not volume",
    description:
      "Carrying waste to a collection point earns 8 points a kilo against 5 for a doorstep pickup, because it saves the municipality a trip. Even a banana peel worth ₹0 earns points, because sorting it correctly is the whole idea.",
    tag: "8 points a kilo",
  },
  {
    icon: "History",
    title: "Your totals are always ready",
    description:
      "Everything you have ever scanned, what it weighed and what it earned you, on one screen that opens straight away — however long you have been using the app.",
    tag: "Opens instantly",
  },
]

export const featureChecklist = [
  "Sign up with an email code, or with Google",
  "Every scan you have made, kept in one place",
  "Choose a doorstep pickup or a drop-off",
  "Cancel any request before a collector takes it",
  "A collector can hand a job back without cancelling it",
  "155 collection points across 4 municipalities",
  "Turn-by-turn route for the collector's whole round",
  "The quoted price and the weighed price, side by side",
  "Welcome, sign-in and verification emails",
  "Photos the app cannot price are still saved for you",
  "Points added the moment a pickup is completed",
  "Free to use, no ads and no charge to a household",
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
    question: "What is GreenRoute, in one line?",
    answer:
      "An app that tells you what your waste is worth and then gets someone to come and take it. You photograph what you are throwing out, the app names the material and the bin it belongs in, quotes a price and credits you points — then a collector comes to your door, or you drop it at a marked point nearby.",
  },
  {
    question: "Does it cost anything to use?",
    answer:
      "No. The app is free, there are no ads and a household is never charged. You are the one being paid — in cash from the collector for what the waste is worth, and in points for having sorted it correctly.",
  },
  {
    question: "What can I actually scan?",
    answer:
      "Sixteen kinds of everyday waste: plastic and glass bottles, cans, paper, cardboard, food containers, plastic cups, scrap metal, batteries, light bulbs, electronics, cloth, wrappers and food waste. Every one of them resolves to a blue, green, red or grey bin, so you always know where it should go.",
  },
  {
    question: "How much is this really worth?",
    answer:
      "Less than people expect for one item, and more than they expect over a month. A photo of a single full bin came back as 13 plastic bottles worth around ₹9. The value is in doing it every week — and in the points, which build up faster than the cash and are what a municipality can reward you for.",
  },
  {
    question: "Who actually comes to collect it?",
    answer:
      "Registered collectors working in your area. With a doorstep request every nearby collector is notified at once and the first to accept takes the job, so you are not left waiting on one person. With a drop-off you carry it to a marked collection point yourself, which pays more because it saves a vehicle trip.",
  },
  {
    question: "How is the price decided — could I be short-changed?",
    answer:
      "The app's figure is an estimate from what it can see in the photo. The final price comes from the collector weighing the waste in front of you. Both numbers are kept side by side in your history, so an estimate and what you were actually paid are always there to compare.",
  },
  {
    question: "What happens if the app gets it wrong?",
    answer:
      "If a photo is blurry, taken from too far away or has no waste in it, you are asked to take another rather than handed a confident wrong answer. It also cannot tell a 250 ml bottle from a two-litre one — which is exactly why the scale, not the camera, decides what you are paid.",
  },
  {
    question: "Can I cancel after a collector has accepted?",
    answer:
      "Not once someone has accepted, because they may already be on their way to you. You can cancel freely up until that moment. If the collector cannot make it after all they hand the job back, and your request returns to the queue for someone else instead of being lost.",
  },
  {
    question: "Is my area covered?",
    answer:
      "Today the network covers Howrah and North 24 Parganas in West Bengal — 155 collection points across four municipalities, including Shibpur, Salkia, Bally, Liluah, Belur, Santragachi, Tikiapara, Salt Lake and Barrackpore. Those points are demo data built from real localities rather than an official municipal bin register, so treat them as a working map, not a published one.",
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

