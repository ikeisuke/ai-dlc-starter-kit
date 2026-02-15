#!/usr/bin/env bash
set -euo pipefail

# squash-unit.sh - Unit完了時に中間コミットを1つにまとめるsquashスクリプト
# git環境（git reset --soft方式）とjj環境（jj squash方式）に対応

# --- グローバル変数 ---
CYCLE=""
UNIT=""  # 現在の処理では未使用だが、呼び出し元との契約として受け取る
MESSAGE=""
DRY_RUN=false
VCS_TYPE=""
BASE_COMMIT=""
TARGET_COUNT=0
CO_AUTHORS=""
SAVED_HEAD=""

# --- ヘルプ・引数解析 ---

show_help() {
    cat <<'EOF'
Usage: squash-unit.sh [OPTIONS]

Unit完了時に中間コミットを1つにまとめるsquashスクリプト。

Required:
  --cycle <CYCLE>         サイクル名（例: v1.15.0）
  --unit <UNIT_NUMBER>    Unit番号（例: 001）
  --message <MESSAGE>     squash後のコミットメッセージ
  --vcs <git|jj>          使用するVCS種類

Optional:
  --base <COMMIT>         起点コミット（git: ハッシュ, jj: change_id）を明示指定。
                          省略時はコミットメッセージのパターンから自動検出。
  --dry-run               実際のsquashを実行せず対象コミットの表示のみ
  -h, --help              このヘルプを表示

Examples:
  squash-unit.sh --cycle v1.15.0 --unit 001 --vcs git --message "feat: [v1.15.0] Unit 001完了 - squashスクリプト作成"
  squash-unit.sh --cycle v1.15.0 --unit 001 --vcs git --message "feat: ..." --base abc1234
  squash-unit.sh --cycle v1.15.0 --unit 001 --vcs git --message "feat: ..." --dry-run
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cycle)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --cycle requires a value" >&2
                    exit 2
                fi
                CYCLE="$2"
                shift 2
                ;;
            --unit)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --unit requires a value" >&2
                    exit 2
                fi
                UNIT="$2"
                shift 2
                ;;
            --message)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --message requires a value" >&2
                    exit 2
                fi
                MESSAGE="$2"
                shift 2
                ;;
            --vcs)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --vcs requires a value (git or jj)" >&2
                    exit 2
                fi
                if [[ "$2" != "git" && "$2" != "jj" ]]; then
                    echo "Error: --vcs must be 'git' or 'jj', got: $2" >&2
                    exit 2
                fi
                VCS_TYPE="$2"
                shift 2
                ;;
            --base)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --base requires a value" >&2
                    exit 2
                fi
                BASE_COMMIT="$2"
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
                echo "Error: unknown option: $1" >&2
                exit 2
                ;;
        esac
    done

    if [[ -z "$CYCLE" ]]; then
        echo "Error: --cycle is required" >&2
        exit 2
    fi
    if [[ -z "$UNIT" ]]; then
        echo "Error: --unit is required" >&2
        exit 2
    fi
    if [[ -z "$MESSAGE" ]]; then
        echo "Error: --message is required" >&2
        exit 2
    fi
    if [[ -z "$VCS_TYPE" ]]; then
        echo "Error: --vcs is required" >&2
        exit 2
    fi
}

# --- 起点特定 ---

find_base_commit_git() {
    local cycle="$1"
    local base_hash=""
    local line
    local log_output
    local merge_base=""

    # サイクルブランチの分岐点を特定し、その範囲内で検索
    merge_base=$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null || true)

    local log_range=""
    if [[ -n "$merge_base" ]]; then
        log_range="${merge_base}..HEAD"
    else
        # フォールバック: 分岐点が見つからない場合は100コミットに制限
        log_range="-n 100"
    fi

    # git log の実行可否を先に確認
    if ! log_output=$(git log --format="%H %s" $log_range 2>&1); then
        echo "Error: git log failed: ${log_output}" >&2
        echo "squash:error:git-log-failed"
        exit 1
    fi

    # パターン: feat: [CYCLE] または chore: [CYCLE] ... Phase完了
    while IFS= read -r line; do
        local hash subject
        hash="${line%% *}"
        subject="${line#* }"
        if [[ "$subject" == "feat: [${cycle}]"* ]] || [[ "$subject" == "chore: [${cycle}]"*"Phase完了" ]]; then
            base_hash="$hash"
            break
        fi
    done <<< "$log_output"

    if [[ -z "$base_hash" ]]; then
        echo "Error: base commit not found for cycle ${cycle}. Expected 'feat: [${cycle}] ...' or 'chore: [${cycle}] ... Phase完了' pattern." >&2
        echo "squash:error:base-not-found"
        exit 1
    fi

    BASE_COMMIT="$base_hash"
    echo "base_commit:${BASE_COMMIT}"
}

find_base_commit_jj() {
    local cycle="$1"
    local base_change_id=""
    local line
    local log_output

    # trunk()からの範囲で検索（サイクルブランチの分岐点以降）
    local jj_range="trunk()..@-"

    # jj log の実行可否を先に確認
    if ! log_output=$(jj log --no-graph -T 'change_id ++ " " ++ description.first_line()' -r "$jj_range" 2>&1); then
        # フォールバック: trunk()が使えない場合は従来の範囲
        if ! log_output=$(jj log --no-graph -T 'change_id ++ " " ++ description.first_line()' -r "ancestors(@-, 50)..@-" 2>&1); then
            echo "Error: jj log failed: ${log_output}" >&2
            echo "squash:error:jj-log-failed"
            exit 1
        fi
    fi

    # パターン: feat: [CYCLE] または chore: [CYCLE] ... Phase完了（change_idを使用）
    while IFS= read -r line; do
        local cid desc
        cid="${line%% *}"
        desc="${line#* }"
        if [[ "$desc" == "feat: [${cycle}]"* ]] || [[ "$desc" == "chore: [${cycle}]"*"Phase完了" ]]; then
            base_change_id="$cid"
            break
        fi
    done <<< "$log_output"

    if [[ -z "$base_change_id" ]]; then
        echo "Error: base revision not found for cycle ${cycle}. Expected 'feat: [${cycle}] ...' or 'chore: [${cycle}] ... Phase完了' pattern." >&2
        echo "squash:error:base-not-found"
        exit 1
    fi

    BASE_COMMIT="$base_change_id"
    echo "base_commit:${BASE_COMMIT}"
}

# --- Co-Authored-By抽出 ---

extract_co_authors() {
    local vcs_type="$1"
    local base="$2"
    local raw_authors=""

    if [[ "$vcs_type" == "git" ]]; then
        raw_authors=$(git log --format="%b" "${base}..HEAD" 2>/dev/null | grep -i "^Co-Authored-By:" || true)
    elif [[ "$vcs_type" == "jj" ]]; then
        raw_authors=$(jj log --no-graph -T 'description' -r "${base}..@-" 2>/dev/null | grep -i "^Co-Authored-By:" || true)
    fi

    # 重複排除（raw行全体で比較）
    if [[ -n "$raw_authors" ]]; then
        CO_AUTHORS=$(echo "$raw_authors" | sort -u)
    else
        CO_AUTHORS=""
    fi
}

# --- squash実行 ---

squash_git() {
    local base="$1"
    local message="$2"
    local co_authors="$3"
    local target_count="$4"

    # 最終コミットメッセージの組み立て
    local full_message="$message"
    if [[ -n "$co_authors" ]]; then
        full_message="${message}"$'\n\n'"${co_authors}"
    fi

    if [[ "$target_count" -eq 1 ]]; then
        # 1件: メッセージ整形のみ（amend）
        if ! git commit --amend -m "$full_message" >/dev/null 2>&1; then
            echo "Error: git commit --amend failed" >&2
            echo "squash:error:amend-failed"
            exit 1
        fi
        local new_hash
        new_hash=$(git rev-parse HEAD 2>/dev/null)
        echo "squash:success:${new_hash}"
        return
    fi

    # 2件以上: reset --soft + commit
    SAVED_HEAD=$(git rev-parse HEAD 2>/dev/null)

    if ! git reset --soft "$base" 2>/dev/null; then
        echo "Error: git reset --soft ${base} failed" >&2
        echo "squash:error:reset-failed"
        exit 1
    fi

    if ! git commit -m "$full_message" >/dev/null 2>&1; then
        echo "Error: git commit failed after reset --soft. Working tree is in intermediate state." >&2
        echo "squash:error:commit-failed"
        echo "recovery:git reset --soft ${SAVED_HEAD}"
        exit 1
    fi

    local new_hash
    new_hash=$(git rev-parse HEAD 2>/dev/null)
    echo "squash:success:${new_hash}"
}

squash_jj() {
    local base_change_id="$1"
    local message="$2"
    local co_authors="$3"
    local target_count="$4"

    # 最終メッセージの組み立て
    local full_message="$message"
    if [[ -n "$co_authors" ]]; then
        full_message="${message}"$'\n\n'"${co_authors}"
    fi

    if [[ "$target_count" -eq 1 ]]; then
        # 1件: メッセージ整形のみ（describe）
        local target_rev
        target_rev=$(jj log --no-graph -T 'change_id' -r "${base_change_id}..@-" 2>/dev/null | head -1)
        if [[ -z "$target_rev" ]]; then
            echo "Error: could not resolve target revision for describe" >&2
            echo "squash:error:resolve-failed"
            exit 1
        fi
        if ! jj describe -r "$target_rev" -m "$full_message" 2>/dev/null; then
            echo "Error: jj describe failed" >&2
            echo "squash:error:describe-failed"
            exit 1
        fi
        echo "squash:success:${target_rev}"
        return
    fi

    # 2件以上: 最新側から順にsquash
    # bookmark確認（警告のみ）
    local bookmarks
    bookmarks=$(jj bookmark list 2>/dev/null || true)
    if [[ -n "$bookmarks" ]]; then
        local rev_list
        rev_list=$(jj log --no-graph -T 'change_id ++ "\n"' -r "${base_change_id}..@-" 2>/dev/null || true)
        local bookmark_warning=false
        while IFS= read -r bm_line; do
            local bm_rev
            bm_rev=$(echo "$bm_line" | awk '{print $NF}' || true)
            if [[ -n "$bm_rev" ]] && echo "$rev_list" | grep -q "$bm_rev" 2>/dev/null; then
                bookmark_warning=true
                break
            fi
        done <<< "$bookmarks"
        if [[ "$bookmark_warning" == "true" ]]; then
            echo "Warning: bookmarks found in target revision range. They may need manual adjustment after squash." >&2
        fi
    fi

    # 順次squash: 最新側から親方向へ統合
    local remaining
    remaining=$(jj log --no-graph -T 'change_id' -r "${base_change_id}..@-" 2>/dev/null | wc -l | tr -d ' ')

    while [[ "$remaining" -gt 1 ]]; do
        # 最新のリビジョンを取得して親にsquash
        local newest_rev
        newest_rev=$(jj log --no-graph -T 'change_id' -r "${base_change_id}..@-" -n 1 2>/dev/null)
        if [[ -z "$newest_rev" ]]; then
            echo "Error: could not resolve revision for squash" >&2
            echo "squash:error:resolve-failed"
            echo "recovery:jj undo"
            exit 1
        fi

        if ! jj squash -r "$newest_rev" 2>/dev/null; then
            echo "Error: jj squash -r ${newest_rev} failed" >&2
            echo "squash:error:squash-failed"
            echo "recovery:jj undo"
            exit 1
        fi

        # revsetで残りのリビジョン数を再取得
        remaining=$(jj log --no-graph -T 'change_id' -r "${base_change_id}..@-" 2>/dev/null | wc -l | tr -d ' ')
    done

    # 統合後のリビジョンにメッセージを設定
    local final_rev
    final_rev=$(jj log --no-graph -T 'change_id' -r "${base_change_id}..@-" 2>/dev/null | head -1)
    if [[ -z "$final_rev" ]]; then
        echo "Error: could not resolve final revision after squash" >&2
        echo "squash:error:resolve-failed"
        echo "recovery:jj undo"
        exit 1
    fi

    if ! jj describe -r "$final_rev" -m "$full_message" 2>/dev/null; then
        echo "Error: jj describe failed after squash" >&2
        echo "squash:error:describe-failed"
        echo "recovery:jj undo"
        exit 1
    fi

    echo "squash:success:${final_rev}"
}

# --- メイン処理 ---

main() {
    parse_args "$@"

    echo "vcs_type:${VCS_TYPE}"

    # 事前チェック: working tree / working copy がcleanであること
    if [[ "$VCS_TYPE" == "git" ]]; then
        local porcelain
        if ! porcelain=$(git status --porcelain 2>&1); then
            echo "Error: git status failed (not a git repository?): ${porcelain}" >&2
            echo "squash:error:not-a-repository"
            exit 1
        fi
        if [[ -n "$porcelain" ]]; then
            echo "Error: working tree is not clean. Please commit or stash changes first." >&2
            echo "squash:error:dirty-working-tree"
            exit 1
        fi
    elif [[ "$VCS_TYPE" == "jj" ]]; then
        local jj_diff
        if ! jj_diff=$(jj diff --stat 2>&1); then
            echo "Error: jj diff failed (not a jj repository?): ${jj_diff}" >&2
            echo "squash:error:not-a-repository"
            exit 1
        fi
        if [[ -n "$jj_diff" ]]; then
            echo "Error: working copy has uncommitted changes. Please commit changes first." >&2
            echo "squash:error:dirty-working-tree"
            exit 1
        fi
    fi

    # 起点コミット特定（--base 指定時は祖先チェックのみ）
    if [[ -n "$BASE_COMMIT" ]]; then
        # P1: 指定されたbaseがHEADの祖先であることを検証
        if [[ "$VCS_TYPE" == "git" ]]; then
            if ! git merge-base --is-ancestor "$BASE_COMMIT" HEAD 2>/dev/null; then
                echo "Error: --base ${BASE_COMMIT} is not an ancestor of HEAD" >&2
                echo "squash:error:base-not-ancestor"
                exit 1
            fi
        fi
        echo "base_commit:${BASE_COMMIT}"
    elif [[ "$VCS_TYPE" == "git" ]]; then
        find_base_commit_git "$CYCLE"
    elif [[ "$VCS_TYPE" == "jj" ]]; then
        find_base_commit_jj "$CYCLE"
    fi

    # 対象コミット数の取得
    if [[ "$VCS_TYPE" == "git" ]]; then
        TARGET_COUNT=$(git log --oneline "${BASE_COMMIT}..HEAD" 2>/dev/null | wc -l | tr -d ' ')
    elif [[ "$VCS_TYPE" == "jj" ]]; then
        TARGET_COUNT=$(jj log --no-graph -T 'change_id ++ "\n"' -r "${BASE_COMMIT}..@-" 2>/dev/null | wc -l | tr -d ' ')
    fi
    echo "target_count:${TARGET_COUNT}"

    # 対象0件: スキップ
    if [[ "$TARGET_COUNT" -eq 0 ]]; then
        echo "squash:skipped:no-commits"
        exit 0
    fi

    # ドライラン: 対象一覧を表示して終了
    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ "$VCS_TYPE" == "git" ]]; then
            git log --oneline "${BASE_COMMIT}..HEAD" 2>/dev/null >&2
        elif [[ "$VCS_TYPE" == "jj" ]]; then
            jj log --no-graph -r "${BASE_COMMIT}..@-" 2>/dev/null >&2
        fi
        echo "squash:dry-run:${TARGET_COUNT}"
        exit 0
    fi

    # Co-Authored-By抽出（squash前に実行）
    extract_co_authors "$VCS_TYPE" "$BASE_COMMIT"

    # squash実行
    if [[ "$VCS_TYPE" == "git" ]]; then
        squash_git "$BASE_COMMIT" "$MESSAGE" "$CO_AUTHORS" "$TARGET_COUNT"
    elif [[ "$VCS_TYPE" == "jj" ]]; then
        squash_jj "$BASE_COMMIT" "$MESSAGE" "$CO_AUTHORS" "$TARGET_COUNT"
    fi
}

main "$@"
