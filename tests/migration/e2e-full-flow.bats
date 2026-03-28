#!/usr/bin/env bats

load helpers/setup

setup() {
  setup_v1_environment
}

teardown() {
  if [[ -n "${BACKUP_DIR:-}" && -d "${BACKUP_DIR}" ]]; then
    rm -rf "${BACKUP_DIR}"
  fi
  teardown_environment
}

@test "e2e: full v1-to-v2 migration pipeline succeeds" {
  # Step 1: Detect
  manifest="$(run_detect)"
  assert_json_field "${manifest}" ".status" "v1_detected"
  resource_count="$(echo "${manifest}" | jq '.resources | length')"
  [ "${resource_count}" -gt 0 ]

  # Save manifest to file for subsequent steps
  MANIFEST_FILE="${TEST_TMPDIR}/manifest.json"
  save_json_to_file "${manifest}" "${MANIFEST_FILE}"

  # Step 2: Backup
  backup_result="$(run_backup "${MANIFEST_FILE}")"
  BACKUP_DIR="$(get_backup_dir "${backup_result}")"
  [ -d "${BACKUP_DIR}" ]

  # Step 3: Apply config
  config_journal="$(run_apply_config "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  assert_json_field "${config_journal}" ".phase" "config"

  # Step 4: Apply data
  data_journal="$(run_apply_data "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  assert_json_field "${data_journal}" ".phase" "data"

  # Step 5: Cleanup
  cleanup_journal="$(run_cleanup "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  assert_json_field "${cleanup_journal}" ".phase" "cleanup"

  # Step 6: Verify
  verify_result="$(run_verify "${MANIFEST_FILE}")"
  assert_json_field "${verify_result}" ".overall" "ok"

  # Verify all checks passed
  fail_count="$(echo "${verify_result}" | jq '[.checks[] | select(.status == "fail")] | length')"
  [ "${fail_count}" -eq 0 ]
}

@test "e2e: already_v2 skips migration" {
  teardown_environment
  setup_v2_environment

  manifest="$(run_detect)"
  assert_json_field "${manifest}" ".status" "already_v2"
  assert_json_array_length "${manifest}" ".resources" "0"

  # No further steps needed when already v2
}

@test "e2e: backup_dir is correctly passed between stages" {
  MANIFEST_FILE="${TEST_TMPDIR}/manifest.json"
  run_detect > "${MANIFEST_FILE}"

  # Backup produces backup_dir
  backup_result="$(run_backup "${MANIFEST_FILE}")"
  BACKUP_DIR="$(get_backup_dir "${backup_result}")"
  [ -d "${BACKUP_DIR}" ]

  # Apply-config, apply-data, cleanup all accept the same backup_dir
  config_result="$(run_apply_config "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  assert_json_field "${config_result}" ".phase" "config"

  data_result="$(run_apply_data "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  assert_json_field "${data_result}" ".phase" "data"

  cleanup_result="$(run_cleanup "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  assert_json_field "${cleanup_result}" ".phase" "cleanup"
}
