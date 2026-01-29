#!/usr/bin/env bash
#
# aidlc-git-info.sh - Git/jj状態取得
#
# 使用方法:
#   ./aidlc-git-info.sh
#
# 出力形式:
#   vcs_type:<git|jj|unknown>
#   current_branch:<branch-name|(no bookmark)|(detached)>
#   worktree_status:<clean|dirty|unknown>
#   recent_commits_count:<0-3>
#   recent_commit_1:<hash> <message>
#   recent_commit_2:<hash> <message>
#   recent_commit_3:<hash> <message>
#

set -uo pipefail

# VCS種類判定
# 出力: "jj", "git", または "unknown"
detect_vcs() {
    # .jj 存在 かつ jj コマンド利用可能 → jj
    if [[ -d ".jj" ]] && command -v jj >/dev/null 2>&1; then
        echo "jj"
        return
    fi
    # .git 存在 → git
    if [[ -d ".git" ]]; then
        echo "git"
        return
    fi
    echo "unknown"
}

# 現在ブランチ/ブックマーク取得
# 引数: VCS種類
# 出力: ブランチ名、(no bookmark)、(detached)、または unknown
get_current_branch() {
    local vcs="$1"
    local branch=""

    if [[ "$vcs" == "jj" ]]; then
        # jjの場合、@に付いているブックマークを取得
        branch=$(jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null) || branch=""
        if [[ -z "$branch" ]]; then
            echo "(no bookmark)"
            return
        fi
        # 複数ある場合は最初の1つを使用（スペース区切りの最初）
        echo "${branch%% *}"
    elif [[ "$vcs" == "git" ]]; then
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

    if [[ "$vcs" == "jj" ]]; then
        # jj diff --stat が空でなければ dirty
        status=$(jj diff --stat 2>/dev/null) || { echo "unknown"; return; }
        if [[ -z "$status" ]]; then
            echo "clean"
        else
            echo "dirty"
        fi
    elif [[ "$vcs" == "git" ]]; then
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

    if [[ "$vcs" == "jj" ]]; then
        # jj log で直近3コミットを取得
        while IFS= read -r line; do
            [[ -n "$line" ]] && RECENT_COMMITS+=("$line")
        done < <(jj log --no-graph -r '::@' -n 3 -T 'change_id.shortest() ++ " " ++ description.first_line() ++ "\n"' 2>/dev/null || true)
    elif [[ "$vcs" == "git" ]]; then
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
