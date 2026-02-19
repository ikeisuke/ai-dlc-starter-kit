#!/usr/bin/env bash
#
# check-open-issues.sh - オープンIssueの一覧を取得
#
# 使用方法:
#   ./check-open-issues.sh [--limit N]
#
# パラメータ:
#   --limit N: 取得件数（デフォルト: 10）
#
# 出力形式:
#   - Issueあり: gh issue listの出力（Issue番号、タイトル、ラベル）
#   - Issueなし: "open_issues:none"
#   - エラー: "error:<エラー種別>[:<コンテキスト>]"
#
# 終了コード:
#   0: 正常終了（Issueの有無に関わらず）
#   1: エラー（gh未インストール等）
#

set -euo pipefail

# デフォルト値
LIMIT=10

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --limit)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-limit-value"
                exit 1
            fi
            if ! [[ "$2" =~ ^[1-9][0-9]*$ ]]; then
                echo "error:invalid-limit-value"
                exit 1
            fi
            LIMIT="$2"
            shift 2
            ;;
        *)
            echo "error:unknown-option:$1"
            exit 1
            ;;
    esac
done

# GitHub CLIの存在確認
if ! command -v gh >/dev/null 2>&1; then
    echo "error:gh-not-installed"
    exit 1
fi

# 認証確認
if ! gh auth status >/dev/null 2>&1; then
    echo "error:gh-not-authenticated"
    exit 1
fi

# オープンIssueの一覧取得
_tmp_stderr=$(mktemp) || { echo "error:gh-issue-list-failed"; exit 1; }
trap '\rm -f "$_tmp_stderr"' EXIT
result=$(gh issue list --state open --limit "$LIMIT" 2>"$_tmp_stderr") || {
    echo "error:gh-issue-list-failed"
    cat "$_tmp_stderr" >&2
    exit 1
}

if [[ -z "$result" ]]; then
    echo "open_issues:none"
else
    echo "$result"
fi
