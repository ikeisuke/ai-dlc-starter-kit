#!/usr/bin/env bash
#
# main-repo-health-check.sh - メインリポジトリの状態異常を Operations Phase 開始時に早期検出
#
# 使用方法:
#   ./main-repo-health-check.sh
#
# 検出項目（HealthCheckItem）:
#   1. unmerged-paths      - メインリポジトリの git status --porcelain=v1 でマージコンフリクト行を検出
#   2. merge-in-progress   - .git/MERGE_HEAD / CHERRY_PICK_HEAD / REBASE_HEAD の存在確認
#   3. conflict-marker     - tracked ファイルにコンフリクトマーカー残骸 scan
#
# 出力形式（stdout）:
#   全体ステータス: status:{ok|warning|error}
#   各項目:        health-check:<item>:<status>:<detail>
#   エラー時:      error:<code>:<message>
#
# 終了コード（guides/exit-code-convention.md 準拠 / スキルベース相対）:
#   0: 正常完了（健全 + 警告検出を含む。警告は stdout の status:warning で通知）
#   1: バリデーションエラー（本 helper は引数を取らないため通常非発生）
#   2: システムエラー（git rev-parse 失敗、git コマンド失敗等）
#
# 設計詳細:
#   .aidlc/cycles/v2.5.4/design-artifacts/logical-designs/unit_002_main_repo_health_check_logical_design.md
#

set -euo pipefail

# resolve_main_repo_path は command substitution で呼ばれるため subshell 実行となり、
# グローバル変数経由のエラー理由伝搬は親スコープに反映されない。stdout に
# "ERROR:<reason>" で返す方式に統一する。

show_help() {
    cat << 'EOF'
Usage: main-repo-health-check.sh

worktree 環境で AI-DLC を運用する際、Operations Phase 開始時にメインリポジトリの
状態異常を早期検出する health check helper。

検出項目:
  - unmerged-paths    : メインリポジトリの git status --porcelain でマージコンフリクト行を検出
  - merge-in-progress : .git/MERGE_HEAD / CHERRY_PICK_HEAD / REBASE_HEAD の存在確認
  - conflict-marker   : tracked ファイルに Git 標準コンフリクトマーカー残骸 scan

OPTIONS:
  -h, --help    このヘルプを表示

出力形式:
  status:{ok|warning|error}
  health-check:<item>:<status>:<detail>

詳細はスクリプトヘッダコメントを参照。
EOF
}

# メインリポジトリの worktree top の絶対パスを解決
# 戻り値: stdout に絶対パス、または "ERROR:<reason>" を 1 行で返す
resolve_main_repo_path() {
    local toplevel git_common_dir
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "ERROR:git rev-parse --show-toplevel failed"
        return 2
    }
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null) || {
        echo "ERROR:git rev-parse --git-common-dir failed"
        return 2
    }

    # 相対パスの場合は worktree top を基準に絶対化
    case "$git_common_dir" in
        /*) ;;  # 既に絶対パス
        *) git_common_dir=$(cd "$toplevel" && cd "$git_common_dir" && pwd) || {
            echo "ERROR:cannot absolutize git-common-dir from toplevel=${toplevel}"
            return 2
        } ;;
    esac

    # main repo top = git-common-dir の親 (.git を 1 階層上に上がる)
    dirname "$git_common_dir"
}

# unmerged paths 検出（porcelain v1 を明示固定）
check_unmerged_paths() {
    local main_repo_path="$1"
    local porcelain
    porcelain=$(git -C "$main_repo_path" status --porcelain=v1 2>/dev/null) || {
        echo "health-check:unmerged-paths:error:git-status-failed"
        return 2
    }

    # grep -c は未マッチ時 exit 1 を返すため || true で吸収
    local unmerged_count
    unmerged_count=$(printf '%s\n' "$porcelain" | grep -c -E "^(UU|AA|DD|DU|UD|AU|UA) " || true)

    if [ "$unmerged_count" -gt 0 ]; then
        echo "health-check:unmerged-paths:warning:count=${unmerged_count}"
        return 1
    else
        echo "health-check:unmerged-paths:ok:count=0"
        return 0
    fi
}

# マージ進行中状態の検出（メインリポジトリのみ検査、linked worktree 側は scope 外）
check_merge_in_progress() {
    local main_repo_path="$1"

    local merge_head_path cherry_path rebase_path
    merge_head_path=$(git -C "$main_repo_path" rev-parse --git-path MERGE_HEAD 2>/dev/null) || {
        echo "health-check:merge-in-progress:error:git-path-failed"
        return 2
    }
    cherry_path=$(git -C "$main_repo_path" rev-parse --git-path CHERRY_PICK_HEAD 2>/dev/null) || {
        echo "health-check:merge-in-progress:error:git-path-failed"
        return 2
    }
    rebase_path=$(git -C "$main_repo_path" rev-parse --git-path REBASE_HEAD 2>/dev/null) || {
        echo "health-check:merge-in-progress:error:git-path-failed"
        return 2
    }

    local in_progress_files=()
    [ -e "$merge_head_path" ] && in_progress_files+=("MERGE_HEAD")
    [ -e "$cherry_path" ] && in_progress_files+=("CHERRY_PICK_HEAD")
    [ -e "$rebase_path" ] && in_progress_files+=("REBASE_HEAD")

    if [ "${#in_progress_files[@]}" -gt 0 ]; then
        local joined
        joined=$(printf '%s,' "${in_progress_files[@]}" | sed 's/,$//')
        echo "health-check:merge-in-progress:warning:files=${joined}"
        return 1
    else
        echo "health-check:merge-in-progress:ok:files=none"
        return 0
    fi
}

# Git 標準コンフリクトマーカー scan（git grep 主経路、BSD/GNU 両対応）
check_conflict_marker() {
    local main_repo_path="$1"
    local matches matches_count grep_ec

    # git grep の exit code: 0=マッチあり / 1=マッチなし / >=2=エラー
    # set -e の状態を変更せず、|| で grep の戻り値をハンドル
    # pathspec :(exclude) で意図的に conflict marker を含む fixture/docs を除外（Unit 002 / #670）
    matches=$(git -C "$main_repo_path" grep -I -n -E "^<<<<<<< |^>>>>>>> |^=======$" -- \
        ':(exclude)tests/main-repo-health-check.bats' \
        ':(exclude).aidlc/cycles/**/design-artifacts/**' 2>/dev/null) && grep_ec=0 || grep_ec=$?

    if [ "$grep_ec" -ge 2 ]; then
        echo "health-check:conflict-marker:error:git-grep-failed"
        return 2
    fi

    if [ -z "$matches" ]; then
        echo "health-check:conflict-marker:ok:count=0"
        return 0
    fi

    matches_count=$(printf '%s\n' "$matches" | wc -l | tr -d ' ')
    echo "health-check:conflict-marker:warning:count=${matches_count}"
    return 1
}

main() {
    case "${1:-}" in
        -h|--help)
            show_help
            return 0
            ;;
    esac

    # set -e 下で関数の non-zero 戻り値がスクリプト終了を引き起こさないよう、
    # 一時的に set +e で囲んで戻り値を変数に取得する
    local resolve_output resolve_ec main_repo_path
    set +e
    resolve_output=$(resolve_main_repo_path)
    resolve_ec=$?
    set -e

    if [ "$resolve_ec" -ne 0 ]; then
        # resolve_main_repo_path はエラー時 "ERROR:<reason>" を stdout に返す
        local reason="${resolve_output#ERROR:}"
        echo "status:error"
        echo "error:git-path-resolve-failed:${reason:-unknown}"
        exit 2
    fi
    main_repo_path="$resolve_output"

    local has_warning=0 has_error=0
    local check_ec

    set +e
    check_unmerged_paths "$main_repo_path"
    check_ec=$?
    set -e
    case $check_ec in
        0) ;;
        1) has_warning=1 ;;
        *) has_error=1 ;;
    esac

    set +e
    check_merge_in_progress "$main_repo_path"
    check_ec=$?
    set -e
    case $check_ec in
        0) ;;
        1) has_warning=1 ;;
        *) has_error=1 ;;
    esac

    set +e
    check_conflict_marker "$main_repo_path"
    check_ec=$?
    set -e
    case $check_ec in
        0) ;;
        1) has_warning=1 ;;
        *) has_error=1 ;;
    esac

    if [ "$has_error" -eq 1 ]; then
        echo "status:error"
        exit 2
    fi
    if [ "$has_warning" -eq 1 ]; then
        echo "status:warning"
    else
        echo "status:ok"
    fi
    exit 0
}

main "$@"
