#!/usr/bin/env bash
# feedback-mode.sh - Unit 001 ドメイン純粋関数 + I/O ラップ + 環境判定
#
# 提供する関数:
#   is_interactive_env             - tty + CI ガード判定（true/false）
#   feedback_mode_normalize <raw>  - 旧値→新値 / 未知値→disabled の正規化
#   feedback_mode_resolve <mode> <env_interactive>          - 4 値の最終実行モードを返す
#   feedback_mode_requires_wizard <mode> <env_interactive>  - wizard 起動要否
#   feedback_cap_check <mode> <current> <limit>             - cap 超過判定 + 適用範囲
#   feedback_mode_save <mode> [scope]                       - write-config.sh ラップ
#
# exit code 規約:
#   0 - 成功（未知値の保守値出力 + warn を含む）
#   1 - ランタイム異常（書込み失敗等）
#   2 - 引数エラー / 環境不整合
# stderr フォーマット: <level>\t<code>\t<detail>  (level=info|warn|error)

# 多重 source ガード（library として source される想定）
if [[ "${__AIDLC_FEEDBACK_MODE_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_FEEDBACK_MODE_SH_LOADED=1

__feedback_mode_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

is_interactive_env() {
    # AIDLC_NON_INTERACTIVE / CI / GITHUB_ACTIONS は false を強制（CI ガード）。
    # AIDLC_FORCE_INTERACTIVE はテスト用 escape hatch（tty 不在環境でも true を強制）。
    # 優先順位: NON_INTERACTIVE > FORCE_INTERACTIVE > CI > tty 判定
    if [[ -n "${AIDLC_NON_INTERACTIVE:-}" ]]; then
        printf 'false\n'
        return 0
    fi
    if [[ -n "${AIDLC_FORCE_INTERACTIVE:-}" ]]; then
        printf 'true\n'
        return 0
    fi
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        printf 'false\n'
        return 0
    fi
    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        printf 'false\n'
        return 0
    fi
    printf 'true\n'
    return 0
}

feedback_mode_normalize() {
    if [[ $# -lt 1 ]]; then
        __feedback_mode_diag error feedback_mode_args "feedback_mode_normalize requires 1 argument"
        return 2
    fi
    local raw="$1"
    case "$raw" in
        interactive|local-issue-only|mirror-only|local-and-mirror|disabled)
            printf '%s\n' "$raw"
            ;;
        silent)
            printf 'interactive\n'
            ;;
        mirror)
            printf 'mirror-only\n'
            ;;
        '')
            printf 'interactive\n'
            ;;
        *)
            __feedback_mode_diag warn feedback_mode_unknown "$raw"
            printf 'disabled\n'
            ;;
    esac
    return 0
}

feedback_mode_resolve() {
    if [[ $# -lt 2 ]]; then
        __feedback_mode_diag error feedback_mode_args "feedback_mode_resolve requires 2 arguments (mode, env_interactive)"
        return 2
    fi
    local mode="$1"
    local env_interactive="$2"
    case "$mode" in
        interactive)
            printf 'disabled\n'
            ;;
        local-issue-only)
            printf 'local_only\n'
            ;;
        mirror-only)
            printf 'mirror_only\n'
            ;;
        local-and-mirror)
            printf 'both\n'
            ;;
        disabled)
            printf 'disabled\n'
            ;;
        *)
            __feedback_mode_diag warn feedback_mode_unknown "resolve:$mode"
            printf 'disabled\n'
            ;;
    esac
    # env_interactive は将来の拡張用に受け取るが現状の出力には影響しない
    # （interactive モードの解釈を呼出側に委ねるため）
    if [[ "$env_interactive" != "true" ]] && [[ "$env_interactive" != "false" ]]; then
        __feedback_mode_diag warn feedback_mode_env_unknown "$env_interactive"
    fi
    return 0
}

feedback_mode_requires_wizard() {
    if [[ $# -lt 2 ]]; then
        __feedback_mode_diag error feedback_mode_args "feedback_mode_requires_wizard requires 2 arguments"
        return 2
    fi
    local mode="$1"
    local env_interactive="$2"
    if [[ "$mode" == "interactive" ]] && [[ "$env_interactive" == "true" ]]; then
        printf 'true\n'
    else
        printf 'false\n'
    fi
    return 0
}

feedback_cap_check() {
    if [[ $# -lt 3 ]]; then
        __feedback_mode_diag error feedback_mode_args "feedback_cap_check requires 3 arguments (mode, current, limit)"
        return 2
    fi
    local mode="$1"
    local current="$2"
    local limit="$3"
    if ! [[ "$current" =~ ^[0-9]+$ ]] || ! [[ "$limit" =~ ^[0-9]+$ ]]; then
        __feedback_mode_diag error feedback_mode_args "current/limit must be non-negative integers (current=$current, limit=$limit)"
        return 2
    fi
    local scope=none
    local over=false
    case "$mode" in
        interactive)
            scope=none
            over=false
            ;;
        local-issue-only)
            scope=local
            if [[ "$current" -ge "$limit" ]]; then over=true; fi
            ;;
        mirror-only)
            scope=mirror
            if [[ "$current" -ge "$limit" ]]; then over=true; fi
            ;;
        local-and-mirror)
            scope=combined
            if [[ "$current" -ge "$limit" ]]; then over=true; fi
            ;;
        disabled)
            scope=none
            over=false
            ;;
        *)
            __feedback_mode_diag warn feedback_mode_unknown "cap_check:$mode"
            scope=none
            over=true
            ;;
    esac
    printf 'over=%s\nscope=%s\n' "$over" "$scope"
    return 0
}

feedback_mode_save() {
    if [[ $# -lt 1 ]]; then
        __feedback_mode_diag error feedback_mode_args "feedback_mode_save requires at least 1 argument (mode)"
        return 2
    fi
    local mode="$1"
    local scope="${2:-local}"
    case "$mode" in
        interactive|local-issue-only|mirror-only|local-and-mirror|disabled)
            : # ok
            ;;
        *)
            __feedback_mode_diag error feedback_mode_invalid "$mode"
            return 2
            ;;
    esac
    case "$scope" in
        project|local) : ;;
        *)
            __feedback_mode_diag error feedback_mode_scope_invalid "$scope"
            return 2
            ;;
    esac
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    # write-config.sh の stdout（"config:written:..."）は呼出側の stdout を汚さないため stderr に流す
    if "$script_dir/write-config.sh" rules.retrospective.feedback_mode "$mode" --scope "$scope" >&2; then
        return 0
    else
        local rc=$?
        __feedback_mode_diag error feedback_mode_save_failed "write-config.sh exit=$rc"
        return 1
    fi
}
