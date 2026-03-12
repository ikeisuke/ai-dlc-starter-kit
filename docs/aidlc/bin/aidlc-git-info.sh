#!/usr/bin/env bash
#
# aidlc-git-info.sh - Git状態取得
#
# 使用方法:
#   ./aidlc-git-info.sh
#
# 出力形式:
#   vcs_type:<git|unknown>
#   current_branch:<branch-name|(detached)>
#   worktree_status:<clean|dirty|unknown>
#   recent_commits_count:<0-3>
#   recent_commit_1:<hash> <message>
#   recent_commit_2:<hash> <message>
#   recent_commit_3:<hash> <message>
#

IFS=$' \t\n'
set -uo pipefail

# VCS種類判定
# 出力: "git" または "unknown"
detect_vcs() {
    # .git 存在（ファイルまたはディレクトリ） かつ git コマンド利用可能 → git
    if [[ -e ".git" ]] && command -v git >/dev/null 2>&1; then
        echo "git"
        return
    fi
    echo "unknown"
}

# 現在ブランチ取得
# 引数: VCS種類
# 出力: ブランチ名、(detached)、または unknown
get_current_branch() {
    local vcs="$1"
    local branch=""

    if [[ "$vcs" == "git" ]]; then
        branch=$(git branch --show-current 2>/dev/null) || branch=""
        if [[ -z "$branch" ]]; then
            # detached HEAD の可能性
            echo "(detached)"
            return
        fi
        echo "$branch"
    else
        echo "unknown"
    fi
}

# ワークツリー状態取得
# 引数: VCS種類
# 出力: "clean", "dirty", または "unknown"
get_worktree_status() {
    local vcs="$1"
    local status=""

    if [[ "$vcs" == "git" ]]; then
        status=$(git status --porcelain 2>/dev/null) || { echo "unknown"; return; }
        if [[ -z "$status" ]]; then
            echo "clean"
        else
            echo "dirty"
        fi
    else
        echo "unknown"
    fi
}

# 直近コミット取得
# 引数: VCS種類
# 出力: 直近3コミットを配列で返す（グローバル変数 RECENT_COMMITS に格納）
get_recent_commits() {
    local vcs="$1"
    RECENT_COMMITS=()

    if [[ "$vcs" == "git" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && RECENT_COMMITS+=("$line")
        done < <(git log --oneline -3 2>/dev/null || true)
    fi
}

# メイン処理
main() {
    local vcs
    vcs=$(detect_vcs)

    echo "vcs_type:$vcs"
    echo "current_branch:$(get_current_branch "$vcs")"
    echo "worktree_status:$(get_worktree_status "$vcs")"

    get_recent_commits "$vcs"
    echo "recent_commits_count:${#RECENT_COMMITS[@]}"

    local i=1
    for commit in "${RECENT_COMMITS[@]}"; do
        echo "recent_commit_$i:$commit"
        ((i++))
    done
}

main
