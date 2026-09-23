#!/usr/bin/env bash
# Contract test for compose.yaml: validates naming, single image/build
# origin, health check presence, absence of versioned secrets, named
# volumes and at least one smoke component.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/tests/helpers/assertions.sh"

cd "${REPO_ROOT}"
cp -n .env.example .env 2>/dev/null || true
config="$(docker compose config 2>&1)"
config_exit=$?
rm -f .env

assert_success "${config_exit}" "docker compose config must resolve with a populated .env"

service_names="$(echo "${config}" | awk '/^services:/{flag=1;next} /^[a-zA-Z]/{flag=0} flag && /^  [a-zA-Z0-9_-]+:/{gsub(":","");print $1}')"

for name in ${service_names}; do
  if [[ ! "${name}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "ASSERT FAILED: service name '${name}' must be lowercase and hyphen-separated" >&2
    ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
  fi
done

assert_contains "${service_names}" "smoke" "compose must define at least one smoke component"

image_count="$(grep -c '^\s*image:' compose.yaml || true)"
build_count="$(grep -c '^\s*build:' compose.yaml || true)"
assert_equal "1" "${image_count}" "compose.yaml must declare exactly one image origin for the single service"
assert_equal "1" "${build_count}" "compose.yaml must declare exactly one build origin for the single service"

assert_contains "${config}" "healthcheck" "every long-running service must declare a health check"

if echo "${config}" | grep -Eiq '(password|secret)\s*:\s*[^$].+'; then
  echo "ASSERT FAILED: compose configuration appears to contain a versioned secret value" >&2
  ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
fi

assert_contains "${config}" "volumes:" "compose.yaml must declare named persistent volumes"

report_assertions