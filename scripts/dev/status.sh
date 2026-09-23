#!/usr/bin/env bash
# Reports each component's state: stopped, starting, healthy, unhealthy or
# exited. Usage: ./scripts/dev/status.sh
# Exit 0 when the state could be obtained (regardless of health); non-zero
# only when the runtime itself cannot be queried.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

if ! docker compose ps --format '{{.Name}}\t{{.State}}\t{{.Health}}' > /tmp/status-output.$$ 2>/tmp/status-error.$$; then
  echo "status.sh: unable to query the container runtime:" >&2
  cat /tmp/status-error.$$ >&2
  rm -f /tmp/status-output.$$ /tmp/status-error.$$
  exit 1
fi

if [ ! -s /tmp/status-output.$$ ]; then
  echo "No components are running. Use './scripts/dev/up.sh' to start the environment."
  rm -f /tmp/status-output.$$ /tmp/status-error.$$
  exit 0
fi

printf '%-24s %-12s %s\n' "COMPONENT" "STATE" "HEALTH"
while IFS=$'\t' read -r name state health; do
  [ -z "${name}" ] && continue
  display_health="${health}"
  if [ -z "${display_health}" ]; then
    case "${state}" in
      running) display_health="starting" ;;
      exited) display_health="exited" ;;
      *) display_health="unknown" ;;
    esac
  fi
  printf '%-24s %-12s %s\n' "${name}" "${state}" "${display_health}"
done < /tmp/status-output.$$

rm -f /tmp/status-output.$$ /tmp/status-error.$$
exit 0
