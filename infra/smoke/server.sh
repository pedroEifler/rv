#!/usr/bin/env bash
# Minimal persistent smoke component used to validate the local environment
# lifecycle (start, health, persistence, reset). It serves the contents of
# the named volume mounted at /data over plain HTTP so tests and humans can
# inspect readiness and persisted state without a domain-specific service.
set -euo pipefail

PORT="${SMOKE_HTTP_PORT:-8080}"
DATA_DIR="/data"
MARKER_FILE="${DATA_DIR}/persistent-marker.txt"
STATUS_FILE="${DATA_DIR}/status.json"

mkdir -p "${DATA_DIR}"

if [ ! -f "${MARKER_FILE}" ]; then
  {
    echo "created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "instance_id=$$-$(date +%s)-${RANDOM:-0}"
  } > "${MARKER_FILE}"
  echo "smoke: created new persistent marker at ${MARKER_FILE}"
else
  echo "smoke: found existing persistent marker at ${MARKER_FILE} (data survived restart)"
fi

cat > "${STATUS_FILE}" <<JSON
{
  "component": "smoke",
  "status": "ok",
  "startedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

echo "smoke: serving ${DATA_DIR} on port ${PORT}"
exec python3 -m http.server "${PORT}" --directory "${DATA_DIR}" --bind 0.0.0.0
