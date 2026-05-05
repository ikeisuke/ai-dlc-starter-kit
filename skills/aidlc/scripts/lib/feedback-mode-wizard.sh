#!/usr/bin/env bash
# feedback-mode-wizard.sh - Unit 001 wizard 関数
#
# 提供する関数:
#   feedback_mode_wizard - read -p ベースの 5 値選択 + 設定保存
#
# 単体実行時は feedback_mode_wizard を呼び出して結果を stdout に返す。
#
# exit code 規約:
#   0 - 成功（保存済み値を stdout）
#   1 - ユーザー中断 / 設定保存失敗
#   2 - 非対話環境で呼ばれた / 引数エラー
# stderr フォーマット: <level>\t<code>\t<detail>

if [[ "${__AIDLC_FEEDBACK_MODE_WIZARD_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_FEEDBACK_MODE_WIZARD_SH_LOADED=1

__feedback_wizard_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=feedback-mode.sh
source "${__feedback_wizard_dir}/feedback-mode.sh"

__feedback_wizard_diag() {
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

feedback_mode_wizard() {
    local env_interactive
    env_interactive="$(is_interactive_env)"
    if [[ "$env_interactive" != "true" ]]; then
        __feedback_wizard_diag error feedback_mode_wizard_non_interactive "wizard requires interactive env (tty + no CI/AIDLC_NON_INTERACTIVE)"
        return 2
    fi

    local scope="${AIDLC_FEEDBACK_MODE_WIZARD_SCOPE:-local}"
    case "$scope" in
        project|local) : ;;
        *)
            __feedback_wizard_diag error feedback_mode_scope_invalid "$scope"
            return 2
            ;;
    esac

    local prompt
    {
        printf '\n振り返り Issue 起票方針を選択してください:\n'
        printf '  1) interactive       : 次回も同じ wizard を起動（暫定状態を維持）\n'
        printf '  2) local-issue-only  : プロダクトリポジトリの Issue にのみ起票\n'
        printf '  3) mirror-only       : upstream（AI-DLC starter kit）の Issue にのみ起票\n'
        printf '  4) local-and-mirror  : 両方に起票（合算 cap）\n'
        printf '  5) disabled          : 起票しない（ローカル記録のみ）\n'
    } >&2

    local choice=""
    local attempt=0
    while [[ $attempt -lt 5 ]]; do
        attempt=$((attempt + 1))
        if ! IFS= read -r -p "選択 (1-5): " choice; then
            __feedback_wizard_diag warn feedback_mode_wizard_aborted "EOF or interrupt during read"
            return 1
        fi
        case "$choice" in
            1) prompt=interactive ;;
            2) prompt=local-issue-only ;;
            3) prompt=mirror-only ;;
            4) prompt=local-and-mirror ;;
            5) prompt=disabled ;;
            *)
                printf '無効な選択です。1〜5 を入力してください。\n' >&2
                continue
                ;;
        esac
        break
    done

    if [[ -z "${prompt:-}" ]]; then
        __feedback_wizard_diag warn feedback_mode_wizard_aborted "max attempts exceeded"
        return 1
    fi

    if ! feedback_mode_save "$prompt" "$scope"; then
        local rc=$?
        __feedback_wizard_diag error feedback_mode_wizard_save_failed "feedback_mode_save exit=$rc"
        return 1
    fi
    printf '%s\n' "$prompt"
    return 0
}

# 直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    feedback_mode_wizard
    exit $?
fi
