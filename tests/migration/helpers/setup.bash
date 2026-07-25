#!/usr/bin/env bash
# Common test helpers for migration script tests (v2→v3)

# Resolve paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES_DIR="$(cd "${TESTS_DIR}/../fixtures" && pwd)"
SCRIPTS_DIR="$(cd "${TESTS_DIR}/../../skills/aidlc-migrate/scripts" && pwd)"

# --- Environment setup/teardown ---

setup_v2_environment() {
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-test-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}"

  # Minimal v2 structure (no v1 artifacts)
  mkdir -p "${TEST_TMPDIR}/.aidlc"
  cat > "${TEST_TMPDIR}/.aidlc/config.toml" << 'TOML'
[project]
name = "test-project"

[paths]
aidlc_dir = "skills/aidlc"
TOML

  mkdir -p "${TEST_TMPDIR}/skills/aidlc"

  git -C "${TEST_TMPDIR}" init --quiet
}

teardown_environment() {
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- JSON assertion helpers ---

assert_json_field() {
  local json="$1"
  local path="$2"
  local expected="$3"
  local actual
  actual="$(echo "${json}" | jq -r "${path}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "JSON assertion failed: ${path}"
    echo "  expected: ${expected}"
    echo "  actual:   ${actual}"
    return 1
  fi
}

assert_json_array_length() {
  local json="$1"
  local path="$2"
  local expected="$3"
  local actual
  actual="$(echo "${json}" | jq "${path} | length")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "JSON array length assertion failed: ${path}"
    echo "  expected: ${expected}"
    echo "  actual:   ${actual}"
    return 1
  fi
}

assert_json_has_field() {
  local json="$1"
  local path="$2"
  local result
  result="$(echo "${json}" | jq "${path}")"
  if [[ "${result}" == "null" ]]; then
    echo "JSON field not found: ${path}"
    return 1
  fi
}

# --- v2→v3 migration helpers ---

V2_GEN_FIXTURES_DIR="${FIXTURES_DIR}/v2-config-generations"

# v2→v3 用のテスト環境（v2 config のみ / state.json なし / clean worktree）
# $1 = v2 config 世代 fixture 名（既定: gen-2.5.5-full）
setup_v2v3_environment() {
  local gen="${1:-gen-2.5.5-full}"
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-test-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}"

  mkdir -p "${TEST_TMPDIR}/.aidlc"
  cp "${V2_GEN_FIXTURES_DIR}/${gen}/config.toml" "${TEST_TMPDIR}/.aidlc/config.toml"

  git -C "${TEST_TMPDIR}" init --quiet
  git -C "${TEST_TMPDIR}" -c user.email=test@example.com -c user.name=test \
    -c commit.gpgsign=false add -A
  git -C "${TEST_TMPDIR}" -c user.email=test@example.com -c user.name=test \
    -c commit.gpgsign=false commit --quiet -m "init v2 environment"
}

run_v3_preflight() {
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-v3-preflight.sh"
}

run_v3_config() {
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-v3-config.sh" "$@"
}

run_v3_archive_index() {
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-v3-archive-index.sh" "$@"
}

# --- Utility helpers ---

save_json_to_file() {
  local json="$1"
  local path="$2"
  echo "${json}" > "${path}"
}
