#!/usr/bin/env bash
#
# post-merge-sync.sh - PRマージ後のworktree同期スクリプト
#
# 親リポジトリのmain pull、worktreeのdetached HEAD化、
# マージ済みサイクルブランチの削除を自動化する。
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
  3. マージ済みの cycle/ ブランチをローカル・リモートから削除

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

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] cd ${PARENT_REPO} && git pull origin main"
else
    if ! (cd "$PARENT_REPO" && git pull origin main); then
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

# === Step 4: マージ済みサイクルブランチの削除 ===
echo ""
echo "=== Step 3: マージ済みサイクルブランチの削除 ==="

DELETE_FAILED=false

# ローカルのcycle/ブランチを列挙
CYCLE_BRANCHES=$(cd "$PARENT_REPO" && git branch --list 'cycle/*' --merged main 2>/dev/null | sed 's/^[* ]*//' || true)

if [[ -z "$CYCLE_BRANCHES" ]]; then
    echo "削除対象のサイクルブランチはありません"
else
    echo "削除対象ブランチ:"
    echo "$CYCLE_BRANCHES" | while read -r branch; do
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
                DELETE_FAILED=true
            fi
        fi
    done <<< "$CYCLE_BRANCHES"

    # リモートブランチ削除
    echo ""
    echo "--- リモートブランチ削除 ---"

    # リモートのcycle/ブランチを列挙
    REMOTE_CYCLE_BRANCHES=$(cd "$PARENT_REPO" && git branch -r --list 'origin/cycle/*' --merged main 2>/dev/null | sed 's|^ *origin/||' || true)

    if [[ -z "$REMOTE_CYCLE_BRANCHES" ]]; then
        echo "削除対象のリモートサイクルブランチはありません"
    else
        echo "削除対象リモートブランチ:"
        echo "$REMOTE_CYCLE_BRANCHES" | while read -r branch; do
            echo "  - origin/$branch"
        done

        # 確認プロンプト
        if [[ "$DRY_RUN" == "true" ]]; then
            while read -r branch; do
                [[ -z "$branch" ]] && continue
                echo "[dry-run] git push origin --delete $branch"
            done <<< "$REMOTE_CYCLE_BRANCHES"
        elif [[ "$YES" == "true" ]]; then
            while read -r branch; do
                [[ -z "$branch" ]] && continue
                if (cd "$PARENT_REPO" && git push origin --delete "$branch" 2>/dev/null); then
                    echo "deleted:remote:$branch"
                else
                    echo "warn:remote-delete-failed:$branch"
                    DELETE_FAILED=true
                fi
            done <<< "$REMOTE_CYCLE_BRANCHES"
        else
            echo ""
            read -rp "リモートブランチを削除しますか？ [y/N]: " answer
            if [[ "$answer" =~ ^[yY] ]]; then
                while read -r branch; do
                    [[ -z "$branch" ]] && continue
                    if (cd "$PARENT_REPO" && git push origin --delete "$branch" 2>/dev/null); then
                        echo "deleted:remote:$branch"
                    else
                        echo "warn:remote-delete-failed:$branch"
                        DELETE_FAILED=true
                    fi
                done <<< "$REMOTE_CYCLE_BRANCHES"
            else
                echo "skip:remote-delete"
            fi
        fi
    fi
fi

echo ""
if [[ "$DELETE_FAILED" == "true" ]]; then
    echo "status:partial-failure"
    exit 1
else
    echo "status:success"
    exit 0
fi
