#!/usr/bin/env bash
#
# pr-ops.sh - PR操作スクリプト
#
# 使用方法:
#   ./pr-ops.sh find-draft
#   ./pr-ops.sh ready <pr_number>
#   ./pr-ops.sh get-related-issues <cycle>
#   ./pr-ops.sh merge <pr_number> [--squash|--rebase]
#
# SUBCOMMANDS:
#   find-draft          現在のブランチからのドラフトPRを検索
#   ready               ドラフトPRをReady for Reviewに変更
#   get-related-issues  Unit定義ファイルから関連Issue番号を取得
#   merge               PRをマージ
#
# OPTIONS:
#   -h, --help       ヘルプを表示
#   --squash         squashマージ（merge時）
#   --rebase         rebaseマージ（merge時）
#
# 出力形式（stdout）:
#   find-draft:
#     pr:found:<number>:<url>
#     pr:not-found
#   ready:
#     pr:<number>:ready
#     pr:<number>:error:<reason>
#   get-related-issues:
#     issues:<#num1>,<#num2>,...
#     issues:none
#   merge:
#     pr:<number>:merged:<method>
#     pr:<number>:error:<reason>
#
# gh利用不可時:
#   error:gh-not-available
#   error:gh-not-authenticated
#

set -euo pipefail

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: pr-ops.sh <subcommand> [options]

PR操作を行うスクリプト。

SUBCOMMANDS:
  find-draft
      現在のブランチからのドラフトPRを検索します。
      ドラフト状態のPRのみを対象とします。

  ready <pr_number>
      ドラフトPRをReady for Reviewに変更します。

  get-related-issues <cycle>
      指定サイクルのUnit定義ファイルから関連Issue番号を取得します。
      例: get-related-issues v1.13.2

  merge <pr_number> [--squash|--rebase]
      PRをマージします。
      オプション指定がない場合は通常マージ（--merge）を使用します。

OPTIONS:
  -h, --help    このヘルプを表示
  --squash      squashマージ
  --rebase      rebaseマージ

出力形式（stdout）:
  find-draft:
    pr:found:<number>:<url>             ドラフトPRが見つかった場合
    pr:not-found                        ドラフトPRが見つからない場合

  ready:
    pr:<number>:ready                   Ready化成功
    pr:<number>:error:<reason>          エラー

  get-related-issues:
    issues:#123,#456,...                Issue番号リスト
    issues:none                         Issueなし

  merge:
    pr:<number>:merged:<method>         マージ成功（method: merge/squash/rebase）
    pr:<number>:error:<reason>          エラー

  gh利用不可時:
    error:gh-not-available              gh未インストール
    error:gh-not-authenticated          gh未認証

例:
  $ pr-ops.sh find-draft
  pr:found:123:https://github.com/owner/repo/pull/123

  $ pr-ops.sh ready 123
  pr:123:ready

  $ pr-ops.sh get-related-issues v1.13.2
  issues:#172,#170

  $ pr-ops.sh merge 123 --squash
  pr:123:merged:squash
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

# gh利用可否を確認し、エラーなら終了
require_gh() {
    local gh_status
    check_gh_available
    gh_status=$?
    if [[ $gh_status -ne 0 ]]; then
        if [[ $gh_status -eq 1 ]]; then
            echo "error:gh-not-available"
        else
            echo "error:gh-not-authenticated"
        fi
        exit 1
    fi
}

# find-draftサブコマンド
# 現在のブランチからのドラフトPRを検索
cmd_find_draft() {
    require_gh

    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "")

    if [[ -z "$current_branch" ]]; then
        echo "error:not-in-git-repo"
        return 1
    fi

    local pr_info
    # ドラフトPRのみを検索（isDraft=true）
    pr_info=$(gh pr list --head "${current_branch}" --state open --json number,url,isDraft --jq '.[] | select(.isDraft == true) | "\(.number):\(.url)"' 2>/dev/null | head -1 || echo "")

    if [[ -z "$pr_info" ]]; then
        echo "pr:not-found"
    else
        echo "pr:found:${pr_info}"
    fi
}

# readyサブコマンド
# 引数: $1=pr_number
cmd_ready() {
    local pr_number="$1"
    require_gh

    local error_output
    if error_output=$(gh pr ready "$pr_number" 2>&1); then
        echo "pr:${pr_number}:ready"
        return 0
    else
        if echo "$error_output" | grep -qi "not found"; then
            echo "pr:${pr_number}:error:not-found"
        elif echo "$error_output" | grep -qi "already ready"; then
            # 既にready状態の場合も成功扱い
            echo "pr:${pr_number}:ready"
            return 0
        elif echo "$error_output" | grep -qi "not a draft\|is not a draft"; then
            # ドラフトでないPRをready化しようとした場合も成功扱い（冪等性）
            echo "pr:${pr_number}:ready"
            return 0
        else
            echo "pr:${pr_number}:error:unknown"
        fi
        return 1
    fi
}

# get-related-issuesサブコマンド
# 引数: $1=cycle
cmd_get_related_issues() {
    local cycle="$1"
    local units_dir="docs/cycles/${cycle}/story-artifacts/units"

    if [[ ! -d "$units_dir" ]]; then
        echo "error:units-dir-not-found"
        return 1
    fi

    # Unit定義ファイル全体から #NNN 形式のIssue番号を抽出
    # grep がマッチしない場合でも終了しないよう || true を追加
    local issues
    issues=$(grep -ohE '#[0-9]+' "${units_dir}"/*.md 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//' || true)

    if [[ -z "$issues" ]]; then
        echo "issues:none"
    else
        echo "issues:${issues}"
    fi
}

# mergeサブコマンド
# 引数: $1=pr_number, $2=merge_method（merge/squash/rebase）
cmd_merge() {
    local pr_number="$1"
    local merge_method="${2:-merge}"
    require_gh

    local merge_flag
    case "$merge_method" in
        merge)
            merge_flag="--merge"
            ;;
        squash)
            merge_flag="--squash"
            ;;
        rebase)
            merge_flag="--rebase"
            ;;
        *)
            echo "pr:${pr_number}:error:invalid-merge-method"
            return 1
            ;;
    esac

    local error_output
    if error_output=$(gh pr merge "$pr_number" "$merge_flag" 2>&1); then
        echo "pr:${pr_number}:merged:${merge_method}"
        return 0
    else
        if echo "$error_output" | grep -qi "not found"; then
            echo "pr:${pr_number}:error:not-found"
        elif echo "$error_output" | grep -qi "not mergeable\|merge conflict"; then
            echo "pr:${pr_number}:error:not-mergeable"
        elif echo "$error_output" | grep -qi "review.*required\|not approved"; then
            echo "pr:${pr_number}:error:review-required"
        else
            echo "pr:${pr_number}:error:unknown"
        fi
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
        find-draft|ready|get-related-issues|merge)
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
        find-draft)
            cmd_find_draft
            ;;

        ready)
            if [[ $# -lt 1 ]]; then
                echo "error:missing-pr-number"
                exit 1
            fi
            local pr_number="$1"
            if cmd_ready "$pr_number"; then
                exit 0
            else
                exit 1
            fi
            ;;

        get-related-issues)
            if [[ $# -lt 1 ]]; then
                echo "error:missing-cycle"
                exit 1
            fi
            local cycle="$1"
            cmd_get_related_issues "$cycle"
            ;;

        merge)
            if [[ $# -lt 1 ]]; then
                echo "error:missing-pr-number"
                exit 1
            fi
            local pr_number="$1"
            shift

            local merge_method="merge"
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --squash)
                        merge_method="squash"
                        ;;
                    --rebase)
                        merge_method="rebase"
                        ;;
                    *)
                        echo "error:unknown-option:$1"
                        exit 1
                        ;;
                esac
                shift
            done

            if cmd_merge "$pr_number" "$merge_method"; then
                exit 0
            else
                exit 1
            fi
            ;;
    esac
}

main "$@"
