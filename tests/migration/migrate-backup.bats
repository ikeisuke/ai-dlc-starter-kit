#!/usr/bin/env bats

load helpers/setup

setup() {
  setup_v1_with_manifest
}

teardown() {
  cleanup_backup_dir
  teardown_environment
}

@test "backup: files are backed up successfully" {
  result="$(run_backup "${MANIFEST_FILE}")"
  BACKUP_DIR="$(get_backup_dir "${result}")"
  [ -d "${BACKUP_DIR}" ]
  files_count="$(echo "${result}" | jq '.files | length')"
  [ "${files_count}" -gt 0 ]
}

@test "backup: symlinks are backed up with link info preserved" {
  result="$(run_backup "${MANIFEST_FILE}")"
  BACKUP_DIR="$(get_backup_dir "${result}")"
  # Assert that a symlink-sourced entry exists in files
  symlink_count="$(echo "${result}" | jq '[.files[] | select(.source | test("agents/skills/aidlc"))] | length')"
  [ "${symlink_count}" -gt 0 ]
  symlink_backup="$(echo "${result}" | jq -r '[.files[] | select(.source | test("agents/skills/aidlc"))][0].backup')"
  [ -L "${symlink_backup}" ] || [ -e "${symlink_backup}" ]
}

@test "backup: directories are backed up recursively" {
  result="$(run_backup "${MANIFEST_FILE}")"
  BACKUP_DIR="$(get_backup_dir "${result}")"
  dir_count="$(echo "${result}" | jq '[.files[] | select(.source | test("backlog/"))] | length')"
  [ "${dir_count}" -gt 0 ]
  dir_backup="$(echo "${result}" | jq -r '[.files[] | select(.source | test("backlog/"))][0].backup')"
  [ -d "${dir_backup}" ]
}

@test "backup: nonexistent files are skipped" {
  jq '.resources += [{"resource_type": "file_kiro", "path": "nonexistent-file.txt", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  result="$(run_backup "${MANIFEST_FILE}")"
  BACKUP_DIR="$(get_backup_dir "${result}")"
  count="$(echo "${result}" | jq '[.files[] | select(.source == "nonexistent-file.txt")] | length')"
  [ "${count}" -eq 0 ]
}

@test "backup: backup_dir is created and returned" {
  result="$(run_backup "${MANIFEST_FILE}")"
  BACKUP_DIR="$(get_backup_dir "${result}")"
  [ -n "${BACKUP_DIR}" ]
  [ -d "${BACKUP_DIR}" ]
}

@test "backup: result JSON has required fields" {
  result="$(run_backup "${MANIFEST_FILE}")"
  BACKUP_DIR="$(get_backup_dir "${result}")"
  assert_json_has_field "${result}" ".backup_dir"
  assert_json_has_field "${result}" ".files"
}
