import logging
import os
import uuid

import cloudinary
import cloudinary.uploader

log = logging.getLogger(__name__)

CLOUD_NAME = os.getenv("CLOUDINARY_CLOUD_NAME", "")
API_KEY = os.getenv("CLOUDINARY_API_KEY", "")
API_SECRET = os.getenv("CLOUDINARY_API_SECRET", "")
FOLDER = os.getenv("CLOUDINARY_FOLDER", "greentech/detections")

_configured = bool(CLOUD_NAME and API_KEY and API_SECRET)

if _configured:
    cloudinary.config(
        cloud_name=CLOUD_NAME,
        api_key=API_KEY,
        api_secret=API_SECRET,
        secure=True,
    )
else:
    log.warning(
        "Cloudinary is not configured (need CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, "
        "CLOUDINARY_API_SECRET) - detection still works, imageUrl will be null"
    )


def is_configured():
    return _configured


def upload(image_bytes):
    if not _configured:
        return None

    try:
        response = cloudinary.uploader.upload(
            image_bytes,
            folder=FOLDER,
            public_id=uuid.uuid4().hex,
            resource_type="image",
            overwrite=False,
        )
        url = response.get("secure_url")
        log.info("Uploaded to Cloudinary: %s", url)
        return url
    except Exception as e:
        log.error("Cloudinary upload failed: %s", e)
        return None
