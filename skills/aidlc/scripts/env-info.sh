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
#   starter_kit_version:バージョン番号（docs/aidlc.toml から取得）
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: env-info.sh [OPTIONS]

依存ツール（gh, dasel, git）の状態を一覧で出力します。

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
  git:available
  starter_kit_version:1.9.2

  $ env-info.sh --setup
  gh:available
  dasel:available
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

# .aidlc/config.toml から project.name を取得
# dasel未インストール時またはファイル不存在時は空値を返す
get_project_name() {
    if ! command -v dasel >/dev/null 2>&1; then
        echo ""
        return
    fi
    if [[ ! -f "${AIDLC_CONFIG}" ]]; then
        echo ""
        return
    fi
    local result
    result=$(dasel -i toml 'project.name' < "${AIDLC_CONFIG}" 2>/dev/null) || { echo ""; return; }
    # daselの出力からクォートを除去（共通ユーティリティ使用）
    aidlc_strip_quotes "$result"
}

# バックログモードを取得（resolve-backlog-mode.sh の共通ロジックを使用）
# resolve-backlog-mode.sh を source
source "${SCRIPT_DIR}/resolve-backlog-mode.sh"

# get_backlog_mode: resolve_backlog_mode を直接使用（ラッパー廃止）
# get_current_branch: aidlc_get_current_branch (lib/bootstrap.sh) を使用

# .aidlc/cycles/ 配下の最新サイクルバージョンを取得
# ディレクトリがない場合は空値を返す
get_latest_cycle() {
    if [[ ! -d "${AIDLC_CYCLES}" ]]; then
        echo ""
        return
    fi
    ls -1 "${AIDLC_CYCLES}/" 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1 || echo ""
}

# .aidlc/config.toml からスターターキットのバージョンを取得
# ファイル不存在/読み取りエラー時は空値を返す
# dasel未インストール時はgrep+sedでフォールバック
get_starter_kit_version() {
    local toml_file="${AIDLC_CONFIG}"

    if [[ ! -f "$toml_file" ]]; then
        echo ""
        return
    fi

    local version=""

    # daselが利用可能な場合
    if command -v dasel >/dev/null 2>&1; then
        version=$(dasel -i toml 'starter_kit_version' < "$toml_file" 2>/dev/null) || version=""
        version=$(aidlc_strip_quotes "$version")
    else
        # dasel未インストール時のフォールバック（grep+sed）
        # 行頭の空白を許容、コメント行は無視、最初の定義のみ採用
        local line
        line=$(grep -E '^[[:space:]]*starter_kit_version[[:space:]]*=' "$toml_file" 2>/dev/null | grep -v '^[[:space:]]*#' | head -1) || line=""

        if [[ -n "$line" ]]; then
            # = の後の値部分を抽出し、インラインコメントを除去
            version="${line#*=}"
            version="${version%%#*}"
            version=$(aidlc_strip_quotes "$version")
        fi
    fi

    echo "$version"
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

    # 出力順序は固定（gh → dasel → git → starter_kit_version）
    echo "gh:$(check_gh)"
    echo "dasel:$(check_tool dasel)"
    echo "git:$(check_tool git)"
    echo "starter_kit_version:$(get_starter_kit_version)"

    # --setup オプション時のみ追加出力
    if [[ "$setup_mode" == true ]]; then
        echo "project.name:$(get_project_name)"
        echo "backlog.mode:$(resolve_backlog_mode)"
        echo "current_branch:$(aidlc_get_current_branch)"
        echo "latest_cycle:$(get_latest_cycle)"
    fi
}

main "$@"
