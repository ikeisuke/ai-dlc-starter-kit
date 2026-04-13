#!/usr/bin/env bash
# Common test helpers for migration script tests

# Resolve paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES_DIR="$(cd "${TESTS_DIR}/../fixtures" && pwd)"
SCRIPTS_DIR="$(cd "${TESTS_DIR}/../../skills/aidlc-migrate/scripts" && pwd)"
V1_FIXTURE_DIR="${FIXTURES_DIR}/v1-structure"

# --- Environment setup/teardown ---

setup_v1_environment() {
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-test-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}"

  # Copy static fixtures
  cp -R "${V1_FIXTURE_DIR}/." "${TEST_TMPDIR}/"

  # Create symlinks dynamically (git cannot track symlinks reliably)
  mkdir -p "${TEST_TMPDIR}/.agents/skills"
  ln -s "../../docs/aidlc/" "${TEST_TMPDIR}/.agents/skills/aidlc"

  mkdir -p "${TEST_TMPDIR}/.kiro/skills"
  ln -s "../../docs/aidlc/" "${TEST_TMPDIR}/.kiro/skills/aidlc"

  ln -s "../docs/aidlc/kiro-agents.json" "${TEST_TMPDIR}/.kiro/agents/aidlc.json"

  # Create target directory for symlinks (so readlink works)
  mkdir -p "${TEST_TMPDIR}/docs/aidlc"

  # Initialize git repo (bootstrap.sh needs git rev-parse --show-toplevel)
  git -C "${TEST_TMPDIR}" init --quiet
}

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

# --- Script runner wrappers ---

run_detect() {
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-detect.sh" 2>/dev/null
}

run_detect_with_stderr() {
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-detect.sh"
}

run_apply_config() {
  local manifest="$1"
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-apply-config.sh" \
    --manifest "${manifest}" 2>/dev/null
}

run_apply_data() {
  local manifest="$1"
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-apply-data.sh" \
    --manifest "${manifest}" 2>/dev/null
}

run_cleanup() {
  local manifest="$1"
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-cleanup.sh" \
    --manifest "${manifest}" 2>/dev/null
}

run_verify() {
  local manifest="$1"
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-verify.sh" \
    --manifest "${manifest}" 2>/dev/null
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

assert_json_has_resource_type() {
  local json="$1"
  local resource_type="$2"
  local count
  count="$(echo "${json}" | jq "[.resources[] | select(.resource_type == \"${resource_type}\")] | length")"
  if [[ "${count}" -eq 0 ]]; then
    echo "Resource type not found: ${resource_type}"
    return 1
  fi
}

# --- Composite setup helpers (DRY) ---

# Setup v1 environment with manifest file generated
# Sets: TEST_TMPDIR, AIDLC_PROJECT_ROOT, MANIFEST_FILE
setup_v1_with_manifest() {
  setup_v1_environment
  MANIFEST_FILE="${TEST_TMPDIR}/manifest.json"
  run_detect > "${MANIFEST_FILE}"
}

# --- Utility helpers ---

save_json_to_file() {
  local json="$1"
  local path="$2"
  echo "${json}" > "${path}"
}

