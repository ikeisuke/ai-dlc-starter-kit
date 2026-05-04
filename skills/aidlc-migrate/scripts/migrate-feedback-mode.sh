#!/usr/bin/env bash
# migrate-feedback-mode.sh - Unit 001 マイグレーション decide 層
#
# 旧 feedback_mode を検出し、写像表に従って新値を決定して manifest に積み込む。
# 実書込みは migrate-apply-config.sh が manifest 経由で実行する。
# バックアップ / rollback は上位 aidlc-migrate の責務（本スクリプトでは扱わない）。
#
# 使用方法:
#   ./migrate-feedback-mode.sh --manifest <manifest_path>
#                              [--non-interactive] [--dry-run]
#
# 注: feedback_mode の現在値取得は read-config.sh の 4 階層マージ経由で行うため、
# 対象 config ファイルパスは引数として受け取らない（Unit 001 設計判断）。
#
# 出力:
#   stdout: journal JSON
#     {"phase":"feedback_mode_decide","decisions":[{...}]}
#   stderr: 診断メッセージ <level>\t<code>\t<detail>
#
# exit code:
#   0 - 成功 / skipped
#   1 - ランタイム異常
#   2 - 引数エラー / 環境不整合

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# REPO_ROOT は migrate-relocate-prefs.sh と同一規約: scripts/../../.. = repo root
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

PROJECT_ROOT="${AIDLC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}" || {
    printf 'error\tproject_root_not_found\t-\n' >&2
    exit 2
}
if ! git -C "$PROJECT_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
    printf 'error\tproject_root_invalid\t%s\n' "$PROJECT_ROOT" >&2
    exit 2
fi

# feedback-mode.sh を source（is_interactive_env / normalize 利用）
# 検索順:
#   1. ${REPO_ROOT}/skills/aidlc/...           （メタ開発・テスト時 / 既存 migrate-* と同じ規約）
#   2. ${PROJECT_ROOT}/skills/aidlc/...        （ダウンストリーム消費プロジェクトでの実利用想定）
FEEDBACK_LIB=""
for candidate in \
    "${REPO_ROOT}/skills/aidlc/scripts/lib/feedback-mode.sh" \
    "${PROJECT_ROOT}/skills/aidlc/scripts/lib/feedback-mode.sh"; do
    if [[ -f "$candidate" ]]; then
        FEEDBACK_LIB="$candidate"
        break
    fi
done
if [[ -z "$FEEDBACK_LIB" ]]; then
    printf 'error\tfeedback_lib_not_found\trepo=%s project=%s\n' "$REPO_ROOT" "$PROJECT_ROOT" >&2
    exit 2
fi
# shellcheck source=/dev/null
source "$FEEDBACK_LIB"

if ! command -v jq >/dev/null 2>&1; then
    printf 'error\tjq_not_installed\t-\n' >&2
    exit 2
fi

# --- 引数パース ---
MANIFEST=""
FORCE_NON_INTERACTIVE=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --manifest)
            [[ $# -lt 2 ]] && { printf 'error\tmissing_value\t--manifest\n' >&2; exit 2; }
            MANIFEST="$2"; shift 2 ;;
        --non-interactive)
            FORCE_NON_INTERACTIVE=true; shift ;;
        --dry-run)
            DRY_RUN=true; shift ;;
        *)
            printf 'error\tunknown_option\t%s\n' "$1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$MANIFEST" ]]; then
    printf 'error\tmissing_required\t--manifest\n' >&2
    exit 2
fi

# read-config.sh で raw 値取得（feedback-mode.sh と同じ検索順で sibling plugin を探索）
RAW=""
read_config_script=""
for candidate in \
    "${REPO_ROOT}/skills/aidlc/scripts/read-config.sh" \
    "${PROJECT_ROOT}/skills/aidlc/scripts/read-config.sh"; do
    if [[ -x "$candidate" ]]; then
        read_config_script="$candidate"
        break
    fi
done
if [[ -n "$read_config_script" ]]; then
    if RAW="$("$read_config_script" rules.retrospective.feedback_mode 2>/dev/null)"; then
        :
    else
        RAW=""
    fi
fi

# 写像表の解決（FeedbackModeMappingFactory 相当）
NORMALIZED="$(feedback_mode_normalize "$RAW")"
DECIDED=""
CONSENT_OUTCOME=""
STATUS=""

# raw が既に新 5 値のいずれかかつ NORMALIZED と一致 → already migrated
case "$RAW" in
    interactive|local-issue-only|mirror-only|local-and-mirror|disabled)
        DECIDED="$NORMALIZED"
        CONSENT_OUTCOME="not_required"
        STATUS="skipped"
        ;;
    silent|'')
        # silent → interactive（同意必要 / 非対話 fallback=disabled）
        # 未設定 → interactive（同意必要 / 非対話 fallback=disabled）
        if [[ "$FORCE_NON_INTERACTIVE" == "true" ]]; then
            DECIDED="disabled"
            CONSENT_OUTCOME="non_interactive_fallback"
            STATUS="queued"
        else
            ENV_INTERACTIVE="$(is_interactive_env)"
            if [[ "$ENV_INTERACTIVE" != "true" ]]; then
                DECIDED="disabled"
                CONSENT_OUTCOME="non_interactive_fallback"
                STATUS="queued"
            else
                printf '\n[aidlc-migrate] feedback_mode を旧値 "%s" から v2.5.1 の "interactive" に移行します。\n' "${RAW:-（未設定）}" >&2
                printf '  interactive モードでは、初回 04-completion §1.5 直前に起票先選択 wizard が起動します。\n' >&2
                printf '  動作変更を伴うため、明示同意が必要です。\n' >&2
                ANSWER=""
                if IFS= read -r -p "interactive へ移行しますか？ [y/N]: " ANSWER; then
                    case "$ANSWER" in
                        y|Y|yes|YES)
                            DECIDED="interactive"
                            CONSENT_OUTCOME="accepted"
                            STATUS="queued"
                            ;;
                        *)
                            DECIDED="disabled"
                            CONSENT_OUTCOME="rejected"
                            STATUS="queued"
                            ;;
                    esac
                else
                    DECIDED="disabled"
                    CONSENT_OUTCOME="non_interactive_fallback"
                    STATUS="queued"
                fi
            fi
        fi
        ;;
    mirror)
        DECIDED="mirror-only"
        CONSENT_OUTCOME="not_required"
        STATUS="queued"
        ;;
    *)
        # 未知値 → 保守的に disabled へ
        printf 'warn\tfeedback_mode_unknown\t%s\n' "$RAW" >&2
        DECIDED="disabled"
        CONSENT_OUTCOME="non_interactive_fallback"
        STATUS="queued"
        ;;
esac

# manifest に追記
if [[ "$DRY_RUN" != "true" ]] && [[ "$STATUS" == "queued" ]]; then
    if [[ ! -f "$MANIFEST" ]]; then
        printf 'error\tmanifest_not_found\t%s\n' "$MANIFEST" >&2
        exit 1
    fi
    tmp_manifest="$(mktemp)"
    if jq --arg from "${RAW:-}" --arg to "$DECIDED" --arg consent "$CONSENT_OUTCOME" \
        '.resources += [{resource_type: "feedback_mode_migrate", from: $from, to: $to, consent_outcome: $consent}]' \
        "$MANIFEST" > "$tmp_manifest"; then
        mv "$tmp_manifest" "$MANIFEST"
    else
        rm -f "$tmp_manifest"
        printf 'error\tmanifest_update_failed\t%s\n' "$MANIFEST" >&2
        exit 1
    fi
fi

# journal JSON 出力
jq -n --arg from "${RAW:-}" --arg to "$DECIDED" --arg consent "$CONSENT_OUTCOME" --arg status "$STATUS" \
    '{
        phase: "feedback_mode_decide",
        decisions: [{
            resource_type: "feedback_mode_migrate",
            from: $from,
            to: $to,
            consent_outcome: $consent,
            status: $status
        }]
    }'

exit 0
