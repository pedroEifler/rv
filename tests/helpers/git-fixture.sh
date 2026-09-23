#!/usr/bin/env bash
# Creates an isolated temporary Git repository fixture for hook and commit
# policy tests, wired to the real project hooks and configuration so tests
# exercise genuine behavior instead of mocks. Source this file.

create_git_fixture() {
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  local fixture
  fixture="$(mktemp -d)"

  git init --quiet "${fixture}"
  git -C "${fixture}" config user.email "test@example.invalid"
  git -C "${fixture}" config user.name "Test Fixture"
  git -C "${fixture}" config commit.gpgsign false

  cp "${repo_root}/commitlint.config.mjs" "${fixture}/"
  cp "${repo_root}/lint-staged.config.mjs" "${fixture}/"
  cp "${repo_root}/package.json" "${fixture}/"
  mkdir -p "${fixture}/scripts/quality"
  cp -r "${repo_root}/scripts/quality/." "${fixture}/scripts/quality/"
  mkdir -p "${fixture}/.husky"
  cp -r "${repo_root}/.husky/." "${fixture}/.husky/"
  ln -s "${repo_root}/node_modules" "${fixture}/node_modules"

  git -C "${fixture}" config core.hooksPath ".husky"

  echo "${fixture}"
}

cleanup_git_fixture() {
  local fixture="$1"
  if [ -n "${fixture}" ] && [ -d "${fixture}" ]; then
    rm -rf "${fixture}"
  fi
}
