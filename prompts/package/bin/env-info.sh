#!/usr/bin/env bash
#
# env-info.sh - 依存ツールの状態を一覧で出力
#
# 使用方法:
#   ./env-info.sh [OPTIONS]
#
# OPTIONS:
#   -h, --help    ヘルプを表示
#
# 出力形式:
#   ツール名:状態
#   - available: 利用可能
#   - not-installed: 未インストール
#   - not-authenticated: インストール済みだが認証されていない（ghのみ）
#

set -euo pipefail

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: env-info.sh [OPTIONS]

依存ツール（gh, dasel, jj, git）の状態を一覧で出力します。

OPTIONS:
  -h, --help    このヘルプを表示

出力形式:
  ツール名:状態

状態:
  available         - 利用可能（インストール済み、認証済み）
  not-installed     - 未インストール
  not-authenticated - インストール済みだが認証されていない（ghのみ）

例:
  $ env-info.sh
  gh:available
  dasel:not-installed
  jj:available
  git:available
EOF
}

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
    # 認証以外の失敗（設定破損等）も not-authenticated として扱う
    if gh auth status >/dev/null 2>&1; then
        echo "available"
    else
        echo "not-authenticated"
    fi
}

# メイン処理
main() {
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done

    # 出力順序は固定（gh → dasel → jj → git）
    echo "gh:$(check_gh)"
    echo "dasel:$(check_tool dasel)"
    echo "jj:$(check_tool jj)"
    echo "git:$(check_tool git)"
}

main "$@"
