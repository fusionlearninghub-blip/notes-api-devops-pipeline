# --- Build stage: install deps into a venv, keep build tools out of final image ---
FROM python:3.12-slim AS builder

WORKDIR /build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# --- Final stage: minimal runtime image ---
FROM python:3.12-slim

# Create non-root user; containers should never run as root
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY --from=builder /opt/venv /opt/venv
COPY main.py .
COPY __init__.py .

# Build-time arg surfaced at runtime via /version endpoint — CI injects the
# commit SHA so a running container's exact source is always traceable.
ARG GIT_SHA=unknown
ENV GIT_SHA=${GIT_SHA} \
    APP_ENV=production

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
