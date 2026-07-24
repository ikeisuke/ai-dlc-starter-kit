#!/usr/bin/env bash
#
# state-read.sh - read a single field from v3 cycle state (.aidlc/state.json)
#
# 指定フィールドの値を stdout に出力する（read-only / 状態は変更しない）。
# 個別キーの存在のみを has() で確認し（欠落と明示 null を区別）、
# state 全体の schema 妥当性検証は行わない（それは state-validate.sh の責務）。
#
# Usage:
#   state-read.sh <field> [file]
#     field: schema_version | current_cycle | define_completed |
#            release.pr_number | release.ready | release.merge_approved | updated_at
#     file : 対象パス（省略時: .aidlc/state.json）
#
# 終了コード（AI-DLC 終了コード規約準拠）:
#   0 = 値を stdout に出力（明示 null は "null" を出力して 0）
#   1 = バリデーションエラー（引数不正 / 未知フィールド / ファイル不存在 /
#       JSON parse 不能 / 指定キーがファイル内に存在しない）
#   2 = システムエラー（jq 未導入 等）
#
set -euo pipefail

readonly DEFAULT_STATE_FILE=".aidlc/state.json"

err() { echo "$@" >&2; }

# --- jq 存在確認（システムエラー） ---
if ! command -v jq >/dev/null 2>&1; then
    err "error: jq not found"
    exit 2
fi

# --- 引数チェック ---
if [[ $# -lt 1 ]]; then
    err "error: field is required"
    err "usage: state-read.sh <field> [file]"
    exit 1
fi

field="$1"
file="${2:-$DEFAULT_STATE_FILE}"

# --- 許容キー → JSON パス配列 ---
case "$field" in
    schema_version|current_cycle|define_completed|updated_at)
        path_json="[\"$field\"]"
        ;;
    release.pr_number)
        path_json='["release","pr_number"]'
        ;;
    release.ready)
        path_json='["release","ready"]'
        ;;
    release.merge_approved)
        path_json='["release","merge_approved"]'
        ;;
    *)
        err "error: unknown field: $field"
        exit 1
        ;;
esac

# --- ファイル存在 ---
if [[ ! -f "$file" ]]; then
    err "error: file not found: $file"
    exit 1
fi

# --- 読み取り可能性（システムエラー） ---
# permission denied 等の読み取りエラーは exit 2（規約: 読み取りエラー = システムエラー）。
if [[ ! -r "$file" ]]; then
    err "error: file not readable: $file"
    exit 2
fi

# --- JSON 妥当性 ---
if ! jq empty "$file" >/dev/null 2>&1; then
    err "error: not valid JSON: $file"
    exit 1
fi

# --- キー存在確認（欠落と明示 null を区別） ---
# 親パス（path[:-1]）が object で、かつ最終キーを has() で保持しているかを確認する。
exists="$(jq -r --argjson p "$path_json" '
  . as $root
  | ($p[0:-1]) as $pp
  | ($root | getpath($pp)) as $parent
  | (($parent | type) == "object") and ($parent | has($p[-1]))
' "$file")"

if [[ "$exists" != "true" ]]; then
    err "error: field not present in state: $field"
    exit 1
fi

# --- 値の出力（明示 null は "null"、boolean は true/false、string は素値） ---
jq -r --argjson p "$path_json" 'getpath($p)' "$file"
exit 0
