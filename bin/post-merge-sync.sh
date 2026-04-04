#!/usr/bin/env bash
#
# post-merge-sync.sh - PRマージ後のworktree同期スクリプト
#
# 親リポジトリのmain pull、worktreeのdetached HEAD化、
# マージ済みブランチ（cycle/ + upgrade/）の削除を自動化する。
#
# 使用方法:
#   ./bin/post-merge-sync.sh [OPTIONS]
#
# オプション:
#   --dry-run   実際の操作を行わず実行予定を表示
#   --yes       リモートブランチ削除の確認をスキップ
#   --help      ヘルプを表示
#
# 終了コード:
#   0: 正常終了
#   1: エラー
#

set -euo pipefail

# === デフォルト値 ===
DRY_RUN=false
YES=false

# === ヘルプ ===
show_help() {
    cat <<'HELP'
Usage: post-merge-sync.sh [OPTIONS]

PRマージ後のworktree同期を自動化します。

処理内容:
  1. 親リポジトリで git pull origin main を実行
  2. worktreeをdetached HEAD状態にする
  3. マージ済みの cycle/ および upgrade/ ブランチをローカル・リモートから削除

Options:
  --dry-run   実際の操作を行わず実行予定を表示
  --yes       リモートブランチ削除の確認をスキップ
  --help      ヘルプを表示
HELP
}

# === 引数解析 ===
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --yes)
            YES=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "error:unknown-option:$1" >&2
            exit 1
            ;;
    esac
done

# === ヘルパー関数 ===

# リモートブランチ削除モードを判定する
# 出力: dry-run / yes / interactive-confirmed / skip
resolve_delete_mode() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "dry-run"
    elif [[ "$YES" == "true" ]]; then
        echo "yes"
    elif [[ ! -t 0 ]]; then
        # 非対話環境: 確認不能のためスキップ（安全デフォルト）
        echo "warn:non-interactive:リモートブランチ削除をスキップします（--yes で自動削除可能）" >&2
        echo "skip"
    else
        echo "" >&2
        read -rp "リモートブランチを削除しますか？ [y/N]: " answer
        if [[ "$answer" =~ ^[yY] ]]; then
            echo "interactive-confirmed"
        else
            echo "skip"
        fi
    fi
}

# リモートブランチの存在確認と削除を実行する
# 引数: $1 = ブランチ名
delete_remote_branch() {
    local branch="$1"
    local ls_remote_exit=0
    (cd "$PARENT_REPO" && git ls-remote --exit-code origin "refs/heads/$branch" >/dev/null 2>&1) || ls_remote_exit=$?

    if [[ "$ls_remote_exit" -eq 2 ]]; then
        echo "skipped:already-deleted:$branch"
    elif [[ "$ls_remote_exit" -ne 0 ]]; then
        echo "warn:remote-check-failed:$branch"
        WARN_COUNT=$((WARN_COUNT + 1))
    else
        local push_output
        push_output=$(cd "$PARENT_REPO" && git push origin --delete "$branch" 2>&1) && {
            echo "deleted:remote:$branch"
            return
        }
        echo "warn:remote-delete-failed:$branch" >&2
        echo "  detail: $push_output" >&2
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
}

# === Step 1: 実行環境の検出 ===
# worktree内から実行されているか確認
WORKTREE_DIR=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "error: gitリポジトリ内で実行してください" >&2
    exit 1
}

GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null) || {
    echo "error: git情報の取得に失敗しました" >&2
    exit 1
}

# 親リポジトリのパスを検出
# worktreeの場合: .git/commondir の親ディレクトリ
# メインの場合: そのまま
PARENT_REPO=$(cd "$GIT_COMMON_DIR" && cd .. && pwd)

# worktree内から実行されているか検証（メインリポジトリでの誤実行を防止）
if [[ "$WORKTREE_DIR" == "$PARENT_REPO" ]]; then
    echo "error: このスクリプトはworktree内から実行してください（メインリポジトリでは実行できません）" >&2
    exit 1
fi

echo "parent_repo:${PARENT_REPO}"
echo "worktree_dir:${WORKTREE_DIR}"

# === Step 2: 親リポジトリで git pull origin main ===
echo ""
echo "=== Step 1: 親リポジトリの更新 ==="

# 親リポジトリがmainブランチであることを確認
PARENT_BRANCH=$(cd "$PARENT_REPO" && git branch --show-current 2>/dev/null) || PARENT_BRANCH=""
if [[ "$PARENT_BRANCH" != "main" ]]; then
    echo "error: 親リポジトリがmainブランチではありません (current: ${PARENT_BRANCH:-detached HEAD})" >&2
    echo "" >&2
    echo "手動で以下を実行してください:" >&2
    echo "  cd ${PARENT_REPO}" >&2
    echo "  git checkout main" >&2
    echo "  git pull origin main" >&2
    exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] cd ${PARENT_REPO} && git pull --ff-only origin main"
else
    if ! (cd "$PARENT_REPO" && git pull --ff-only origin main); then
        echo "error: git pull origin main に失敗しました" >&2
        echo "" >&2
        echo "手動で以下を実行してください:" >&2
        echo "  cd ${PARENT_REPO}" >&2
        echo "  git pull origin main" >&2
        exit 1
    fi
    echo "ok:pull-complete"
fi

# === Step 3: worktreeをdetached HEAD状態にする ===
echo ""
echo "=== Step 2: worktreeのdetached HEAD化 ==="

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] cd ${WORKTREE_DIR} && git checkout --detach"
else
    if ! (cd "$WORKTREE_DIR" && git checkout --detach 2>/dev/null); then
        echo "error: worktreeのdetached HEAD化に失敗しました" >&2
        echo "" >&2
        echo "手動で以下を実行してください:" >&2
        echo "  cd ${WORKTREE_DIR}" >&2
        echo "  git checkout --detach" >&2
        exit 1
    fi
    echo "ok:detached"
fi

# === Step 4: マージ済みブランチの削除 ===
echo ""
echo "=== Step 3: マージ済みブランチの削除 ==="

WARN_COUNT=0

# ローカルのcycle/ + upgrade/ブランチを列挙
MERGED_BRANCHES=$(cd "$PARENT_REPO" && {
    git branch --list 'cycle/*' --merged main 2>/dev/null
    git branch --list 'upgrade/*' --merged main 2>/dev/null
} | sed 's/^[* ]*//' || true)

if [[ -z "$MERGED_BRANCHES" ]]; then
    echo "削除対象のマージ済みブランチはありません"
else
    echo "削除対象ブランチ:"
    echo "$MERGED_BRANCHES" | while read -r branch; do
        echo "  - $branch"
    done

    # ローカルブランチ削除
    echo ""
    echo "--- ローカルブランチ削除 ---"
    while read -r branch; do
        [[ -z "$branch" ]] && continue
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[dry-run] git branch -d $branch"
        else
            if (cd "$PARENT_REPO" && git branch -d "$branch" 2>/dev/null); then
                echo "deleted:local:$branch"
            else
                echo "warn:local-delete-failed:$branch"
                WARN_COUNT=$((WARN_COUNT + 1))
            fi
        fi
    done <<< "$MERGED_BRANCHES"

    # リモートブランチ削除
    echo ""
    echo "--- リモートブランチ削除 ---"

    # リモートのcycle/ + upgrade/ブランチを列挙
    REMOTE_MERGED_BRANCHES=$(cd "$PARENT_REPO" && {
        git branch -r --list 'origin/cycle/*' --merged main 2>/dev/null
        git branch -r --list 'origin/upgrade/*' --merged main 2>/dev/null
    } | sed 's|^ *origin/||' || true)

    if [[ -z "$REMOTE_MERGED_BRANCHES" ]]; then
        echo "削除対象のリモートマージ済みブランチはありません"
    else
        echo "削除対象リモートブランチ:"
        echo "$REMOTE_MERGED_BRANCHES" | while read -r branch; do
            echo "  - origin/$branch"
        done

        # モード判定: dry-run > --yes > 対話/非対話
        DELETE_MODE="$(resolve_delete_mode)"

        case "$DELETE_MODE" in
            dry-run)
                while read -r branch; do
                    [[ -z "$branch" ]] && continue
                    echo "[dry-run] git push origin --delete $branch"
                done <<< "$REMOTE_MERGED_BRANCHES"
                ;;
            yes|interactive-confirmed)
                while read -r branch; do
                    [[ -z "$branch" ]] && continue
                    delete_remote_branch "$branch"
                done <<< "$REMOTE_MERGED_BRANCHES"
                ;;
            skip)
                echo "skip:remote-delete"
                ;;
        esac
    fi
fi

echo ""
if [[ "$WARN_COUNT" -gt 0 ]]; then
    echo "status:warning"
else
    echo "status:success"
fi
exit 0
