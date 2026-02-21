#!/usr/bin/env bash
#
# validate-remote-sync.sh - リモート同期状態の検証
#
# 使用方法:
#   ./validate-remote-sync.sh
#
# 出力形式:
#   status:{ok|warning|error}
#   - ok: 全コミットがリモートにpush済み
#   - warning: 未pushコミットあり
#   - error: 検証失敗
#
#   warning時の追加出力:
#   remote:{リモート名}
#   branch:{ブランチ名}
#   unpushed_commits:{件数}
#
#   error時の追加出力:
#   remote:{リモート名|unknown}
#   branch:{ブランチ名|unknown}
#   error:{fetch-failed|no-upstream|log-failed|branch-unresolved}
#
# 終了コード:
#   0: 正常（ok/warning）
#   1: エラー
#

set -euo pipefail

# --- Step 0: ブランチ名・リモート名解決 ---

BRANCH=$(git branch --show-current 2>/dev/null) || true
if [ -z "$BRANCH" ]; then
    echo "status:error"
    echo "remote:unknown"
    echo "branch:unknown"
    echo "error:branch-unresolved"
    echo "Error: Cannot determine current branch (detached HEAD?)" >&2
    exit 1
fi

REMOTE=$(git config "branch.${BRANCH}.remote" 2>/dev/null || echo "origin")
if [ -z "$REMOTE" ]; then
    REMOTE="origin"
fi

# --- Step A: リモートfetch ---

if ! git fetch -- "$REMOTE" >/dev/null 2>&1; then
    echo "status:error"
    echo "remote:${REMOTE}"
    echo "branch:${BRANCH}"
    echo "error:fetch-failed"
    echo "Error: git fetch ${REMOTE} failed" >&2
    exit 1
fi

# --- Step B: 追跡ブランチ解決 ---

REMOTE_REF=$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null || true)

if [ -z "$REMOTE_REF" ]; then
    if git show-ref --verify "refs/remotes/${REMOTE}/${BRANCH}" >/dev/null 2>&1; then
        REMOTE_REF="${REMOTE}/${BRANCH}"
    else
        echo "status:error"
        echo "remote:${REMOTE}"
        echo "branch:${BRANCH}"
        echo "error:no-upstream"
        echo "Error: No upstream tracking branch found for ${BRANCH}" >&2
        exit 1
    fi
fi

# --- Step C: 未pushコミット検出 ---

UNPUSHED=$(git log "${REMOTE_REF}..HEAD" --oneline 2>/dev/null) || {
    echo "status:error"
    echo "remote:${REMOTE}"
    echo "branch:${BRANCH}"
    echo "error:log-failed"
    echo "Error: git log ${REMOTE_REF}..HEAD failed" >&2
    exit 1
}

if [ -z "$UNPUSHED" ]; then
    echo "status:ok"
else
    COUNT=$(echo "$UNPUSHED" | wc -l | tr -d ' ')
    echo "status:warning"
    echo "remote:${REMOTE}"
    echo "branch:${BRANCH}"
    echo "unpushed_commits:${COUNT}"
fi
