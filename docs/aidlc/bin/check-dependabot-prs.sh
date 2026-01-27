#!/usr/bin/env bash
#
# check-dependabot-prs.sh - Dependabot PRの一覧を取得
#
# 使用方法:
#   ./check-dependabot-prs.sh
#
# 出力形式:
#   - PRあり: gh pr listの出力（PR番号、タイトル、状態）
#   - PRなし: "dependabot_prs:none"
#   - エラー: "error:[エラー内容]"
#
# 終了コード:
#   0: 正常終了（PRの有無に関わらず）
#   1: エラー（gh未インストール等）
#

set -euo pipefail

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

# Dependabot PRの一覧取得
result=$(gh pr list --label "dependencies" --state open 2>&1) || {
    echo "error:${result}"
    exit 1
}

if [[ -z "$result" ]]; then
    echo "dependabot_prs:none"
else
    echo "$result"
fi
