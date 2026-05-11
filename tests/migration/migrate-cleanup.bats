#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

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

@test "cleanup: absolute paths are rejected (reason=absolute_path / Unit 002)" {
  jq '.resources = [{"resource_type": "file_kiro", "path": "/etc/passwd", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-cleanup.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-cleanup:path-traversal	/etc/passwd	reason=absolute_path;field=path"* ]]
}

@test "cleanup: parent traversal is rejected (reason=parent_traversal / Unit 002)" {
  jq '.resources = [{"resource_type": "file_kiro", "path": "../../../etc/passwd", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-cleanup.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-cleanup:path-traversal	../../../etc/passwd	reason=parent_traversal;field=path"* ]]
}

@test "cleanup: symlink escape is rejected (reason=symlink_escape / Unit 002)" {
  # プロジェクトルート配下に外部を指す symlink を作成
  mkdir -p "${TEST_TMPDIR}/outside-target"
  ln -sf "${TEST_TMPDIR}/outside-target" "${TEST_TMPDIR}/escape-link"
  # 物理解決後配下外になる外部ターゲットを別ディレクトリに用意
  local outside_root
  outside_root="$(mktemp -d /tmp/aidlc-outside-XXXXXX)"
  ln -sfn "${outside_root}" "${TEST_TMPDIR}/escape-link"
  jq '.resources = [{"resource_type": "file_kiro", "path": "escape-link/payload", "action": "delete", "ownership_evidence": null}]' \
    "${MANIFEST_FILE}" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "${MANIFEST_FILE}"
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-cleanup.sh" --manifest "${MANIFEST_FILE}"
  cd "$BATS_TMPDIR" || true
  rm -rf "${outside_root}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-cleanup:path-traversal	escape-link/payload	reason=symlink_escape;field=path"* ]]
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
