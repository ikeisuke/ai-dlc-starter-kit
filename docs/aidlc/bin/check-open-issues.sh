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
#   - エラー: "error:[エラー内容]"
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
result=$(gh issue list --state open --limit "$LIMIT" 2>&1) || {
    echo "error:${result}"
    exit 1
}

if [[ -z "$result" ]]; then
    echo "open_issues:none"
else
    echo "$result"
fi
