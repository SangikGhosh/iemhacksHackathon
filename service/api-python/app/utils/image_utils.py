import io

from PIL import Image, ImageOps

MAX_BYTES = 10 * 1024 * 1024
MAX_SIDE = 1280
ALLOWED_FORMATS = {"JPEG", "PNG", "WEBP", "BMP"}


class ImageError(Exception):
    def __init__(self, message, status=400):
        super().__init__(message)
        self.message = message
        self.status = status


def load(raw):
    if not raw:
        raise ImageError("Empty image file")

    if len(raw) > MAX_BYTES:
        raise ImageError("Image too large, max 10MB", 413)

    try:
        image = Image.open(io.BytesIO(raw))
        image.verify()
        image = Image.open(io.BytesIO(raw))
    except Exception:
        raise ImageError("File is not a valid image")

    if image.format not in ALLOWED_FORMATS:
        raise ImageError("Unsupported image format, use JPEG, PNG, WEBP or BMP")

    source_format = image.format
    image = ImageOps.exif_transpose(image)
    converted = image.convert("RGB")
    converted.info["sourceFormat"] = source_format
    return converted


def describe(image, raw):
    return {
        "width": image.width,
        "height": image.height,
        "format": (image.info.get("sourceFormat") or "JPEG").lower(),
        "sizeBytes": len(raw),
    }


def resize(image, max_side=MAX_SIDE):
    width, height = image.size
    longest = max(width, height)

    if longest <= max_side:
        return image, 1.0

    scale = max_side / longest
    resized = image.resize((int(width * scale), int(height * scale)), Image.LANCZOS)
    return resized, scale


def to_jpeg_bytes(image, quality=85):
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=quality)
    return buffer.getvalue()
