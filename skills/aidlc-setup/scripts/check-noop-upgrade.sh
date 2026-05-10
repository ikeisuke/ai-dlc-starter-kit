#!/usr/bin/env bash
#
# check-noop-upgrade.sh - aidlc-setup アップグレードフローの no-op 判定
#
# `migrate-config.sh` の `result:` 行と `detect-missing-keys.sh` 後の対話結果集約値を
# 入力として、`.aidlc/config.toml` の `starter_kit_version` 更新が不要 (no-op) かを判定する。
# Domain 層の判定規則は NoOpPolicy.decide() に対応する純関数で、
# Application/Infrastructure 層 (パース・引数解析) も本スクリプトに同梱する (1 ファイル完結)。
#
# 使用方法:
#   check-noop-upgrade.sh \
#       --migrate-config-result <result-line> \
#       --detect-missing-applied <0|1>
#
# 引数:
#   --migrate-config-result <line>
#       migrate-config.sh stdout の `result:...` 行
#       (例: "result:completed:migrated=0,skipped=18,warnings=0")
#   --detect-missing-applied <0|1>
#       detect-missing-keys.sh + 対話結果で実際に追記が行われたかの集約値
#       (0 = 追加なし / 1 = 追加あり)
#
# 出力 (stdout、成功・失敗いずれも 3 行固定):
#   noop=<true|false|>           true / false / 失敗時は空
#   reason=<reason-enum|>        no-changes|migrate-config-changed|missing-keys-applied|空
#   error=<error-detail|>        失敗時のみ非空
#
# 終了コード:
#   0  判定成功 (noop= と reason= は非空 / error= は空)
#   2  判定失敗 (noop= と reason= は空 / error= は非空 / 呼び出し側はフォールバック扱い)
#

set -euo pipefail

# --- 出力サニタイズ ---
# 改行 (LF/CR) とタブを `?` に置換し、最大 200 文字に切り詰める。
# 「stdout 3 行固定」契約を外部入力 (引数値など) で破られないようにする防御層。
sanitize_for_output() {
    local raw="$1"
    raw="${raw//$'\n'/?}"
    raw="${raw//$'\r'/?}"
    raw="${raw//$'\t'/?}"
    if (( ${#raw} > 200 )); then
        raw="${raw:0:200}"
    fi
    printf '%s' "$raw"
}

# --- 出力ヘルパー ---
emit_decision() {
    local noop
    local reason
    local err
    noop=$(sanitize_for_output "$1")
    reason=$(sanitize_for_output "$2")
    err=$(sanitize_for_output "$3")
    printf 'noop=%s\n' "$noop"
    printf 'reason=%s\n' "$reason"
    printf 'error=%s\n' "$err"
}

emit_failure() {
    local detail="$1"
    emit_decision "" "" "$detail"
    exit 2
}

# --- 引数解析 ---
MIGRATE_RESULT=""
DETECT_APPLIED=""
_seen_migrate=false
_seen_detect=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --migrate-config-result)
            if [[ $# -lt 2 ]]; then
                emit_failure "missing-arg-value:--migrate-config-result"
            fi
            MIGRATE_RESULT="$2"
            _seen_migrate=true
            shift 2
            ;;
        --detect-missing-applied)
            if [[ $# -lt 2 ]]; then
                emit_failure "missing-arg-value:--detect-missing-applied"
            fi
            DETECT_APPLIED="$2"
            _seen_detect=true
            shift 2
            ;;
        *)
            emit_failure "unknown-arg:$1"
            ;;
    esac
done

if [[ "$_seen_migrate" != "true" ]]; then
    emit_failure "missing-arg:--migrate-config-result"
fi
if [[ "$_seen_detect" != "true" ]]; then
    emit_failure "missing-arg:--detect-missing-applied"
fi

# --- detect-missing-applied のバリデーション (0 / 1 のみ許可) ---
case "$DETECT_APPLIED" in
    0|1) ;;
    *) emit_failure "invalid-value:--detect-missing-applied=${DETECT_APPLIED}" ;;
esac

# --- migrate-config-result のパース ---
# 期待形式:
#   result:<status>:migrated=<N>,skipped=<M>,warnings=<W>
# <status> は completed / completed-with-warnings / その他文字列を許容 (本スクリプトは status を参照しない)
if [[ -z "$MIGRATE_RESULT" ]]; then
    emit_failure "invalid-input:empty-migrate-config-result"
fi

# 行全体アンカー付きの厳密な形式チェック (前方一致や末尾ゴミ文字を拒否)
# 期待形式: result:<status>:migrated=<N>,skipped=<M>,warnings=<W>
#   - <status> は英字 / 数字 / ハイフンのみ許可
#   - <N> / <M> / <W> は非負整数
_re='^result:[A-Za-z0-9-]+:migrated=([0-9]+),skipped=([0-9]+),warnings=([0-9]+)$'
if [[ ! "$MIGRATE_RESULT" =~ $_re ]]; then
    emit_failure "invalid-input:malformed-result-line"
fi

MIGRATED="${BASH_REMATCH[1]}"
WARNINGS="${BASH_REMATCH[3]}"

# --- NoOpPolicy.decide() : 純関数 ---
# noop = (migrated == 0) && (warnings == 0) && (missing_applied == 0)
#
# 優先順位 (両方 false 寄与の場合):
#   1. migrate-config-changed (migrated > 0 OR warnings > 0)
#   2. missing-keys-applied (missing_applied == 1)
if [[ "$MIGRATED" -eq 0 ]] && [[ "$WARNINGS" -eq 0 ]] && [[ "$DETECT_APPLIED" -eq 0 ]]; then
    emit_decision "true" "no-changes" ""
    exit 0
fi

if [[ "$MIGRATED" -gt 0 ]] || [[ "$WARNINGS" -gt 0 ]]; then
    emit_decision "false" "migrate-config-changed" ""
    exit 0
fi

# 残るのは migrated=0 && warnings=0 && missing_applied=1
emit_decision "false" "missing-keys-applied" ""
exit 0
