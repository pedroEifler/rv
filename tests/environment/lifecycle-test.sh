#!/usr/bin/env bash
# Integration test for the environment lifecycle scripts against a real
# Docker daemon: healthy startup, status reporting, an occupied-port
# failure and a startup timeout failure.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/tests/helpers/assertions.sh"
cd "${REPO_ROOT}"

if ! docker info >/dev/null 2>&1; then
  echo "SKIPPED: Docker is not reachable; lifecycle-test.sh requires a running Docker daemon." >&2
  exit 1
fi

cleanup() {
  docker compose down --volumes --remove-orphans >/dev/null 2>&1 || true
  [ -n "${port_pid:-}" ] && kill "${port_pid}" >/dev/null 2>&1 || true
  rm -f .env
}
trap cleanup EXIT

cp .env.example .env

echo "--- Scenario: healthy startup ---"
UP_TIMEOUT_SECONDS=120 bash scripts/dev/up.sh
assert_success "$?" "up.sh should succeed when the smoke component becomes healthy"

status_output="$(bash scripts/dev/status.sh)"
assert_success "$?" "status.sh should succeed while the runtime is queryable"
assert_contains "${status_output}" "healthy" "status.sh should report the smoke component as healthy"

echo "--- Scenario: occupied port failure ---"
bash scripts/dev/down.sh >/dev/null
port="$(grep -oE 'SMOKE_HTTP_PORT=[0-9]+' .env.example | cut -d= -f2)"
python3 -c "import socket,time,sys; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(('0.0.0.0', ${port})); s.listen(1); time.sleep(60)" &
port_pid=$!
sleep 1
UP_TIMEOUT_SECONDS=20 bash scripts/dev/up.sh >/tmp/up-port-conflict.$$ 2>&1
occupied_exit=$?
assert_failure "${occupied_exit}" "up.sh should fail when the configured port is already occupied"
kill "${port_pid}" >/dev/null 2>&1 || true
wait "${port_pid}" 2>/dev/null || true
port_pid=""
rm -f /tmp/up-port-conflict.$$
docker compose down --remove-orphans >/dev/null 2>&1 || true

echo "--- Scenario: startup timeout failure ---"
docker compose build >/dev/null 2>&1
UP_TIMEOUT_SECONDS=0 bash scripts/dev/up.sh >/tmp/up-timeout.$$ 2>&1
timeout_exit=$?
assert_failure "${timeout_exit}" "up.sh should fail when the health timeout elapses before readiness"
rm -f /tmp/up-timeout.$$

report_assertions
