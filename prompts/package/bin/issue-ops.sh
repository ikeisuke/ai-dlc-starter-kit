#!/usr/bin/env bash
#
# issue-ops.sh - Issue操作スクリプト
#
# 使用方法:
#   ./issue-ops.sh label <issue_number> <label_name>
#   ./issue-ops.sh remove-label <issue_number> <label_name>
#   ./issue-ops.sh set-status <issue_number> <status>
#   ./issue-ops.sh close <issue_number> [--not-planned]
#
# SUBCOMMANDS:
#   label        Issueにラベルを付与
#   remove-label Issueからラベルを削除
#   set-status   Issueのステータスラベルを更新（排他制御付き）
#   close        IssueをClose
#
# OPTIONS:
#   -h, --help       ヘルプを表示
#   --not-planned    Close時にnot planned理由を指定
#
# STATUS VALUES (set-status):
#   backlog             status:backlog ラベルを付与
#   in-progress         status:in-progress ラベルを付与
#   blocked             status:blocked ラベルを付与
#   waiting-for-review  status:waiting-for-review ラベルを付与
#
# 出力形式（stdout）:
#   成功時: issue:<number>:<status>[:<detail>]
#   エラー時: issue:<number>:error:<reason>
#   引数エラー時: error:<reason>
#
# 例:
#   $ ./issue-ops.sh label 123 "cycle:v1.8.0"
#   issue:123:labeled:cycle:v1.8.0
#
#   $ ./issue-ops.sh close 123
#   issue:123:closed
#
#   $ ./issue-ops.sh close 123 --not-planned
#   issue:123:closed:not-planned
#
#   $ ./issue-ops.sh remove-label 123 "status:backlog"
#   issue:123:removed-label:status:backlog
#
#   $ ./issue-ops.sh set-status 123 in-progress
#   issue:123:status-updated:in-progress
#

set -euo pipefail

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: issue-ops.sh <subcommand> [options]

Issue操作（ラベル付け、Close）を行うスクリプト。

SUBCOMMANDS:
  label <issue_number> <label_name>
      Issueにラベルを付与します。

  remove-label <issue_number> <label_name>
      Issueからラベルを削除します。

  set-status <issue_number> <status>
      Issueのステータスラベルを更新します（排他制御付き）。
      既存のstatus:*ラベルを削除してから、新しいステータスラベルを付与します。

      status:
        backlog             status:backlog
        in-progress         status:in-progress
        blocked             status:blocked
        waiting-for-review  status:waiting-for-review

  close <issue_number> [--not-planned]
      IssueをCloseします。
      --not-planned を指定すると「not planned」理由でCloseします。

OPTIONS:
  -h, --help    このヘルプを表示

出力形式（stdout）:
  成功時:
    issue:<number>:labeled:<label_name>
    issue:<number>:removed-label:<label_name>
    issue:<number>:status-updated:<status>
    issue:<number>:closed
    issue:<number>:closed:not-planned

  エラー時:
    issue:<number>:error:not-found
    issue:<number>:error:gh-not-available
    issue:<number>:error:gh-not-authenticated
    issue:<number>:error:auth-error
    issue:<number>:error:invalid-status
    issue:<number>:error:unknown

  引数エラー時:
    error:missing-subcommand
    error:unknown-subcommand:<name>
    error:missing-issue-number
    error:missing-label-name
    error:missing-status

例:
  $ issue-ops.sh label 123 "cycle:v1.8.0"
  issue:123:labeled:cycle:v1.8.0

  $ issue-ops.sh remove-label 123 "status:backlog"
  issue:123:removed-label:status:backlog

  $ issue-ops.sh set-status 123 in-progress
  issue:123:status-updated:in-progress

  $ issue-ops.sh close 123
  issue:123:closed

  $ issue-ops.sh close 123 --not-planned
  issue:123:closed:not-planned
EOF
}

# gh CLIが利用可能かチェック
# 戻り値: 0=利用可能, 1=gh未インストール, 2=gh未認証
check_gh_available() {
    if ! command -v gh >/dev/null 2>&1; then
        return 1
    fi
    if ! gh auth status >/dev/null 2>&1; then
        return 2
    fi
    return 0
}

# 出力フォーマット生成（Issue番号あり）
# 引数: $1=issue_number, $2=status, $3=detail（optional）
format_output() {
    local issue_number="$1"
    local status="$2"
    local detail="${3:-}"

    if [[ -n "$detail" ]]; then
        echo "issue:${issue_number}:${status}:${detail}"
    else
        echo "issue:${issue_number}:${status}"
    fi
}

# ghエラーを解析してエラー理由を返す
# 引数: $1=ghのエラー出力
# 出力: エラー理由（ハイフン区切り）
# 注: check_gh_availableによるプレチェック(gh-not-authenticated)とは別。
#      この関数はghコマンド実行時のエラー出力を分類する。
parse_gh_error() {
    local error_output="$1"

    if echo "$error_output" | grep -qi "not found\|could not find\|could not resolve"; then
        echo "not-found"
    elif echo "$error_output" | grep -qi "authentication\|unauthorized\|forbidden\|401\|403\|token\|credential"; then
        echo "auth-error"
    else
        echo "unknown"
    fi
}

# labelサブコマンド
# 引数: $1=issue_number, $2=label_name
cmd_label() {
    local issue_number="$1"
    local label_name="$2"
    local gh_status
    local error_output

    # gh利用可否確認
    check_gh_available
    gh_status=$?
    if [[ $gh_status -ne 0 ]]; then
        if [[ $gh_status -eq 1 ]]; then
            format_output "$issue_number" "error" "gh-not-available"
        else
            format_output "$issue_number" "error" "gh-not-authenticated"
        fi
        return 1
    fi

    # ラベル付与実行（-- でissue番号のオプション解釈を防止）
    if error_output=$(gh issue edit --add-label "$label_name" -- "$issue_number" 2>&1); then
        format_output "$issue_number" "labeled" "$label_name"
        return 0
    else
        local reason
        reason=$(parse_gh_error "$error_output")
        format_output "$issue_number" "error" "$reason"
        return 1
    fi
}

# remove-labelサブコマンド
# 引数: $1=issue_number, $2=label_name
cmd_remove_label() {
    local issue_number="$1"
    local label_name="$2"
    local gh_status
    local error_output

    # gh利用可否確認
    check_gh_available
    gh_status=$?
    if [[ $gh_status -ne 0 ]]; then
        if [[ $gh_status -eq 1 ]]; then
            format_output "$issue_number" "error" "gh-not-available"
        else
            format_output "$issue_number" "error" "gh-not-authenticated"
        fi
        return 1
    fi

    # ラベル削除実行（-- でissue番号のオプション解釈を防止）
    if error_output=$(gh issue edit --remove-label "$label_name" -- "$issue_number" 2>&1); then
        format_output "$issue_number" "removed-label" "$label_name"
        return 0
    else
        local reason
        reason=$(parse_gh_error "$error_output")
        format_output "$issue_number" "error" "$reason"
        return 1
    fi
}

# set-statusサブコマンド
# 引数: $1=issue_number, $2=status
cmd_set_status() {
    local issue_number="$1"
    local status="$2"
    local gh_status
    local error_output
    local new_label

    # ステータス値のバリデーション
    case "$status" in
        backlog)
            new_label="status:backlog"
            ;;
        in-progress)
            new_label="status:in-progress"
            ;;
        blocked)
            new_label="status:blocked"
            ;;
        waiting-for-review)
            new_label="status:waiting-for-review"
            ;;
        *)
            format_output "$issue_number" "error" "invalid-status"
            return 1
            ;;
    esac

    # gh利用可否確認
    check_gh_available
    gh_status=$?
    if [[ $gh_status -ne 0 ]]; then
        if [[ $gh_status -eq 1 ]]; then
            format_output "$issue_number" "error" "gh-not-available"
        else
            format_output "$issue_number" "error" "gh-not-authenticated"
        fi
        return 1
    fi

    # 既存のstatus:*ラベルを取得して削除
    local existing_labels
    existing_labels=$(gh issue view "$issue_number" --json labels --jq '.labels[].name | select(startswith("status:"))' 2>/dev/null || true)

    if [[ -n "$existing_labels" ]]; then
        while IFS= read -r old_label; do
            if [[ -n "$old_label" ]]; then
                gh issue edit --remove-label "$old_label" -- "$issue_number" >/dev/null 2>&1 || true
            fi
        done <<< "$existing_labels"
    fi

    # 新しいステータスラベルを付与
    if error_output=$(gh issue edit --add-label "$new_label" -- "$issue_number" 2>&1); then
        format_output "$issue_number" "status-updated" "$status"
        return 0
    else
        local reason
        reason=$(parse_gh_error "$error_output")
        format_output "$issue_number" "error" "$reason"
        return 1
    fi
}

# closeサブコマンド
# 引数: $1=issue_number, $2=not_planned（"true" or "false"）
cmd_close() {
    local issue_number="$1"
    local not_planned="${2:-false}"
    local gh_status
    local error_output

    # gh利用可否確認
    check_gh_available
    gh_status=$?
    if [[ $gh_status -ne 0 ]]; then
        if [[ $gh_status -eq 1 ]]; then
            format_output "$issue_number" "error" "gh-not-available"
        else
            format_output "$issue_number" "error" "gh-not-authenticated"
        fi
        return 1
    fi

    # Close実行（-- でissue番号のオプション解釈を防止）
    local close_args=()
    if [[ "$not_planned" == "true" ]]; then
        close_args+=("--reason" "not planned")
    fi
    close_args+=("--" "$issue_number")

    if error_output=$(gh issue close "${close_args[@]}" 2>&1); then
        if [[ "$not_planned" == "true" ]]; then
            format_output "$issue_number" "closed" "not-planned"
        else
            format_output "$issue_number" "closed"
        fi
        return 0
    else
        local reason
        reason=$(parse_gh_error "$error_output")
        format_output "$issue_number" "error" "$reason"
        return 1
    fi
}

# メイン処理
main() {
    local subcommand=""

    # 引数がない場合
    if [[ $# -eq 0 ]]; then
        echo "error:missing-subcommand"
        exit 1
    fi

    # 最初の引数を確認
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        label|remove-label|set-status|close)
            subcommand="$1"
            shift
            ;;
        -*)
            echo "error:unknown-option:$1"
            exit 1
            ;;
        *)
            echo "error:unknown-subcommand:$1"
            exit 1
            ;;
    esac

    # サブコマンド別処理
    case "$subcommand" in
        label)
            # 引数チェック
            if [[ $# -lt 1 ]]; then
                echo "error:missing-issue-number"
                exit 1
            fi
            if [[ $# -lt 2 ]]; then
                echo "error:missing-label-name"
                exit 1
            fi

            local issue_number="$1"
            local label_name="$2"

            if cmd_label "$issue_number" "$label_name"; then
                exit 0
            else
                exit 1
            fi
            ;;

        remove-label)
            # 引数チェック
            if [[ $# -lt 1 ]]; then
                echo "error:missing-issue-number"
                exit 1
            fi
            if [[ $# -lt 2 ]]; then
                echo "error:missing-label-name"
                exit 1
            fi

            local issue_number="$1"
            local label_name="$2"

            if cmd_remove_label "$issue_number" "$label_name"; then
                exit 0
            else
                exit 1
            fi
            ;;

        set-status)
            # 引数チェック
            if [[ $# -lt 1 ]]; then
                echo "error:missing-issue-number"
                exit 1
            fi
            if [[ $# -lt 2 ]]; then
                echo "error:missing-status"
                exit 1
            fi

            local issue_number="$1"
            local status="$2"

            if cmd_set_status "$issue_number" "$status"; then
                exit 0
            else
                exit 1
            fi
            ;;

        close)
            # 引数チェック
            if [[ $# -lt 1 ]]; then
                echo "error:missing-issue-number"
                exit 1
            fi

            local issue_number="$1"
            shift

            local not_planned="false"
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --not-planned)
                        not_planned="true"
                        ;;
                    *)
                        echo "error:unknown-option:$1"
                        exit 1
                        ;;
                esac
                shift
            done

            if cmd_close "$issue_number" "$not_planned"; then
                exit 0
            else
                exit 1
            fi
            ;;
    esac
}

main "$@"
