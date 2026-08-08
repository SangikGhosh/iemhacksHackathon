import os

from app.services import metadata_service

MIN_TRUST_CONFIDENCE = float(os.getenv("MIN_TRUST_CONFIDENCE", "0.35"))
MANUAL_PRICING_ITEMS = int(os.getenv("MANUAL_PRICING_ITEMS", "5"))
PICKUP_MIN_ITEMS = int(os.getenv("PICKUP_MIN_ITEMS", "5"))
PICKUP_MIN_VALUE = float(os.getenv("PICKUP_MIN_VALUE", "20"))
PRICE_BAND = float(os.getenv("PRICE_BAND", "0.15"))
CO2_PER_TREE_YEAR_KG = float(os.getenv("CO2_PER_TREE_YEAR_KG", "21"))
CURRENCY = os.getenv("CURRENCY", "INR")

STATUS_OK = "OK"
STATUS_NO_WASTE = "NO_WASTE_DETECTED"
STATUS_LOW_CONFIDENCE = "LOW_CONFIDENCE"
STATUS_MANUAL_PRICING = "MANUAL_PRICING_REQUIRED"

ACTION_RECLICK = "RECLICK_IMAGE"
ACTION_COLLECTOR_PRICES = "COLLECTOR_SETS_PRICE"

SET_BY_SYSTEM = "SYSTEM"
SET_BY_COLLECTOR = "COLLECTOR"

OFFER_ESTIMATED = "ESTIMATED"
OFFER_PENDING_COLLECTOR = "PENDING_COLLECTOR_CONFIRMATION"
OFFER_NO_RESALE_VALUE = "NO_RESALE_VALUE"
OFFER_UNAVAILABLE = "UNAVAILABLE"


def _empty_response(ignored_labels):
    if ignored_labels:
        shown = ", ".join(sorted(set(ignored_labels))[:3])
        message = (
            f"No garbage detected. The image shows {shown}. "
            "Please re-click the image with the waste clearly visible."
        )
    else:
        message = (
            "No garbage detected in the image. "
            "Please re-click the image with the waste clearly visible."
        )
    return {
        "eligible": False,
        "status": STATUS_NO_WASTE,
        "message": message,
        "actionRequired": ACTION_RECLICK,
        "summary": {"totalObjects": 0},
        "materials": [],
        "offer": {
            "currency": CURRENCY,
            "minimumOffer": 0.0,
            "estimatedOffer": 0.0,
            "maximumOffer": 0.0,
            "status": OFFER_UNAVAILABLE,
            "finalPriceSetBy": SET_BY_COLLECTOR,
            "reason": "No waste items were detected",
        },
        "wasteAnalysis": {
            "dryWaste": 0,
            "wetWaste": 0,
            "hazardousWaste": 0,
            "recyclable": 0,
            "nonRecyclable": 0,
        },
        "environment": {
            "carbonSavedKg": 0.0,
            "treesEquivalent": 0.0,
            "landfillReducedKg": 0.0,
        },
        "recommendation": {
            "primaryBin": None,
            "secondaryBin": None,
            "pickupRecommended": False,
        },
        "quality": {"detectionQuality": "NONE", "averageConfidence": 0.0},
        "totalRewardPoints": 0,
        "aiSummary": message,
    }


def _aggregate(objects):
    grouped = {}

    for o in objects:
        entry = metadata_service.entry_for(o.rawLabel)
        material = grouped.setdefault(
            entry["label"],
            {
                "material": entry["label"],
                "plural": entry["plural"],
                "summaryKey": entry["key"],
                "category": entry["category"],
                "stream": entry["stream"],
                "bin": entry["bin"],
                "recyclable": entry["recyclable"],
                "count": 0,
                "pricePerKg": entry["price"],
                "unitWeightKg": entry["weight"],
                "rewardPoints": 0,
                "carbonSavedKg": 0.0,
            },
        )
        material["count"] += 1
        material["rewardPoints"] += entry["reward"]
        material["carbonSavedKg"] += entry["carbon"]

    materials = []
    for m in grouped.values():
        weight = round(m["count"] * m["unitWeightKg"], 3)
        materials.append(
            {
                "material": m["material"],
                "plural": m["plural"],
                "category": m["category"],
                "bin": m["bin"],
                "recyclable": m["recyclable"],
                "count": m["count"],
                "pricePerKg": m["pricePerKg"],
                "averageWeightPerItemKg": m["unitWeightKg"],
                "estimatedWeightKg": weight,
                "estimatedValue": round(weight * m["pricePerKg"], 2),
                "rewardPoints": m["rewardPoints"],
                "carbonSavedKg": round(m["carbonSavedKg"], 3),
                "stream": m["stream"],
                "summaryKey": m["summaryKey"],
            }
        )

    materials.sort(key=lambda m: m["count"], reverse=True)
    return materials


def _summary(materials, total):
    summary = {"totalObjects": total}
    for m in materials:
        summary[m["summaryKey"]] = summary.get(m["summaryKey"], 0) + m["count"]
    return summary


def _percentages(materials, total):
    def pct(predicate):
        matched = sum(m["count"] for m in materials if predicate(m))
        return round(matched * 100 / total) if total else 0

    dry = pct(lambda m: m["stream"] == metadata_service.STREAM_DRY)
    wet = pct(lambda m: m["stream"] == metadata_service.STREAM_WET)
    hazardous = pct(lambda m: m["stream"] == metadata_service.STREAM_HAZARDOUS)
    recyclable = pct(lambda m: m["recyclable"])

    return {
        "dryWaste": dry,
        "wetWaste": wet,
        "hazardousWaste": hazardous,
        "recyclable": recyclable,
        "nonRecyclable": 100 - recyclable,
    }


def _environment(materials):
    carbon = round(sum(m["carbonSavedKg"] for m in materials), 2)
    landfill = round(sum(m["estimatedWeightKg"] for m in materials), 2)
    return {
        "carbonSavedKg": carbon,
        "treesEquivalent": round(carbon / CO2_PER_TREE_YEAR_KG, 2),
        "landfillReducedKg": landfill,
    }


def _recommendation(materials, total, value):
    bins = {}
    for m in materials:
        bins[m["bin"]] = bins.get(m["bin"], 0) + m["count"]

    ordered = sorted(bins.items(), key=lambda kv: kv[1], reverse=True)
    hazardous = any(m["stream"] == metadata_service.STREAM_HAZARDOUS for m in materials)

    return {
        "primaryBin": ordered[0][0] if ordered else None,
        "secondaryBin": ordered[1][0] if len(ordered) > 1 else None,
        "pickupRecommended": total >= PICKUP_MIN_ITEMS or value >= PICKUP_MIN_VALUE,
        "separateHazardous": hazardous,
    }


def _name(material, count):
    return material["material"] if count == 1 else material["plural"]


def _quality(objects):
    if not objects:
        return {"detectionQuality": "NONE", "averageConfidence": 0.0}

    average = round(sum(o.confidence for o in objects) / len(objects), 2)

    if average >= 0.60:
        level = "HIGH"
    elif average >= 0.45:
        level = "MEDIUM"
    else:
        level = "LOW"

    return {"detectionQuality": level, "averageConfidence": average}


def _ai_summary(materials, total, offer, analysis, environment):
    leader = materials[0]

    if len(materials) == 1:
        sentences = [f"{total} {_name(leader, total)} detected."]
    else:
        listed = [f"{m['count']} {_name(m, m['count'])}" for m in materials[:3]]
        joined = ", ".join(listed[:-1]) + f" and {listed[-1]}"
        sentences = [f"{total} waste items detected: {joined}."]

    recyclable = [m for m in materials if m["recyclable"]]
    if recyclable:
        bins = sorted({m["bin"].capitalize() for m in recyclable})
        where = " and ".join(bins)
        if analysis["recyclable"] == 100:
            sentences.append(
                f"These are fully recyclable and should be placed in the {where} bin."
            )
        else:
            sentences.append(
                f"{analysis['recyclable']}% is recyclable and belongs in the {where} bin."
            )
    else:
        bins = sorted({m["bin"].capitalize() for m in materials})
        sentences.append(
            f"None of this is recyclable - it belongs in the {' and '.join(bins)} bin."
        )

    hazardous = [m for m in materials if m["stream"] == metadata_service.STREAM_HAZARDOUS]
    if hazardous:
        names = ", ".join(_name(m, m["count"]) for m in hazardous)
        sentences.append(
            f"Separate the {names} first - hazardous waste must never go in a regular bin."
        )

    weight = environment["landfillReducedKg"]
    if weight > 0:
        sentences.append(f"Estimated total weight is {weight} kg.")

    if offer["maximumOffer"] > 0:
        sentences.append(
            f"Estimated offer is {CURRENCY} {offer['estimatedOffer']}, "
            f"between {CURRENCY} {offer['minimumOffer']} and {offer['maximumOffer']}."
        )

    if offer["finalPriceSetBy"] == SET_BY_COLLECTOR:
        sentences.append("The collector will verify the final weight before payment.")

    return " ".join(sentences)


def assess(objects, ignored_labels):
    if not objects:
        return _empty_response(ignored_labels)

    best = max(o.confidence for o in objects)

    if best < MIN_TRUST_CONFIDENCE:
        response = _empty_response(ignored_labels)
        response["status"] = STATUS_LOW_CONFIDENCE
        response["message"] = (
            "The waste in this image is unclear. Please re-click the image in better "
            "light with the items closer to the camera."
        )
        response["summary"] = {"totalObjects": len(objects)}
        response["offer"]["reason"] = "Detection confidence too low to price"
        response["aiSummary"] = response["message"]
        return response

    total = len(objects)
    materials = _aggregate(objects)
    gross = sum(m["estimatedValue"] for m in materials)

    offer = {
        "currency": CURRENCY,
        "minimumOffer": round(gross * (1 - PRICE_BAND), 2),
        "estimatedOffer": round(gross, 2),
        "maximumOffer": round(gross * (1 + PRICE_BAND), 2),
        "status": OFFER_ESTIMATED if gross > 0 else OFFER_NO_RESALE_VALUE,
        "finalPriceSetBy": SET_BY_SYSTEM,
        "reason": None if gross > 0 else "This waste type has no resale value",
    }

    mixed = len(materials) > 1
    crowded = total > MANUAL_PRICING_ITEMS

    if mixed or crowded:
        offer["finalPriceSetBy"] = SET_BY_COLLECTOR
        noun = "material" if len(materials) == 1 else "materials"
        offer["reason"] = (
            f"{total} items across {len(materials)} {noun} - weight is estimated "
            "from item counts, so the collector confirms the final price on the scale"
        )
        if gross > 0:
            offer["status"] = OFFER_PENDING_COLLECTOR
        status = STATUS_MANUAL_PRICING
        action = ACTION_COLLECTOR_PRICES
        message = (
            f"{total} waste items detected across {len(materials)} {noun}. "
            f"Offer up to {CURRENCY} {offer['maximumOffer']}; the collector will weigh "
            "and confirm the final price."
        )
    else:
        status = STATUS_OK
        action = None
        message = f"{materials[0]['material']} detected and priced."

    analysis = _percentages(materials, total)
    environment = _environment(materials)

    return {
        "eligible": True,
        "status": status,
        "message": message,
        "actionRequired": action,
        "summary": _summary(materials, total),
        "materials": [
            {k: v for k, v in m.items() if k != "summaryKey"} for m in materials
        ],
        "offer": offer,
        "wasteAnalysis": analysis,
        "environment": environment,
        "recommendation": _recommendation(
            materials, total, offer["maximumOffer"]
        ),
        "totalRewardPoints": sum(m["rewardPoints"] for m in materials),
        "quality": _quality(objects),
        "aiSummary": _ai_summary(materials, total, offer, analysis, environment),
    }
