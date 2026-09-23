#!/usr/bin/env bash
# Integration test proving persistence semantics: down.sh preserves named
# volumes, a cancelled reset preserves data, and only reset.sh --confirm
# removes data.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/tests/helpers/assertions.sh"
cd "${REPO_ROOT}"

if ! docker info >/dev/null 2>&1; then
  echo "SKIPPED: Docker is not reachable; persistence-test.sh requires a running Docker daemon." >&2
  exit 1
fi

cleanup() {
  docker compose down --volumes --remove-orphans >/dev/null 2>&1 || true
  rm -f .env
}
trap cleanup EXIT

cp .env.example .env
docker compose down --volumes --remove-orphans >/dev/null 2>&1 || true

port="$(grep -oE 'SMOKE_HTTP_PORT=[0-9]+' .env.example | cut -d= -f2)"

echo "--- initial start ---"
UP_TIMEOUT_SECONDS=120 bash scripts/dev/up.sh >/dev/null
assert_success "$?" "initial up.sh should succeed"
marker_1="$(curl -s "http://localhost:${port}/persistent-marker.txt")"
assert_contains "${marker_1}" "instance_id" "the smoke component should expose a persistent marker file"

echo "--- down.sh preserves the named volume ---"
bash scripts/dev/down.sh >/dev/null
assert_success "$?" "down.sh should succeed"
docker volume ls --format '{{.Name}}' | grep -q smoke-data
assert_success "$?" "the named volume must still exist after down.sh"

echo "--- restart reuses the preserved data ---"
UP_TIMEOUT_SECONDS=120 bash scripts/dev/up.sh >/dev/null
assert_success "$?" "up.sh should succeed again after down.sh"
marker_2="$(curl -s "http://localhost:${port}/persistent-marker.txt")"
assert_equal "${marker_1}" "${marker_2}" "the persistent marker must be unchanged after a normal restart"

echo "--- reset without --confirm in a non-interactive shell preserves data ---"
bash scripts/dev/reset.sh < /dev/null
reset_cancel_exit=$?
docker volume ls --format '{{.Name}}' | grep -q smoke-data
assert_success "$?" "the named volume must still exist after an unconfirmed non-interactive reset attempt"
assert_failure "${reset_cancel_exit}" "reset.sh without --confirm in a non-interactive shell must exit non-zero and delete nothing"

echo "--- confirmed reset removes data ---"
bash scripts/dev/reset.sh --confirm
assert_success "$?" "reset.sh --confirm should succeed"
if docker volume ls --format '{{.Name}}' | grep -q smoke-data; then
  echo "ASSERT FAILED: the named volume should be removed after reset.sh --confirm" >&2
  ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
fi

echo "--- a fresh start after reset creates new data ---"
UP_TIMEOUT_SECONDS=120 bash scripts/dev/up.sh >/dev/null
assert_success "$?" "up.sh should succeed after a confirmed reset"
marker_3="$(curl -s "http://localhost:${port}/persistent-marker.txt")"
if [ "${marker_3}" = "${marker_1}" ]; then
  echo "ASSERT FAILED: a new marker was expected after reset.sh --confirm deleted the volume" >&2
  ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
fi

report_assertions
