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
    result=$(dasel -i toml 'project.name' < docs/aidlc.toml 2>/dev/null) || { echo ""; return; }
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
    result=$(dasel -i toml 'backlog.mode' < docs/aidlc.toml 2>/dev/null) || { echo ""; return; }
    # daselの出力からクォートを除去
    echo "$result" | tr -d "'"
}

# 現在のブランチ/bookmarkを取得
# jj/git環境を考慮した優先順位で取得
# jj環境ではbookmarkを、git環境ではブランチ名を返す
get_current_branch() {
    local result=""

    # 1. jj が利用可能な場合、bookmarkを取得
    if command -v jj >/dev/null 2>&1; then
        local bookmarks
        bookmarks=$(jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null) || bookmarks=""

        if [[ -n "$bookmarks" ]]; then
            # * マーカー（現在のワーキングコピー）を除去
            bookmarks=$(echo "$bookmarks" | tr -d '*')
            # 複数スペース/タブ/改行を単一スペースに正規化
            bookmarks=$(echo "$bookmarks" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')

            # cycle/ で始まるものを優先
            local cycle_bookmark=""
            local first_bookmark=""
            for b in $bookmarks; do
                if [[ -z "$first_bookmark" ]]; then
                    first_bookmark="$b"
                fi
                if [[ "$b" == cycle/* && -z "$cycle_bookmark" ]]; then
                    cycle_bookmark="$b"
                fi
            done

            if [[ -n "$cycle_bookmark" ]]; then
                result="$cycle_bookmark"
            elif [[ -n "$first_bookmark" ]]; then
                result="$first_bookmark"
            fi
        fi
    fi

    # 2. jjで取得できなかった場合、git branch --show-current を試行
    if [[ -z "$result" ]]; then
        result=$(git branch --show-current 2>/dev/null) || result=""
    fi

    # 3. detached HEAD の場合、git rev-parse --abbrev-ref HEAD を試行
    if [[ -z "$result" ]]; then
        local abbrev_ref
        abbrev_ref=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || abbrev_ref=""
        # "HEAD" の場合は空値として扱う
        if [[ "$abbrev_ref" != "HEAD" ]]; then
            result="$abbrev_ref"
        fi
    fi

    echo "$result"
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

# docs/aidlc.toml からスターターキットのバージョンを取得
# ファイル不存在/読み取りエラー時は空値を返す
# dasel未インストール時はgrep+sedでフォールバック
get_starter_kit_version() {
    local toml_file="docs/aidlc.toml"

    if [[ ! -f "$toml_file" ]]; then
        echo ""
        return
    fi

    local version=""

    # daselが利用可能な場合
    if command -v dasel >/dev/null 2>&1; then
        version=$(dasel -i toml 'starter_kit_version' < "$toml_file" 2>/dev/null) || version=""
        # 両端の空白をトリム → 両端の引用符を除去
        version=$(echo "$version" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        version=$(echo "$version" | sed "s/^[\"']//;s/[\"']$//")
    else
        # dasel未インストール時のフォールバック（grep+sed）
        # 行頭の空白を許容、コメント行は無視、最初の定義のみ採用
        local line
        line=$(grep -E '^[[:space:]]*starter_kit_version[[:space:]]*=' "$toml_file" 2>/dev/null | grep -v '^[[:space:]]*#' | head -1) || line=""

        if [[ -n "$line" ]]; then
            # = の後の値部分を抽出
            version=$(echo "$line" | sed 's/^[^=]*=[[:space:]]*//')
            # インラインコメント（# 以降）を除去（引用符内の # は考慮しない簡易実装）
            version=$(echo "$version" | sed 's/[[:space:]]*#.*//')
            # 両端の空白と引用符を除去
            version=$(echo "$version" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            version=$(echo "$version" | sed "s/^[\"']//;s/[\"']$//")
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
