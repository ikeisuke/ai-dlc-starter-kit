#!/usr/bin/env bash
#
# retrospective-generate.sh - retrospective.md 生成 + feedback_mode 解決 + 空ファイル禁止補完
#
# 使用方法:
#   retrospective-generate.sh <cycle>
#
# 入力:
#   cycle - サイクルバージョン（^v[0-9]+\.[0-9]+\.[0-9]+$ 形式）
#
# 出力:
#   stdout: retrospective\tcreated\t<path> / retrospective\tskip\tdisabled / retrospective\tskip\talready-exists
#   stderr: warn\tfeedback-mode-invalid\t<value>:downgrade-to-silent / error\t<code>\t<payload>
#
# 終了コード:
#   0 - 正常（生成 / スキップ いずれも 0）
#   2 - fatal エラー
#
# 責務外:
#   - YAML スキーマ検証 / q*_answer ダウングレード判定 / Markdown 内 YAML 抽出
#     → retrospective-validate.sh が担当

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"
# shellcheck source=lib/cycle-version-check.sh
source "${SCRIPT_DIR}/lib/cycle-version-check.sh"

readonly TEMPLATE_PATH="${AIDLC_PLUGIN_ROOT}/templates/retrospective_template.md"
readonly SCHEMA_PATH="${AIDLC_PLUGIN_ROOT}/config/retrospective-schema.yml"

# スキーマから契約値を動的読み込み（ハードコード回避 / 単一ソース）
_load_schema_values() {
    if ! command -v dasel >/dev/null 2>&1 || [ ! -f "$SCHEMA_PATH" ]; then
        # フォールバック（スキーマ未配置 / dasel 未インストール時）
        VALID_FEEDBACK_MODES=("silent" "mirror" "disabled")
        DEFAULT_FEEDBACK_MODE="silent"
        return
    fi

    VALID_FEEDBACK_MODES=()
    while IFS= read -r line; do
        line="${line#- }"
        line="${line//\"/}"
        line="$(echo "$line" | sed 's/^[ \t]*//; s/[ \t]*$//')"
        if [ -n "$line" ]; then
            VALID_FEEDBACK_MODES+=("$line")
        fi
    done < <(dasel query -i yaml 'retrospective_schema.valid_feedback_modes' <"$SCHEMA_PATH" 2>/dev/null || true)

    if [ "${#VALID_FEEDBACK_MODES[@]}" -eq 0 ]; then
        VALID_FEEDBACK_MODES=("silent" "mirror" "disabled")
    fi

    DEFAULT_FEEDBACK_MODE="$(dasel query -i yaml 'retrospective_schema.default_feedback_mode' <"$SCHEMA_PATH" 2>/dev/null | sed 's/^"//; s/"$//' || echo "silent")"
    if [ -z "$DEFAULT_FEEDBACK_MODE" ]; then
        DEFAULT_FEEDBACK_MODE="silent"
    fi
}
_load_schema_values

# 引数チェック
if [ "$#" -lt 1 ]; then
    echo "error	retrospective-generate	missing-cycle-argument" >&2
    exit 2
fi

CYCLE="$1"

# サイクルバージョン検証（v2.5.0 以降）
# step file (operations/04-completion.md) と挙動を統一:
#   v2.5.0 未満 → retrospective\tskip\tcycle-too-old + exit 0（スキップ）
#   フォーマット違反 → exit 2（cycle-version-check が出力済み）
# 注: `if ! cmd` 構文だと $? が常に 0/1 になり exit 2 を識別できないため、
# `|| rc=$?` 形式で実 rc を取得する（set -e は影響しない / pipefail は単一コマンドのため無関係）
rc=0
aidlc_is_cycle_v25_or_later "$CYCLE" || rc=$?
if [ "$rc" -ne 0 ]; then
    if [ "$rc" -eq 2 ]; then
        exit 2
    fi
    # rc == 1: v2.5.0 未満 → スキップ（exit 0）
    echo "retrospective	skip	cycle-too-old"
    exit 0
fi

# テンプレート存在確認
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "error	retrospective-template-not-found	${TEMPLATE_PATH}" >&2
    exit 2
fi

# feedback_mode 解決（4 階層マージ）
FEEDBACK_MODE_RAW=""
if FEEDBACK_MODE_RAW="$("${SCRIPT_DIR}/read-config.sh" rules.retrospective.feedback_mode 2>/dev/null)"; then
    :
else
    rc=$?
    if [ "$rc" -eq 2 ]; then
        echo "error	read-config-failed	rules.retrospective.feedback_mode" >&2
        exit 2
    fi
    # rc == 1: キー不在 → デフォルト
    FEEDBACK_MODE_RAW="$DEFAULT_FEEDBACK_MODE"
fi

# 不正値チェック → silent ダウングレード
FEEDBACK_MODE="$FEEDBACK_MODE_RAW"
_is_valid_mode=0
for valid in "${VALID_FEEDBACK_MODES[@]}"; do
    if [ "$FEEDBACK_MODE" = "$valid" ]; then
        _is_valid_mode=1
        break
    fi
done
if [ "$_is_valid_mode" -eq 0 ]; then
    echo "warn	feedback-mode-invalid	${FEEDBACK_MODE_RAW}:downgrade-to-silent" >&2
    FEEDBACK_MODE="silent"
fi

# disabled スキップ
if [ "$FEEDBACK_MODE" = "disabled" ]; then
    echo "retrospective	skip	disabled"
    exit 0
fi

# 出力先決定
RETROSPECTIVE_PATH="${AIDLC_CYCLES}/${CYCLE}/operations/retrospective.md"
RETROSPECTIVE_DIR="$(dirname "$RETROSPECTIVE_PATH")"

# 既存ファイルあり → スキップ
if [ -f "$RETROSPECTIVE_PATH" ]; then
    echo "retrospective	skip	already-exists"
    exit 0
fi

# ディレクトリ作成
if ! mkdir -p "$RETROSPECTIVE_DIR" 2>/dev/null; then
    echo "error	mkdir-failed	${RETROSPECTIVE_DIR}" >&2
    exit 2
fi

# テンプレート展開（{{CYCLE}} 置換 / _safe_transform 相当: tmp → mv）
TMP_FILE="$(mktemp "${RETROSPECTIVE_DIR}/.retrospective.XXXXXX")"
trap 'rm -f "$TMP_FILE"' EXIT

if ! sed "s|{{CYCLE}}|${CYCLE}|g" "$TEMPLATE_PATH" >"$TMP_FILE"; then
    echo "error	template-render-failed	${TEMPLATE_PATH}" >&2
    exit 2
fi

# 空ファイル禁止補完: 問題項目が「### 問題 1: {{タイトル}}」のままで実質的にエントリ無し相当の場合、
# 「### 問題なし」明示エントリを追加する。本実装では「### 問題 」見出しが 1 つも無い場合に補完する。
if ! grep -q "^### 問題 " "$TMP_FILE"; then
    {
        cat "$TMP_FILE"
        printf '\n### 問題なし\n\n本サイクルでは特筆すべきプロセス問題は発生しなかった。\n'
    } >"${TMP_FILE}.complete"
    mv "${TMP_FILE}.complete" "$TMP_FILE"
fi

# 最終配置
if ! mv "$TMP_FILE" "$RETROSPECTIVE_PATH"; then
    echo "error	mv-failed	${RETROSPECTIVE_PATH}" >&2
    exit 2
fi
trap - EXIT

echo "retrospective	created	${RETROSPECTIVE_PATH}"
exit 0
