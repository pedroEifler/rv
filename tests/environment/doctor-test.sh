#!/usr/bin/env bash
# Contract test for scripts/dev/doctor.sh: verifies every mandatory check
# category is reported and that failures include corrective guidance.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../helpers/assertions.sh
source "${REPO_ROOT}/tests/helpers/assertions.sh"

output="$(bash "${REPO_ROOT}/scripts/dev/doctor.sh" 2>&1)"
exit_code=$?

assert_contains "${output}" "WSL" "doctor output should mention WSL"
assert_contains "${output}" "Ubuntu" "doctor output should mention the Ubuntu/distribution check"
assert_contains "${output}" "Docker" "doctor output should mention Docker"
assert_contains "${output}" "Compose" "doctor output should mention Compose"
assert_contains "${output}" "Java 25" "doctor output should mention the Java 25 requirement"
assert_contains "${output}" "Node" "doctor output should mention the Node requirement"
assert_contains "${output}" "filesystem" "doctor output should mention the repository filesystem location"
assert_contains "${output}" "Summary:" "doctor output should include a summary line"

fail_lines="$(echo "${output}" | grep -c '^\[FAIL\]' || true)"
fix_lines_after_fail="$(echo "${output}" | grep -A1 '^\[FAIL\]' | grep -c 'fix:' || true)"
if [ "${fail_lines}" -gt 0 ]; then
  assert_equal "${fail_lines}" "${fix_lines_after_fail}" "every FAIL line must be followed by a corrective 'fix:' line"
  assert_failure "${exit_code}" "doctor.sh must exit non-zero when a mandatory check fails"
else
  assert_success "${exit_code}" "doctor.sh must exit zero when every mandatory check passes"
fi

report_assertions
