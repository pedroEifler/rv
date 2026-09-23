#!/usr/bin/env bash
# Docker HEALTHCHECK probe for the smoke component. Exits 0 only when the
# HTTP endpoint responds, allowing Compose/scripts to distinguish a running
# process from a ready (healthy) one.
set -euo pipefail

PORT="${SMOKE_HTTP_PORT:-8080}"

curl --fail --silent --show-error --max-time 2 "http://127.0.0.1:${PORT}/status.json" > /dev/null
