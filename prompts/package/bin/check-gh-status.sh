#!/usr/bin/env bash
#
# check-gh-status.sh - GitHub CLIの利用可否を確認
#
# 使用方法:
#   ./check-gh-status.sh
#
# 出力形式:
#   gh:{状態}
#   - available: インストール済み、認証済み
#   - not-installed: 未インストール
#   - not-authenticated: インストール済みだが未認証
#

set -euo pipefail

# GitHub CLIの存在確認
if ! command -v gh >/dev/null 2>&1; then
    echo "gh:not-installed"
    exit 0
fi

# gh auth status はローカル認証情報を参照（ネットワーク不要）
if gh auth status >/dev/null 2>&1; then
    echo "gh:available"
else
    echo "gh:not-authenticated"
fi
