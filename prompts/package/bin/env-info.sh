#!/usr/bin/env bash
#
# env-info.sh - 依存ツールの状態を一覧で出力
#
# 使用方法:
#   ./env-info.sh [OPTIONS]
#
# OPTIONS:
#   -h, --help    ヘルプを表示
#   --setup       セットアップ情報を追加出力
#
# 出力形式:
#   ツール名:状態
#   - available: 利用可能
#   - not-installed: 未インストール
#   - not-authenticated: インストール済みだが認証されていない（ghのみ）
#   starter_kit_version:バージョン番号（version.txt から取得）
#

set -euo pipefail

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: env-info.sh [OPTIONS]

依存ツール（gh, dasel, jj, git）の状態を一覧で出力します。

OPTIONS:
  -h, --help    このヘルプを表示
  --setup       セットアップ情報を追加出力

出力形式:
  ツール名:状態
  starter_kit_version:バージョン番号

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
  starter_kit_version:1.9.2

  $ env-info.sh --setup
  gh:available
  dasel:available
  jj:available
  git:available
  starter_kit_version:1.9.2
  project.name:my-project
  backlog.mode:issue-only
  current_branch:main
  latest_cycle:v1.0.0
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

# docs/aidlc.toml から project.name を取得
# dasel未インストール時またはファイル不存在時は空値を返す
get_project_name() {
    if ! command -v dasel >/dev/null 2>&1; then
        echo ""
        return
    fi
    if [[ ! -f "docs/aidlc.toml" ]]; then
        echo ""
        return
    fi
    local result
    result=$(cat docs/aidlc.toml | dasel -i toml 'project.name' 2>/dev/null) || { echo ""; return; }
    # daselの出力からクォートを除去
    echo "$result" | tr -d "'"
}

# docs/aidlc.toml から backlog.mode を取得
# dasel未インストール時またはファイル不存在時は空値を返す
get_backlog_mode() {
    if ! command -v dasel >/dev/null 2>&1; then
        echo ""
        return
    fi
    if [[ ! -f "docs/aidlc.toml" ]]; then
        echo ""
        return
    fi
    local result
    result=$(cat docs/aidlc.toml | dasel -i toml 'backlog.mode' 2>/dev/null) || { echo ""; return; }
    # daselの出力からクォートを除去
    echo "$result" | tr -d "'"
}

# 現在のGitブランチを取得
# Gitリポジトリ外では空値を返す
get_current_branch() {
    git branch --show-current 2>/dev/null || echo ""
}

# docs/cycles/ 配下の最新サイクルバージョンを取得
# ディレクトリがない場合は空値を返す
get_latest_cycle() {
    if [[ ! -d "docs/cycles" ]]; then
        echo ""
        return
    fi
    ls -1 docs/cycles/ 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1 || echo ""
}

# version.txt からスターターキットのバージョンを取得
# ファイル不存在/空/読み取りエラー時は空値を返す
# 正規化: 1行目のみ取得し、CRを除去
get_starter_kit_version() {
    if [[ ! -f "version.txt" ]]; then
        echo ""
        return
    fi
    local version=""
    IFS= read -r version < version.txt 2>/dev/null || true
    # CRを除去（Windows改行対応）
    echo "${version//$'\r'/}"
}

# メイン処理
main() {
    local setup_mode=false

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --setup)
                setup_mode=true
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done

    # 出力順序は固定（gh → dasel → jj → git → starter_kit_version）
    echo "gh:$(check_gh)"
    echo "dasel:$(check_tool dasel)"
    echo "jj:$(check_tool jj)"
    echo "git:$(check_tool git)"
    echo "starter_kit_version:$(get_starter_kit_version)"

    # --setup オプション時のみ追加出力
    if [[ "$setup_mode" == true ]]; then
        echo "project.name:$(get_project_name)"
        echo "backlog.mode:$(get_backlog_mode)"
        echo "current_branch:$(get_current_branch)"
        echo "latest_cycle:$(get_latest_cycle)"
    fi
}

main "$@"
