#!/bin/bash
# get-default-branch.sh - リモートのデフォルトブランチを取得
#
# 使用方法:
#   docs/aidlc/bin/get-default-branch.sh
#
# 出力形式:
#   branch:main
#   branch:master
#   branch:unknown
#
# 終了コード:
#   0: 成功（ブランチ取得成功またはunknown）

set -euo pipefail

# リモートからデフォルトブランチを取得
get_default_branch() {
    local branch

    # 方法1: git remote show originから取得
    branch=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
    if [[ -n "$branch" ]]; then
        echo "branch:$branch"
        return 0
    fi

    # 方法2: main/masterの存在確認
    if git show-ref --verify "refs/remotes/origin/main" >/dev/null 2>&1; then
        echo "branch:main"
        return 0
    fi

    if git show-ref --verify "refs/remotes/origin/master" >/dev/null 2>&1; then
        echo "branch:master"
        return 0
    fi

    echo "branch:unknown"
    return 0
}

get_default_branch
