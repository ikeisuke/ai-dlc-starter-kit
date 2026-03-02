#!/usr/bin/env bash
#
# post-merge-cleanup.sh - PRマージ後のworktreeクリーンアップ
#
# 使用方法:
#   ./post-merge-cleanup.sh --cycle <VERSION> [--dry-run]
#
# 引数:
#   --cycle <VERSION>   サイクルバージョン（例: v1.5.3）
#   --dry-run           コマンドを実行せず、実行予定を表示
#   -h, --help          ヘルプを表示
#
# 処理ステップ:
#   0a: 実行環境検証（worktree判定、メインリポジトリ特定）
#   0b: 作業状態検証（未コミット変更、未pushコミット）
#   1:  メインリポジトリでpull
#   2:  worktreeでfetch
#   3:  detached HEADに切り替え
#   4:  ローカルブランチ削除
#   5:  リモートブランチ削除
#
# 出力形式（stdout）:
#   step:<N>:<名前>                    ステップ開始
#   step_result:<N>:ok                 ステップ成功
#   step_result:<N>:warning:<code>     非致命的エラー
#   step_result:<N>:error:<code>       致命的エラー
#   step:dry-run:<コマンド>            dry-runモード
#   main_repo_path:<パス>              メインリポジトリパス
#   branch:<ブランチ名>               対象ブランチ
#   status:success|warning|error       最終結果
#   message:<テキスト>                 説明メッセージ
#
# 終了コード:
#   0: success / warning / dry-run
#   1: error（致命的エラー）

set -euo pipefail

# --- グローバル変数 ---
CYCLE=""
DRY_RUN=false
MAIN_REPO_PATH=""
BRANCH_NAME=""
MAIN_REMOTE=""
DEFAULT_BRANCH=""
WT_REMOTE=""
WT_DEFAULT_BRANCH=""
OVERALL="success"

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: post-merge-cleanup.sh --cycle <VERSION> [--dry-run]

PRマージ後のworktreeクリーンアップを実行するスクリプト。

OPTIONS:
  --cycle <VERSION>   サイクルバージョン（必須、例: v1.5.3）
  --dry-run           コマンドを実行せず、実行予定を表示
  -h, --help          このヘルプを表示

STEPS:
  0a: 実行環境検証
  0b: 作業状態検証
  1:  メインリポジトリでpull
  2:  worktreeでfetch
  3:  detached HEADに切り替え
  4:  ローカルブランチ削除
  5:  リモートブランチ削除

出力形式:
  各ステップの詳細はスクリプトヘッダを参照。
EOF
}

# --- ユーティリティ関数 ---

# 致命的エラーで中断
fatal_error() {
    local step="$1"
    local code="$2"
    local msg="$3"

    echo "step_result:${step}:error:${code}"
    echo "status:error"
    echo "message:${msg}"
    echo "Error: ${msg}" >&2
    exit 1
}

# リモート名をgit remote一覧で検証
validate_remote() {
    local repo_path="$1"
    local remote="$2"
    git -C "$repo_path" remote | grep -Fqx -- "$remote"
}

# リモートのデフォルトブランチを解決
resolve_default_branch() {
    local repo_path="$1"
    local remote="$2"
    local ref

    # 1. symbolic-refから解決
    ref=$(git -C "$repo_path" symbolic-ref "refs/remotes/${remote}/HEAD" 2>/dev/null || true)
    if [ -n "$ref" ]; then
        # refs/remotes/<remote>/ プレフィックスを除去（スラッシュ含みブランチ名に対応）
        local prefix="refs/remotes/${remote}/"
        printf '%s\n' "${ref#"$prefix"}"
        return
    fi

    # 2. main/masterの存在確認でフォールバック
    if git -C "$repo_path" show-ref --verify "refs/remotes/${remote}/main" >/dev/null 2>&1; then
        printf '%s\n' "main"
    elif git -C "$repo_path" show-ref --verify "refs/remotes/${remote}/master" >/dev/null 2>&1; then
        printf '%s\n' "master"
    else
        printf '%s\n' "main"
    fi
}

# --- 処理ステップ ---

step_0a() {
    echo "step:0a:実行環境検証"

    # worktree環境判定
    local git_dir toplevel
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
        fatal_error "0a" "not-in-worktree" "gitリポジトリ内ではありません"
    }
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
        fatal_error "0a" "not-in-worktree" "gitリポジトリのトップレベルを取得できません"
    }

    # 通常リポジトリの--git-dirは<toplevel>/.git、worktreeは.git/worktrees/<name>形式
    local abs_git_dir
    if [[ "$git_dir" = /* ]]; then
        abs_git_dir="$git_dir"
    else
        abs_git_dir="${toplevel}/${git_dir}"
    fi

    if [ "$abs_git_dir" = "${toplevel}/.git" ]; then
        fatal_error "0a" "not-in-worktree" "このスクリプトはworktree環境でのみ実行できます"
    fi

    # メインリポジトリパスを特定（git worktree list --porcelainから属性ベースで検出）
    local worktree_output main_worktree_path=""
    worktree_output=$(git worktree list --porcelain 2>/dev/null) || {
        fatal_error "0a" "main-repo-detection-failed" "git worktree listの実行に失敗しました"
    }

    # porcelain形式: 各worktreeはブランク行で区切られる
    # 最初のworktreeエントリがメインリポジトリ（ルートworktree）
    # ただし属性ベースで判定: "bare"行がなく、最初のworktreeブロックのパスを使用
    local current_path="" is_first=true
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" == worktree\ * ]]; then
            current_path="${line#worktree }"
        elif [ -z "$line" ] || [ -z "${line+x}" ]; then
            if [ "$is_first" = true ] && [ -n "$current_path" ]; then
                main_worktree_path="$current_path"
                break
            fi
            is_first=false
            current_path=""
        fi
    done <<< "$worktree_output"

    # 最後のブロック（改行なしで終わる場合）
    if [ -z "$main_worktree_path" ] && [ "$is_first" = true ] && [ -n "$current_path" ]; then
        main_worktree_path="$current_path"
    fi

    if [ -z "$main_worktree_path" ]; then
        fatal_error "0a" "main-repo-detection-failed" "メインリポジトリのパスを特定できませんでした"
    fi

    MAIN_REPO_PATH="$main_worktree_path"
    echo "main_repo_path:${MAIN_REPO_PATH}"

    # サイクルブランチの存在確認
    BRANCH_NAME="cycle/${CYCLE}"
    if ! git show-ref --verify "refs/heads/${BRANCH_NAME}" >/dev/null 2>&1; then
        fatal_error "0a" "branch-not-found" "ブランチ ${BRANCH_NAME} が存在しません"
    fi
    echo "branch:${BRANCH_NAME}"

    echo "step_result:0a:ok"
}

step_0b() {
    echo "step:0b:作業状態検証"

    # 未コミット変更チェック
    local status_output
    status_output=$(git status --porcelain 2>/dev/null) || true
    if [ -n "$status_output" ]; then
        fatal_error "0b" "uncommitted-changes" "未コミットの変更があります。先にコミットまたはstashしてください"
    fi

    # 未pushコミットチェック（upstream未設定時はスキップ）
    local upstream
    upstream=$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null || true)
    if [ -n "$upstream" ]; then
        local unpushed
        unpushed=$(git log "${upstream}..HEAD" --oneline 2>/dev/null || true)
        if [ -n "$unpushed" ]; then
            fatal_error "0b" "unpushed-commits" "未pushのコミットがあります。先にpushしてください"
        fi
    fi

    echo "step_result:0b:ok"
}

step_1() {
    echo "step:1:メインリポジトリpull"

    # メインリポジトリ用のリモート・デフォルトブランチ解決
    # 1. リモート決定: originが存在すればorigin、なければ最初のリモート
    if git -C "$MAIN_REPO_PATH" remote | grep -q "^origin$"; then
        MAIN_REMOTE="origin"
    else
        MAIN_REMOTE=$(git -C "$MAIN_REPO_PATH" remote | head -1)
        if [ -z "$MAIN_REMOTE" ]; then
            fatal_error "1" "pull-failed" "メインリポジトリにリモートが設定されていません"
        fi
    fi
    # 2. デフォルトブランチ特定
    DEFAULT_BRANCH=$(resolve_default_branch "$MAIN_REPO_PATH" "$MAIN_REMOTE")
    # 3. デフォルトブランチの設定からリモートを再解決
    local configured_remote
    configured_remote=$(git -C "$MAIN_REPO_PATH" config "branch.${DEFAULT_BRANCH}.remote" 2>/dev/null || true)
    if [ -n "$configured_remote" ]; then
        if validate_remote "$MAIN_REPO_PATH" "$configured_remote"; then
            MAIN_REMOTE="$configured_remote"
            DEFAULT_BRANCH=$(resolve_default_branch "$MAIN_REPO_PATH" "$MAIN_REMOTE")
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "step:dry-run:git -C ${MAIN_REPO_PATH} checkout ${DEFAULT_BRANCH}"
        echo "step:dry-run:git -C ${MAIN_REPO_PATH} pull ${MAIN_REMOTE} ${DEFAULT_BRANCH}"
        echo "step_result:1:ok"
        return
    fi

    # デフォルトブランチをチェックアウト（メインリポジトリが別ブランチにいる場合に備える）
    if ! git -C "$MAIN_REPO_PATH" checkout "$DEFAULT_BRANCH" >/dev/null 2>&1; then
        fatal_error "1" "pull-failed" "メインリポジトリのデフォルトブランチへのチェックアウトに失敗しました: git -C ${MAIN_REPO_PATH} checkout ${DEFAULT_BRANCH}"
    fi

    if ! GIT_TERMINAL_PROMPT=0 git -C "$MAIN_REPO_PATH" pull -- "$MAIN_REMOTE" "$DEFAULT_BRANCH" >/dev/null 2>&1; then
        fatal_error "1" "pull-failed" "メインリポジトリのpullに失敗しました: git -C ${MAIN_REPO_PATH} pull ${MAIN_REMOTE} ${DEFAULT_BRANCH}"
    fi

    echo "step_result:1:ok"
}

step_2() {
    echo "step:2:worktreeでfetch"

    # worktree用のリモート解決
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || true)
    WT_REMOTE=""
    if [ -n "$current_branch" ]; then
        local branch_remote
        branch_remote=$(git config "branch.${current_branch}.remote" 2>/dev/null || true)
        if [ -n "$branch_remote" ] && validate_remote "." "$branch_remote"; then
            WT_REMOTE="$branch_remote"
        fi
    fi
    if [ -z "$WT_REMOTE" ]; then
        if git remote | grep -q "^origin$"; then
            WT_REMOTE="origin"
        else
            WT_REMOTE=$(git remote | head -1)
            if [ -z "$WT_REMOTE" ]; then
                fatal_error "2" "fetch-failed" "リモートが設定されていません"
            fi
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "step:dry-run:git fetch ${WT_REMOTE}"
        echo "step_result:2:ok"
        return
    fi

    if ! GIT_TERMINAL_PROMPT=0 git fetch -- "$WT_REMOTE" >/dev/null 2>&1; then
        fatal_error "2" "fetch-failed" "fetchに失敗しました: git fetch ${WT_REMOTE}"
    fi

    echo "step_result:2:ok"
}

step_3() {
    echo "step:3:detached HEAD切り替え"

    # WT_REMOTEのデフォルトブランチ解決
    WT_DEFAULT_BRANCH=$(resolve_default_branch "." "$WT_REMOTE")

    if [ "$DRY_RUN" = true ]; then
        echo "step:dry-run:git checkout --detach ${WT_REMOTE}/${WT_DEFAULT_BRANCH}"
        echo "step_result:3:ok"
        return
    fi

    if ! git checkout --detach "${WT_REMOTE}/${WT_DEFAULT_BRANCH}" >/dev/null 2>&1; then
        fatal_error "3" "detach-failed" "detached HEADへの切り替えに失敗しました: git checkout --detach ${WT_REMOTE}/${WT_DEFAULT_BRANCH}"
    fi

    echo "step_result:3:ok"
}

step_4() {
    echo "step:4:ローカルブランチ削除"

    if [ "$DRY_RUN" = true ]; then
        echo "step:dry-run:git branch -d ${BRANCH_NAME}"
        echo "step_result:4:ok"
        return
    fi

    if ! git branch -d "$BRANCH_NAME" >/dev/null 2>&1; then
        echo "step_result:4:warning:local-branch-delete-failed"
        echo "message:ローカルブランチ削除に失敗しました。手動で実行してください: git branch -d ${BRANCH_NAME}"
        OVERALL="warning"
        return
    fi

    echo "step_result:4:ok"
}

step_5() {
    echo "step:5:リモートブランチ削除"

    if [ "$DRY_RUN" = true ]; then
        echo "step:dry-run:git push ${WT_REMOTE} --delete ${BRANCH_NAME}"
        echo "step_result:5:ok"
        return
    fi

    if ! GIT_TERMINAL_PROMPT=0 git push "$WT_REMOTE" --delete -- "$BRANCH_NAME" >/dev/null 2>&1; then
        echo "step_result:5:warning:remote-branch-delete-failed"
        echo "message:リモートブランチ削除に失敗しました。手動で実行してください: git push ${WT_REMOTE} --delete ${BRANCH_NAME}"
        OVERALL="warning"
        return
    fi

    echo "step_result:5:ok"
}

# --- 引数パース ---

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --cycle)
                if [ -z "${2:-}" ]; then
                    echo "Error: --cycle にはバージョンを指定してください" >&2
                    exit 1
                fi
                CYCLE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Error: 不明なオプション: $1" >&2
                echo "Usage: post-merge-cleanup.sh --cycle <VERSION> [--dry-run]" >&2
                exit 1
                ;;
        esac
    done

    if [ -z "$CYCLE" ]; then
        echo "Error: --cycle は必須です" >&2
        echo "Usage: post-merge-cleanup.sh --cycle <VERSION> [--dry-run]" >&2
        exit 1
    fi

    # バージョン形式バリデーション
    if ! printf '%s\n' "$CYCLE" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
        echo "Error: バージョン形式が不正です: ${CYCLE}（例: v1.5.3）" >&2
        exit 1
    fi
}

# --- メイン ---

main() {
    parse_args "$@"

    step_0a
    step_0b
    step_1
    step_2
    step_3
    step_4
    step_5

    echo "status:${OVERALL}"
    if [ "$DRY_RUN" = true ]; then
        echo "message:dry-run完了（実際のコマンドは実行されていません）"
    elif [ "$OVERALL" = "success" ]; then
        echo "message:クリーンアップが完了しました"
    fi
}

main "$@"
