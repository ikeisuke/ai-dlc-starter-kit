#!/usr/bin/env bash
#
# post-merge-cleanup.sh - PRマージ後のクリーンアップ
#
# worktree環境と通常ブランチ環境の両方に対応。
# 実行環境を自動判定し、適切なクリーンアップフローを実行する。
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
#   0a: 実行環境検証（worktree/通常ブランチ判定、リポジトリパス特定）
#   0b: 作業状態検証（未コミット変更、未pushコミット）
#   1:  デフォルトブランチ更新
#   2:  fetch
#   3:  ブランチ状態整理（worktree: detached HEAD、通常ブランチ: スキップ）
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
IS_WORKTREE=""
LOCAL_BRANCH_EXISTS=true
OVERALL="success"

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: post-merge-cleanup.sh --cycle <VERSION> [--dry-run]

PRマージ後のクリーンアップを実行するスクリプト。
worktree環境と通常ブランチ環境の両方に対応。

OPTIONS:
  --cycle <VERSION>   サイクルバージョン（必須、例: v1.5.3）
  --dry-run           コマンドを実行せず、実行予定を表示
  -h, --help          このヘルプを表示

STEPS:
  0a: 実行環境検証（worktree/通常ブランチ自動判定）
  0b: 作業状態検証
  1:  デフォルトブランチ更新
  2:  fetch
  3:  ブランチ状態整理
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

# 共通タイブレーク規則: 候補リストからoriginを優先して1件選択
# 引数:
#   stdin - 候補リモート名（1行1件）
# 出力: stdout にリモート名（1行）。候補なしの場合は空
_select_remote_candidate() {
    local candidates
    candidates=$(cat)
    if [ -z "$candidates" ]; then
        return
    fi
    if printf '%s\n' "$candidates" | grep -Fqx "origin"; then
        printf '%s\n' "origin"
    else
        printf '%s\n' "$candidates" | head -1
    fi
}

# ブランチ名を探索キーとして、該当ブランチを持つリモートを探索する
# 探索のみ行い、副作用（グローバル変数更新、警告出力）は持たない
# 引数:
#   $1 - effective_branch（ブランチ短縮名、例: cycle/v1.27.1）
# 出力: stdout にリモート名（1行）。見つからない場合は空
find_remote_by_branch() {
    local effective_branch="$1"

    # 戦略2: refs/remotes 探索（ローカル、ネットワーク不要）
    local refs_result
    refs_result=$(git for-each-ref --format='%(refname)' "refs/remotes/*/${effective_branch}" 2>/dev/null \
        | sed "s|^refs/remotes/||; s|/${effective_branch}\$||" || true)
    if [ -n "$refs_result" ]; then
        local candidate
        candidate=$(printf '%s\n' "$refs_result" | _select_remote_candidate)
        if [ -n "$candidate" ] && validate_remote "." "$candidate"; then
            printf '%s\n' "$candidate"
            return
        fi
    fi

    # 戦略3: git ls-remote 探索（ネットワーク必要）
    # タイムアウト手段の検出（1回のみ）
    local timeout_cmd=""
    if command -v gtimeout >/dev/null 2>&1; then
        timeout_cmd="gtimeout 5"
    elif command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout 5"
    fi

    local ls_candidates="" remote_name ls_output
    while IFS= read -r remote_name; do
        [ -z "$remote_name" ] && continue
        # セキュリティ: credential helper/askPass を無効化し、資格情報の意図しない利用を防止
        local git_safe_opts=(-c credential.helper= -c core.askPass=)
        if [ -n "$timeout_cmd" ]; then
            ls_output=$(GIT_TERMINAL_PROMPT=0 $timeout_cmd git "${git_safe_opts[@]}" ls-remote --heads "$remote_name" "refs/heads/${effective_branch}" 2>/dev/null || true)
        else
            # フォールバック: HTTP(S)はGIT_HTTP_LOW_SPEED_*、SSHはConnectTimeout=5で制限
            ls_output=$(GIT_TERMINAL_PROMPT=0 GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=5 GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=5 -o IdentityAgent=none -o IdentitiesOnly=yes -F /dev/null' git "${git_safe_opts[@]}" ls-remote --heads "$remote_name" "refs/heads/${effective_branch}" 2>/dev/null || true)
        fi
        if [ -n "$ls_output" ]; then
            if [ -z "$ls_candidates" ]; then
                ls_candidates="$remote_name"
            else
                ls_candidates="${ls_candidates}
${remote_name}"
            fi
        fi
    done <<< "$(git remote 2>/dev/null)"

    if [ -n "$ls_candidates" ]; then
        local candidate
        candidate=$(printf '%s\n' "$ls_candidates" | _select_remote_candidate)
        if [ -n "$candidate" ] && validate_remote "." "$candidate"; then
            printf '%s\n' "$candidate"
            return
        fi
    fi
}

# ブランチ名からリモートを解決し、WT_REMOTEに設定
# 引数:
#   $1 - ブランチ名（空の場合はブランチ設定の参照をスキップし、BRANCH_NAMEを探索キーとして使用）
#   $2 - エラー時のステップ名（fatal_errorの第1引数）
#   $3 - エラー時のエラーコード（fatal_errorの第2引数）
# API契約:
#   入力優先順位: branch_name（引数） > BRANCH_NAME（グローバル）
#   カレントディレクトリのリポジトリコンテキストで動作する
resolve_remote() {
    local branch_name="${1:-}"
    local error_step="$2"
    local error_code="$3"
    local searched=false

    # 戦略1: ブランチ追跡設定から解決
    if [ -n "$branch_name" ]; then
        local branch_remote
        branch_remote=$(git config "branch.${branch_name}.remote" 2>/dev/null || true)
        if [ -n "$branch_remote" ] && validate_remote "." "$branch_remote"; then
            WT_REMOTE="$branch_remote"
            return
        fi
    fi

    # 探索キー決定: branch_name（引数） > BRANCH_NAME（グローバル）
    local effective_branch="${branch_name:-$BRANCH_NAME}"

    # 戦略2-3: refs/remotes および ls-remote 探索
    if [ -n "$effective_branch" ]; then
        searched=true
        local candidate
        candidate=$(find_remote_by_branch "$effective_branch")
        if [ -n "$candidate" ]; then
            WT_REMOTE="$candidate"
            return
        fi
    fi

    # 戦略4: フォールバック（既存ロジック + 警告）
    if git remote | grep -q "^origin$"; then
        WT_REMOTE="origin"
    else
        WT_REMOTE=$(git remote | head -1)
        if [ -z "$WT_REMOTE" ]; then
            fatal_error "$error_step" "$error_code" "リモートが設定されていません"
        fi
    fi

    # 探索を実行したにも関わらずフォールバックに到達した場合、警告出力
    if [ "$searched" = true ]; then
        echo "message:警告: ブランチ ${effective_branch} のリモートを特定できませんでした。${WT_REMOTE} にフォールバックします"
    fi
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
        # 通常ブランチ環境
        IS_WORKTREE=false
        MAIN_REPO_PATH="$toplevel"
    else
        # worktree環境
        IS_WORKTREE=true

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
    fi

    echo "main_repo_path:${MAIN_REPO_PATH}"

    # サイクルブランチの存在確認
    BRANCH_NAME="cycle/${CYCLE}"
    if ! git show-ref --verify "refs/heads/${BRANCH_NAME}" >/dev/null 2>&1; then
        LOCAL_BRANCH_EXISTS=false
        echo "message:ローカルブランチ ${BRANCH_NAME} が存在しません（削除済み）。リモートブランチ削除のみ実行します"
    fi
    echo "branch:${BRANCH_NAME}"

    # 通常ブランチ: step_1のcheckoutでcurrent_branchが変わる前にWT_REMOTEをプリフェッチ
    if [ "$IS_WORKTREE" = false ]; then
        if [ "$LOCAL_BRANCH_EXISTS" = true ]; then
            resolve_remote "$BRANCH_NAME" "0a" "no-remote"
        else
            # ブランチ不在時はブランチ設定を参照せずにリモート解決
            resolve_remote "" "0a" "no-remote"
        fi
    fi

    if [ "$LOCAL_BRANCH_EXISTS" = true ]; then
        echo "step_result:0a:ok"
    else
        echo "step_result:0a:warning:branch-not-found"
        OVERALL="warning"
    fi
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
    echo "step:1:デフォルトブランチ更新"

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
    echo "step:2:fetch"

    # リモート解決（worktree: current_branchベース、通常ブランチ: step_0aでプリフェッチ済み）
    if [ "$IS_WORKTREE" = true ]; then
        local current_branch
        current_branch=$(git branch --show-current 2>/dev/null || true)
        WT_REMOTE=""
        resolve_remote "${current_branch:-}" "2" "fetch-failed"
    fi
    # 通常ブランチ: WT_REMOTEはstep_0aでプリフェッチ済み

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
    echo "step:3:ブランチ状態整理"

    # 通常ブランチ: step_1でデフォルトブランチにcheckout済みのためスキップ
    if [ "$IS_WORKTREE" = false ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "step:dry-run:skip (already on default branch)"
        fi
        echo "step_result:3:ok"
        return
    fi

    # worktree: detached HEADに切り替え
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

    # ブランチ不在時はスキップ
    if [ "$LOCAL_BRANCH_EXISTS" = false ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "step:dry-run:skip (local branch ${BRANCH_NAME} does not exist)"
        fi
        echo "step_result:4:ok:skipped-branch-not-found"
        echo "message:ローカルブランチ ${BRANCH_NAME} は既に削除済みのためスキップ"
        return
    fi

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

    # パストラバーサル防止
    if printf '%s\n' "$CYCLE" | grep -qF '..'; then
        echo "Error: バージョンにパストラバーサル（..）は許可されていません: ${CYCLE}" >&2
        exit 1
    fi

    # バージョン形式バリデーション
    if ! printf '%s\n' "$CYCLE" | grep -qE '^([a-z0-9][a-z0-9-]*/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
        echo "Error: バージョン形式が不正です: ${CYCLE}（例: v1.5.3 または waf/v1.5.3）" >&2
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
