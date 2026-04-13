#!/usr/bin/env bats

load helpers/setup

setup() {
  setup_v1_with_manifest
}

teardown() {
  teardown_environment
}

@test "cleanup: files with action=delete are removed" {
  # Create a known file and a manifest targeting it
  touch "${TEST_TMPDIR}/deleteme.txt"
  jq '.resources = [{"resource_type": "file_kiro", "path": "deleteme.txt", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  [ -f "${TEST_TMPDIR}/deleteme.txt" ]
  run_cleanup "${MANIFEST_FILE}" > /dev/null
  [ ! -f "${TEST_TMPDIR}/deleteme.txt" ]
}

@test "cleanup: symlinks with action=delete are removed" {
  [ -L "${TEST_TMPDIR}/.agents/skills/aidlc" ]
  run_cleanup "${MANIFEST_FILE}" > /dev/null
  [ ! -L "${TEST_TMPDIR}/.agents/skills/aidlc" ]
}

@test "cleanup: directories with action=delete are removed" {
  [ -d "${TEST_TMPDIR}/.aidlc/cycles/backlog" ]
  run_cleanup "${MANIFEST_FILE}" > /dev/null
  [ ! -d "${TEST_TMPDIR}/.aidlc/cycles/backlog" ]
}

@test "cleanup: nonexistent files are skipped" {
  jq '.resources = [{"resource_type": "file_kiro", "path": "nonexistent.txt", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  result="$(run_cleanup "${MANIFEST_FILE}")"
  status_val="$(echo "${result}" | jq -r '.applied[0].status')"
  [ "${status_val}" = "skipped" ]
}

@test "cleanup: absolute paths are rejected" {
  jq '.resources = [{"resource_type": "file_kiro", "path": "/etc/passwd", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  result="$(run_cleanup "${MANIFEST_FILE}")"
  status_val="$(echo "${result}" | jq -r '.applied[0].status')"
  [ "${status_val}" = "error" ]
}

@test "cleanup: path traversal is rejected" {
  jq '.resources = [{"resource_type": "file_kiro", "path": "../../../etc/passwd", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  result="$(run_cleanup "${MANIFEST_FILE}")"
  status_val="$(echo "${result}" | jq -r '.applied[0].status')"
  [ "${status_val}" = "error" ]
}

@test "cleanup: empty parent directories are auto-removed" {
  mkdir -p "${TEST_TMPDIR}/nested/deep/dir"
  touch "${TEST_TMPDIR}/nested/deep/dir/file.txt"
  jq '.resources = [{"resource_type": "file_kiro", "path": "nested/deep/dir/file.txt", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  run_cleanup "${MANIFEST_FILE}" > /dev/null
  [ ! -f "${TEST_TMPDIR}/nested/deep/dir/file.txt" ]
  [ ! -d "${TEST_TMPDIR}/nested/deep/dir" ]
}

@test "cleanup: journal JSON has correct structure" {
  result="$(run_cleanup "${MANIFEST_FILE}")"
  assert_json_field "${result}" ".phase" "cleanup"
  assert_json_has_field "${result}" ".applied"
}
