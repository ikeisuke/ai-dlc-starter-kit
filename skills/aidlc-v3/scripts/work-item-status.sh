#!/usr/bin/env bash
#
# work-item-status.sh - read or transition a work item's frontmatter status
#
# work item（*.md）の YAML frontmatter の `status` を扱う単一の安全境界スクリプト。
# frontmatter status のパース責務を本スクリプト 1 箇所に集約し、呼び出し側（develop.md /
# テスト）に脆弱なパースを残さない（docs/v3/data-model.md §4 / RFC P4）。
#
# frontmatter の構造解釈（ブロック抽出 / スカラー抽出 / malformed guard）は共有ライブラリ
# lib/frontmatter.sh に集約済み（#733 T1）。本スクリプトは構造解釈を共有 parser へ委譲し、
# status 行一意性 / status enum 検証 / 期待現在 status 検証 / atomic write（意味判定・状態遷移）を担う。
#
# 2 モード:
#   read  : work-item-status.sh --read <work-item-path>
#           現在 status を堅牢に読取り `status:<value>` を stdout 出力（状態変更なし）。
#   write : work-item-status.sh <work-item-path> <expected-current> <next-status>
#           現在 status が <expected-current> と一致する場合のみ、frontmatter の status 行を
#           <next-status> へ atomic（temp + mv）に書き換える（不正遷移ガード / 競合検出）。
#
# 両モード共通の堅牢性ガード:
#   - frontmatter（先頭 --- 〜 次の ---）内の `^status:` 行が「ちょうど 1 行」でなければ exit 1
#     （0 行 = status 不在 / 2 行以上 = 曖昧）。本文側・frontmatter 外の `status:` は対象外。
#   - status 値は共有 parser（fm_scalar loose）で抽出（前後空白・inline コメント・両端引用符を考慮）し
#     非空であること + status enum（pending/in_progress/blocked/done/withdrawn）に一致しなければ exit 1。
#
# 終了コード（AI-DLC 終了コード規約準拠 / 既存 state-*.sh・work-item-validate.sh と一致）:
#   0 = 正常（read: status 出力 / write: 書き込み完了）
#   1 = バリデーションエラー（引数不正 / ファイル不存在 / status 行 0 or 複数 / 値 malformed /
#       enum 不正 / write の期待現在 status 不一致）
#   2 = システムエラー（ファイル読取不可 / mktemp 失敗 / mv 失敗 / jq 等の外部不備）
#
# updated_at 等のタイムスタンプは frontmatter に持たないため本スクリプトでは扱わない。
#
set -uo pipefail

# 共有 frontmatter parser ライブラリを source（スクリプト配置基準 / cwd 非依存 / bash 3.2 互換）
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/frontmatter.sh disable=SC1091
. "$_SCRIPT_DIR/lib/frontmatter.sh"

readonly STATUS_ENUM='pending in_progress blocked done withdrawn'

err() { echo "$@" >&2; }

# in_list <value> <space-separated-list> : value がリストに含まれれば 0
in_list() {
    local _il_needle="$1" _il_item
    for _il_item in $2; do
        [[ "$_il_item" == "$_il_needle" ]] && return 0
    done
    return 1
}

# --- 引数パース（モード判定） ---
if [[ $# -lt 1 ]]; then
    err "error: arguments required"
    err "usage: work-item-status.sh --read <work-item-path>"
    err "       work-item-status.sh <work-item-path> <expected-current> <next-status>"
    exit 1
fi

mode="write"
if [[ "$1" == "--read" ]]; then
    mode="read"
    shift
    if [[ $# -ne 1 ]]; then
        err "error: --read requires exactly one <work-item-path>"
        exit 1
    fi
    file="$1"
else
    if [[ $# -ne 3 ]]; then
        err "error: write mode requires <work-item-path> <expected-current> <next-status>"
        exit 1
    fi
    file="$1"
    expected_current="$2"
    next_status="$3"
fi

# --- 対象ファイル存在・可読性 ---
if [[ ! -f "$file" ]]; then
    err "error: work item not found: $file"
    exit 1
fi
if [[ ! -r "$file" ]]; then
    err "error: work item not readable: $file"
    exit 2
fi

# --- frontmatter ブロック終端ガード（閉じ --- 必須 / malformed file の改変防止 / 共有 parser） ---
if ! fm_has_closing_frontmatter "$file"; then
    err "error: malformed frontmatter (missing closing '---'): $file"
    exit 1
fi

# --- frontmatter 抽出 + status 行一意性ガード（抽出・カウントは共有 parser） ---
fm="$(fm_extract_block "$file")"
status_line_count="$(fm_key_count "$fm" status)"
# fm_key_count は不在時も "0" を返す。数値として比較する。
if [[ "$status_line_count" -eq 0 ]]; then
    err "error: no 'status:' line in frontmatter: $file"
    exit 1
fi
if [[ "$status_line_count" -gt 1 ]]; then
    err "error: ambiguous: multiple 'status:' lines ($status_line_count) in frontmatter: $file"
    exit 1
fi

# --- 現在 status の抽出（共有 parser fm_scalar loose） + 非空ガード + enum 検証（consumer 責務） ---
current_status="$(fm_scalar "$fm" status)"
if [[ -z "$current_status" ]]; then
    err "error: malformed status value in frontmatter: $file"
    exit 1
fi
if ! in_list "$current_status" "$STATUS_ENUM"; then
    err "error: bad status enum '$current_status' in $file"
    exit 1
fi

# --- read モード: 現在 status を出力して終了 ---
if [[ "$mode" == "read" ]]; then
    echo "status:$current_status"
    exit 0
fi

# --- write モード: 引数 enum 検証 ---
if ! in_list "$expected_current" "$STATUS_ENUM"; then
    err "error: bad expected-current enum '$expected_current'"
    exit 1
fi
if ! in_list "$next_status" "$STATUS_ENUM"; then
    err "error: bad next-status enum '$next_status'"
    exit 1
fi

# --- 期待現在 status 検証（不正遷移 / 競合検出） ---
if [[ "$current_status" != "$expected_current" ]]; then
    err "error: status mismatch: expected '$expected_current' but found '$current_status' in $file"
    exit 1
fi

# --- atomic 書き込み: frontmatter 内の唯一の status 行のみ置換 ---
dir="$(dirname "$file")"
tmp="$(mktemp "$dir/.work-item-status.XXXXXX")" || { err "error: mktemp failed"; exit 2; }
trap 'rm -f "$tmp"' EXIT

# 先頭 --- 〜 次の --- の frontmatter 領域内の status 行のみを置換する。
# frontmatter 外（本文）の status: 行は変更しない。status 一意性は上で保証済み。
if ! awk -v newstatus="$next_status" '
    BEGIN { infm = 0; seen_open = 0 }
    NR == 1 && $0 == "---" { infm = 1; seen_open = 1; print; next }
    infm == 1 && $0 == "---" { infm = 0; print; next }
    infm == 1 && /^status:/ { print "status: " newstatus; next }
    { print }
' "$file" > "$tmp"; then
    err "error: awk replacement failed"
    exit 2
fi

# --- atomic 置換 ---
if ! mv "$tmp" "$file"; then
    err "error: mv failed"
    exit 2
fi
trap - EXIT  # temp は mv 済み

echo "status:written"
exit 0
