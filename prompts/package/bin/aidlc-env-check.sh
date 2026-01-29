#!/usr/bin/env bash
#
# aidlc-env-check.sh - AI-DLC環境チェック
#
# 使用方法:
#   ./aidlc-env-check.sh
#
# 出力形式:
#   gh:available|not-installed|not-authenticated
#   dasel:available|not-installed
#   jj:available|not-installed
#   git:available|not-installed
#

set -uo pipefail

# 汎用ツール存在確認関数
# 引数: ツール名
# 出力: "available" または "not-installed"
check_tool() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        echo "available"
    else
        echo "not-installed"
    fi
}

# gh固有の認証状態確認
# 出力: "available", "not-installed", または "not-authenticated"
check_gh() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "not-installed"
        return
    fi
    # gh auth status はローカルの認証情報を確認（ネットワーク不要）
    if gh auth status >/dev/null 2>&1; then
        echo "available"
    else
        echo "not-authenticated"
    fi
}

# メイン処理
main() {
    # 出力順序は env-info.sh と同じ（gh → dasel → jj → git）
    echo "gh:$(check_gh)"
    echo "dasel:$(check_tool dasel)"
    echo "jj:$(check_tool jj)"
    echo "git:$(check_tool git)"
}

main
