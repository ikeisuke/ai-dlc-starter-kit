#!/usr/bin/env bats

load helpers/setup

setup() {
  setup_v1_with_manifest
}

teardown() {
  teardown_environment
}

@test "apply-config: docs/aidlc replaced with skills/aidlc in config.toml" {
  result="$(run_apply_config "${MANIFEST_FILE}")"
  # Assert config.toml exists and was updated
  [ -f "${TEST_TMPDIR}/.aidlc/config.toml" ]
  ! grep -q 'docs/aidlc' "${TEST_TMPDIR}/.aidlc/config.toml"
  grep -q 'skills/aidlc' "${TEST_TMPDIR}/.aidlc/config.toml"
  status_val="$(echo "${result}" | jq -r '[.applied[] | select(.resource_type == "config_update")][0].status')"
  [ "${status_val}" = "success" ]
}

@test "apply-config: skipped when no docs/aidlc references" {
  sed -i.bak 's|docs/aidlc|skills/aidlc|g' "${TEST_TMPDIR}/.aidlc/config.toml"
  rm -f "${TEST_TMPDIR}/.aidlc/config.toml.bak"
  run_detect > "${MANIFEST_FILE}"
  result="$(run_apply_config "${MANIFEST_FILE}")"
  applied_count="$(echo "${result}" | jq '[.applied[] | select(.resource_type == "config_update")] | length')"
  [ "${applied_count}" -eq 0 ]
}

@test "apply-config: error when file not found" {
  jq '.resources = [{"resource_type": "config_update", "path": "nonexistent/config.toml", "action": "update", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  result="$(run_apply_config "${MANIFEST_FILE}")"
  status_val="$(echo "${result}" | jq -r '.applied[0].status')"
  [ "${status_val}" = "error" ]
}

@test "apply-config: journal JSON has correct structure" {
  result="$(run_apply_config "${MANIFEST_FILE}")"
  assert_json_field "${result}" ".phase" "config"
  assert_json_has_field "${result}" ".applied"
}
