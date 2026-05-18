#!/bin/bash
# retrospective-api.sh
#
# /aidlc-retrospective 独立スキル向け公開 API 層（Facade）
#
# v2.6.0 Unit 005 で新設。`skills/aidlc-retrospective/` から内部 lib の
# 実装詳細に依存しないための単方向境界を提供する。
#
# 設計参照:
#   .aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_005_aidlc_retrospective_skill_extraction_domain_model.md
#   .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_005_aidlc_retrospective_skill_extraction_logical_design.md
#
# 出力タイプ規約:
#   タイプ A（key=value 複数行 / 副作用あり）:
#       retrospective_api_create_issue / retrospective_api_record_response
#   タイプ B（raw text 1 行 / 純粋値）:
#       retrospective_api_resolve_feedback_mode / retrospective_api_requires_wizard
#       retrospective_api_run_wizard / retrospective_api_check_cap
#       retrospective_api_compose_body / retrospective_api_is_interactive_env
#       retrospective_api_prefill / retrospective_api_update_issue
#
# 終了コード規約（呼出側で統一解釈）:
#   0=成功 / 1=warn(recoverable) / 2=fatal / 3=マージ前完結契約違反 / 4=dialog-required

# 多重 source ガード
if [[ -n "${RETROSPECTIVE_API_SOURCED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
RETROSPECTIVE_API_SOURCED=1

# ─── bootstrap: AIDLC_BASE 解決 ─────────────────────────────────────
# 優先順位: ① 環境変数 AIDLC_BASE → ② 本ファイル絶対パス起点 → ③ git toplevel 起点
_retrospective_api_resolve_base() {
    if [[ -n "${AIDLC_BASE:-}" && -d "$AIDLC_BASE/scripts/lib" ]]; then
        printf '%s\n' "$AIDLC_BASE"
        return 0
    fi
    local self_path
    self_path="${BASH_SOURCE[0]:-}"
    if [[ -n "$self_path" ]]; then
        local self_dir
        self_dir=$(cd "$(dirname "$self_path")" && pwd 2>/dev/null || true)
        if [[ -n "$self_dir" ]]; then
            local candidate="$self_dir/../.."
            if [[ -d "$candidate/scripts/lib" ]]; then
                (cd "$candidate" && pwd)
                return 0
            fi
        fi
    fi
    local toplevel
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -n "$toplevel" && -d "$toplevel/skills/aidlc/scripts/lib" ]]; then
        printf '%s\n' "$toplevel/skills/aidlc"
        return 0
    fi
    return 1
}

_RETROSPECTIVE_API_BASE=$(_retrospective_api_resolve_base) || {
    echo "error: retrospective-api.sh: AIDLC_BASE 解決失敗（AIDLC_BASE 環境変数を設定してください）" >&2
    return 2 2>/dev/null || exit 2
}

# 内部 lib の source（タイプ別関数を再エクスポート可能にする）
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/feedback-mode.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/feedback-mode-wizard.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/retrospective-issue.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/retrospective-llm-draft.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/retrospective-human-review.sh" 2>/dev/null || true

# ─── 公開 API（タイプ B / 純粋値）───────────────────────────────────

# retrospective_api_resolve_feedback_mode <raw_value>
# stdout: 正規化済 mode（silent / mirror / disabled / interactive / "" → silent fallback）
retrospective_api_resolve_feedback_mode() {
    feedback_mode_normalize "$@"
}

# retrospective_api_is_interactive_env
# stdout: true / false
retrospective_api_is_interactive_env() {
    is_interactive_env "$@"
}

# retrospective_api_requires_wizard <mode> <env_interactive>
# stdout: true / false（wizard 起動要否）
retrospective_api_requires_wizard() {
    feedback_mode_requires_wizard "$@"
}

# retrospective_api_run_wizard
# stdout: wizard で確定した mode
retrospective_api_run_wizard() {
    feedback_mode_wizard "$@"
}

# retrospective_api_check_cap <mode> <current_count> <limit>
# stdout: over=true|false（feedback_cap_check の出力をそのまま中継）
retrospective_api_check_cap() {
    feedback_cap_check "$@"
}

# retrospective_api_compose_body <draft_yaml_path> <kpt_md_path> <cycle>
# stdout: Issue 本文 Markdown
retrospective_api_compose_body() {
    retrospective_body_compose "$@"
}

# retrospective_api_prefill <cycle> <kpt_md_path>
# stdout: prefill draft YAML（cap 超過時は空 / fallback 時も空 YAML）
retrospective_api_prefill() {
    if command -v retrospective_prefill_hook >/dev/null 2>&1; then
        retrospective_prefill_hook "$@"
    else
        # フック未定義時は空 YAML フォールバック
        printf ''
    fi
}

# retrospective_api_aggregate_enabled
# v2.6.6 / #710 / Unit 001
# 集約 Issue 起票 opt-in フラグ (rules.retrospective.aggregate_issue_enabled) の値を返す。
# stdout: 常に "true" または "false" を 1 行
# exit:   常に 0 (hard fail させない / fail-safe)
# fail-safe フォールバック:
#   - read-config.sh exit 1 (キー不在 / 既定動作)            : stdout="false" / warn なし
#   - read-config.sh exit 0 + 不正値 (true|false 以外)       : stdout="false" / stderr warn
#   - read-config.sh exit 2+ (読み取り層エラー)              : stdout="false" / stderr warn
retrospective_api_aggregate_enabled() {
    local _local_aggregate_enabled_value=""
    local _local_aggregate_enabled_rc=0
    local _local_aggregate_enabled_stderr_file
    _local_aggregate_enabled_stderr_file="${TMPDIR:-/tmp}/aidlc-aggregate-enabled-stderr.$$"

    # caller の errexit 状態を変更しないよう、command substitution を if で評価し
    # exit code を直接捕捉する（set +e / set -e で caller 状態を上書きしない）
    if _local_aggregate_enabled_value=$(
        "$_RETROSPECTIVE_API_BASE/scripts/read-config.sh" rules.retrospective.aggregate_issue_enabled 2>"$_local_aggregate_enabled_stderr_file"
    ); then
        _local_aggregate_enabled_rc=0
    else
        _local_aggregate_enabled_rc=$?
    fi

    rm -f "$_local_aggregate_enabled_stderr_file" 2>/dev/null || true

    case "$_local_aggregate_enabled_rc" in
        0)
            case "$_local_aggregate_enabled_value" in
                true|false)
                    printf '%s\n' "$_local_aggregate_enabled_value"
                    return 0
                    ;;
                *)
                    printf '[warn] retrospective_api_aggregate_enabled: read-config.sh が不正値 "%s" を返したため既定 false にフォールバックします\n' \
                        "$_local_aggregate_enabled_value" >&2
                    printf 'false\n'
                    return 0
                    ;;
            esac
            ;;
        1)
            # キー不在 / defaults.toml fallback 失敗時 = 既定動作扱い
            printf 'false\n'
            return 0
            ;;
        *)
            printf '[warn] retrospective_api_aggregate_enabled: read-config.sh が rc=%s を返したため既定 false にフォールバックします\n' \
                "$_local_aggregate_enabled_rc" >&2
            printf 'false\n'
            return 0
            ;;
    esac
}

# ─── 公開 API（タイプ A / 副作用あり）────────────────────────────────

# retrospective_api_record_response <cycle> <response>
# stdout: なし（タイプ A の特例 / exit code で判定）
retrospective_api_record_response() {
    retrospective_dialog_token_record_response "$@"
}

# retrospective_api_create_issue <body_path> <mode> <cycle>
# stdout: result=created|spooled|skipped + issue_url= / reason= 等の key=value 行
# exit: 0/1/2/4
retrospective_api_create_issue() {
    retrospective_issue_create "$@"
}

# retrospective_api_update_issue <issue_url> <cycle>
# stdout: なし（hook の warn は stderr）
# exit: 0（hook 失敗時も警告継続）
retrospective_api_update_issue() {
    if command -v retrospective_update_hook >/dev/null 2>&1; then
        retrospective_update_hook "$@" || true
    fi
}
