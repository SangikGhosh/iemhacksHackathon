import logging
import os

from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import detect
from app.services import cloudinary_service, yolo_service

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s - %(message)s",
)

log = logging.getLogger(__name__)

app = FastAPI(title="GreenTech Detection API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ALLOWED_ORIGINS", "*").split(","),
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(detect.router)


@app.on_event("startup")
def warmup():
    yolo_service.load_model()
    log.info(
        "Ready - weights=%s cloudinary=%s",
        yolo_service.model_name(),
        cloudinary_service.is_configured(),
    )


@app.get("/health")
def health():
    return {
        "status": "ok",
        "weights": yolo_service.model_name(),
        "cloudinary": cloudinary_service.is_configured(),
    }
