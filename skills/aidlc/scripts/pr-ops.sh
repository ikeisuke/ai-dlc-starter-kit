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
#     pr:<number>:auto-merge-set:<method>
#     pr:<number>:error:<reason>
#
# gh利用不可時:
#   error:gh-not-available
#   error:gh-not-authenticated
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

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

  merge <pr_number> [--squash|--rebase] [--skip-checks]
      PRをマージします。
      オプション指定がない場合は通常マージ（--merge）を使用します。
      --skip-checks 指定時は、必須CIチェックが未設定のリポジトリ
      （no-checks-configured）でのみCIバイパスを許可します。
      failed/pending/checks-query-failed ではバイパスされません。

OPTIONS:
  -h, --help     このヘルプを表示
  --squash       squashマージ
  --rebase       rebaseマージ
  --skip-checks  no-checks-configured時のみCIバイパスを許可

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
    pr:<number>:auto-merge-set:<method> auto-merge設定成功（CI完了後に自動マージ）
    pr:<number>:error:<reason>          エラー

    checks-status-unknown エラー時は以下の3行を順序固定で出力:
      pr:<number>:error:checks-status-unknown
      pr:<number>:reason:<no-checks-configured|checks-query-failed>
      pr:<number>:hint:<人間向けガイダンス>
    reason=no-checks-configured の場合のみ --skip-checks で再実行可能。

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
# 出力:
#   issues:<all_csv>       後方互換行（closes + relates 結合）
#   closes:<closes_csv>    完全対応Issueのみ
#   relates:<relates_csv>  部分対応Issueのみ
cmd_get_related_issues() {
    local cycle="$1"
    local units_dir="${AIDLC_CYCLES}/${cycle}/story-artifacts/units"

    if [[ ! -d "$units_dir" ]]; then
        echo "error:units-dir-not-found"
        return 1
    fi

    local -a closes_list=()
    local -a relates_list=()

    # 各Unit定義ファイルの「## 関連Issue」セクション内のみを対象に解析
    local file section line
    for file in "${units_dir}"/*.md; do
        [[ -f "$file" ]] || continue
        # 「## 関連Issue」セクションを切り出し（次の##ヘッダーまたはファイル末尾まで）
        section=$(awk '/^## 関連Issue/{found=1;next} found && /^## /{exit} found{print}' "$file" 2>/dev/null || true)
        [[ -z "$section" ]] && continue
        while IFS= read -r line; do
            if [[ "$line" =~ \#([0-9]+)（部分対応） ]]; then
                relates_list+=("#${BASH_REMATCH[1]}")
            elif [[ "$line" =~ \#([0-9]+) ]]; then
                closes_list+=("#${BASH_REMATCH[1]}")
            fi
        done <<< "$section"
    done

    # 重複除去・ソート
    local closes_csv relates_csv all_csv
    if [[ ${#closes_list[@]} -gt 0 ]]; then
        closes_csv=$(printf '%s\n' "${closes_list[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')
    fi
    if [[ ${#relates_list[@]} -gt 0 ]]; then
        relates_csv=$(printf '%s\n' "${relates_list[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')
    fi

    # 後方互換: 全Issue結合
    local -a all_list=("${closes_list[@]}" "${relates_list[@]}")
    if [[ ${#all_list[@]} -gt 0 ]]; then
        all_csv=$(printf '%s\n' "${all_list[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')
    fi

    echo "issues:${all_csv:-none}"
    echo "closes:${closes_csv:-none}"
    echo "relates:${relates_csv:-none}"
}

# resolve_check_status: gh pr checks の生出力から CheckStatus 5分類の文字列を返す
# 出力: pass / fail / pending / no-checks-configured / checks-query-failed
# 引数: $1=pr_number
resolve_check_status() {
    local pr_number="$1"
    local stderr_file
    stderr_file=$(mktemp)

    # if/else で exit code を保持（|| true は $? が常に 0 になるため使わない）
    local stdout_value
    local checks_ec
    if stdout_value=$(gh pr checks "$pr_number" --required --json bucket --jq '[.[].bucket] | if length == 0 then "pass" elif all(. == "pass") then "pass" elif any(. == "pending") then "pending" else "fail" end' 2>"$stderr_file"); then
        checks_ec=0
    else
        checks_ec=$?
    fi
    local stderr_value
    stderr_value=$(<"$stderr_file")
    rm -f "$stderr_file"

    # stdout が pass/fail/pending のいずれかなら exit code に関わらず優先
    # 理由: gh pr checks は pending 時に exit 8 を返す（公式仕様: cli.github.com/manual/gh_pr_checks）
    # cancel/skipping は jq で "fail" に丸められるため既存挙動として "fail" として扱う
    if [[ "$stdout_value" =~ ^(pass|fail|pending)$ ]]; then
        printf '%s\n' "$stdout_value"
        return 0
    fi
    # no-checks 判定: gh pr checks --required は 2 パターンの stderr を返す
    #  - "no checks reported on the '<branch>' branch" (チェック自体が設定されていない)
    #  - "no required checks reported on the '<branch>' branch" (チェックはあるが required 指定なし)
    # どちらも --skip-checks バイパス可能な no-checks-configured として扱う。
    if [[ "$checks_ec" -ne 0 && ("$stderr_value" == *"no checks reported"* || "$stderr_value" == *"no required checks reported"*) ]]; then
        printf 'no-checks-configured\n'
        return 0
    fi
    printf 'checks-query-failed\n'
    return 0
}

# emit_checks_status_unknown_error: checks-status-unknown 系エラーを順序固定で出力
# 引数: $1=pr_number, $2=reason_code (no-checks-configured | checks-query-failed)
# 出力順: error → reason → hint（3行連続）
emit_checks_status_unknown_error() {
    local pr_number="$1"
    local reason_code="$2"
    local hint_text
    case "$reason_code" in
        no-checks-configured)
            hint_text="この PR では必須 CI チェックが検出されませんでした。リポジトリに必須チェックが未設定の場合は --skip-checks を付与してバイパスできます（failed/pending/API エラー時は無効）。"
            ;;
        checks-query-failed)
            hint_text="CI チェック状態の取得に失敗しました（ネットワークまたは API エラーの可能性）。--skip-checks では回避できません。時間を置いて再試行してください。"
            ;;
        *)
            hint_text="不明な reason_code: ${reason_code}"
            ;;
    esac
    echo "pr:${pr_number}:error:checks-status-unknown"
    echo "pr:${pr_number}:reason:${reason_code}"
    echo "pr:${pr_number}:hint:${hint_text}"
}

# mergeサブコマンド
# 引数: $1=pr_number, $2=merge_method（merge/squash/rebase）, $3=skip_checks (0|1)
cmd_merge() {
    local pr_number="$1"
    local merge_method="${2:-merge}"
    local skip_checks="${3:-0}"
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

    # 存在確認ドメイン: PR 自体が存在するかを先に確定
    # （checks 系エラー分類より前。stale/invalid PR 番号を checks-query-failed に誤分類しないため）
    # transient エラー（network / API 一時障害）と not-found を stderr メッセージで分離する。
    local pr_view_stderr pr_view_ec=0
    pr_view_stderr=$(gh pr view "$pr_number" --json number --jq '.number' 2>&1 >/dev/null) || pr_view_ec=$?
    if [[ $pr_view_ec -ne 0 ]]; then
        case "$pr_view_stderr" in
            *"no pull requests found"*|*"could not resolve to a PullRequest"*|*"GraphQL: Could not resolve"*|*"no pull request found"*)
                echo "pr:${pr_number}:error:not-found"
                echo "pr:${pr_number}:hint:PR 番号が無効またはリポジトリに存在しません。gh pr list で現在の PR を確認してください。"
                return 1
                ;;
            *)
                echo "pr:${pr_number}:error:pr-view-failed"
                echo "pr:${pr_number}:hint:gh pr view が失敗しました（ネットワーク / API 一時障害の可能性）。時間を置いて再試行してください。stderr: ${pr_view_stderr}"
                return 1
                ;;
        esac
    fi

    # 判定ドメイン: CheckStatus を先に確定（head_sha 取得より前）
    local check_status
    check_status=$(resolve_check_status "$pr_number")

    # 決定ドメイン: CheckStatus + skip_checks から action を決定
    # 安全性契約: fail / pending / checks-query-failed は skip_checks を無視
    local action=""
    case "$check_status" in
        pass)
            action="merge-now"
            ;;
        fail)
            echo "pr:${pr_number}:error:checks-failed"
            return 1
            ;;
        pending)
            action="set-auto-merge"
            ;;
        no-checks-configured)
            if [[ "$skip_checks" -eq 1 ]]; then
                action="merge-now"
            else
                emit_checks_status_unknown_error "$pr_number" "no-checks-configured"
                return 1
            fi
            ;;
        checks-query-failed)
            # skip_checks が指定されていても無視（安全側に倒す）
            emit_checks_status_unknown_error "$pr_number" "checks-query-failed"
            return 1
            ;;
        *)
            echo "pr:${pr_number}:error:unknown"
            return 1
            ;;
    esac

    # 実行ドメイン: head_sha を遅延解決（merge-now / set-auto-merge のみ）
    local head_sha
    head_sha=$(gh pr view "$pr_number" --json headRefOid --jq '.headRefOid' 2>/dev/null || echo "")
    if [[ -z "$head_sha" ]]; then
        echo "pr:${pr_number}:error:head-sha-unavailable"
        return 1
    fi

    local head_flag="--match-head-commit ${head_sha}"

    if [[ "$action" == "merge-now" ]]; then
        local error_output
        # shellcheck disable=SC2086
        if error_output=$(gh pr merge "$pr_number" "$merge_flag" $head_flag 2>&1); then
            echo "pr:${pr_number}:merged:${merge_method}"
            return 0
        else
            if echo "$error_output" | grep -qi "not found"; then
                echo "pr:${pr_number}:error:not-found"
            elif echo "$error_output" | grep -qi "not mergeable\|merge conflict"; then
                echo "pr:${pr_number}:error:not-mergeable"
            elif echo "$error_output" | grep -qi "review.*required\|not approved"; then
                echo "pr:${pr_number}:error:review-required"
            elif echo "$error_output" | grep -qi "head.*match\|does not match"; then
                echo "pr:${pr_number}:error:head-mismatch"
            else
                echo "pr:${pr_number}:error:unknown"
            fi
            return 1
        fi
    fi

    # action == "set-auto-merge" (pending)
    local auto_error
    # shellcheck disable=SC2086
    if auto_error=$(gh pr merge "$pr_number" "$merge_flag" --auto $head_flag 2>&1); then
        echo "pr:${pr_number}:auto-merge-set:${merge_method}"
        return 0
    else
        if echo "$auto_error" | grep -qi "auto-merge is not allowed\|not enabled\|auto_merge"; then
            echo "pr:${pr_number}:error:auto-merge-not-enabled"
        elif echo "$auto_error" | grep -qi "permission\|forbidden\|403"; then
            echo "pr:${pr_number}:error:permission-denied"
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
            local skip_checks=0
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --squash)
                        merge_method="squash"
                        ;;
                    --rebase)
                        merge_method="rebase"
                        ;;
                    --skip-checks)
                        skip_checks=1
                        ;;
                    *)
                        echo "error:unknown-option:$1"
                        exit 1
                        ;;
                esac
                shift
            done

            if cmd_merge "$pr_number" "$merge_method" "$skip_checks"; then
                exit 0
            else
                exit 1
            fi
            ;;
    esac
}

main "$@"
