#!/usr/bin/env bash
# Reusable shell assertion helpers for tests/environment and tests/hooks.
# Source this file; it does not execute anything on its own.

ASSERTIONS_FAILED=0

assert_equal() {
  local expected="$1" actual="$2" message="${3:-values should be equal}"
  if [ "${expected}" != "${actual}" ]; then
    echo "ASSERT FAILED: ${message} (expected='${expected}' actual='${actual}')" >&2
    ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
    return 1
  fi
  return 0
}

assert_contains() {
  local haystack="$1" needle="$2" message="${3:-expected substring not found}"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    echo "ASSERT FAILED: ${message} (looking for '${needle}')" >&2
    ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
    return 1
  fi
  return 0
}

assert_exit_code() {
  local expected="$1" actual="$2" message="${3:-unexpected exit code}"
  if [ "${expected}" != "${actual}" ]; then
    echo "ASSERT FAILED: ${message} (expected exit=${expected} actual exit=${actual})" >&2
    ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
    return 1
  fi
  return 0
}

assert_success() {
  assert_exit_code 0 "$1" "${2:-expected command to succeed}"
}

assert_failure() {
  local actual="$1" message="${2:-expected command to fail}"
  if [ "${actual}" -eq 0 ]; then
    echo "ASSERT FAILED: ${message} (command unexpectedly succeeded)" >&2
    ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
    return 1
  fi
  return 0
}

assert_file_exists() {
  local path="$1" message="${2:-expected file to exist: $1}"
  if [ ! -e "${path}" ]; then
    echo "ASSERT FAILED: ${message}" >&2
    ASSERTIONS_FAILED=$((ASSERTIONS_FAILED + 1))
    return 1
  fi
  return 0
}

report_assertions() {
  if [ "${ASSERTIONS_FAILED}" -gt 0 ]; then
    echo "FAILED: ${ASSERTIONS_FAILED} assertion(s) failed in $0" >&2
    exit 1
  fi
  echo "PASSED: all assertions succeeded in $0"
  exit 0
}
