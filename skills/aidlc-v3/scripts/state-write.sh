#!/usr/bin/env bash
#
# state-write.sh - atomically update an allowed field in v3 cycle state
#
# 許可フィールドのみを更新し、updated_at を自動更新したうえで
# atomic（temp file + mv）に書き込む。書き込み確定前に state-validate.sh で検証する。
# 本スクリプトは「既存 state.json の更新」専用（初期 state の生成は Phase 3 / define フローへ defer）。
#
# 非互換 schema_version ガード（Unit 004 #731）: 書き込み前に既存 state を state-validate.sh で
# 検証し、schema_version がサポート対象外（未知）の場合は更新を拒否してファイルを不変のまま保持する
# （migration・手動対応を案内）。互換性判定は state-validate.sh を SoT として再利用する。
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
#       ファイル不存在 / JSON parse 不能 / 書き込み後 state が invalid /
#       既存 state の schema_version がサポート対象外 = 更新拒否・ファイル不変 / Unit 004）
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

# --- 非互換 schema_version の更新ガード（Unit 004 #731）---
# 既存 state の schema_version が未知（サポート対象外）の場合、ファイルを一切変更せず更新を拒否する。
# 互換性判定は state-validate.sh を Single Source of Truth として再利用する（supported 集合を
# 本スクリプトに重複定義しない）。mktemp より前に実行するため、拒否時は temp も作らずファイル不変。
# rc 別ハンドリング:
#   rc=0 かつ status:valid → 既知 + 構造健全。従来どおり更新へ進む
#   rc=0 かつ status:warn:unsupported-schema-version: 接頭辞 → 更新拒否（exit 1 / ファイル不変）
#         （接頭辞のみで判定し値内容に依存しない / 設計レビュー指摘 #2）
#   rc=0 だが上記いずれでもない → validator 出力契約違反として exit 2（fail-safe / コードレビュー指摘）
#   rc=1（未知以外の invalid）→ 従来動作を維持（ここでは何もせず、後段の post-write 検証で捕捉）
#   rc=2（システムエラー）→ exit 2
set +e
precheck_out="$("$VALIDATE" "$file" 2>/dev/null)"
precheck_rc=$?
set -e
case "$precheck_rc" in
    0)
        # 先頭行のみを取り出し、リテラル接頭辞で判定する（value 内容非依存 / 単一行保証）。
        precheck_first_line="${precheck_out%%$'\n'*}"
        case "$precheck_first_line" in
            status:valid)
                : ;; # 既知 + 構造健全。従来どおり更新へ進む
            status:warn:unsupported-schema-version:*)
                err "error: refusing to update state with unsupported schema_version (migration or manual handling required; file left unchanged): $file"
                err "  see docs/v3/data-model.md §6"
                exit 1
                ;;
            *)
                # validator が rc=0 で想定外の出力（空 / 未知 status 行）を返した = 出力契約違反。
                # valid 扱いで更新を継続すると parse 契約の防御が崩れるため、fail-safe で停止する。
                err "error: validator returned unexpected output on rc=0 (contract violation): '$precheck_first_line'"
                exit 2
                ;;
        esac
        ;;
    1) : ;; # 未知以外の invalid は従来動作（post-write 検証で捕捉）
    2) err "error: validator system error during pre-write schema compatibility check"; exit 2 ;;
    *) err "error: validator exited unexpectedly (rc=$precheck_rc)"; exit 2 ;; # 126/127 等の漏れ防止
esac

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
