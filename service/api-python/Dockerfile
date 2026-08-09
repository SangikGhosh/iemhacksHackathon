FROM python:3.12-slim-bookworm AS build

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install --index-url https://download.pytorch.org/whl/cpu torch torchvision \
 && pip install -r requirements.txt \
 && pip uninstall -y opencv-python opencv-contrib-python \
 && pip install opencv-python-headless

ENV YOLO_CONFIG_DIR=/tmp/ultralytics
RUN mkdir -p /weights && cd /weights \
 && python -c "from ultralytics import YOLO; YOLO('yolov8m.pt')" \
 && test -s /weights/yolov8m.pt


FROM python:3.12-slim-bookworm AS runtime

RUN apt-get update \
 && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 curl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system --gid 1001 greentech \
 && useradd --system --uid 1001 --gid greentech --create-home greentech

COPY --from=build /opt/venv /opt/venv

WORKDIR /app
COPY --from=build --chown=greentech:greentech /weights/yolov8m.pt ./yolov8m.pt
COPY --chown=greentech:greentech app ./app

RUN mkdir -p /app/app/weights /home/greentech/.config/Ultralytics \
 && chown -R greentech:greentech /app /home/greentech

USER greentech

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    YOLO_CONFIG_DIR=/home/greentech/.config/Ultralytics \
    MPLCONFIGDIR=/tmp/matplotlib \
    OMP_NUM_THREADS=2 \
    APP_PORT=8000 \
    UVICORN_WORKERS=1

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS "http://127.0.0.1:${APP_PORT}/health" || exit 1

ENTRYPOINT ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${APP_PORT} --workers ${UVICORN_WORKERS}"]
