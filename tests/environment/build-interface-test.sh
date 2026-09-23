#!/usr/bin/env bash
# Integration test for the Gradle Wrapper build interface: proves the
# Wrapper works without a globally installed Gradle, that a formatting
# violation is caught without mutating the file, and that clean-check
# results are repeatable.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/tests/helpers/assertions.sh"
cd "${REPO_ROOT}"

if command -v gradle >/dev/null 2>&1; then
  echo "NOTE: a global 'gradle' command exists; the Wrapper is still used exclusively by this test."
fi

version_output="$(./gradlew --version --no-daemon 2>&1)"
assert_success "$?" "./gradlew --version should succeed without a global Gradle installation"
assert_contains "${version_output}" "Gradle 9.7.1" "the Wrapper must report Gradle 9.7.1"

scratch="tests/environment/.scratch-formatting-check.md"
cleanup() {
  rm -f "${scratch}"
}
trap cleanup EXIT

printf '# Scratch\t\nSome   text with   irregular   spacing.\n' > "${scratch}"
checksum_before="$(sha256sum "${scratch}" | awk '{print $1}')"

./gradlew spotlessCheck --console=plain --no-daemon >/tmp/spotless-check.$$ 2>&1
violation_exit=$?
assert_failure "${violation_exit}" "spotlessCheck must fail when a tracked Markdown file has a formatting violation"

checksum_after_check="$(sha256sum "${scratch}" | awk '{print $1}')"
assert_equal "${checksum_before}" "${checksum_after_check}" "spotlessCheck must not mutate the offending file"
rm -f /tmp/spotless-check.$$

./gradlew spotlessApply --console=plain --no-daemon >/dev/null
assert_success "$?" "spotlessApply should succeed and fix the violation"

checksum_after_apply="$(sha256sum "${scratch}" | awk '{print $1}')"
if [ "${checksum_before}" = "${checksum_after_apply}" ]; then
  echo "ASSERT FAILED: spotlessApply should have changed the file content" >&2
  ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
fi

./gradlew spotlessCheck --console=plain --no-daemon >/dev/null
assert_success "$?" "spotlessCheck should pass after spotlessApply fixed the violation"

echo "--- repeatable clean check ---"
./gradlew clean check --console=plain --no-daemon >/tmp/check-1.$$ 2>&1
first_exit=$?
./gradlew clean check --console=plain --no-daemon >/tmp/check-2.$$ 2>&1
second_exit=$?
assert_equal "${first_exit}" "${second_exit}" "two consecutive clean check runs must produce the same result"
rm -f /tmp/check-1.$$ /tmp/check-2.$$

report_assertions
