#!/usr/bin/env bash
#
# state-validate.sh - v3 cycle state (.aidlc/state.json) schema validator
#
# state.json が docs/v3/data-model.md §3 の schema に適合する有効な state かを
# 検証する（検証ロジックの Single Source of Truth）。状態は一切変更しない。
#
# Usage:
#   state-validate.sh [file]
#     file: 検証対象パス（省略時: .aidlc/state.json）
#
# 終了コード（AI-DLC 終了コード規約準拠）:
#   0 = 有効（valid）または未知 schema_version（WARN / 互換性なし / Unit 004 #731）
#       未知 schema_version は invalid 扱いにせず WARN + exit 0 とする（docs/v3/data-model.md §6 /
#       終了コード規約「WARN 付き完了を exit 非 0 にしない」）。
#   1 = バリデーションエラー（ファイル不存在 / JSON parse 不能 / 必須フィールド欠落 /
#       型不正 / release サブフィールド欠落 / updated_at の ISO 8601 形式不正）
#   2 = システムエラー（jq 未導入 等）
#
# 出力契約（stdout）:
#   status:valid                                          有効（既知 schema_version + 構造検証通過）
#   status:warn:unsupported-schema-version:<safe-value>   未知 schema_version（単一行 / <safe-value> は
#                                                         改行・制御文字を除去したサニタイズ済み値 / Unit 004）
#
set -euo pipefail

readonly DEFAULT_STATE_FILE=".aidlc/state.json"
# サポート対象 schema_version 集合（docs/v3/data-model.md §3 を SoT とする / 初版 "3.0"）。
# 本配列が schema 互換性判定の Single Source of Truth であり、state-write.sh は本スクリプト経由で
# 互換性を判定する（リストを重複定義しない / Unit 004 #731）。将来の対応版追加は本配列に値を足す。
SUPPORTED_SCHEMA_VERSIONS=("3.0")
readonly SUPPORTED_SCHEMA_VERSIONS
# ISO 8601（UTC / オフセット）。桁数だけでなく基本範囲も制約する。
# 実在日（2月30日・うるう年）までは検証しない（形式 + 基本範囲のみ）。
readonly ISO8601_RE='^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?(Z|[+-](0[0-9]|1[0-9]|2[0-3]):[0-5][0-9])$'

err() { echo "$@" >&2; }

# --- jq 存在確認（システムエラー） ---
if ! command -v jq >/dev/null 2>&1; then
    err "error: jq not found"
    exit 2
fi

file="${1:-$DEFAULT_STATE_FILE}"

# --- ファイル存在（バリデーション） ---
if [[ ! -f "$file" ]]; then
    err "invalid: file not found: $file"
    exit 1
fi

# --- 読み取り可能性（システムエラー） ---
# permission denied 等の読み取りエラーは exit 2（規約: 読み取りエラー = システムエラー）。
# JSON parse 不能（exit 1）と区別するため jq 実行前に確認する。
if [[ ! -r "$file" ]]; then
    err "error: file not readable: $file"
    exit 2
fi

# --- JSON 妥当性（バリデーション） ---
# 【検証契約】本 Unit は jq を唯一の JSON ツールとする（Unit 制約）。よって「JSON 妥当性」は
# jq が受理する入力をもって妥当とする（jq は先頭ゼロ数値 001 等を 1 にコアースする寛容性を持つ）。
# RFC 8259 strict 構文検証（別 parser 依存の追加）は本 Unit のスコープ外。state.json は
# state-write.sh が機械生成する前提であり、手書きの非標準 JSON 混入経路は限定的。
if ! jq empty "$file" >/dev/null 2>&1; then
    err "invalid: not valid JSON: $file"
    exit 1
fi

# --- 前段: schema_version の存在・型のみ検証（互換性判定の前提）---
# schema_version の has + string 型を先に保証し、この直後に値の互換性判定（後述）を行う。
# 残りの構造検証（current_cycle / release / updated_at 等）は互換性判定の「後」に置く。
# これにより未知 schema_version は構造検証より前に WARN 短絡でき、
# 「未知 schema_version かつ release 欠落」のようなケースも warn として扱える（Unit 004 #731）。
schema_version_error="$(jq -r '
  if   (has("schema_version") | not)        then "missing field: schema_version"
  elif (.schema_version | type != "string") then "type error: schema_version must be string"
  else "" end
' "$file")"

if [[ -n "$schema_version_error" ]]; then
    err "invalid: $schema_version_error"
    exit 1
fi

# --- 互換性判定: schema_version 値を supported 集合と照合 ---
# 未知バージョンは invalid（exit 1）にせず WARN + exit 0 で短絡する（docs/v3/data-model.md §6）。
schema_version="$(jq -r '.schema_version' "$file")"
is_supported=0
for _sv in "${SUPPORTED_SCHEMA_VERSIONS[@]}"; do
    if [[ "$schema_version" == "$_sv" ]]; then
        is_supported=1
        break
    fi
done

if [[ "$is_supported" -eq 0 ]]; then
    # status 行の parse 契約保護: schema_version は JSON 上 string 型制約のみで改行・制御文字を
    # 含みうるため、stdout の status 行に載せる値はサニタイズ（制御文字除去）して単一行を保証する。
    # 呼び出し側（state-write.sh）はリテラル接頭辞 status:warn:unsupported-schema-version: のみで
    # 判定し、接頭辞より後ろの値内容には依存しない（Unit 004 設計レビュー指摘 #2）。
    safe_schema_version="$(printf '%s' "$schema_version" | tr -d '[:cntrl:]')"
    err "warn: unsupported schema_version: '$safe_schema_version' (migration or manual handling required; see docs/v3/data-model.md §6)"
    printf 'status:warn:unsupported-schema-version:%s\n' "$safe_schema_version"
    exit 0
fi

# --- 後段: 残りの必須フィールド存在・型・release サブフィールド検証（既知バージョンのみ）---
# 型検証の前に release サブフィールドの存在を has() で確認する。
# jq は欠落キーと明示 null をともに null/type=="null" と返すため、
# 型検証のみでは必須サブフィールド欠落を有効扱いしてしまう。
validation_error="$(jq -r '
  if   (has("current_cycle") | not)         then "missing field: current_cycle"
  elif (.current_cycle | type != "string")  then "type error: current_cycle must be string"
  elif (has("define_completed") | not)      then "missing field: define_completed"
  elif (.define_completed | type != "boolean") then "type error: define_completed must be boolean"
  elif (has("release") | not)               then "missing field: release"
  elif (.release | type != "object")        then "type error: release must be object"
  elif (.release | has("pr_number") | not)     then "missing field: release.pr_number"
  elif (.release | has("ready") | not)         then "missing field: release.ready"
  elif (.release | has("merge_approved") | not) then "missing field: release.merge_approved"
  elif ((.release.pr_number | type) as $t | ($t != "number" and $t != "null"))
       then "type error: release.pr_number must be integer or null"
  elif ((.release.pr_number | type) == "number" and (.release.pr_number != (.release.pr_number | floor)))
       then "type error: release.pr_number must be integer"
  elif (.release.ready | type != "boolean")        then "type error: release.ready must be boolean"
  elif (.release.merge_approved | type != "boolean") then "type error: release.merge_approved must be boolean"
  elif (has("updated_at") | not)            then "missing field: updated_at"
  elif (.updated_at | type != "string")     then "type error: updated_at must be string"
  else "" end
' "$file")"

if [[ -n "$validation_error" ]]; then
    err "invalid: $validation_error"
    exit 1
fi

# --- updated_at の ISO 8601 形式検証 ---
updated_at="$(jq -r '.updated_at' "$file")"
if [[ ! "$updated_at" =~ $ISO8601_RE ]]; then
    err "invalid: updated_at is not a valid ISO 8601 timestamp: $updated_at"
    exit 1
fi

echo "status:valid"
exit 0
