#!/usr/bin/env bash
# Starts the local environment: validates configuration, builds/starts the
# required components and waits until every one of them is healthy.
# Usage: ./scripts/dev/up.sh
# Exit 0 only when all required components are healthy; non-zero on invalid
# configuration, startup failure or a health timeout.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

TIMEOUT_SECONDS="${UP_TIMEOUT_SECONDS:-120}"

echo "Validating Compose configuration..."
if ! docker compose config >/dev/null 2>/tmp/up-config-error.$$; then
  echo "up.sh: Compose configuration is invalid:" >&2
  cat /tmp/up-config-error.$$ >&2
  rm -f /tmp/up-config-error.$$
  exit 1
fi
rm -f /tmp/up-config-error.$$

echo "Starting components..."
if ! docker compose up -d --build; then
  echo "up.sh: failed to start one or more components (check for occupied ports or build errors above)." >&2
  exit 1
fi

echo "Waiting for components to become healthy (timeout ${TIMEOUT_SECONDS}s)..."
elapsed=0
interval=3
while [ "${elapsed}" -lt "${TIMEOUT_SECONDS}" ]; do
  total=0
  healthy=0
  unhealthy=0
  while IFS= read -r line; do
    [ -z "${line}" ] && continue
    total=$((total + 1))
    case "${line}" in
      healthy) healthy=$((healthy + 1)) ;;
      unhealthy) unhealthy=$((unhealthy + 1)) ;;
    esac
  done < <(docker compose ps --format '{{.Health}}' 2>/dev/null)

  if [ "${unhealthy}" -gt 0 ]; then
    echo "up.sh: at least one component reported unhealthy. Run './scripts/dev/status.sh' for details." >&2
    exit 1
  fi

  if [ "${total}" -gt 0 ] && [ "${healthy}" -eq "${total}" ]; then
    echo "up.sh: all ${total} component(s) are healthy."
    exit 0
  fi

  sleep "${interval}"
  elapsed=$((elapsed + interval))
done

echo "up.sh: timed out after ${TIMEOUT_SECONDS}s waiting for components to become healthy. Run './scripts/dev/status.sh' for details." >&2
exit 1
