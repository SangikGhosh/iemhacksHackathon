import logging
import os
import threading
import time

from ultralytics import YOLO

from app.services import metadata_service
from app.models.waste_metadata import BoundingBox, DetectedObject

log = logging.getLogger(__name__)

WEIGHTS = os.getenv("YOLO_WEIGHTS", "app/weights/best.pt")
FALLBACK_WEIGHTS = os.getenv("YOLO_FALLBACK_WEIGHTS", "yolov8m.pt")
CONFIDENCE = float(os.getenv("YOLO_CONFIDENCE", "0.30"))
IOU = float(os.getenv("YOLO_IOU", "0.50"))
IMAGE_SIZE = int(os.getenv("YOLO_IMAGE_SIZE", "1280"))
MAX_DETECTIONS = int(os.getenv("YOLO_MAX_DETECTIONS", "300"))
WASTE_ONLY = os.getenv("YOLO_WASTE_ONLY", "true").lower() == "true"
AGNOSTIC_NMS = os.getenv("YOLO_AGNOSTIC_NMS", "true").lower() == "true"
MODEL_ID = os.getenv("MODEL_ID", "waste-detector-v1")
WEIGHTS_VERSION = os.getenv("WEIGHTS_VERSION", "2026.08.08")

FAMILY_NAMES = {
    "yolov8n": "YOLOv8 Nano",
    "yolov8s": "YOLOv8 Small",
    "yolov8m": "YOLOv8 Medium",
    "yolov8l": "YOLOv8 Large",
    "yolov8x": "YOLOv8 Extra Large",
    "yolo11n": "YOLO11 Nano",
    "yolo11s": "YOLO11 Small",
    "yolo11m": "YOLO11 Medium",
}

_model = None
_model_name = None
_lock = threading.Lock()


def load_model():
    global _model, _model_name

    if _model is not None:
        return _model

    with _lock:
        if _model is not None:
            return _model

        weights = WEIGHTS if os.path.exists(WEIGHTS) else FALLBACK_WEIGHTS
        log.info("Loading YOLO weights: %s (imgsz=%s conf=%s)", weights, IMAGE_SIZE, CONFIDENCE)
        _model = YOLO(weights)
        _model_name = weights
        return _model


def model_name():
    return _model_name


def display_name():
    if not _model_name:
        return None
    stem = os.path.splitext(os.path.basename(_model_name))[0]
    return FAMILY_NAMES.get(stem, "Waste Detector (custom)")


def model_info(inference_ms):
    return {
        "modelId": MODEL_ID,
        "name": display_name(),
        "weightsVersion": WEIGHTS_VERSION,
        "inferenceTimeMs": inference_ms,
    }


def debug_info():
    return {
        "weightsFile": os.path.basename(_model_name) if _model_name else None,
        "confidenceThreshold": CONFIDENCE,
        "iouThreshold": IOU,
        "imageSize": IMAGE_SIZE,
        "maxDetections": MAX_DETECTIONS,
    }


def detect(image, scale=1.0):
    model = load_model()

    started = time.perf_counter()

    results = model.predict(
        source=image,
        conf=CONFIDENCE,
        iou=IOU,
        imgsz=IMAGE_SIZE,
        max_det=MAX_DETECTIONS,
        agnostic_nms=AGNOSTIC_NMS,
        verbose=False,
    )

    inference_ms = int((time.perf_counter() - started) * 1000)

    if not results:
        return [], [], inference_ms

    result = results[0]
    names = result.names
    accepted = []
    ignored = []

    for box in result.boxes:
        raw_label = names[int(box.cls[0])]
        confidence = round(float(box.conf[0]), 2)

        if WASTE_ONLY and not metadata_service.is_waste(raw_label):
            ignored.append(raw_label)
            continue

        if confidence < metadata_service.min_confidence(raw_label):
            ignored.append(raw_label)
            continue

        x1, y1, x2, y2 = (float(v) / scale for v in box.xyxy[0].tolist())
        accepted.append((confidence, raw_label, x1, y1, x2, y2))

    accepted.sort(key=lambda d: d[0], reverse=True)

    objects = [
        DetectedObject(
            id=f"obj-{index:03d}",
            material=metadata_service.display_label(raw_label),
            rawLabel=raw_label,
            confidence=confidence,
            boundingBox=BoundingBox(
                xMin=int(round(x1)),
                yMin=int(round(y1)),
                xMax=int(round(x2)),
                yMax=int(round(y2)),
            ),
        )
        for index, (confidence, raw_label, x1, y1, x2, y2) in enumerate(accepted, start=1)
    ]

    return objects, ignored, inference_ms
