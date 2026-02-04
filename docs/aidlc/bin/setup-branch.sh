#!/usr/bin/env bash
# setup-branch.sh - ブランチ/worktree作成
#
# 使用方法:
#   setup-branch.sh <version> <mode>
#
# 引数:
#   version: サイクルバージョン（例: v1.12.1）
#   mode: branch または worktree
#
# 出力形式:
#   status:success|already_exists|error
#   branch:cycle/v1.12.1
#   worktree_path:.worktree/cycle-v1.12.1  (worktreeモードのみ)
#   message:詳細メッセージ

set -euo pipefail

# 使用方法を表示
usage() {
    echo "使用方法: $0 <version> <mode>"
    echo "  version: サイクルバージョン（例: v1.12.1）"
    echo "  mode: branch または worktree"
    exit 1
}

# 出力ヘルパー
output() {
    local status="$1"
    local branch="$2"
    local worktree_path="${3:-}"
    local message="$4"

    echo "status:${status}"
    echo "branch:${branch}"
    if [[ -n "$worktree_path" ]]; then
        echo "worktree_path:${worktree_path}"
    fi
    echo "message:${message}"
}

# ブランチが存在するか確認
branch_exists() {
    local branch="$1"
    git show-ref --verify "refs/heads/${branch}" >/dev/null 2>&1
}

# worktreeが存在するか確認
worktree_exists() {
    local path="$1"
    git worktree list --porcelain 2>/dev/null | grep -q "^worktree.*${path}$"
}

# ブランチモード
handle_branch_mode() {
    local version="$1"
    local branch="cycle/${version}"

    if branch_exists "$branch"; then
        # 既存ブランチに切り替え
        if git checkout "$branch" 2>/dev/null; then
            output "already_exists" "$branch" "" "既存のブランチ ${branch} に切り替えました"
        else
            output "error" "$branch" "" "ブランチの切り替えに失敗しました"
            return 1
        fi
    else
        # 新規ブランチを作成して切り替え
        if git checkout -b "$branch" 2>/dev/null; then
            output "success" "$branch" "" "新しいブランチ ${branch} を作成して切り替えました"
        else
            output "error" "$branch" "" "ブランチの作成に失敗しました"
            return 1
        fi
    fi
}

# worktreeモード
handle_worktree_mode() {
    local version="$1"
    local branch="cycle/${version}"
    local worktree_path=".worktree/cycle-${version}"

    # worktreeが既に登録されているか確認
    if worktree_exists "$worktree_path"; then
        output "already_exists" "$branch" "$worktree_path" "worktree ${worktree_path} は既に存在します"
        return 0
    fi

    # ディレクトリは存在するがworktreeとして登録されていない場合
    if [[ -d "$worktree_path" ]]; then
        output "error" "$branch" "$worktree_path" "ディレクトリ ${worktree_path} が存在しますがworktreeとして登録されていません"
        return 1
    fi

    # .worktreeディレクトリを作成
    mkdir -p .worktree

    if branch_exists "$branch"; then
        # 既存ブランチでworktreeを作成
        if git worktree add "$worktree_path" "$branch" 2>/dev/null; then
            output "success" "$branch" "$worktree_path" "既存ブランチ ${branch} でworktreeを作成しました"
        else
            output "error" "$branch" "$worktree_path" "worktreeの作成に失敗しました"
            return 1
        fi
    else
        # 新規ブランチとworktreeを同時に作成
        if git worktree add -b "$branch" "$worktree_path" 2>/dev/null; then
            output "success" "$branch" "$worktree_path" "新しいブランチ ${branch} でworktreeを作成しました"
        else
            output "error" "$branch" "$worktree_path" "worktreeの作成に失敗しました"
            return 1
        fi
    fi
}

# メイン処理
main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    local version="$1"
    local mode="$2"

    # バージョン形式の検証
    if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        output "error" "" "" "無効なバージョン形式: ${version}（vX.Y.Z形式で指定してください）"
        return 1
    fi

    case "$mode" in
        branch)
            handle_branch_mode "$version"
            ;;
        worktree)
            handle_worktree_mode "$version"
            ;;
        *)
            output "error" "" "" "無効なモード: ${mode}（branch または worktree を指定してください）"
            return 1
            ;;
    esac
}

main "$@"
