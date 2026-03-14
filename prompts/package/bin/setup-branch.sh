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
#   main_status:up-to-date|behind|fetch-failed  (オプション、成功時のみ)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/validate.sh"

# 使用方法を表示
usage() {
    echo "使用方法: $0 <version> <mode>"
    echo "  version: サイクルバージョン（例: v1.12.1）"
    echo "  mode: branch または worktree"
    exit 1
}

# 出力ヘルパー
# 引数: $1=status, $2=branch, $3=worktree_path, $4=message, $5=error_code(エラー時のみ)
output() {
    local status="$1"
    local branch="$2"
    local worktree_path="${3:-}"
    local message="$4"
    local error_code="${5:-}"

    echo "status:${status}"
    echo "branch:${branch}"
    if [[ -n "$worktree_path" ]]; then
        echo "worktree_path:${worktree_path}"
    fi
    echo "message:${message}"
    if [[ -n "$error_code" ]]; then
        echo "error_code:${error_code}"
    fi
}

# ブランチが存在するか確認
branch_exists() {
    local branch="$1"
    git show-ref --verify "refs/heads/${branch}" >/dev/null 2>&1
}

# worktreeが存在するか確認
worktree_exists() {
    local path="$1"
    # 相対パスを絶対パスに変換（git worktree listは絶対パスを出力するため）
    local abs_path
    # realpath優先、利用不可または失敗時はcd+pwdにフォールバック
    if command -v realpath >/dev/null 2>&1 && abs_path=$(realpath "$path" 2>/dev/null); then
        : # realpathで変換成功
    else
        abs_path="$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")" 2>/dev/null || abs_path="$(pwd)/$path"
    fi
    # -F: 固定文字列マッチ（.などの正規表現文字を無効化）
    git worktree list --porcelain 2>/dev/null | grep -qF "$abs_path"
}

# mainブランチの最新化チェック
check_main_freshness() {
    local target_ref="${1:-HEAD}"

    # fetch（GIT_TERMINAL_PROMPT=0で非対話、失敗時はfetch-failedで即return）
    if ! GIT_TERMINAL_PROMPT=0 git fetch -- origin >/dev/null 2>&1; then
        echo "main_status:fetch-failed"
        return 0
    fi

    # リモートのデフォルトブランチ検出（get-default-branch.shと同じロジック）
    local remote_main=""
    local default_branch
    default_branch=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
    if [[ -n "$default_branch" ]]; then
        remote_main="origin/${default_branch}"
    elif git rev-parse --verify origin/main >/dev/null 2>&1; then
        remote_main="origin/main"
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
        remote_main="origin/master"
    else
        echo "main_status:fetch-failed"
        return 0
    fi

    # 最新化判定: remote_mainがtarget_refの祖先かを確認
    if git merge-base --is-ancestor "$remote_main" "$target_ref" 2>/dev/null; then
        echo "main_status:up-to-date"
    else
        echo "main_status:behind"
    fi

    return 0
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
            output "error" "$branch" "" "ブランチの切り替えに失敗しました" "branch-checkout-failed"
            return 1
        fi
    else
        # 新規ブランチを作成して切り替え
        if git checkout -b "$branch" 2>/dev/null; then
            output "success" "$branch" "" "新しいブランチ ${branch} を作成して切り替えました"
        else
            output "error" "$branch" "" "ブランチの作成に失敗しました" "branch-creation-failed"
            return 1
        fi
    fi
}

# worktreeモード
handle_worktree_mode() {
    local version="$1"
    local branch="cycle/${version}"
    local worktree_path=".worktree/cycle-${version//\//-}"

    # worktreeが既に登録されているか確認
    if worktree_exists "$worktree_path"; then
        output "already_exists" "$branch" "$worktree_path" "worktree ${worktree_path} は既に存在します"
        return 0
    fi

    # ディレクトリは存在するがworktreeとして登録されていない場合
    if [[ -d "$worktree_path" ]]; then
        output "error" "$branch" "$worktree_path" "ディレクトリ ${worktree_path} が存在しますがworktreeとして登録されていません" "directory-exists-not-registered"
        return 1
    fi

    # .worktreeディレクトリを作成
    mkdir -p .worktree

    if branch_exists "$branch"; then
        # 既存ブランチでworktreeを作成
        if git worktree add "$worktree_path" "$branch" 2>/dev/null; then
            output "success" "$branch" "$worktree_path" "既存ブランチ ${branch} でworktreeを作成しました"
        else
            output "error" "$branch" "$worktree_path" "worktreeの作成に失敗しました" "worktree-creation-failed"
            return 1
        fi
    else
        # 新規ブランチとworktreeを同時に作成
        if git worktree add -b "$branch" "$worktree_path" 2>/dev/null; then
            output "success" "$branch" "$worktree_path" "新しいブランチ ${branch} でworktreeを作成しました"
        else
            output "error" "$branch" "$worktree_path" "worktreeの作成に失敗しました" "worktree-creation-failed"
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

    # サイクル名の検証（共通ライブラリ使用）
    if ! validate_cycle "$version"; then
        output "error" "" "" "無効なバージョン形式: ${version}（英小文字・数字・ハイフン・ドットで構成し、パストラバーサル（..）は許可されていません）" "invalid-version-format"
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
            output "error" "" "" "無効なモード: ${mode}（branch または worktree を指定してください）" "invalid-mode"
            return 1
            ;;
    esac

    # ブランチ/worktree作成成功後にmain最新化チェック
    # サイクルブランチのHEADを判定対象にする
    check_main_freshness "cycle/${version}"
}

main "$@"
