#!/usr/bin/env bash
#
# operations-release.sh - Operations Phase ステップ7リリース準備の orchestration ラッパー
#
# 使用方法:
#   ./operations-release.sh <subcommand> [options...]
#
# SUBCOMMANDS:
#   version-check    ステップ 7.1 - バージョン確認（iOS 分岐 + suggest-version.sh）
#   lint             ステップ 7.5 - run-markdownlint.sh 実行
#   pr-ready         ステップ 7.8 - ドラフト PR Ready 化 + PR 本文更新
#   verify-git       ステップ 7.9-7.11 - コミット漏れ / リモート同期 / main 差分チェック
#   merge-pr         ステップ 7.13 - PR マージ実行
#
# GLOBAL OPTIONS:
#   -h, --help       ヘルプを表示
#   --dry-run        実際の副作用を抑止し、呼び出される引数のみを "would run: ..." 形式で stdout に出力
#
# 設計原則:
#   - 既存スクリプトの stdout / exit code を透過するパススルーラッパー（正規化しない）
#   - 既存スクリプト（pr-ops.sh / validate-git.sh / suggest-version.sh / ios-build-check.sh /
#     run-markdownlint.sh）は本スクリプトの範囲では変更しない
#   - 集約サマリが必要な場合のみ、既存出力の末尾に "<subcommand>:summary:..." を追加
#
# 詳細な契約は Unit 005 の論理設計（.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/
# unit_005_tier2_integration_logical_design.md）を参照。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

# --- ヘルプ ---

print_help() {
    cat <<'EOF'
operations-release.sh - Operations Phase ステップ7リリース準備の orchestration ラッパー

使用方法:
  operations-release.sh <subcommand> [options...]

Subcommands:
  version-check    ステップ 7.1  - バージョン確認（iOS 分岐 + suggest-version.sh）
  lint             ステップ 7.5  - run-markdownlint.sh 実行
  pr-ready         ステップ 7.8  - ドラフト PR Ready 化 + PR 本文更新
  verify-git       ステップ 7.9-7.11 - コミット漏れ / リモート同期 / main 差分チェック
  merge-pr         ステップ 7.13 - PR マージ実行

Global options:
  -h, --help       ヘルプを表示
  --dry-run        実際の副作用を抑止し、呼び出されるコマンドのみを出力

各サブコマンドのヘルプは `operations-release.sh <subcommand> --help` で参照してください。
EOF
}

print_help_version_check() {
    cat <<'EOF'
operations-release.sh version-check [--dry-run] [--ios-skip-marketing-version]

Operations Phase ステップ 7.1 バージョン確認のラッパー。

Options:
  --ios-skip-marketing-version    Inception 履歴に「iOSバージョン更新実施」記録がある場合に
                                  AI エージェントが付与するフラグ。
                                  付与時は suggest-version.sh（MARKETING_VERSION 確認）をスキップし、
                                  ios-build-check.sh のみを実行する。
  --dry-run                       副作用を抑止し、呼び出しコマンドを "would run: ..." 形式で出力
  -h, --help                      このヘルプを表示

Behavior:
  1. .aidlc/config.toml から project.type を read-config.sh で取得
  2. project.type == "ios":
     - --ios-skip-marketing-version なし: suggest-version.sh（MARKETING_VERSION 確認）
       → ios-build-check.sh（ビルド番号確認）の順で実行
     - --ios-skip-marketing-version あり: ios-build-check.sh のみ実行
  3. それ以外（general 扱い）: suggest-version.sh を呼び出し stdout / exit code を透過
EOF
}

print_help_lint() {
    cat <<'EOF'
operations-release.sh lint [--dry-run] [--cycle <CYCLE>]

Operations Phase ステップ 7.5 markdownlint 実行のラッパー。

Options:
  --cycle <CYCLE>   サイクル名（必須。省略時は git ブランチから cycle/<name> を推定）
  --dry-run         副作用を抑止し、呼び出しコマンドを "would run: ..." 形式で出力
  -h, --help        このヘルプを表示

Behavior:
  run-markdownlint.sh <CYCLE> を呼び出し、stdout / exit code をそのまま透過する。
EOF
}

print_help_pr_ready() {
    cat <<'EOF'
operations-release.sh pr-ready [--dry-run] [--cycle <CYCLE>] [--pr <PR>] [--body-file <PATH>]

Operations Phase ステップ 7.8 ドラフト PR Ready 化 + PR 本文更新のラッパー。

Options:
  --cycle <CYCLE>       サイクル名（pr-ops.sh get-related-issues に渡す。省略時は git ブランチから推定）
  --pr <PR>             既知 PR 番号（省略時は pr-ops.sh find-draft で検索）
  --body-file <PATH>    PR 本文ファイル（markdown 側でテンプレート生成済みを想定）
  --dry-run             副作用を抑止し、呼び出しコマンドを出力
  -h, --help            このヘルプを表示

Behavior:
  1. pr-ops.sh get-related-issues <CYCLE> を呼び出し stdout 透過
  2. --pr 未指定なら pr-ops.sh find-draft で検索
  3. ドラフト PR がある場合:
       a. pr-ops.sh ready <PR>
       b. --body-file 指定時のみ gh pr edit <PR> --body-file <PATH>
  4. ドラフト PR がない場合（部分成功 retry の冪等化）:
       a. 同ブランチの非ドラフト open PR を `gh pr list` で検索（重複 PR 作成防止）
       b. 既存の Ready 化済み PR が見つかった場合:
          - "pr:found-ready:<番号>" を出力
          - --body-file 指定時のみ gh pr edit <PR> --body-file <PATH>（ready 化はスキップ）
          - --body-file 未指定なら成功扱いで終了
       c. 既存 PR が見つからない場合:
          - --body-file 未指定ならエラー（stderr: "pr-ready:error:body-file-required"、exit 1）
          - --body-file 指定なら gh pr create --base main --title <CYCLE> --body-file <PATH>
            （--draft フラグは付けない）

Exit code:
  最終ステップで呼び出された既存スクリプト / gh コマンドの終了コードを透過。
  例外: --body-file 必須エラーのみ exit 1 を返す。
EOF
}

print_help_verify_git() {
    cat <<'EOF'
operations-release.sh verify-git [--dry-run] [--default-branch <BRANCH>]

Operations Phase ステップ 7.9-7.11 事前チェックのラッパー。

Options:
  --default-branch <BRANCH>  デフォルトブランチ名（省略時は git remote show origin から取得、
                             取得失敗時は main → master の順にフォールバック）
  --dry-run                  副作用を抑止し、呼び出しコマンドを出力
  -h, --help                 このヘルプを表示

Behavior:
  1. validate-git.sh uncommitted  … 7.9 コミット漏れ確認
  2. validate-git.sh remote-sync  … 7.10 リモート同期確認
  3. git merge-base --is-ancestor origin/<DEFAULT_BRANCH> HEAD  … 7.11 main 差分チェック（推奨）
  4. 末尾に集約サマリを追加:
       verify-git:summary:uncommitted=<status>:remote-sync=<status>:default-branch=<status>

Exit code:
  max(uncommitted_ec, remote_sync_ec) を返す。
  7.9 / 7.10 のハードエラー（exit 2 + status:error）は exit 2 で透過する。
  7.11 の fetch / merge-base 失敗は exit code に影響させず "default-branch=skipped" と記録する。
EOF
}

print_help_merge_pr() {
    cat <<'EOF'
operations-release.sh merge-pr [--dry-run] --pr <PR> --method <merge|squash|rebase> [--skip-checks]

Operations Phase ステップ 7.13 PR マージ実行のラッパー。

Options:
  --pr <PR>          マージ対象 PR 番号（必須）
  --method <METHOD>  マージ方法（必須）: merge / squash / rebase
                     "ask" は markdown 側で事前解決すること
  --skip-checks      no-checks-configured 時のみ CI バイパスを許可
                     failed/pending/checks-query-failed ではバイパスされない
  --dry-run          副作用を抑止し、呼び出しコマンドを出力
  -h, --help         このヘルプを表示

Behavior:
  --method に応じて以下を実行（--skip-checks 指定時は末尾に透過）:
    merge  → pr-ops.sh merge <PR> [--skip-checks]
    squash → pr-ops.sh merge <PR> --squash [--skip-checks]
    rebase → pr-ops.sh merge <PR> --rebase [--skip-checks]
  pr-ops.sh の stdout / exit code をそのまま透過する。

エラーコード（merged / auto-merge-set / error:auto-merge-not-enabled /
error:checks-failed / error:permission-denied / error:not-mergeable /
error:review-required / error:gh-not-available / error:gh-not-authenticated /
error:checks-status-unknown / error:head-sha-unavailable / error:head-mismatch 等）
の解釈・対処案内は markdown 側（operations-release.md）の責務。

checks-status-unknown エラー時は以下の順序固定 3 行が出力される:
  pr:<N>:error:checks-status-unknown
  pr:<N>:reason:<no-checks-configured|checks-query-failed>
  pr:<N>:hint:<ガイダンス>
reason=no-checks-configured の場合のみ --skip-checks で再実行可能。
reason=checks-query-failed では --skip-checks は効かない（安全側の仕様）。
EOF
}

# --- 共通ユーティリティ ---

log_dry_run() {
    # 呼び出し予定のコマンドを "would run: ..." 形式で stdout に出力
    printf 'would run: %s\n' "$*"
}

# オプション値の存在を検証。欠落（引数不足）または空文字列（`--option ""`）の場合、
# <subcommand>:error:missing-value:<option> を stderr に出力して return 1 する。
# 空文字列を有効値として受け入れたい場合は呼び出し側で別ルートを用意すること。
require_option_value() {
    local subcommand="$1"
    local option="$2"
    local remaining_count="$3"
    local value="${4:-}"
    if [[ "$remaining_count" -lt 2 || -z "$value" ]]; then
        printf '%s:error:missing-value:%s\n' "$subcommand" "$option" >&2
        return 1
    fi
    return 0
}

resolve_cycle_from_branch() {
    # git branch --show-current が cycle/<name> なら <name> を echo、それ以外は空文字
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")
    if [[ "$branch" =~ ^cycle/(.+)$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
    else
        printf '%s' ""
    fi
}

resolve_default_branch() {
    # git remote show origin からデフォルトブランチを取得、失敗時は main → master
    local remote_output default_branch
    if remote_output=$(git remote show origin 2>/dev/null); then
        default_branch=$(printf '%s\n' "$remote_output" | awk '/HEAD branch/ {print $NF; exit}')
        if [[ -n "${default_branch:-}" && "$default_branch" != "(unknown)" ]]; then
            printf '%s' "$default_branch"
            return 0
        fi
    fi
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        printf '%s' "main"
        return 0
    fi
    if git show-ref --verify --quiet refs/remotes/origin/master; then
        printf '%s' "master"
        return 0
    fi
    # fallback
    printf '%s' "main"
}

# --- サブコマンド実装 ---

cmd_version_check() {
    local ios_skip_marketing=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_help_version_check
                return 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --ios-skip-marketing-version)
                ios_skip_marketing=1
                shift
                ;;
            *)
                printf 'version-check:error:unknown-option:%s\n' "$1" >&2
                return 1
                ;;
        esac
    done

    # project.type 判定（read-config.sh は非破壊的な読み取りなので dry-run でも実行して
    # 分岐を正確に出力する）
    local project_type=""
    if project_type=$("$SCRIPT_DIR/read-config.sh" project.type 2>/dev/null); then
        :
    else
        project_type=""
    fi

    if [[ "$project_type" = "ios" ]]; then
        # iOS: --ios-skip-marketing-version が付与されていない場合は、
        # まず通常の MARKETING_VERSION 確認（suggest-version.sh）を実行してから
        # ビルド番号確認（ios-build-check.sh）を実行する。
        # Inception 履歴に「iOSバージョン更新実施」記録がある場合のみ marketing を省略できる。
        if [[ "$ios_skip_marketing" = "0" ]]; then
            if [[ "$DRY_RUN" = "1" ]]; then
                log_dry_run "$SCRIPT_DIR/suggest-version.sh"
            else
                "$SCRIPT_DIR/suggest-version.sh" || return $?
            fi
        fi
        if [[ "$DRY_RUN" = "1" ]]; then
            log_dry_run "$SCRIPT_DIR/ios-build-check.sh"
            return 0
        fi
        "$SCRIPT_DIR/ios-build-check.sh"
        return $?
    fi

    # general 扱い: suggest-version.sh を実行
    if [[ "$DRY_RUN" = "1" ]]; then
        log_dry_run "$SCRIPT_DIR/suggest-version.sh"
        return 0
    fi
    "$SCRIPT_DIR/suggest-version.sh"
    return $?
}

cmd_lint() {
    local cycle=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_help_lint
                return 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --cycle)
                require_option_value "lint" "--cycle" "$#" "${2:-}" || return 1
                cycle="$2"
                shift 2
                ;;
            *)
                printf 'lint:error:unknown-option:%s\n' "$1" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "$cycle" ]]; then
        cycle=$(resolve_cycle_from_branch)
    fi

    if [[ "$DRY_RUN" = "1" ]]; then
        log_dry_run "$SCRIPT_DIR/run-markdownlint.sh $cycle"
        return 0
    fi
    "$SCRIPT_DIR/run-markdownlint.sh" "$cycle"
    return $?
}

cmd_pr_ready() {
    local cycle=""
    local pr_number=""
    local body_file=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_help_pr_ready
                return 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --cycle)
                require_option_value "pr-ready" "--cycle" "$#" "${2:-}" || return 1
                cycle="$2"
                shift 2
                ;;
            --pr)
                require_option_value "pr-ready" "--pr" "$#" "${2:-}" || return 1
                pr_number="$2"
                shift 2
                ;;
            --body-file)
                require_option_value "pr-ready" "--body-file" "$#" "${2:-}" || return 1
                body_file="$2"
                shift 2
                ;;
            *)
                printf 'pr-ready:error:unknown-option:%s\n' "$1" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "$cycle" ]]; then
        cycle=$(resolve_cycle_from_branch)
    fi

    # 1. get-related-issues（stdout・exit code を透過。非 0 なら即エラー返し）
    if [[ "$DRY_RUN" = "1" ]]; then
        log_dry_run "$SCRIPT_DIR/pr-ops.sh get-related-issues $cycle"
    else
        "$SCRIPT_DIR/pr-ops.sh" get-related-issues "$cycle" || return $?
    fi

    # 2. PR 番号解決
    if [[ -z "$pr_number" ]]; then
        if [[ "$DRY_RUN" = "1" ]]; then
            log_dry_run "$SCRIPT_DIR/pr-ops.sh find-draft"
            # dry-run 時はドラフト PR の存在を判定できないため、3パターンを出力する:
            #   (1) ドラフト PR あり: ready → edit
            #   (2) ドラフト PR なし、既存 Ready PR あり: edit のみ（ready スキップ）
            #   (3) どちらもなし: gh pr create
            if [[ -n "$body_file" ]]; then
                log_dry_run "# (case 1) ドラフト PR あり: ready → edit"
                log_dry_run "$SCRIPT_DIR/pr-ops.sh ready <PR_FROM_FIND_DRAFT>"
                log_dry_run "gh pr edit <PR_FROM_FIND_DRAFT> --body-file $body_file"
                log_dry_run "# (case 2) ドラフト PR なし、既存 Ready PR あり（部分成功 retry）"
                log_dry_run "gh pr list --head <current-branch> --state open --json number,isDraft --jq '.[] | select(.isDraft == false) | .number'"
                log_dry_run "gh pr edit <EXISTING_PR> --body-file $body_file"
                log_dry_run "# (case 3) どちらもなし: gh pr create"
                log_dry_run "gh pr create --base main --title $cycle --body-file $body_file"
            else
                log_dry_run "$SCRIPT_DIR/pr-ops.sh ready <PR_FROM_FIND_DRAFT>"
                log_dry_run "# if draft not found and existing Ready PR not found: pr-ready:error:body-file-required (exit 1)"
            fi
            return 0
        fi
        local find_output find_ec=0
        find_output=$("$SCRIPT_DIR/pr-ops.sh" find-draft 2>&1) || find_ec=$?
        printf '%s\n' "$find_output"
        if [[ $find_ec -ne 0 ]]; then
            return $find_ec
        fi
        # pr-ops.sh find-draft の出力契約:
        #   pr:found:<番号>:<url>   → ドラフト PR あり
        #   pr:not-found             → ドラフト PR なし
        pr_number=$(printf '%s\n' "$find_output" | awk -F':' '/^pr:found:/ {print $3; exit}')
    fi

    if [[ -n "$pr_number" ]]; then
        # ドラフト PR あり
        if [[ "$DRY_RUN" = "1" ]]; then
            log_dry_run "$SCRIPT_DIR/pr-ops.sh ready $pr_number"
            if [[ -n "$body_file" ]]; then
                log_dry_run "gh pr edit $pr_number --body-file $body_file"
            fi
            return 0
        fi
        "$SCRIPT_DIR/pr-ops.sh" ready "$pr_number" || return $?
        if [[ -n "$body_file" ]]; then
            gh pr edit "$pr_number" --body-file "$body_file" || return $?
        fi
        return 0
    fi

    # ドラフト PR なし
    # 部分成功後の retry を冪等化するため、非ドラフト（既に Ready 化済み）の open PR を検索する。
    # 見つかった場合は ready 化をスキップし、body 更新のみ実行する（重複 PR 作成を防止）。
    #
    # 重要: gh pr list の失敗（API transient エラー等）を「PR なし」と誤判定すると、
    # 実際には既存 PR があるのに重複 PR を作成してしまう。失敗時はエラー終了する。
    local existing_pr_number=""
    if [[ "$DRY_RUN" = "1" ]]; then
        log_dry_run "gh pr list --head <current-branch> --state open --json number,isDraft --jq '.[] | select(.isDraft == false) | .number'"
        log_dry_run "# if existing non-draft PR found: gh pr edit <PR> --body-file $body_file (ready 化スキップ)"
        log_dry_run "# else: gh pr create --base main --title $cycle --body-file $body_file"
    else
        local current_branch
        current_branch=$(git branch --show-current 2>/dev/null || echo "")
        if [[ -z "$current_branch" ]]; then
            # 現在ブランチが取得できない（detached HEAD / git リポジトリ外 / git エラー）。
            # 重複 PR 作成を避けるためエラー終了する。
            printf 'pr-ready:error:current-branch-unavailable\n' >&2
            return 1
        fi
        local pr_list_output pr_list_ec=0
        pr_list_output=$(gh pr list --head "$current_branch" --state open --json number,isDraft --jq '.[] | select(.isDraft == false) | .number' 2>&1) || pr_list_ec=$?
        if [[ $pr_list_ec -ne 0 ]]; then
            # gh pr list 失敗 → エラー出力を透過して終了。重複 PR 作成は行わない。
            printf '%s\n' "$pr_list_output" >&2
            printf 'pr-ready:error:gh-pr-list-failed:%d\n' "$pr_list_ec" >&2
            return $pr_list_ec
        fi
        existing_pr_number=$(printf '%s\n' "$pr_list_output" | head -1)
    fi

    if [[ -n "$existing_pr_number" ]]; then
        # Ready 化済みの open PR が既に存在する → ready 化スキップ、body 更新のみ
        printf 'pr:found-ready:%s\n' "$existing_pr_number"
        if [[ -z "$body_file" ]]; then
            # body-file なしなら更新するものがない → 成功扱いで終了
            return 0
        fi
        if [[ "$DRY_RUN" = "1" ]]; then
            log_dry_run "gh pr edit $existing_pr_number --body-file $body_file"
            return 0
        fi
        gh pr edit "$existing_pr_number" --body-file "$body_file" || return $?
        return 0
    fi

    if [[ -z "$body_file" ]]; then
        printf 'pr-ready:error:body-file-required\n' >&2
        return 1
    fi

    if [[ "$DRY_RUN" = "1" ]]; then
        log_dry_run "gh pr create --base main --title $cycle --body-file $body_file"
        return 0
    fi
    gh pr create --base main --title "$cycle" --body-file "$body_file" || return $?
    return 0
}

cmd_verify_git() {
    local default_branch=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_help_verify_git
                return 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --default-branch)
                require_option_value "verify-git" "--default-branch" "$#" "${2:-}" || return 1
                default_branch="$2"
                shift 2
                ;;
            *)
                printf 'verify-git:error:unknown-option:%s\n' "$1" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "$default_branch" ]]; then
        default_branch=$(resolve_default_branch)
    fi

    if [[ "$DRY_RUN" = "1" ]]; then
        log_dry_run "$SCRIPT_DIR/validate-git.sh uncommitted"
        log_dry_run "$SCRIPT_DIR/validate-git.sh remote-sync"
        log_dry_run "git fetch origin $default_branch"
        log_dry_run "git merge-base --is-ancestor origin/$default_branch HEAD"
        printf 'verify-git:summary:uncommitted=<status>:remote-sync=<status>:default-branch=<status>\n'
        return 0
    fi

    # 1. uncommitted
    local uncommitted_output uncommitted_ec=0
    uncommitted_output=$("$SCRIPT_DIR/validate-git.sh" uncommitted 2>&1) || uncommitted_ec=$?
    printf '%s\n' "$uncommitted_output"
    local uncommitted_status
    uncommitted_status=$(printf '%s\n' "$uncommitted_output" | awk -F':' '/^status:/ {print $2; exit}')
    [[ -z "$uncommitted_status" ]] && uncommitted_status="unknown"

    # 2. remote-sync
    local remote_sync_output remote_sync_ec=0
    remote_sync_output=$("$SCRIPT_DIR/validate-git.sh" remote-sync 2>&1) || remote_sync_ec=$?
    printf '%s\n' "$remote_sync_output"
    local remote_sync_status
    remote_sync_status=$(printf '%s\n' "$remote_sync_output" | awk -F':' '/^status:/ {print $2; exit}')
    [[ -z "$remote_sync_status" ]] && remote_sync_status="unknown"

    # 3. default branch 差分チェック（推奨、障害分離）。default_branch は上で解決済み。
    local default_branch_status="skipped"
    if git fetch origin "$default_branch" >/dev/null 2>&1; then
        if git merge-base --is-ancestor "origin/$default_branch" HEAD >/dev/null 2>&1; then
            default_branch_status="ok"
        else
            default_branch_status="warning"
        fi
    fi

    # 4. 集約サマリ
    printf 'verify-git:summary:uncommitted=%s:remote-sync=%s:default-branch=%s\n' \
        "$uncommitted_status" "$remote_sync_status" "$default_branch_status"

    # 5. 終了コード: max(uncommitted_ec, remote_sync_ec)
    local final_ec=0
    if [[ $uncommitted_ec -gt $final_ec ]]; then final_ec=$uncommitted_ec; fi
    if [[ $remote_sync_ec -gt $final_ec ]]; then final_ec=$remote_sync_ec; fi
    return $final_ec
}

cmd_merge_pr() {
    local pr_number=""
    local method=""
    local skip_checks=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_help_merge_pr
                return 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --pr)
                require_option_value "merge-pr" "--pr" "$#" "${2:-}" || return 1
                pr_number="$2"
                shift 2
                ;;
            --method)
                require_option_value "merge-pr" "--method" "$#" "${2:-}" || return 1
                method="$2"
                shift 2
                ;;
            --skip-checks)
                skip_checks=1
                shift
                ;;
            *)
                printf 'merge-pr:error:unknown-option:%s\n' "$1" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "$pr_number" ]]; then
        printf 'merge-pr:error:pr-required\n' >&2
        return 1
    fi
    if [[ -z "$method" ]]; then
        printf 'merge-pr:error:method-required\n' >&2
        return 1
    fi

    local -a extra_args=()
    if [[ "$skip_checks" -eq 1 ]]; then
        extra_args+=("--skip-checks")
    fi

    case "$method" in
        merge)
            if [[ "$DRY_RUN" = "1" ]]; then
                log_dry_run "$SCRIPT_DIR/pr-ops.sh merge $pr_number${extra_args[*]:+ ${extra_args[*]}}"
                return 0
            fi
            "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number" "${extra_args[@]}"
            return $?
            ;;
        squash)
            if [[ "$DRY_RUN" = "1" ]]; then
                log_dry_run "$SCRIPT_DIR/pr-ops.sh merge $pr_number --squash${extra_args[*]:+ ${extra_args[*]}}"
                return 0
            fi
            "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number" --squash "${extra_args[@]}"
            return $?
            ;;
        rebase)
            if [[ "$DRY_RUN" = "1" ]]; then
                log_dry_run "$SCRIPT_DIR/pr-ops.sh merge $pr_number --rebase${extra_args[*]:+ ${extra_args[*]}}"
                return 0
            fi
            "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number" --rebase "${extra_args[@]}"
            return $?
            ;;
        *)
            printf 'merge-pr:error:invalid-method:%s\n' "$method" >&2
            return 1
            ;;
    esac
}

# --- ディスパッチャ ---

main() {
    if [[ $# -eq 0 ]]; then
        print_help
        return 1
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        -h|--help)
            print_help
            return 0
            ;;
        version-check)
            cmd_version_check "$@"
            ;;
        lint)
            cmd_lint "$@"
            ;;
        pr-ready)
            cmd_pr_ready "$@"
            ;;
        verify-git)
            cmd_verify_git "$@"
            ;;
        merge-pr)
            cmd_merge_pr "$@"
            ;;
        *)
            printf 'operations-release:error:unknown-subcommand:%s\n' "$subcommand" >&2
            print_help >&2
            return 1
            ;;
    esac
}

main "$@"
