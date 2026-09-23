#!/usr/bin/env bash
# Stops the environment and permanently deletes its named volumes.
# Interactive usage: ./scripts/dev/reset.sh (asks for confirmation)
# Non-interactive usage: ./scripts/dev/reset.sh --confirm
# Any other invocation, or a declined interactive confirmation, cancels
# without deleting data.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

CONFIRMED=0
if [ "${1:-}" = "--confirm" ]; then
  CONFIRMED=1
elif [ "${1:-}" != "" ]; then
  echo "reset.sh: unknown argument '${1}'. Use --confirm for non-interactive execution." >&2
  exit 2
fi

if [ "${CONFIRMED}" -ne 1 ]; then
  if [ ! -t 0 ]; then
    echo "reset.sh: non-interactive shell without --confirm. Cancelling without deleting data." >&2
    exit 1
  fi
  read -r -p "This will permanently delete all local persistent data. Type 'yes' to continue: " answer
  if [ "${answer}" != "yes" ]; then
    echo "reset.sh: cancelled. No data was deleted."
    exit 0
  fi
fi

echo "reset.sh: stopping environment and removing named volumes..."
if docker compose down --volumes --remove-orphans; then
  echo "reset.sh: environment reset. All named volumes were deleted."
  exit 0
fi

echo "reset.sh: failed to reset the environment cleanly." >&2
exit 1
