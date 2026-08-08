from dataclasses import dataclass


@dataclass(frozen=True)
class BoundingBox:
    xMin: int
    yMin: int
    xMax: int
    yMax: int


@dataclass(frozen=True)
class DetectedObject:
    id: str
    material: str
    rawLabel: str
    confidence: float
    boundingBox: BoundingBox
