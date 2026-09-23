#!/usr/bin/env bash
# Environment doctor: checks WSL, Docker, Compose, Java and Node prerequisites
# and reports the repository checkout location. Usage: ./scripts/dev/doctor.sh
# Exits 0 only when every mandatory check passes.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

PASS=0
FAIL=0
WARN=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; echo "       fix: $2"; FAIL=$((FAIL + 1)); }
warn() { echo "[WARN] $1"; echo "       fix: $2"; WARN=$((WARN + 1)); }

echo "Running development environment doctor..."
echo

# WSL version check
if grep -qi microsoft /proc/version 2>/dev/null; then
  if [ "${WSL_INTEROP:-}" != "" ] || grep -qi "wsl2" /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ]; then
    pass "Running inside WSL (distribution: ${WSL_DISTRO_NAME:-unknown})"
  else
    warn "Running inside WSL but could not confirm version 2" "Run 'wsl --set-version <distro> 2' from Windows PowerShell."
  fi
else
  fail "Not running inside WSL" "Install WSL 2 and Ubuntu 22.04+, then run this script from inside the distribution."
fi

# Distribution check
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [ "${ID:-}" = "ubuntu" ]; then
    major="${VERSION_ID%%.*}"
    if [ "${major}" -ge 22 ] 2>/dev/null; then
      pass "Ubuntu ${VERSION_ID} meets the 22.04+ requirement"
    else
      fail "Ubuntu ${VERSION_ID} is older than 22.04" "Upgrade the WSL distribution to Ubuntu 22.04 or later."
    fi
  else
    warn "Distribution '${ID:-unknown}' is not Ubuntu" "Use Ubuntu 22.04+ for the documented, supported experience."
  fi
else
  warn "Could not read /etc/os-release" "Verify the WSL distribution is a supported Linux release."
fi

# Docker check
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    pass "Docker is installed and the daemon is reachable"
  else
    fail "Docker CLI found but the daemon is not reachable" "Start Docker Desktop and enable WSL integration for this distribution."
  fi
else
  fail "Docker CLI not found" "Install Docker Desktop with WSL 2 integration enabled for this distribution."
fi

# Compose check
if docker compose version >/dev/null 2>&1; then
  pass "Docker Compose plugin is available"
else
  fail "Docker Compose plugin not found" "Update Docker Desktop; Compose v2 ships as the 'docker compose' plugin."
fi

# Java check
if command -v java >/dev/null 2>&1; then
  java_version="$(java -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+).*/\1/')"
  if [ "${java_version}" = "25" ]; then
    pass "Java ${java_version} matches the required Java 25 toolchain"
  else
    fail "Java version '${java_version}' does not match the required Java 25" "Install Java 25 (Temurin/OpenJDK) and ensure it is first on PATH."
  fi
else
  fail "Java not found on PATH" "Install Java 25 and ensure it is first on PATH."
fi

# Node check
if command -v node >/dev/null 2>&1; then
  node_version="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
  if [ "${node_version}" = "24" ]; then
    pass "Node.js ${node_version} belongs to the required Node 24 LTS line"
  else
    fail "Node.js version 'v${node_version}' does not belong to the Node 24 LTS line" "Install Node.js 24 LTS, for example via 'nvm install 24' (see .nvmrc)."
  fi
else
  fail "Node.js not found on PATH" "Install Node.js 24 LTS, for example via nvm (see .nvmrc)."
fi

# Repository filesystem check
repo_path="$(pwd -P)"
if [[ "${repo_path}" == /mnt/* ]]; then
  fail "Repository is checked out under '${repo_path}' (a Windows-mounted /mnt/* path)" "Clone the repository inside the WSL Linux filesystem, e.g. ~/projects/rv, for correct performance and file semantics."
else
  pass "Repository is checked out on the Linux filesystem (${repo_path})"
fi

echo
echo "Summary: ${PASS} passed, ${WARN} warnings, ${FAIL} failed."

if [ "${FAIL}" -gt 0 ]; then
  exit 1
fi
exit 0
