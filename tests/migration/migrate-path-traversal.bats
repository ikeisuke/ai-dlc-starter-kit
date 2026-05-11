#!/usr/bin/env bats

# Unit 002 (Issue #680): aidlc-migrate manifest 由来パスのトラバーサル検証
# 4 攻撃シナリオ × 3 スクリプト × 主要フィールド組合せのフルマトリクステスト

bats_require_minimum_version 1.5.0

load helpers/setup

setup() {
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-test-trav-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}"
  git -C "${TEST_TMPDIR}" init --quiet
  mkdir -p "${TEST_TMPDIR}/.aidlc" "${TEST_TMPDIR}/safe-target"
  cat > "${TEST_TMPDIR}/.aidlc/config.toml" << 'TOML'
[project]
name = "test"
TOML
  MANIFEST_FILE="${TEST_TMPDIR}/manifest.json"
  # 外部攻撃ターゲット（リポジトリ外）
  OUTSIDE_TARGET="$(mktemp -d /tmp/aidlc-outside-trav-XXXXXX)"
  export OUTSIDE_TARGET
  # 副作用検証用マーカー（攻撃により書き換えられたら検出）
  printf 'CANARY-DO-NOT-WRITE\n' > "${OUTSIDE_TARGET}/canary.txt"
  CANARY_CHECKSUM_BEFORE="$(shasum "${OUTSIDE_TARGET}/canary.txt")"
  export CANARY_CHECKSUM_BEFORE
}

teardown() {
  cd "$BATS_TMPDIR" || true
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
  if [[ -n "${OUTSIDE_TARGET:-}" && -d "${OUTSIDE_TARGET}" ]]; then
    rm -rf "${OUTSIDE_TARGET}"
  fi
}

# --- 攻撃 manifest 生成ヘルパー ---

# attack_type: absolute / parent / symlink / outside-via-name
# resource_payload: jq で .resources に代入する JSON
write_attack_manifest() {
  local resource_payload="$1"
  printf '{"version":"1.0","resources":%s}\n' "${resource_payload}" > "${MANIFEST_FILE}"
}

# --- 副作用未発生アサート ---

assert_no_external_side_effect() {
  local actual_checksum
  actual_checksum="$(shasum "${OUTSIDE_TARGET}/canary.txt")"
  if [[ "${actual_checksum}" != "${CANARY_CHECKSUM_BEFORE}" ]]; then
    echo "EXTERNAL SIDE EFFECT DETECTED: canary checksum mismatch" >&2
    echo "  expected: ${CANARY_CHECKSUM_BEFORE}" >&2
    echo "  actual:   ${actual_checksum}" >&2
    return 1
  fi
}

# === migrate-apply-config.sh ===

@test "apply-config: v1_config_move path=absolute is rejected (exit 1 / absolute_path)" {
  write_attack_manifest '[{"resource_type":"v1_config_move","path":"/etc/passwd","destination":".aidlc/config.toml"}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-apply-config.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-apply-config:path-traversal	/etc/passwd	reason=absolute_path;field=path"* ]]
  assert_no_external_side_effect
}

@test "apply-config: v1_config_move destination=parent_traversal is rejected (exit 1 / parent_traversal)" {
  touch "${TEST_TMPDIR}/source.toml"
  write_attack_manifest '[{"resource_type":"v1_config_move","path":"source.toml","destination":"../../../etc/shadow"}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-apply-config.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-apply-config:path-traversal	../../../etc/shadow	reason=parent_traversal;field=destination"* ]]
  assert_no_external_side_effect
}

@test "apply-config: config_update path=symlink_escape is rejected (exit 1 / symlink_escape)" {
  ln -sfn "${OUTSIDE_TARGET}" "${TEST_TMPDIR}/escape-link"
  write_attack_manifest '[{"resource_type":"config_update","path":"escape-link/config.toml"}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-apply-config.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-apply-config:path-traversal	escape-link/config.toml	reason=symlink_escape;field=path"* ]]
  assert_no_external_side_effect
}

# === migrate-apply-data.sh ===

@test "apply-data: move_dir path=absolute is rejected (exit 1 / absolute_path)" {
  write_attack_manifest '[{"resource_type":"v1_data_move","action":"move_dir","path":"/etc","destination":".aidlc/cycles"}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-apply-data.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-apply-data:path-traversal	/etc	reason=absolute_path;field=path"* ]]
  assert_no_external_side_effect
}

@test "apply-data: move_dir destination=parent_traversal is rejected (exit 1 / parent_traversal)" {
  mkdir -p "${TEST_TMPDIR}/src"
  write_attack_manifest '[{"resource_type":"v1_data_move","action":"move_dir","path":"src","destination":"../../../tmp/evil"}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-apply-data.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-apply-data:path-traversal	../../../tmp/evil	reason=parent_traversal;field=destination"* ]]
  assert_no_external_side_effect
}

@test "apply-data: data_migration path=symlink_escape is rejected (exit 1 / symlink_escape)" {
  ln -sfn "${OUTSIDE_TARGET}" "${TEST_TMPDIR}/escape-link"
  write_attack_manifest '[{"resource_type":"data_migration","path":"escape-link/canary.txt"}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-apply-data.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-apply-data:path-traversal	escape-link/canary.txt	reason=symlink_escape;field=path"* ]]
  assert_no_external_side_effect
}

# === migrate-cleanup.sh ===

@test "cleanup: delete path=absolute is rejected (exit 1 / absolute_path)" {
  write_attack_manifest '[{"resource_type":"file_kiro","path":"/etc/passwd","action":"delete","ownership_evidence":null}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-cleanup.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-cleanup:path-traversal	/etc/passwd	reason=absolute_path;field=path"* ]]
  assert_no_external_side_effect
}

@test "cleanup: delete path=parent_traversal is rejected (exit 1 / parent_traversal)" {
  write_attack_manifest '[{"resource_type":"file_kiro","path":"../../../etc/hosts","action":"delete","ownership_evidence":null}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-cleanup.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-cleanup:path-traversal	../../../etc/hosts	reason=parent_traversal;field=path"* ]]
  assert_no_external_side_effect
}

@test "cleanup: materialize path=symlink_escape is rejected (exit 1 / symlink_escape)" {
  ln -sfn "${OUTSIDE_TARGET}" "${TEST_TMPDIR}/escape-link"
  write_attack_manifest '[{"resource_type":"file_kiro","path":"escape-link/canary.txt","action":"materialize"}]'
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${SCRIPTS_DIR}/migrate-cleanup.sh" --manifest "${MANIFEST_FILE}"
  [ "${status}" -eq 1 ]
  [[ "${stderr}" == *"error	migrate-cleanup:path-traversal	escape-link/canary.txt	reason=symlink_escape;field=path"* ]]
  assert_no_external_side_effect
}

# === path-guard 単体機能テスト ===

@test "path-guard: init fails when AIDLC_PROJECT_ROOT is unset (exit 2 / aidlc_project_root_unset)" {
  run --separate-stderr env -u AIDLC_PROJECT_ROOT SCRIPTS_DIR="${SCRIPTS_DIR}" bash -c '
    source "${SCRIPTS_DIR}/lib/path-guard.sh"
    _aidlc_migrate_path_guard_init
  '
  [ "${status}" -eq 2 ]
  [[ "${stderr}" == *"error	path-guard:init-failed	(unset)	reason=aidlc_project_root_unset"* ]]
}

@test "path-guard: validate accepts normal relative path (exit 0)" {
  mkdir -p "${TEST_TMPDIR}/subdir"
  run --separate-stderr env AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" SCRIPTS_DIR="${SCRIPTS_DIR}" bash -c '
    source "${SCRIPTS_DIR}/lib/path-guard.sh"
    _aidlc_migrate_path_guard_init || exit $?
    _aidlc_migrate_validate_path "subdir/file.txt" "path" "test"
  '
  [ "${status}" -eq 0 ]
  [ -z "${stderr}" ]
}

@test "path-guard: validate handles realpath -m fallback (pure bash cd -P loop)" {
  # PATH を細工して realpath を不在にし、pure bash フォールバックを発動させる
  mkdir -p "${TEST_TMPDIR}/subdir"
  local fake_path_dir
  fake_path_dir="$(mktemp -d /tmp/aidlc-fake-path-XXXXXX)"
  # PATH に bash / read / cd / pwd 等の最小限のみを露出
  ln -sf "$(command -v bash)" "${fake_path_dir}/bash"
  ln -sf "$(command -v cat)" "${fake_path_dir}/cat"
  run --separate-stderr env -i HOME="${HOME}" PATH="${fake_path_dir}" AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" SCRIPTS_DIR="${SCRIPTS_DIR}" "${fake_path_dir}/bash" -c '
    source "${SCRIPTS_DIR}/lib/path-guard.sh"
    _aidlc_migrate_path_guard_init || exit $?
    _aidlc_migrate_validate_path "subdir/file.txt" "path" "test"
  '
  cd "$BATS_TMPDIR" || true
  rm -rf "${fake_path_dir}"
  [ "${status}" -eq 0 ]
}
