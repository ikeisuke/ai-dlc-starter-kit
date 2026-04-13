#!/usr/bin/env bats

load helpers/setup

setup() {
  setup_v1_with_manifest
}

teardown() {
  teardown_environment
}

@test "verify: config_paths OK after successful migration" {
  run_apply_config "${MANIFEST_FILE}" > /dev/null
  run_apply_data "${MANIFEST_FILE}" > /dev/null
  run_cleanup "${MANIFEST_FILE}" > /dev/null
  result="$(run_verify "${MANIFEST_FILE}")"
  config_status="$(echo "${result}" | jq -r '[.checks[] | select(.name == "config_paths")][0].status')"
  [ "${config_status}" = "ok" ]
}

@test "verify: config_paths FAIL when docs/aidlc remains" {
  result="$(run_verify "${MANIFEST_FILE}")"
  config_status="$(echo "${result}" | jq -r '[.checks[] | select(.name == "config_paths")][0].status')"
  [ "${config_status}" = "fail" ]
}

@test "verify: v1_artifacts_removed OK after cleanup" {
  run_apply_config "${MANIFEST_FILE}" > /dev/null
  run_apply_data "${MANIFEST_FILE}" > /dev/null
  run_cleanup "${MANIFEST_FILE}" > /dev/null
  result="$(run_verify "${MANIFEST_FILE}")"
  artifacts_status="$(echo "${result}" | jq -r '[.checks[] | select(.name == "v1_artifacts_removed")][0].status')"
  [ "${artifacts_status}" = "ok" ]
}

@test "verify: v1_artifacts_removed FAIL when artifacts remain" {
  result="$(run_verify "${MANIFEST_FILE}")"
  artifacts_status="$(echo "${result}" | jq -r '[.checks[] | select(.name == "v1_artifacts_removed")][0].status')"
  [ "${artifacts_status}" = "fail" ]
}

@test "verify: data_migrated OK after data migration" {
  run_apply_config "${MANIFEST_FILE}" > /dev/null
  run_apply_data "${MANIFEST_FILE}" > /dev/null
  run_cleanup "${MANIFEST_FILE}" > /dev/null
  result="$(run_verify "${MANIFEST_FILE}")"
  data_status="$(echo "${result}" | jq -r '[.checks[] | select(.name == "data_migrated")][0].status')"
  [ "${data_status}" = "ok" ]
}

@test "verify: data_migrated FAIL when docs/aidlc remains in data files" {
  result="$(run_verify "${MANIFEST_FILE}")"
  has_data_migration="$(jq '[.resources[] | select(.resource_type == "data_migration")] | length' "${MANIFEST_FILE}")"
  if [ "${has_data_migration}" -gt 0 ]; then
    data_status="$(echo "${result}" | jq -r '[.checks[] | select(.name == "data_migrated")][0].status')"
    [ "${data_status}" = "fail" ]
  fi
}

@test "verify: overall=ok when all checks pass" {
  run_apply_config "${MANIFEST_FILE}" > /dev/null
  run_apply_data "${MANIFEST_FILE}" > /dev/null
  run_cleanup "${MANIFEST_FILE}" > /dev/null
  result="$(run_verify "${MANIFEST_FILE}")"
  assert_json_field "${result}" ".overall" "ok"
}

@test "verify: result JSON has correct structure" {
  result="$(run_verify "${MANIFEST_FILE}")"
  assert_json_has_field "${result}" ".checks"
  assert_json_has_field "${result}" ".overall"
  first_check_name="$(echo "${result}" | jq -r '.checks[0].name')"
  [ "${first_check_name}" != "null" ]
}
