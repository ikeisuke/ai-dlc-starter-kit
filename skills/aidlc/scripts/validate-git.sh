#!/usr/bin/env bash
#
# validate-git.sh - Git状態バリデーション
#
# 使用方法:
#   ./validate-git.sh <subcommand>
#
# SUBCOMMANDS:
#   uncommitted     未コミット変更の検出
#   remote-sync     リモート同期状態の検証
#   all             uncommitted → remote-sync を順次実行
#
# OPTIONS:
#   -h, --help      ヘルプを表示
#
# 出力形式（stdout）:
#   uncommitted:
#     status:{ok|warning|error}
#     warning時: files_count:{件数}, file:{porcelain行}
#     error時: error:<code>:<message>（例: error:git-status-failed:git status --porcelain failed）
#
#   remote-sync:
#     status:{ok|warning|error}
#     warning時: remote:{名前}, branch:{名前}, unpushed_commits:{件数}
#     error時: remote:{名前|unknown}, branch:{名前|unknown},
#              error:<code>:<message>（例: error:fetch-failed:git fetch origin failed）
#
#   all:
#     --- uncommitted ---
#     [uncommittedの出力]
#     --- remote-sync ---
#     [remote-syncの出力]
#     --- summary ---
#     status:{ok|warning|error}
#
# 終了コード:
#   0: 正常（ok/warning）
#   2: 操作エラー（git操作失敗等）
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"
source "${SCRIPT_DIR}/lib/validate.sh"

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: validate-git.sh <subcommand>

Git状態のバリデーションを行うスクリプト。

SUBCOMMANDS:
  uncommitted
      未コミット変更を検出します。
      status:ok（変更なし）またはstatus:warning（変更あり）を出力。

  remote-sync
      ローカルの全コミットがリモートにpush済みか検証します。
      status:ok（同期済み）またはstatus:warning（未push）を出力。

  all
      uncommitted → remote-sync を順次実行します。
      エラー発生時は以降のチェックをスキップします。
      末尾に総合結果（--- summary ---）を出力します。

OPTIONS:
  -h, --help    このヘルプを表示

出力形式:
  各サブコマンドの詳細はスクリプトヘッダを参照。
EOF
}

# --- 検証ロジック関数群 ---

run_uncommitted() {
    local files
    files=$(git status --porcelain 2>/dev/null) || {
        echo "status:error"
        emit_error "git-status-failed" "git status --porcelain failed"
        return 2
    }

    if [ -z "$files" ]; then
        echo "status:ok"
    else
        local count
        count=$(printf '%s\n' "$files" | wc -l | tr -d ' ')
        echo "status:warning"
        echo "files_count:${count}"
        printf '%s\n' "$files" | while IFS= read -r line; do
            echo "file:${line}"
        done
    fi
}

run_remote_sync() {
    # Step 0: ブランチ名・リモート名解決
    local branch
    branch=$(git branch --show-current 2>/dev/null) || true
    if [ -z "$branch" ]; then
        echo "status:error"
        echo "remote:unknown"
        echo "branch:unknown"
        emit_error "branch-unresolved" "Cannot determine current branch (detached HEAD?)"
        return 2
    fi

    local remote
    remote=$(git config "branch.${branch}.remote" 2>/dev/null || echo "origin")
    if [ -z "$remote" ]; then
        remote="origin"
    fi

    # Step A: リモートfetch（非対話モードで実行）
    if ! GIT_TERMINAL_PROMPT=0 git fetch -- "$remote" >/dev/null 2>&1; then
        echo "status:error"
        echo "remote:${remote}"
        echo "branch:${branch}"
        emit_error "fetch-failed" "git fetch ${remote} failed"
        return 2
    fi

    # Step B: 追跡ブランチ解決
    local remote_ref
    remote_ref=$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null || true)

    if [ -z "$remote_ref" ]; then
        if git show-ref --verify "refs/remotes/${remote}/${branch}" >/dev/null 2>&1; then
            remote_ref="${remote}/${branch}"
        else
            echo "status:error"
            echo "remote:${remote}"
            echo "branch:${branch}"
            emit_error "no-upstream" "No upstream tracking branch found for ${branch}"
            return 2
        fi
    fi

    # Step C: 未pushコミット検出
    local unpushed
    unpushed=$(git log "${remote_ref}..HEAD" --oneline 2>/dev/null) || {
        echo "status:error"
        echo "remote:${remote}"
        echo "branch:${branch}"
        emit_error "log-failed" "git log ${remote_ref}..HEAD failed"
        return 2
    }

    if [ -z "$unpushed" ]; then
        echo "status:ok"
    else
        local count
        count=$(printf '%s\n' "$unpushed" | wc -l | tr -d ' ')
        echo "status:warning"
        echo "remote:${remote}"
        echo "branch:${branch}"
        echo "unpushed_commits:${count}"
    fi
}

# --- サブコマンドディスパッチ ---

run_all() {
    local overall="ok"
    local output
    local exit_code

    # uncommittedチェック
    echo "--- uncommitted ---"
    exit_code=0
    output=$(run_uncommitted) || exit_code=$?
    printf '%s\n' "$output"

    if [ "$exit_code" -ne 0 ]; then
        overall="error"
        echo "--- summary ---"
        echo "status:${overall}"
        return 2
    fi
    if printf '%s\n' "$output" | grep -q "^status:warning"; then
        overall="warning"
    fi

    # remote-syncチェック
    echo "--- remote-sync ---"
    exit_code=0
    output=$(run_remote_sync) || exit_code=$?
    printf '%s\n' "$output"

    if [ "$exit_code" -ne 0 ]; then
        overall="error"
    elif printf '%s\n' "$output" | grep -q "^status:warning"; then
        if [ "$overall" != "error" ]; then
            overall="warning"
        fi
    fi

    echo "--- summary ---"
    echo "status:${overall}"

    if [ "$overall" = "error" ]; then
        return 2
    fi
}

# --- メイン ---

case "${1:-}" in
    uncommitted)
        run_uncommitted
        ;;
    remote-sync)
        run_remote_sync
        ;;
    all)
        run_all
        ;;
    -h|--help)
        show_help
        ;;
    "")
        emit_error "missing-subcommand" "サブコマンドを指定してください"
        echo "Usage: validate-git.sh <uncommitted|remote-sync|all>" >&2
        exit 1
        ;;
    *)
        emit_error "unknown-subcommand" "不明なサブコマンド: $1"
        echo "Usage: validate-git.sh <uncommitted|remote-sync|all>" >&2
        exit 1
        ;;
esac
