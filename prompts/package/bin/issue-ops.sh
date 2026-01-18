#!/usr/bin/env bash
#
# issue-ops.sh - Issue操作スクリプト
#
# 使用方法:
#   ./issue-ops.sh label <issue_number> <label_name>
#   ./issue-ops.sh close <issue_number> [--not-planned]
#
# SUBCOMMANDS:
#   label     Issueにラベルを付与
#   close     IssueをClose
#
# OPTIONS:
#   -h, --help       ヘルプを表示
#   --not-planned    Close時にnot planned理由を指定
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

set -euo pipefail

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: issue-ops.sh <subcommand> [options]

Issue操作（ラベル付け、Close）を行うスクリプト。

SUBCOMMANDS:
  label <issue_number> <label_name>
      Issueにラベルを付与します。

  close <issue_number> [--not-planned]
      IssueをCloseします。
      --not-planned を指定すると「not planned」理由でCloseします。

OPTIONS:
  -h, --help    このヘルプを表示

出力形式（stdout）:
  成功時:
    issue:<number>:labeled:<label_name>
    issue:<number>:closed
    issue:<number>:closed:not-planned

  エラー時:
    issue:<number>:error:not-found
    issue:<number>:error:gh-not-available
    issue:<number>:error:gh-not-authenticated
    issue:<number>:error:unknown

  引数エラー時:
    error:missing-subcommand
    error:unknown-subcommand:<name>
    error:missing-issue-number
    error:missing-label-name

例:
  $ issue-ops.sh label 123 "cycle:v1.8.0"
  issue:123:labeled:cycle:v1.8.0

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
parse_gh_error() {
    local error_output="$1"

    if echo "$error_output" | grep -qi "not found\|could not find\|could not resolve"; then
        echo "not-found"
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
        label|close)
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
