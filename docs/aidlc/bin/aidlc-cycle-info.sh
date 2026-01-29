#!/usr/bin/env bash
#
# aidlc-cycle-info.sh - AI-DLCサイクル情報取得
#
# 使用方法:
#   ./aidlc-cycle-info.sh
#
# 出力形式:
#   current_cycle:<version|none>
#   cycle_phase:<inception|construction|operations|unknown>
#   latest_cycle:<version|none>
#   cycle_dir:<path|none>
#

set -uo pipefail

# 現在ブランチ取得（git/jj両対応）
get_current_branch() {
    local branch=""

    # jj優先
    if [[ -d ".jj" ]] && command -v jj >/dev/null 2>&1; then
        branch=$(jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null) || branch=""
        # 複数ある場合は最初の1つ
        branch="${branch%% *}"
    fi

    # jjで取得できなければgit
    if [[ -z "$branch" ]] && [[ -d ".git" ]]; then
        branch=$(git branch --show-current 2>/dev/null) || branch=""
    fi

    echo "$branch"
}

# ブランチ名からバージョン抽出
# 入力: cycle/v1.11.1 → 出力: v1.11.1
# マッチしない場合は空文字
extract_version() {
    local branch="$1"
    if [[ "$branch" =~ ^cycle/(v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# 最新サイクルバージョン取得
# docs/cycles/ 内のバージョンディレクトリを走査
get_latest_cycle() {
    if [[ ! -d "docs/cycles" ]]; then
        echo ""
        return
    fi
    # バージョン形式のディレクトリのみ抽出し、バージョンソートで最新を取得
    ls -1 docs/cycles/ 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || echo ""
}

# フェーズ判定
# 引数: サイクルバージョン
# 出力: inception, construction, operations, または unknown
detect_phase() {
    local version="$1"

    if [[ -z "$version" ]]; then
        echo "unknown"
        return
    fi

    local cycle_dir="docs/cycles/$version"
    if [[ ! -d "$cycle_dir" ]]; then
        echo "unknown"
        return
    fi

    # フェーズ判定（ディレクトリ存在で判定）
    if [[ -d "$cycle_dir/operations" ]]; then
        echo "operations"
    elif [[ -d "$cycle_dir/construction" ]]; then
        echo "construction"
    else
        echo "inception"
    fi
}

# メイン処理
main() {
    local branch
    branch=$(get_current_branch)

    local version
    version=$(extract_version "$branch")

    local latest
    latest=$(get_latest_cycle)

    # current_cycle
    if [[ -n "$version" ]]; then
        echo "current_cycle:$version"
    else
        echo "current_cycle:none"
    fi

    # cycle_phase
    echo "cycle_phase:$(detect_phase "$version")"

    # latest_cycle
    if [[ -n "$latest" ]]; then
        echo "latest_cycle:$latest"
    else
        echo "latest_cycle:none"
    fi

    # cycle_dir
    if [[ -n "$version" ]] && [[ -d "docs/cycles/$version" ]]; then
        echo "cycle_dir:docs/cycles/$version"
    else
        echo "cycle_dir:none"
    fi
}

main
