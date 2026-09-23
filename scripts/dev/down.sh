#!/usr/bin/env bash
# Stops the local environment: removes containers and networks while
# preserving named volumes (persistent data). Usage: ./scripts/dev/down.sh
# Idempotent: exits 0 if the environment is already stopped.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

if docker compose down --remove-orphans; then
  echo "down.sh: environment stopped. Named volumes were preserved."
  exit 0
fi

echo "down.sh: failed to stop the environment cleanly." >&2
exit 1
