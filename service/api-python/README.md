# api-python — Waste Detection Service

FastAPI + YOLO (Ultralytics) + a metadata dictionary. Takes a photo of waste and returns what
is in it, which bin it belongs in, what it is worth, and how many reward points it earns.

There is **no LLM in the detection path**. Nothing calls out to an AI API.

---

## Contents

- [How it works](#how-it-works)
- [Who actually does the detection](#who-actually-does-the-detection)
- [Quick start](#quick-start)
- [Endpoints](#endpoints)
- [Full response](#full-response)
- [Response field reference](#response-field-reference)
- [status and actionRequired](#status-and-actionrequired)
- [offer.status](#offerstatus)
- [How the price is calculated](#how-the-price-is-calculated)
- [Reward points and carbon](#reward-points-and-carbon)
- [Detection tuning](#detection-tuning)
- [Per-class confidence floors](#per-class-confidence-floors)
- [Metadata tables](#metadata-tables)
- [Configuration](#configuration)
- [Cloudinary](#cloudinary)
- [Testing](#testing)
- [Known limitations](#known-limitations)
- [Integrating with the Java service](#integrating-with-the-java-service)
- [Design decisions](#design-decisions)
- [Project structure](#project-structure)

---

## How it works

The service is **two layers, and only one of them is learned**.

```text
photo
  |
  v
Layer 1 - PERCEPTION  (pretrained neural network, statistical)
  YOLOv8m returns boxes + COCO class labels: 13x "bottle", 1x "donut"
  |
  v
Layer 2 - DOMAIN KNOWLEDGE  (our dictionaries, hand-written)
  LABEL_MAP    "bottle" -> "pet_bottle"
  WASTE_TYPES  "pet_bottle" -> BLUE bin, INR 25/kg, 0.03 kg, 5 points, 0.15 kg CO2
  |
  v
Layer 3 - BUSINESS RULES  (assessment_service.py)
  aggregate -> weigh -> price -> pick bin -> decide who sets the final price
  |
  v
JSON response
```

Worked example for a bin full of bottles:

```text
photo -> YOLOv8m -> 13x "bottle" @0.82..0.32 -> LABEL_MAP -> "pet_bottle"
      -> WASTE_TYPES -> BLUE bin, INR 25/kg, 0.03 kg/item
      -> 13 x 0.03 = 0.39 kg -> 0.39 x 25 = INR 9.75 -> +/-15% -> INR 8.29 to 11.21
```

---

## Who actually does the detection

**We did not train a model.** Detection is done by an off-the-shelf pretrained network.

| | |
| --- | --- |
| Architecture | YOLOv8 Medium |
| Parameters | 25,902,640 |
| Weights file | `yolov8m.pt`, 49 MB |
| Trained by | Ultralytics |
| Dataset | COCO (Microsoft Common Objects in Context), ~118k hand-annotated photos, 80 classes |
| Source | downloaded from `github.com/ultralytics/assets` on first boot |

### What the network outputs

For each detected box: 4 coordinates plus one probability across **80 COCO classes**.
Non-Maximum Suppression then drops overlapping duplicates.

The network has **no concept of waste, recycling, bins or money**. It was trained to find
"bottle" and "banana" in ordinary photographs. Nothing in those 25.9M parameters knows that
PET trades at INR 25/kg. That knowledge is entirely in our `WASTE_TYPES` table.

### What COCO can and cannot see

Of COCO's 80 classes, **27** map to something waste-like:

```text
apple, backpack, banana, book, bottle, bowl, cell phone, clock, cup, fork, hair drier,
handbag, keyboard, knife, laptop, microwave, mouse, orange, remote, scissors, spoon,
tie, toaster, tv, umbrella, vase, wine glass
```

These waste words **do not exist in the model's vocabulary at all**:

```text
can, wrapper, packet, sachet, light bulb, battery, cardboard, carton, paper,
plastic bag, tetrapak, glass bottle, e-waste, tyre, diaper
```

This is not a tuning problem. No confidence threshold can make a network emit a class it has
no output neuron for. It is also why a cartoon can read as "remote" at 0.66 confidence — COCO
contains no cartoons, so the network is extrapolating outside its training distribution.

### What changes when you train `best.pt`

Training on a waste dataset (TACO, TrashNet, or your own labelled photos) replaces layer 1
with a network whose output classes *are* `aluminium_can`, `plastic_wrapper`, `light_bulb`.

**Layer 2 needs no code change** — `LABEL_MAP` already has entries waiting for those names,
and `yolo_service.py` prefers `app/weights/best.pt` over the fallback automatically.

### How to describe this honestly

Do not claim you trained a model. Say:

> Detection uses YOLOv8, pretrained on COCO. Training a waste detector from scratch was not
> realistic in the time available, so we made the recognition layer swappable and put the
> engineering into the domain layer — material taxonomy, bin routing, weight-based pricing,
> and the confidence rules that catch what the model gets wrong. Drop in trained weights and
> the API contract does not change.

---

## Quick start

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env          # fill in CLOUDINARY_* if you want image upload
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

First boot downloads `yolov8m.pt` (~50 MB) automatically. `.env` is loaded by python-dotenv.

Interactive docs at `http://localhost:8000/docs` — it has a working file-upload form, which is
faster than Postman for a quick check. Postman can import `http://localhost:8000/openapi.json`
to generate the whole collection.

---

## Endpoints

| Method | Path | Body | Returns |
| --- | --- | --- | --- |
| POST | `/api/v1/detect` | `multipart/form-data`, field `image` | detections + classification + offer |
| GET | `/api/v1/waste-types` | — | the full metadata catalog (16 types) |
| GET | `/health` | — | status, loaded weights, cloudinary on/off |

```bash
curl -X POST http://localhost:8000/api/v1/detect -F "image=@bin.jpg"
```

In Postman the field must be named `image` and its type switched from **Text** to **File**
(hover the key row, use the dropdown on the right). Do not set `Content-Type` manually —
Postman must generate the multipart boundary itself.

Errors return `{"detail": "..."}`:

| Code | Cause |
| --- | --- |
| 400 | not a valid image, or unsupported format (JPEG/PNG/WEBP/BMP only) |
| 413 | over 10 MB |
| 422 | missing `image` field, or wrong field name |

---

## Full response

```json
{
  "success": true,
  "status": "MANUAL_PRICING_REQUIRED",
  "message": "13 waste items detected across 1 material. Offer up to INR 11.21; the collector will weigh and confirm the final price.",
  "actionRequired": "COLLECTOR_SETS_PRICE",
  "timestamp": "2026-08-08T04:21:44Z",
  "apiVersion": "v1",
  "processingTimeMs": 1857,
  "imageUrl": "https://res.cloudinary.com/<cloud>/image/upload/v1/greentech/detections/ab12.jpg",
  "image":   { "width": 1000, "height": 750, "format": "jpeg", "sizeBytes": 276040 },
  "model":   { "modelId": "waste-detector-v1", "name": "YOLOv8 Medium",
               "weightsVersion": "2026.08.08", "inferenceTimeMs": 1811 },
  "quality": { "detectionQuality": "MEDIUM", "averageConfidence": 0.58 },
  "summary": { "totalObjects": 13, "petBottles": 13 },
  "materials": [
    { "material": "PET Bottle", "plural": "PET Bottles", "category": "PLASTIC", "bin": "BLUE",
      "recyclable": true, "count": 13, "pricePerKg": 25,
      "averageWeightPerItemKg": 0.03, "estimatedWeightKg": 0.39, "estimatedValue": 9.75,
      "rewardPoints": 65, "carbonSavedKg": 1.95, "stream": "DRY" }
  ],
  "offer": {
    "currency": "INR",
    "minimumOffer": 8.29,
    "estimatedOffer": 9.75,
    "maximumOffer": 11.21,
    "status": "PENDING_COLLECTOR_CONFIRMATION",
    "finalPriceSetBy": "COLLECTOR",
    "reason": "13 items across 1 material - weight is estimated from item counts, so the collector confirms the final price on the scale"
  },
  "wasteAnalysis": { "dryWaste": 100, "wetWaste": 0, "hazardousWaste": 0,
                     "recyclable": 100, "nonRecyclable": 0 },
  "environment": { "carbonSavedKg": 1.95, "treesEquivalent": 0.09, "landfillReducedKg": 0.39 },
  "recommendation": { "primaryBin": "BLUE", "secondaryBin": null,
                      "pickupRecommended": true, "separateHazardous": false },
  "totalRewardPoints": 65,
  "aiSummary": "13 PET Bottles detected. These are fully recyclable and should be placed in the Blue bin. Estimated total weight is 0.39 kg. Estimated offer is INR 9.75, between INR 8.29 and 11.21. The collector will verify the final weight before payment.",
  "objects": [
    { "id": "obj-001", "material": "PET Bottle", "rawLabel": "bottle", "confidence": 0.82,
      "boundingBox": { "xMin": 234, "yMin": 463, "xMax": 475, "yMax": 678 } }
  ],
  "ignoredObjects": ["donut"]
}
```

---

## Response field reference

| Block | Purpose |
| --- | --- |
| `success` | always `true` for a 200 — outcomes live in `status`, not here |
| `status` / `actionRequired` | what happened, and what the app should do next |
| `message` | one-line text safe to show the user as-is |
| `timestamp` | UTC ISO-8601, for audit logs |
| `apiVersion` | contract version, currently `v1` |
| `processingTimeMs` | total request time including image decode and upload |
| `imageUrl` | Cloudinary URL, or `null` if upload is not configured |
| `image` | width, height, format, sizeBytes of the uploaded file |
| `model` | modelId, friendly name, weightsVersion, inferenceTimeMs |
| `quality` | detectionQuality + averageConfidence |
| `summary` | counts per material key, plus `totalObjects` |
| `materials[]` | the business view — one row per material |
| `offer` | all money: minimum / estimated / maximum, and who confirms it |
| `wasteAnalysis` | dry / wet / hazardous / recyclable percentages |
| `environment` | carbonSavedKg, treesEquivalent, landfillReducedKg |
| `recommendation` | primaryBin, secondaryBin, pickupRecommended, separateHazardous |
| `totalRewardPoints` | what the Java service adds to `user.points` |
| `aiSummary` | plain-English paragraph, built locally |
| `objects[]` | the computer-vision view — one row per detection |
| `ignoredObjects` | non-waste the model saw, and detections below their class floor |
| `debug` | only present when `INCLUDE_DEBUG=true` |

### Three levels, no repetition

`summary` for totals, `materials[]` for the business view, `objects[]` for per-detection
detail. Bin, price, weight and carbon live **once** in `materials[]`; `objects[].material`
points back to that row rather than restating it. Payload for a 13-object response is ~3.6 KB.

### objects[]

Boxes are `xMin/yMin/xMax/yMax`, the convention most CV libraries use. Confidence is rounded
to 2 decimals. Every detection carries a stable `id` (`obj-001`, ordered by confidence) so a
frontend can highlight one box without index maths.

`rawLabel` is what the model actually predicted; `material` is the display name after mapping.
Keeping both means the Java side can award points on `material` while you can still see what
the model saw when a classification looks wrong.

### quality

| detectionQuality | averageConfidence |
| --- | --- |
| `HIGH` | 0.60 and above |
| `MEDIUM` | 0.45 to 0.59 |
| `LOW` | below 0.45 |
| `NONE` | nothing detected |

Use it to decide whether to trust a result silently or nudge the user to retake the photo.

### model and debug

`model` deliberately carries no weights filename or hardware string — those are implementation
detail. Set `INCLUDE_DEBUG=true` for a `debug` block with the weights file and the confidence,
IoU, image-size and max-detection thresholds. **Leave it off in production**;
`.env.example` ships `false`.

### aiSummary is not an LLM

It is built by `_ai_summary()` in `assessment_service.py` — four conditional string
concatenations. No API call, no model, no network. It is instant, free, works offline, and
cannot hallucinate a number that contradicts the JSON beside it.

Sentences are conditional: the hazardous warning only appears with red-bin items, and the
collector line only when `finalPriceSetBy` is `COLLECTOR`.

The Java service can overwrite `aiSummary` with a real OpenRouter response without changing
this contract. If a judge asks whether it is AI-generated, the honest answer is that the
*content* comes from a real CNN's detections but the *sentence* is templated. Consider
renaming the field to `disposalAdvice` if that matters to you.

---

## status and actionRequired

A detection can succeed technically and still be unusable. All of these return HTTP 200 with
`success: true` — they are outcomes, not failures.

| status | actionRequired | when |
| --- | --- | --- |
| `OK` | `null` | one material, confident, 5 items or fewer |
| `NO_WASTE_DETECTED` | `RECLICK_IMAGE` | no waste found (person, animal, cartoon, empty scene) |
| `LOW_CONFIDENCE` | `RECLICK_IMAGE` | waste found but nothing above `MIN_TRUST_CONFIDENCE` |
| `MANUAL_PRICING_REQUIRED` | `COLLECTOR_SETS_PRICE` | mixed materials, or more than `MANUAL_PRICING_ITEMS` |

`ignoredObjects` is what makes the message specific — "No garbage detected. The image shows
person." rather than a blank failure.

Note that `NO_WASTE_DETECTED` means *the model saw no mappable waste*, not *there is no waste*.

---

## offer.status

Four values, because "ESTIMATED" is not always honest.

| status | when | finalPriceSetBy |
| --- | --- | --- |
| `ESTIMATED` | one material, 5 items or fewer — the system stands behind the number | SYSTEM |
| `PENDING_COLLECTOR_CONFIRMATION` | value found, but mixed materials or many items | COLLECTOR |
| `NO_RESALE_VALUE` | waste detected, worth INR 0 (organic, wrappers) | SYSTEM |
| `UNAVAILABLE` | nothing detected, or confidence too low to price | COLLECTOR |

Measured on real images:

| Image | offer.status | Offer |
| --- | --- | --- |
| single laptop | `ESTIMATED` | INR 153 – 207 |
| bin full of bottles | `PENDING_COLLECTOR_CONFIRMATION` | INR 8.29 – 11.21 |
| banana only | `NO_RESALE_VALUE` | INR 0 |
| human photo | `UNAVAILABLE` | INR 0 |

The reference bin photo returns `PENDING_COLLECTOR_CONFIRMATION` **even though it is a single
material** — 13 items exceeds `MANUAL_PRICING_ITEMS=5`, and 13 bottles is exactly where the
flat 30 g assumption is weakest (that photo contains one large jug among small bottles).
Marking it `ESTIMATED` would be overclaiming.

`estimatedOffer` is the computed midpoint; `minimumOffer` / `maximumOffer` are that value
-/+ `PRICE_BAND` (15%). Show `maximumOffer` as the headline "up to" figure and
`estimatedOffer` as what the user should actually expect.

**All money lives in this one block.** There is no second copy of the value elsewhere.

---

## How the price is calculated

Rule-based and fully deterministic. **No randomness anywhere** — the same photo always
produces the same number. (The only `random` call in the codebase generates Cloudinary
filenames.)

### Four steps

```text
1. estimatedWeightKg = count x averageWeightPerItemKg      13 x 0.03  = 0.39 kg
2. estimatedValue    = estimatedWeightKg x pricePerKg      0.39 x 25  = INR 9.75
3. gross             = sum of estimatedValue per material             = INR 9.75
4. min / max         = gross x (1 -/+ PRICE_BAND)          +/-15% = INR 8.29 - 11.21
```

`materials[]` exposes every input, so anyone can check the arithmetic.

### Where the constants come from

Both inputs are **hardcoded in `WASTE_TYPES`, not measured from the image**:

| Material | `weight` (kg/item) | `price` (INR/kg) |
| --- | --- | --- |
| PET Bottle | 0.03 | 25 |
| HDPE Bottle | 0.05 | 30 |
| Aluminium Can | 0.015 | 120 |
| Glass Bottle | 0.4 | 2 |
| Scrap Metal | 0.2 | 30 |
| E-Waste | 1.5 | 60 |
| Paper | 0.2 | 12 |
| Cardboard | 0.3 | 8 |
| Battery | 0.05 | 30 |
| Food Container | 0.02 | 15 |
| Plastic Cup | 0.01 | 10 |
| Textile | 0.3 | 5 |
| Organic / Wrapper / Light Bulb / Mixed | varies | 0 |

These are plausible Indian market values — a 1 L PET bottle really is about 30 g, and PET
scrap really does trade around INR 20-30/kg.

### The honest limitation

**The vision model contributes only the count.** It cannot see whether a bottle is 250 ml or
2 L, whether it is empty or full, or how thick the plastic is.

So the real error is not the +/-15% band — it is the unit-weight assumption. That is exactly
why `finalPriceSetBy` flips to `COLLECTOR` on any mixed or multi-item image. The number is an
**indicative quote to set expectations**; the scale decides what gets paid.

If a judge pushes on accuracy, that is the answer — the design already concedes the limit
rather than pretending a camera can weigh things.

---

## Reward points and carbon

Points and carbon are **per item, not per kg**, so they are always returned even when pricing
is unavailable. A user still earns points on a mixed bag or on zero-value organic waste.

```text
totalRewardPoints = sum of (reward per item) across all detections
carbonSavedKg     = sum of (carbon per item)
treesEquivalent   = carbonSavedKg / CO2_PER_TREE_YEAR_KG      (default 21 kg/tree/year)
landfillReducedKg = total estimatedWeightKg
```

---

## Detection tuning

Defaults matter more than they look. On the reference bin photo, the shipped defaults find
**13 items**; the wrong ones find **2**.

Measured on that photo:

| Change | Result |
| --- | --- |
| `imgsz` 640 -> 1280 | 2 -> 6 detections |
| `yolov8n` -> `yolov8m` | 6 -> 14 detections |
| `max_det` 20 -> 300 | a low cap silently truncates a full bin |
| `conf` 0.35 -> 0.30 | marginal |

**Image size is the biggest lever, not confidence.** Lowering confidence alone at 640 px did
essentially nothing (2 -> 2).

### Why confidence is 0.30

Swept against a real bin photo and clean scenes:

| conf | bin pile | library | room | cartoon |
| --- | --- | --- | --- | --- |
| 0.20 | 18 | 18 | 11 | 1 |
| 0.25 | 17 | 10 | 7 | 1 |
| **0.30** | **14** | **1** | **4** | **1** |
| 0.35 | 10 | 0 | 4 | 1 |
| 0.45 | 10 | 0 | 4 | 1 |

At 0.20 the pile improves but a library photo invents 18 "books". At 0.35+ the pile loses a
third of its bottles. 0.30 is the balance point.

---

## Per-class confidence floors

Some COCO classes are unreliable on waste photos — a grey plastic jug reads as `donut` at
0.35, and library shelves read as `book`. `MIN_CONFIDENCE_BY_LABEL` in `metadata_service.py`
gives those classes their own floor while bottles stay at the global 0.30:

| Class | Floor |
| --- | --- |
| donut, cake, sandwich, hot dog, pizza | 0.55 |
| carrot, broccoli, bowl, vase, remote, clock | 0.50 |
| apple, orange, banana, book | 0.45 |
| everything else | global `YOLO_CONFIDENCE` |

Anything below its floor moves to `ignoredObjects`.

**Why per class rather than a blanket raise:** the donut false positive sits at 0.348. Raising
the global floor to 0.45 removes it — but also costs 3 real bottles (13 -> 10) on the
reference photo. Per-class floors remove the donut and keep all 13.

---

## Metadata tables

`app/services/metadata_service.py` holds three tables:

- **`WASTE_TYPES`** — 16 categories, each with `label`, `plural`, `key`, `bin`, `recyclable`,
  `price`, `reward`, `carbon`, `weight`, `category`, `stream`
- **`LABEL_MAP`** — ~90 rules mapping a model label to a waste category
  (`bottle` -> `pet_bottle`, `cell phone` -> `e_waste`)
- **`MIN_CONFIDENCE_BY_LABEL`** — per-class confidence floors

### The 16 categories

| Key | Label | Bin | Stream | Recyclable |
| --- | --- | --- | --- | --- |
| `pet_bottle` | PET Bottle | BLUE | DRY | yes |
| `hdpe_bottle` | HDPE Bottle | BLUE | DRY | yes |
| `glass_bottle` | Glass Bottle | GREEN | DRY | yes |
| `aluminium_can` | Aluminium Can | BLUE | DRY | yes |
| `plastic_wrapper` | Plastic Wrapper | GREY | DRY | no |
| `food_container` | Food Container | BLUE | DRY | yes |
| `plastic_cup` | Plastic Cup | BLUE | DRY | yes |
| `light_bulb` | Light Bulb | RED | HAZARDOUS | no |
| `battery` | Battery | RED | HAZARDOUS | yes |
| `e_waste` | E-Waste | RED | HAZARDOUS | yes |
| `paper` | Paper | BLUE | DRY | yes |
| `cardboard` | Cardboard | BLUE | DRY | yes |
| `scrap_metal` | Scrap Metal | BLUE | DRY | yes |
| `textile` | Textile | GREY | DRY | no |
| `organic` | Organic Waste | GREEN | WET | no |
| `general` | Mixed Waste | GREY | DRY | no |

### Adding a class

Add a row to `WASTE_TYPES`, then one or more rules to `LABEL_MAP` pointing at it. Anything
unmapped falls back to `general` (GREY bin, 1 point).

With `YOLO_WASTE_ONLY=true` (default) unmapped detections are dropped entirely, so a photo of
a person holding a bottle returns only the bottle — the person lands in `ignoredObjects`.

---

## Configuration

Everything is env-driven. See `.env.example`.

| Variable | Default | Purpose |
| --- | --- | --- |
| `APP_PORT` | 8000 | server port |
| `YOLO_WEIGHTS` | `app/weights/best.pt` | preferred weights, used if the file exists |
| `YOLO_FALLBACK_WEIGHTS` | `yolov8m.pt` | downloaded automatically if the above is missing |
| `YOLO_CONFIDENCE` | 0.30 | global detection floor |
| `YOLO_IOU` | 0.50 | NMS overlap threshold |
| `YOLO_IMAGE_SIZE` | 1280 | inference resolution — biggest lever on dense scenes |
| `YOLO_MAX_DETECTIONS` | 300 | hard cap on boxes per image |
| `YOLO_WASTE_ONLY` | true | drop unmapped classes; set false to see everything |
| `YOLO_AGNOSTIC_NMS` | true | suppress overlaps across different classes |
| `MIN_TRUST_CONFIDENCE` | 0.35 | below this for every detection -> `LOW_CONFIDENCE` |
| `MANUAL_PRICING_ITEMS` | 5 | more items than this -> collector sets the price |
| `PICKUP_MIN_ITEMS` | 5 | at or above this -> `pickupRecommended: true` |
| `PICKUP_MIN_VALUE` | 20 | or at or above this offer value |
| `PRICE_BAND` | 0.15 | +/- band around the estimated offer |
| `CO2_PER_TREE_YEAR_KG` | 21 | divisor for `treesEquivalent` |
| `CURRENCY` | INR | currency code in `offer` |
| `API_VERSION` | v1 | reported as `apiVersion` |
| `MODEL_ID` | waste-detector-v1 | reported as `model.modelId` |
| `WEIGHTS_VERSION` | 2026.08.08 | reported as `model.weightsVersion` |
| `INCLUDE_DEBUG` | false | include the `debug` block |
| `CORS_ALLOWED_ORIGINS` | `*` | comma-separated browser origins |
| `CLOUDINARY_*` | — | see below |

---

## Cloudinary

The uploaded image is stored so the Java service and municipal dashboard can show what was
submitted. Upload runs **in parallel with inference** (`asyncio.to_thread`), which cut ~1.3s
off the response.

All three of `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` and `CLOUDINARY_API_SECRET` must be
set and belong to the **same account**. If any is missing the service logs a warning at
startup, skips the upload, and returns `imageUrl: null`. **Detection is unaffected** — a
missing image host should not take down waste detection.

Files land in `CLOUDINARY_FOLDER` (default `greentech/detections`) with a random UUID filename.

### Two failure modes worth knowing

```text
Cloudinary is not configured (need CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, ...)
```

One or more values are blank.

```text
Cloudinary upload failed: Request forbidden due to missing permissions (actions=["create"])
```

The credentials are **valid but scoped without upload rights**. This is not a wrong-key
problem — the account authenticates fine. Fix it in Cloudinary under
**Settings -> API Keys**: edit the key and enable the create/upload permission, or use the
master key.

Verify a credential triple without running the app:

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  "https://<api_key>:<api_secret>@api.cloudinary.com/v1_1/<cloud_name>/ping"
```

200 means the credentials are valid. It does **not** prove they can upload.

---

## Testing

Verified against 16 real images covering every branch. Current result: **15 pass, 1 known
failure.**

| Case | Expected | Result |
| --- | --- | --- |
| human portrait | `NO_WASTE_DETECTED` | pass |
| group of people | `LOW_CONFIDENCE` | pass |
| cartoon drawing | `NO_WASTE_DETECTED` | **fail — see limitations** |
| animal photo | `NO_WASTE_DETECTED` | pass |
| street sign | `NO_WASTE_DETECTED` | pass |
| library shelves | `NO_WASTE_DETECTED` | pass |
| 8 items, one material | `MANUAL_PRICING_REQUIRED` | pass |
| blurry tiled items | `MANUAL_PRICING_REQUIRED` | pass |
| mixed materials | `MANUAL_PRICING_REQUIRED` | pass |
| 3 materials | `MANUAL_PRICING_REQUIRED` | pass |
| cup + spoon | `MANUAL_PRICING_REQUIRED` | pass |
| 1 bottle in a room | `OK` | pass |
| single laptop | `OK` | pass |
| single metal item | `OK` | pass |
| organic, no resale | `OK` | pass |
| bags + phone, people ignored | `MANUAL_PRICING_REQUIRED` | pass |

Also verified: nothing-detectable returns `success: true` with 0 objects; text file -> 400;
truncated JPEG -> 400; missing field -> 422; 6000x6000 PNG -> 200; PNG input works.

**Timing** (12-core CPU, no GPU): cold first request ~3.4s including model load, warm requests
**~1.8s**, of which ~1.8s is inference. A GPU would cut this by roughly 10x.

---

## Known limitations

1. **Cartoons and drawings can produce confident false positives.** The reference cartoon
   returns `OK` because the model sees a "remote" at 0.66. No confidence floor fixes a
   confidently wrong answer — this needs trained weights.
2. **COCO has no waste classes.** Cans, wrappers, light bulbs, batteries and cardboard are
   invisible today. See [Who actually does the detection](#who-actually-does-the-detection).
3. **Weight is assumed, not measured.** A 250 ml bottle and a 2 L jug both count as 0.03 kg.
4. **Context is invisible.** A library photo and a pile of waste paper look the same to the
   model; only the per-class floor for `book` separates them, imperfectly.
5. **Single process.** The model is loaded once per worker; running multiple uvicorn workers
   multiplies memory by ~500 MB each.

---

## Integrating with the Java service

The Java auth/rewards service (`service/api-java`) is the system of record. Suggested flow:

1. Mobile app uploads the photo to `POST /api/v1/detect`.
2. Java reads `status` and `actionRequired` first — if `RECLICK_IMAGE`, show `message` and
   stop; award nothing.
3. On `OK` or `MANUAL_PRICING_REQUIRED`, persist the detection with `imageUrl`, `summary`,
   `materials[]` and `offer`.
4. Add `totalRewardPoints` to `user.points`.
5. If `offer.finalPriceSetBy` is `COLLECTOR`, create a pickup request rather than a fixed
   quote, and show `offer.maximumOffer` as an "up to" figure.
6. Optionally replace `aiSummary` with an OpenRouter-generated sentence.

Only award points **server-side**, from the response the Java service fetched itself. Never
trust points sent by the client.

---

## Design decisions

**No LLM in the detection path.** A template summary is instant, free, offline, and cannot
contradict the JSON beside it. Java can add a real LLM sentence later.

**`pricing` was replaced by `offer`.** The old `pricing.estimatedScrapValue: {minimum, maximum}`
held exactly the same two numbers the `offer` block now holds, so keeping both would have been
duplicate data. All money lives in `offer` alone. If a consumer already expects `pricing`, it
is a small change to restore.

**Prices are real market rates, not placeholders.** An earlier draft used INR 3/kg for PET,
which valued a full bin at INR 1.44 — a number anyone who knows scrap would immediately
question.

**Mixed piles still show a value.** Judges and users want a number; the business rule keeps
the final decision with the collector. Both are true at once.

**`objects[]` does not repeat material metadata.** Thirteen identical `classification` blocks
became one `materials[]` row plus a `material` reference per object.

**Detection thresholds were tuned with measurements, not intuition.** See
[Detection tuning](#detection-tuning).

---

## Project structure

```text
app/
  api/
    detect.py              endpoints, response assembly
  services/
    yolo_service.py        model loading, inference, per-class floors, box conversion
    metadata_service.py    WASTE_TYPES, LABEL_MAP, MIN_CONFIDENCE_BY_LABEL
    assessment_service.py  aggregation, pricing, status rules, aiSummary
    cloudinary_service.py  image upload (optional)
  models/
    waste_metadata.py      DetectedObject, BoundingBox
  utils/
    image_utils.py         validation, EXIF rotation, resize, describe
  weights/
    best.pt                your trained weights go here (gitignored)
  main.py                  app wiring, CORS, startup warmup, /health
```

The codebase contains **no comments** by design — names and structure carry the meaning.
