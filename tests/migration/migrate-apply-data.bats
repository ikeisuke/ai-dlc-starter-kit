#!/usr/bin/env bats

load helpers/setup

setup() {
  setup_v1_with_backup
}

teardown() {
  cleanup_backup_dir
  teardown_environment
}

@test "apply-data: docs/aidlc replaced with aidlc_dir template in markdown" {
  result="$(run_apply_data "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  example_md="${TEST_TMPDIR}/.aidlc/cycles/v1.0.0/history/example.md"
  [ -f "${example_md}" ]
  ! grep -q 'docs/aidlc' "${example_md}"
  grep -q '{{aidlc_dir}}' "${example_md}"
  success_count="$(echo "${result}" | jq '[.applied[] | select(.status == "success")] | length')"
  [ "${success_count}" -gt 0 ]
}

@test "apply-data: skipped when no docs/aidlc references" {
  find "${TEST_TMPDIR}/.aidlc/cycles" -name "*.md" -exec sed -i.bak 's|docs/aidlc|already-migrated|g' {} \;
  find "${TEST_TMPDIR}/.aidlc/cycles" -name "*.bak" -delete
  run_detect > "${MANIFEST_FILE}"
  result="$(run_apply_data "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  applied_count="$(echo "${result}" | jq '[.applied[] | select(.resource_type == "data_migration")] | length')"
  [ "${applied_count}" -eq 0 ]
}

@test "apply-data: error when file not found" {
  jq '.resources = [{"resource_type": "data_migration", "path": "nonexistent/file.md", "action": "migrate", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  result="$(run_apply_data "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  status_val="$(echo "${result}" | jq -r '.applied[0].status')"
  [ "${status_val}" = "error" ]
}

@test "apply-data: journal JSON has correct structure" {
  result="$(run_apply_data "${MANIFEST_FILE}" "${BACKUP_DIR}")"
  assert_json_field "${result}" ".phase" "data"
  assert_json_has_field "${result}" ".applied"
}
