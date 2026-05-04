#!/usr/bin/env bash
# bats helper for tests/aidlc-setup/
# 静的検証ヘルパ群（grep / awk ベース）

set -uo pipefail

# リポジトリルートを絶対パスで解決
HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${HELPER_DIR}/../../.." && pwd)"

# 検査対象ステップファイル
readonly STEP_FILE_PATH="${REPO_ROOT}/skills/aidlc-setup/steps/03-migrate.md"

# 重複検査対象（観点 D3）
readonly OTHER_STEP_FILES=(
  "${REPO_ROOT}/skills/aidlc-setup/steps/01-detect.md"
  "${REPO_ROOT}/skills/aidlc-setup/steps/02-generate-config.md"
)

# 指定見出しが STEP_FILE 内に存在するか
# 引数: $1 = section_anchor 文字列 (例: "## 9b.")
# 戻り値: 0=存在, 1=不在, 2=STEP_FILE 不存在
assert_section_exists() {
  local anchor="$1"
  if [[ ! -f "${STEP_FILE_PATH}" ]]; then
    echo "STEP_FILE not found: ${STEP_FILE_PATH}" >&2
    return 2
  fi
  if grep -q -F -- "${anchor}" "${STEP_FILE_PATH}"; then
    return 0
  else
    echo "section anchor not found: ${anchor}" >&2
    return 1
  fi
}

# 指定パターンの STEP_FILE 内出現数が期待値と一致するか
# 引数: $1 = pattern (BRE / 行頭固定可能), $2 = expected count
# 戻り値: 0=一致, 1=不一致, 2=STEP_FILE 不存在
assert_section_count() {
  local pattern="$1"
  local expected="$2"
  if [[ ! -f "${STEP_FILE_PATH}" ]]; then
    echo "STEP_FILE not found: ${STEP_FILE_PATH}" >&2
    return 2
  fi
  local actual
  actual="$(grep -c -- "${pattern}" "${STEP_FILE_PATH}" || true)"
  if [[ "${actual}" -eq "${expected}" ]]; then
    return 0
  else
    echo "section count mismatch: pattern=${pattern} expected=${expected} actual=${actual}" >&2
    return 1
  fi
}

# 行番号順序検証 (line_after < line_target < line_before)
# 引数: $1 = after_id, $2 = target_id, $3 = before_id
#   各 ID は "## <id>" の形で grep される (例: "9", "9b", "10")
# 戻り値: 0=順序正, 1=順序違反, 2=いずれかのセクション不在
assert_section_between() {
  local after_id="$1"
  local target_id="$2"
  local before_id="$3"

  if [[ ! -f "${STEP_FILE_PATH}" ]]; then
    echo "STEP_FILE not found: ${STEP_FILE_PATH}" >&2
    return 2
  fi

  local line_after line_target line_before
  line_after="$(grep -n -- "^## ${after_id}\." "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  line_target="$(grep -n -- "^## ${target_id}\." "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  line_before="$(grep -n -- "^## ${before_id}\." "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"

  if [[ -z "${line_after}" || -z "${line_target}" || -z "${line_before}" ]]; then
    echo "section not found: after=${line_after} target=${line_target} before=${line_before}" >&2
    return 2
  fi

  if (( line_after < line_target && line_target < line_before )); then
    return 0
  else
    echo "section order violation: after=${line_after} target=${line_target} before=${line_before}" >&2
    return 1
  fi
}

# セクション本文を抽出（次の "## " 見出しまで、または EOF まで）
# 引数: $1 = section_anchor (例: "## 9b.")
# stdout: 本文文字列
# 戻り値: 0=抽出成功, 1=セクション不在
extract_section_body() {
  local anchor="$1"
  if [[ ! -f "${STEP_FILE_PATH}" ]]; then
    echo "STEP_FILE not found: ${STEP_FILE_PATH}" >&2
    return 1
  fi
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
      if (in_section == 1) {
        print
      }
    }
  ' "${STEP_FILE_PATH}"
}

# セクション本文に token が含まれるか (grep -F -- 使用、dash 始まりトークン対応)
# 引数: $1 = section_anchor, $2 = token
# 戻り値: 0=含有, 1=未含有, 2=セクション不在
assert_body_contains_token() {
  local anchor="$1"
  local token="$2"
  local body
  body="$(extract_section_body "${anchor}")"
  if [[ -z "${body}" ]]; then
    echo "section body empty or not found: ${anchor}" >&2
    return 2
  fi
  if printf '%s' "${body}" | grep -q -F -- "${token}"; then
    return 0
  else
    echo "token not found in section body: anchor=${anchor} token=${token}" >&2
    return 1
  fi
}

# セクション本文にいずれか 1 トークンが含まれるか (2 段判定方式 / 観点 C2)
# 引数: $1 = section_anchor, $2..$n = tokens
# 戻り値: 0=いずれか含有, 1=全て未含有, 2=セクション不在
assert_body_contains_any() {
  local anchor="$1"
  shift
  local body
  body="$(extract_section_body "${anchor}")"
  if [[ -z "${body}" ]]; then
    echo "section body empty or not found: ${anchor}" >&2
    return 2
  fi
  local tk
  for tk in "$@"; do
    if printf '%s' "${body}" | grep -q -F -- "${tk}"; then
      return 0
    fi
  done
  echo "none of tokens found in section body: anchor=${anchor} tokens=$*" >&2
  return 1
}

# OTHER_STEP_FILES に token が含まれないか (観点 D3)
# 引数: $1 = token
# 戻り値: 0=重複なし, 1=重複検出, 2=対象ファイル不在
assert_other_files_no_token() {
  local token="$1"
  local f
  for f in "${OTHER_STEP_FILES[@]}"; do
    if [[ ! -f "${f}" ]]; then
      echo "OTHER_STEP_FILES entry not found: ${f}" >&2
      return 2
    fi
    if grep -q -F -- "${token}" "${f}"; then
      echo "token unexpectedly found in other step file: file=${f} token=${token}" >&2
      return 1
    fi
  done
  return 0
}
