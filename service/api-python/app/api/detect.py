import asyncio
import logging
import os
import time
from dataclasses import asdict
from datetime import datetime, timezone

from fastapi import APIRouter, File, HTTPException, UploadFile

from app.services import (
    assessment_service,
    cloudinary_service,
    metadata_service,
    yolo_service,
)
from app.utils import image_utils
from app.utils.image_utils import ImageError

log = logging.getLogger(__name__)

API_VERSION = os.getenv("API_VERSION", "v1")
INCLUDE_DEBUG = os.getenv("INCLUDE_DEBUG", "false").lower() == "true"

router = APIRouter(prefix="/api/v1")


@router.post("/detect")
async def detect(image: UploadFile = File(...)):
    started = time.perf_counter()

    raw = await image.read()

    try:
        original = image_utils.load(raw)
    except ImageError as e:
        raise HTTPException(status_code=e.status, detail=e.message)

    resized, _ = image_utils.resize(original)

    upload = asyncio.create_task(
        asyncio.to_thread(cloudinary_service.upload, image_utils.to_jpeg_bytes(resized))
    )

    objects, ignored, inference_ms = await asyncio.to_thread(yolo_service.detect, resized)

    assessment = assessment_service.assess(objects, ignored)

    image_url = await upload

    elapsed = int((time.perf_counter() - started) * 1000)

    response = {
        "success": True,
        "eligible": assessment["eligible"],
        "status": assessment["status"],
        "message": assessment["message"],
        "actionRequired": assessment["actionRequired"],
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "apiVersion": API_VERSION,
        "processingTimeMs": elapsed,
        "imageUrl": image_url,
        "image": image_utils.describe(original, raw),
        "model": yolo_service.model_info(inference_ms),
        "quality": assessment["quality"],
        "summary": assessment["summary"],
        "materials": assessment["materials"],
        "offer": assessment["offer"],
        "wasteAnalysis": assessment["wasteAnalysis"],
        "environment": assessment["environment"],
        "recommendation": assessment["recommendation"],
        "totalRewardPoints": assessment["totalRewardPoints"],
        "aiSummary": assessment["aiSummary"],
        "objects": [asdict(o) for o in objects],
        "ignoredObjects": sorted(set(ignored)),
    }

    if INCLUDE_DEBUG:
        response["debug"] = yolo_service.debug_info()

    return response


@router.get("/waste-types")
async def waste_types():
    return {"apiVersion": API_VERSION, "types": metadata_service.catalog()}
