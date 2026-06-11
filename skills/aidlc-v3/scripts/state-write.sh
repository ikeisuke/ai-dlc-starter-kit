#!/usr/bin/env bash
#
# state-write.sh - atomically update an allowed field in v3 cycle state
#
# 許可フィールドのみを更新し、updated_at を自動更新したうえで
# atomic（temp file + mv）に書き込む。書き込み確定前に state-validate.sh で検証する。
# 本スクリプトは「既存 state.json の更新」専用（初期 state の生成は Phase 3 / define フローへ defer）。
#
# Usage:
#   state-write.sh <field> <value> [file]
#     field: define_completed | release.pr_number | release.ready | release.merge_approved
#     value: true | false  （boolean フィールド）
#            <integer> | null （release.pr_number）
#     file : 対象パス（省略時: .aidlc/state.json）
#
# updated_at は書き込み時に現在 UTC へ自動更新する。
# 環境変数 AIDLC_STATE_NOW（ISO 8601 文字列）が設定されていればその値を使う（テスト用）。
#
# 終了コード（AI-DLC 終了コード規約準拠）:
#   0 = 書き込み完了
#   1 = バリデーションエラー（引数不正 / 許可外フィールド / 値型不正 /
#       ファイル不存在 / JSON parse 不能 / 書き込み後 state が invalid）
#   2 = システムエラー（jq 未導入 / 依存スクリプト不備 / 外部コマンド失敗）
#
set -euo pipefail

readonly DEFAULT_STATE_FILE=".aidlc/state.json"

err() { echo "$@" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VALIDATE="$SCRIPT_DIR/state-validate.sh"

# --- jq 存在確認（システムエラー） ---
if ! command -v jq >/dev/null 2>&1; then
    err "error: jq not found"
    exit 2
fi

# --- 依存スクリプト確認（システムエラー） ---
# set -euo pipefail のまま依存呼び出しを素通しすると、存在しないコマンドの 127 /
# 実行権限なしの 126 が外部へ漏れ、終了コード規約の 0/1/2 契約を破る。
# 起動時に明示確認して exit 2 に正規化する。
if [[ ! -x "$VALIDATE" ]]; then
    err "error: dependency not found or not executable: $VALIDATE"
    exit 2
fi

# --- 引数チェック ---
if [[ $# -lt 2 ]]; then
    err "error: field and value are required"
    err "usage: state-write.sh <field> <value> [file]"
    exit 1
fi

field="$1"
value="$2"
file="${3:-$DEFAULT_STATE_FILE}"

# --- 許可フィールド検証 + 値の型検証 + JSON パス配列 ---
# 許可フィールドは data-model.md §3.3 の書き込みタイミング表に一致。
# schema_version / current_cycle / updated_at は更新対象外（前者2つは作成時確定、
# updated_at は自動更新のため直接指定不可）。
case "$field" in
    define_completed)
        path_json='["define_completed"]'
        case "$value" in
            true|false) jq_value="$value" ;;
            *) err "error: $field must be true or false"; exit 1 ;;
        esac
        ;;
    release.ready)
        path_json='["release","ready"]'
        case "$value" in
            true|false) jq_value="$value" ;;
            *) err "error: $field must be true or false"; exit 1 ;;
        esac
        ;;
    release.merge_approved)
        path_json='["release","merge_approved"]'
        case "$value" in
            true|false) jq_value="$value" ;;
            *) err "error: $field must be true or false"; exit 1 ;;
        esac
        ;;
    release.pr_number)
        path_json='["release","pr_number"]'
        # 先頭ゼロ（001 / -01）は拒否する。jq --argjson は先頭ゼロを黙って
        # コアース（001 -> 1）するため、入力段階で厳格に弾き意図しない値書き込みを防ぐ。
        if [[ "$value" == "null" ]]; then
            jq_value="null"
        elif [[ "$value" =~ ^(0|-?[1-9][0-9]*)$ ]]; then
            jq_value="$value"
        else
            err "error: $field must be an integer (no leading zeros) or null"
            exit 1
        fi
        ;;
    *)
        err "error: field not writable: $field"
        exit 1
        ;;
esac

# --- updated_at の値（テスト時は AIDLC_STATE_NOW で上書き可能） ---
now="${AIDLC_STATE_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

# --- 対象ファイル存在（更新専用） ---
if [[ ! -f "$file" ]]; then
    err "error: file not found (state-write updates an existing state only): $file"
    exit 1
fi

# --- 読み取り可能性（システムエラー） ---
if [[ ! -r "$file" ]]; then
    err "error: file not readable: $file"
    exit 2
fi

# --- JSON 妥当性 ---
if ! jq empty "$file" >/dev/null 2>&1; then
    err "error: not valid JSON: $file"
    exit 1
fi

# --- temp file を対象ファイルと同一ディレクトリに作成（mv の atomic 性を担保） ---
dir="$(dirname "$file")"
tmp="$(mktemp "$dir/.state.json.XXXXXX")" || { err "error: mktemp failed"; exit 2; }
trap 'rm -f "$tmp"' EXIT

# --- field 更新 + updated_at 更新を temp file へ書き出す ---
if ! jq --argjson p "$path_json" --argjson v "$jq_value" --arg now "$now" '
    setpath($p; $v) | .updated_at = $now
' "$file" > "$tmp"; then
    err "error: jq update failed"
    exit 2
fi

# --- 書き込み後 state を validate（検証 SoT 再利用 / rc を正規化） ---
set +e
"$VALIDATE" "$tmp" >/dev/null 2>&1
rc=$?
set -e
case "$rc" in
    0) : ;; # 有効
    1) err "error: validation failed after write (original file kept)"; exit 1 ;;
    2) err "error: validator system error"; exit 2 ;;
    *) err "error: validator exited unexpectedly (rc=$rc)"; exit 2 ;; # 126/127 等の漏れ防止
esac

# --- atomic 置換 ---
if ! mv "$tmp" "$file"; then
    err "error: mv failed"
    exit 2
fi
trap - EXIT  # temp は mv 済み

echo "status:written"
exit 0
