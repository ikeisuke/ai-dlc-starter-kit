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
#     status:{ok|warning|diverged|error}
#     warning時 (unpushed): remote:{名前}, branch:{名前}, unpushed_commits:{件数}
#     warning時 (behind):   remote:{名前}, branch:{名前}, behind_commits:{件数}
#     diverged時: remote:{名前}, branch:{名前}, diverged_ahead:{件数}, diverged_behind:{件数},
#                 recommended_command:{解決済みforce-with-leaseコマンド}
#     error時: remote:{名前|unknown}, branch:{名前|unknown},
#              error:<code>:<message>
#              <code> ∈ {fetch-failed, no-upstream, branch-unresolved,
#                       merge-base-failed, upstream-resolve-failed, log-failed}
#
#   all:
#     --- uncommitted ---
#     [uncommittedの出力]
#     --- remote-sync ---
#     [remote-syncの出力]
#     --- summary ---
#     status:{ok|warning|diverged|error}
#     - ok: 全サブチェック正常
#     - warning: いずれかが warning 相当（unpushed / uncommitted あり等）
#     - diverged: remote-sync が diverged（squash 後等、warning より優先して表示）
#     - error: いずれかが error（blocking）
#
# 終了コード:
#   0: 正常（ok/warning/diverged）
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
      ローカル HEAD と upstream の双方向 ancestry を判定し、同期状態を分類します。
      status:ok（完全一致）／status:warning（未push or behind）／
      status:diverged（双方向に差分、squash 後等）／status:error を出力。

  all
      uncommitted → remote-sync を順次実行します。
      エラー発生時は以降のチェックをスキップします。
      末尾に総合結果（--- summary ---）を出力します（status: ok|warning|diverged|error）。

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
    # Step 1: CurrentBranch 解決
    local branch
    branch=$(git branch --show-current 2>/dev/null) || true
    if [ -z "$branch" ]; then
        echo "status:error"
        echo "remote:unknown"
        echo "branch:unknown"
        emit_error "branch-unresolved" "Cannot determine current branch (detached HEAD?)"
        return 2
    fi

    # Step 2: Upstream config 解決（ローカル git config のみ、network 不要）
    local remote
    remote=$(git config "branch.${branch}.remote" 2>/dev/null || echo "origin")
    if [ -z "$remote" ]; then
        remote="origin"
    fi

    # upstream branch 名を branch.*.merge から解決（一次ソース、異名 upstream 対応）
    # - branch.*.merge 未設定 → no-upstream（追跡ブランチ未設定、最も一般的）
    # - branch.*.merge が refs/heads/* 以外 → upstream-resolve-failed（不正設定）
    local merge_ref
    merge_ref=$(git config "branch.${branch}.merge" 2>/dev/null || true)
    if [ -z "$merge_ref" ]; then
        echo "status:error"
        echo "remote:${remote}"
        echo "branch:${branch}"
        emit_error "no-upstream" "No upstream tracking branch configured (branch.${branch}.merge is not set)"
        return 2
    fi
    local upstream_branch
    case "$merge_ref" in
        refs/heads/*)
            upstream_branch="${merge_ref#refs/heads/}"
            ;;
        *)
            echo "status:error"
            echo "remote:${remote}"
            echo "branch:${branch}"
            emit_error "upstream-resolve-failed" "branch.${branch}.merge has invalid format: ${merge_ref}"
            return 2
            ;;
    esac

    # Step 3: FetchExecutor（非対話モードで実行）
    if ! GIT_TERMINAL_PROMPT=0 git fetch -- "$remote" >/dev/null 2>&1; then
        echo "status:error"
        echo "remote:${remote}"
        echo "branch:${branch}"
        emit_error "fetch-failed" "git fetch ${remote} failed"
        return 2
    fi

    # Step 4: Upstream tracking ref の存在確認（fetch 後、異名 upstream 対応）
    local remote_ref="${remote}/${upstream_branch}"
    if ! git show-ref --verify "refs/remotes/${remote_ref}" >/dev/null 2>&1; then
        echo "status:error"
        echo "remote:${remote}"
        echo "branch:${branch}"
        emit_error "no-upstream" "No upstream tracking branch found: refs/remotes/${remote_ref}"
        return 2
    fi

    # Step 5: AncestryResolver - 双方向 ancestry を必ず両方取得（片方だけで早期 return しない）
    # merge-base --is-ancestor は 0=祖先, 1=祖先でない, 2以上=システムエラー
    # set -e 下で exit 1 がスクリプト終了を引き起こさないよう、一時的に set +e で囲む
    local a_ec b_ec
    set +e
    git merge-base --is-ancestor "${remote_ref}" HEAD >/dev/null 2>&1
    a_ec=$?
    git merge-base --is-ancestor HEAD "${remote_ref}" >/dev/null 2>&1
    b_ec=$?
    set -e

    # システムエラー判定（どちらかが exit 2 以上）
    if [ "$a_ec" -ge 2 ] || [ "$b_ec" -ge 2 ]; then
        echo "status:error"
        echo "remote:${remote}"
        echo "branch:${branch}"
        emit_error "merge-base-failed" "git merge-base --is-ancestor failed (a_ec=${a_ec}, b_ec=${b_ec})"
        return 2
    fi

    # Step 6: CommitCountResolver - ahead/behind を両方取得
    local ahead_count behind_count
    ahead_count=$(git rev-list --count "${remote_ref}..HEAD" 2>/dev/null) || {
        echo "status:error"
        echo "remote:${remote}"
        echo "branch:${branch}"
        emit_error "log-failed" "git rev-list --count ${remote_ref}..HEAD failed"
        return 2
    }
    behind_count=$(git rev-list --count "HEAD..${remote_ref}" 2>/dev/null) || {
        echo "status:error"
        echo "remote:${remote}"
        echo "branch:${branch}"
        emit_error "log-failed" "git rev-list --count HEAD..${remote_ref} failed"
        return 2
    }

    # Step 7: RemoteSyncStateClassifier + StatusLineRenderer
    # 2 ビット真理値表で 4 状態に分類（A=a_ec==0, B=b_ec==0）
    if [ "$a_ec" -eq 0 ] && [ "$b_ec" -eq 0 ]; then
        # (true, true): 完全一致
        echo "status:ok"
    elif [ "$a_ec" -eq 0 ] && [ "$b_ec" -ne 0 ]; then
        # (true, false): unpushed（HEAD が upstream を追い越し、既存互換）
        echo "status:warning"
        echo "remote:${remote}"
        echo "branch:${branch}"
        echo "unpushed_commits:${ahead_count}"
    elif [ "$a_ec" -ne 0 ] && [ "$b_ec" -eq 0 ]; then
        # (false, true): behind（upstream が HEAD を追い越し、新規分類）
        echo "status:warning"
        echo "remote:${remote}"
        echo "branch:${branch}"
        echo "behind_commits:${behind_count}"
    else
        # (false, false): diverged（双方向に差分、新規ステータス）
        echo "status:diverged"
        echo "remote:${remote}"
        echo "branch:${branch}"
        echo "diverged_ahead:${ahead_count}"
        echo "diverged_behind:${behind_count}"
        echo "recommended_command:git push --force-with-lease ${remote} HEAD:${upstream_branch}"
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
    elif printf '%s\n' "$output" | grep -q "^status:diverged"; then
        if [ "$overall" != "error" ]; then
            overall="diverged"
        fi
    elif printf '%s\n' "$output" | grep -q "^status:warning"; then
        if [ "$overall" != "error" ] && [ "$overall" != "diverged" ]; then
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
