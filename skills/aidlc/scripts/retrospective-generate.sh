#!/usr/bin/env bash
# retrospective-generate.sh - 互換アダプタ層（v2.5.1+ / Unit 002）
#
# 旧 stdout プレフィックス契約を保持しつつ、内部処理は retrospective_issue_create() に委譲する。
# v2.7.x で完全削除予定（Plan §「互換アダプタ層 保証範囲」参照）。
#
# Usage (旧 I/F): retrospective-generate.sh <CYCLE>
#
# 出力（旧プレフィックス互換）:
#   retrospective\tcreated\t<issue_url>
#   retrospective\tskip\tdisabled
#   retrospective\tskip\talready-exists
#   retrospective\tskip\tspooled
#
# 終了コード:
#   0 - 正常 / 受理可能経路
#   1 - failed
#   2 - 引数 / fatal

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/retrospective-issue.sh
source "$SCRIPT_DIR/lib/retrospective-issue.sh"

CYCLE="${1:-}"
if [[ -z "$CYCLE" ]]; then
    echo "error	usage	retrospective-generate.sh <CYCLE>" >&2
    exit 2
fi

# cycle バリデーション（sed の前に / Unit 002 path traversal 防御）
if ! __retro_validate_cycle "$CYCLE"; then
    exit 2
fi

# Deprecation warning
echo "warn	deprecated	retrospective-generate.sh は v2.5.1 で互換アダプタ層化されました（v2.7.x で削除予定 / 新フローは 04-completion.md §1.5 経由で retrospective_issue_create を直接呼び出してください）" >&2

# feedback_mode 解決
RAW_MODE=""
if [[ -x "$SCRIPT_DIR/read-config.sh" ]]; then
    RAW_MODE=$("$SCRIPT_DIR/read-config.sh" rules.retrospective.feedback_mode 2>/dev/null || true)
fi

# Unit 001 feedback-mode.sh で正規化
if [[ -f "$SCRIPT_DIR/lib/feedback-mode.sh" ]]; then
    # shellcheck source=lib/feedback-mode.sh
    source "$SCRIPT_DIR/lib/feedback-mode.sh"
    MODE=$(feedback_mode_normalize "$RAW_MODE")
else
    MODE="${RAW_MODE:-disabled}"
fi

# disabled は即 skip
if [[ "$MODE" == "disabled" ]]; then
    printf 'retrospective\tskip\tdisabled\n'
    exit 0
fi

# KPT テンプレ展開（最小実装: テンプレファイルから {{CYCLE}} を置換）
KPT_PATH=$(mktemp -t aidlc-retro-kpt.XXXXXX)
TEMPLATE_PATH="${AIDLC_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}/templates/retrospective_template.md"
if [[ -f "$TEMPLATE_PATH" ]]; then
    sed "s/{{CYCLE}}/$CYCLE/g" "$TEMPLATE_PATH" > "$KPT_PATH"
fi

# 空 draft で本文構築
DRAFT_PATH=$(mktemp -t aidlc-retro-draft.XXXXXX)
: > "$DRAFT_PATH"

BODY_PATH=$(mktemp -t aidlc-retro-body.XXXXXX)
if ! retrospective_body_compose "$DRAFT_PATH" "$KPT_PATH" "$CYCLE" > "$BODY_PATH"; then
    echo "error	body-compose-failed	cycle=$CYCLE" >&2
    rm -f "$KPT_PATH" "$DRAFT_PATH" "$BODY_PATH"
    exit 2
fi

# Issue 起票
RESULT_PATH=$(mktemp -t aidlc-retro-result.XXXXXX)
set +e
retrospective_issue_create "$BODY_PATH" "$MODE" "$CYCLE" > "$RESULT_PATH"
RC=$?
set -e

# 旧プレフィックスへ変換
case $RC in
    0)
        if grep -q '^result=created' "$RESULT_PATH"; then
            URL=$(awk -F'=' '/^(local|mirror)_issue_url=|^issue_url=/{print $2; exit}' "$RESULT_PATH")
            printf 'retrospective\tcreated\t%s\n' "$URL"
        elif grep -q '^result=spooled' "$RESULT_PATH"; then
            printf 'retrospective\tskip\tspooled\n'
        elif grep -q 'reason=duplicate' "$RESULT_PATH"; then
            printf 'retrospective\tskip\talready-exists\n'
        elif grep -q 'reason=mode-disabled' "$RESULT_PATH"; then
            printf 'retrospective\tskip\tdisabled\n'
        else
            printf 'retrospective\tskip\tunknown\n'
        fi
        ;;
    1)
        REASON=$(awk -F'=' '/^reason=/{print $2; exit}' "$RESULT_PATH")
        echo "error	create-failed	reason=$REASON" >&2
        rm -f "$KPT_PATH" "$DRAFT_PATH" "$BODY_PATH" "$RESULT_PATH"
        exit 1
        ;;
    *)
        echo "error	create-fatal	rc=$RC" >&2
        rm -f "$KPT_PATH" "$DRAFT_PATH" "$BODY_PATH" "$RESULT_PATH"
        exit 2
        ;;
esac

rm -f "$KPT_PATH" "$DRAFT_PATH" "$BODY_PATH" "$RESULT_PATH"
exit 0
