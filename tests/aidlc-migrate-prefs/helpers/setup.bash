#!/usr/bin/env bash
# bats helper for tests/aidlc-migrate-prefs/

set -uo pipefail

HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${HELPER_DIR}/../../.." && pwd)"

readonly SCRIPT_PATH="${REPO_ROOT}/skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh"
readonly FIXTURES_DIR="${REPO_ROOT}/tests/fixtures/aidlc-migrate-prefs"
readonly STEP_FILE_PATH="${REPO_ROOT}/skills/aidlc-migrate/steps/02-execute.md"

# 一時環境構築
# 引数: $1 = project_fixture_name (p-all7-keys / p-mixed-3keys / p-no-keys)
#       $2 = user_global_fixture_name (u-empty / u-with-key) または "none" でファイル不在
setup_env() {
  local project_fixture="$1"
  local user_global_fixture="$2"

  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-migrate-prefs-XXXXXX)"
  export TEST_TMPDIR

  # project ルート構築
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}/project"
  mkdir -p "${AIDLC_PROJECT_ROOT}/.aidlc"
  cp -R "${FIXTURES_DIR}/${project_fixture}/.aidlc/." "${AIDLC_PROJECT_ROOT}/.aidlc/"
  git -C "${AIDLC_PROJECT_ROOT}" init --quiet 2>/dev/null || true

  # user-global 配置
  if [[ "${user_global_fixture}" == "none" ]]; then
    # ファイル不在状態をシミュレート
    export AIDLC_USER_GLOBAL_PATH="${TEST_TMPDIR}/user-global/aidlc-config.toml"
    # ディレクトリだけ作成（ファイルは作らない）
    mkdir -p "$(dirname "${AIDLC_USER_GLOBAL_PATH}")"
  else
    export AIDLC_USER_GLOBAL_PATH="${TEST_TMPDIR}/user-global/aidlc-config.toml"
    mkdir -p "$(dirname "${AIDLC_USER_GLOBAL_PATH}")"
    cp "${FIXTURES_DIR}/${user_global_fixture}/aidlc-config.toml" "${AIDLC_USER_GLOBAL_PATH}"
  fi
}

teardown_env() {
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    \rm -rf "${TEST_TMPDIR}"
  fi
}

# script 実行ラッパ
run_detect() {
  bash "${SCRIPT_PATH}" detect "$@"
}

run_move() {
  bash "${SCRIPT_PATH}" move "$@"
}

run_keep() {
  bash "${SCRIPT_PATH}" keep "$@"
}

# sha256 取得（cross-platform）
_sha256_of() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    echo "no-sha256-command" >&2
    return 1
  fi
}

# ファイル変更チェック（前後 sha 比較）
# 使い方: snap=$(snapshot_sha "$file") ... ; assert_unchanged "$file" "$snap"
snapshot_sha() {
  _sha256_of "$1"
}

assert_unchanged() {
  local file="$1"
  local expected_sha="$2"
  local actual_sha
  actual_sha="$(_sha256_of "$file")"
  if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo "file unexpectedly changed: $file (sha: $expected_sha -> $actual_sha)" >&2
    return 1
  fi
}

assert_changed() {
  local file="$1"
  local expected_sha="$2"
  local actual_sha
  actual_sha="$(_sha256_of "$file")"
  if [[ "$actual_sha" == "$expected_sha" ]]; then
    echo "file unexpectedly unchanged: $file" >&2
    return 1
  fi
}

# project から指定キーが除去されたか
assert_key_absent_in_project() {
  local key="$1"
  local section_part="${key%.*}"
  local leaf_part="${key##*.}"
  if awk -v sec="[${section_part}]" -v lf="${leaf_part}" '
    BEGIN { in_section = 0; found = 0 }
    {
      if ($0 == sec) { in_section = 1; next }
      if (in_section && /^\[/ && $0 != sec) { in_section = 0 }
      if (in_section && $0 ~ "^[[:space:]]*"lf"[[:space:]]*=") { found = 1 }
    }
    END { exit (found ? 1 : 0) }
  ' "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"; then
    return 0
  else
    echo "key still present in project: ${key}" >&2
    return 1
  fi
}

# user-global に指定キーが追記されたか + 値の正規化チェック
assert_key_present_in_user_global() {
  local key="$1"
  local expected_normalized="$2"   # 例: "required" / true / ["claude"]
  local section_part="${key%.*}"
  local leaf_part="${key##*.}"
  if awk -v sec="[${section_part}]" -v lf="${leaf_part}" -v expected_val="${expected_normalized}" '
    BEGIN { in_section = 0; found = 0; matched = 0 }
    {
      if ($0 == sec) { in_section = 1; next }
      if (in_section && /^\[/ && $0 != sec) { in_section = 0 }
      if (in_section && $0 ~ "^[[:space:]]*"lf"[[:space:]]*=") {
        found = 1
        # 値部分抽出
        v = $0
        sub("^[[:space:]]*"lf"[[:space:]]*=[[:space:]]*", "", v)
        if (v == expected_val) { matched = 1 }
      }
    }
    END {
      if (!found) { exit 1 }
      if (!matched) { exit 2 }
      exit 0
    }
  ' "${AIDLC_USER_GLOBAL_PATH}"; then
    return 0
  else
    local rc=$?
    if [[ $rc -eq 1 ]]; then
      echo "key not found in user-global: ${key}" >&2
    else
      echo "key value mismatch in user-global: ${key} expected=${expected_normalized}" >&2
    fi
    return 1
  fi
}

# 02-execute.md 用静的検証ヘルパ（Unit 002 と同等パターン、簡略版）
extract_step_section_body() {
  local anchor="$1"
  awk -v anchor="${anchor}" '
    BEGIN { in_section = 0 }
    {
      if (in_section == 0 && index($0, anchor) == 1) {
        in_section = 1
        print
        next
      }
      if (in_section == 1 && /^## / && index($0, anchor) != 1) {
        exit 0
      }
      if (in_section == 1) { print }
    }
  ' "${STEP_FILE_PATH}"
}

assert_step_body_contains() {
  local anchor="$1"
  local token="$2"
  local body
  body="$(extract_step_section_body "${anchor}")"
  if printf '%s' "${body}" | grep -q -F -- "${token}"; then
    return 0
  fi
  echo "token not found in step section ${anchor}: ${token}" >&2
  return 1
}

assert_step_section_count() {
  local pattern="$1"
  local expected="$2"
  local actual
  actual="$(grep -c -- "${pattern}" "${STEP_FILE_PATH}" || true)"
  if [[ "${actual}" -eq "${expected}" ]]; then
    return 0
  fi
  echo "step section count mismatch: pattern=${pattern} expected=${expected} actual=${actual}" >&2
  return 1
}

assert_step_section_between() {
  local after_id="$1"
  local target_id="$2"
  local before_id="$3"
  local line_after line_target line_before
  line_after="$(grep -n -- "^## ${after_id}\." "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  line_target="$(grep -n -- "^## ${target_id}\." "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  line_before="$(grep -n -- "^## ${before_id}\." "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  if [[ -z "${line_after}" || -z "${line_target}" || -z "${line_before}" ]]; then
    echo "step section not found: after=${line_after} target=${line_target} before=${line_before}" >&2
    return 1
  fi
  if (( line_after < line_target && line_target < line_before )); then
    return 0
  else
    echo "step section order violation: after=${line_after} target=${line_target} before=${line_before}" >&2
    return 1
  fi
}
