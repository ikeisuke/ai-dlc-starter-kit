#!/usr/bin/env bash
#
# operations-release.sh - Operations Phase ステップ7リリース準備の orchestration ラッパー
#
# 使用方法:
#   ./operations-release.sh <subcommand> [options...]
#
# SUBCOMMANDS:
#   version-check    ステップ 7.1 - バージョン確認（iOS 分岐 + suggest-version.sh）
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
  version-check                ステップ 7.1   - バージョン確認（iOS 分岐 + suggest-version.sh）
  pr-ready                     ステップ 7.8   - ドラフト PR Ready 化 + PR 本文更新
  verify-git                   ステップ 7.9-7.11 - コミット漏れ / リモート同期 / main 差分チェック
  merge-pr                     ステップ 7.13  - PR マージ実行
  record-release-prep-commit   ステップ 7.7.1 - release_prep_commit slot 記録 (Unit 004)
  squash-712                   ステップ 7.12.5 - PR レビュー反映コミット Squash 統合 (Unit 004)

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

# _pr_ready_validate_body_file - PR 本文ファイルの不在 / 0 バイトを検出する単一 SoT 検証ヘルパー
#
# Args:
#   $1 body_file   検証対象のパス
#
# Returns:
#   0  通常ファイルとして存在しサイズ >= 1
#   1  不在 / 非 regular file（state=Missing）または 0 バイト（state=Empty）
#
# Side Effects:
#   検証エラー時のみ stderr に機械可読メッセージ（error<TAB><code><TAB><path>）を出力。
#   Empty 時は加えて人間可読の案内行を出力。ファイル内容は出力しない（情報リーク防止）。
#
# 関連 Issue: #678
# 関連 Unit: v2.6.2 Unit 001
_pr_ready_validate_body_file() {
    local body_file="$1"
    if [[ ! -f "$body_file" ]]; then
        printf 'error\tpr-ready:body-file-missing\t%s\n' "$body_file" >&2
        return 1
    fi
    if [[ ! -s "$body_file" ]]; then
        printf 'error\tpr-ready:body-file-empty\t%s\n' "$body_file" >&2
        printf '本文が空です。--body-file の中身を確認してから再実行してください\n' >&2
        return 1
    fi
    return 0
}

# gh_pr_edit_body_with_fallback - gh pr edit のスコープ不足エラー時に gh api PATCH へ fallback する
#
# Args:
#   $1 pr_number   PR 番号
#   $2 body_file   PR 本文ファイル
#
# 関連 Issue: #626
# 関連 Unit: v2.5.5 Unit 005
gh_pr_edit_body_with_fallback() {
    local pr_number="$1"
    local body_file="$2"
    local stderr_file
    local stderr_capture=""
    local edit_ec=0

    # 二重防御: cmd_pr_ready 経由を介さず直接呼び出される経路でも body_file の妥当性を検証する
    # （Issue #678 / v2.6.2 Unit 001）
    _pr_ready_validate_body_file "$body_file" || return 1

    # 1. gh CLI 経路を実行（stdout は呼び出し元へ透過、stderr のみ一時ファイルに捕捉して grep で判別する）
    stderr_file=$(mktemp -t aidlc-gh-pr-edit-stderr.XXXXXX)
    gh pr edit "$pr_number" --body-file "$body_file" 2>"$stderr_file" || edit_ec=$?
    stderr_capture=$(<"$stderr_file")
    rm -f "$stderr_file"
    if [[ $edit_ec -eq 0 ]]; then
        # 成功時も stderr が空でなければ透過する（warning 等を握り潰さない）
        if [[ -n "$stderr_capture" ]]; then
            printf '%s\n' "$stderr_capture" >&2
        fi
        return 0
    fi

    # 2. ScopeErrorDetector: read:org / read:discussion / requires.*scope / Could not resolve to a User
    if printf '%s' "$stderr_capture" | grep -qE 'read:org|read:discussion|requires.*scope|Could not resolve to a User'; then
        # 3. fallback 発動シグナル（ドメインモデル §「FallbackOutcome」）
        printf 'pr-ready:fallback:rest-patch:%s\n' "$pr_number" >&2
        # 4. REST PATCH 経路（stdout は呼び出し元へ透過する）
        local patch_ec=0
        gh api -X PATCH "/repos/{owner}/{repo}/pulls/${pr_number}" -F "body=@${body_file}" || patch_ec=$?
        if [[ $patch_ec -ne 0 ]]; then
            # 5. fallback 失敗ログキー（DR-003 観測点）
            printf 'pr-ready:fallback:rest-patch:failed:%s:%d\n' "$pr_number" "$patch_ec" >&2
            return $patch_ec
        fi
        return 0
    fi

    # 6. 非スコープエラー: 元 stderr を透過し、元 exit code で return
    printf '%s\n' "$stderr_capture" >&2
    return $edit_ec
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

    # 0. body-file 事前検証（Issue #678 / v2.6.2 Unit 001）:
    # 引数パース直後・cycle 解決前に最早期で fail-fast する。
    # --body-file 指定時は get-related-issues / find-draft / gh pr edit より前に検証エラーで停止し、
    # 0 バイト / 不在 / 非 regular file 由来の PR 本文 null 上書き事故を構造的に防止する。
    if [[ -n "$body_file" ]]; then
        _pr_ready_validate_body_file "$body_file" || return 1
    fi

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
                log_dry_run "# fallback (when scope-insufficient): gh api -X PATCH /repos/{owner}/{repo}/pulls/<PR_FROM_FIND_DRAFT> -F body=@$body_file"
                log_dry_run "# (case 2) ドラフト PR なし、既存 Ready PR あり（部分成功 retry）"
                log_dry_run "gh pr list --head <current-branch> --state open --json number,isDraft --jq '.[] | select(.isDraft == false) | .number'"
                log_dry_run "gh pr edit <EXISTING_PR> --body-file $body_file"
                log_dry_run "# fallback (when scope-insufficient): gh api -X PATCH /repos/{owner}/{repo}/pulls/<EXISTING_PR> -F body=@$body_file"
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
                log_dry_run "# fallback (when scope-insufficient): gh api -X PATCH /repos/{owner}/{repo}/pulls/$pr_number -F body=@$body_file"
            fi
            return 0
        fi
        "$SCRIPT_DIR/pr-ops.sh" ready "$pr_number" || return $?
        if [[ -n "$body_file" ]]; then
            gh_pr_edit_body_with_fallback "$pr_number" "$body_file" || return $?
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
            log_dry_run "# fallback (when scope-insufficient): gh api -X PATCH /repos/{owner}/{repo}/pulls/$existing_pr_number -F body=@$body_file"
            return 0
        fi
        gh_pr_edit_body_with_fallback "$existing_pr_number" "$body_file" || return $?
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

# Unit 005 (#616) pre-flight check: マージ前 write-history 追加コミット漏れガード
# validate-git.sh uncommitted を呼出し、status:warning 時は exit 1 で停止する
__operations_release_pre_flight_check() {
    local uncommitted_output
    uncommitted_output=$("$SCRIPT_DIR/validate-git.sh" uncommitted 2>&1) || true

    local uncommitted_status
    uncommitted_status=$(printf '%s\n' "$uncommitted_output" | awk -F':' '/^status:/ {print $2; exit}')
    [[ -z "$uncommitted_status" ]] && uncommitted_status="unknown"

    case "$uncommitted_status" in
        ok)
            return 0
            ;;
        warning)
            printf 'error\tpre-merge-uncommitted-detected\t%s\n' "$uncommitted_output" >&2
            return 1
            ;;
        error|unknown|*)
            printf 'warn\tpre-merge-uncommitted-unknown\tvalidate-git.sh status undecidable: %s\n' "$uncommitted_output" >&2
            return 0
            ;;
    esac
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

    # Unit 005 (#616) pre-flight check: --skip-checks 指定なし時のみ実行
    # dry-run でも pre-flight は必ず通す（構造的検証の信頼性 / I2）
    if [[ "$skip_checks" -eq 0 ]]; then
        if ! __operations_release_pre_flight_check; then
            return 1
        fi
        if [[ "$DRY_RUN" = "1" ]]; then
            printf 'merge-pr:dry-run:pre-flight-pass\n'
        fi
    fi

    # Bash 3.2 + set -u では空配列の "${array[@]}" が unbound variable になるため、
    # 追加引数がある場合だけ配列展開する。
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
            if [[ ${#extra_args[@]} -gt 0 ]]; then
                "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number" "${extra_args[@]}"
            else
                "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number"
            fi
            return $?
            ;;
        squash)
            if [[ "$DRY_RUN" = "1" ]]; then
                log_dry_run "$SCRIPT_DIR/pr-ops.sh merge $pr_number --squash${extra_args[*]:+ ${extra_args[*]}}"
                return 0
            fi
            if [[ ${#extra_args[@]} -gt 0 ]]; then
                "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number" --squash "${extra_args[@]}"
            else
                "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number" --squash
            fi
            return $?
            ;;
        rebase)
            if [[ "$DRY_RUN" = "1" ]]; then
                log_dry_run "$SCRIPT_DIR/pr-ops.sh merge $pr_number --rebase${extra_args[*]:+ ${extra_args[*]}}"
                return 0
            fi
            if [[ ${#extra_args[@]} -gt 0 ]]; then
                "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number" --rebase "${extra_args[@]}"
            else
                "$SCRIPT_DIR/pr-ops.sh" merge "$pr_number" --rebase
            fi
            return $?
            ;;
        *)
            printf 'merge-pr:error:invalid-method:%s\n' "$method" >&2
            return 1
            ;;
    esac
}

# --- Unit 004 (#639): record-release-prep-commit / squash-712 サブコマンド ---

print_help_record_release_prep_commit() {
    cat <<'EOF'
operations-release.sh record-release-prep-commit [--dry-run] --cycle <CYCLE>

Operations Phase ステップ 7.7.1 release_prep_commit slot 記録のラッパー (Unit 004 / #639)。

Options:
  --cycle <CYCLE>   サイクル名（必須、例: v2.5.2）。progress.md のパス解決に使用
  --dry-run         副作用を抑止し、実行予定を "would run: ..." 出力
  -h, --help        このヘルプを表示

Behavior:
  1. git rev-parse HEAD で 40 桁 SHA を取得
  2. .aidlc/cycles/<CYCLE>/operations/progress.md の "<!-- release_prep_commit: -->" 行を更新
     - 行不在時: 固定スロットセクション末尾に "<!-- release_prep_commit: <SHA> -->" を追加
     - 行存在時: 値を新 SHA で置換
  3. git add operations/progress.md && git commit -m "chore: [<CYCLE>] release_prep_commit 記録 - <SHA-prefix>"

Output (stdout):
  release_prep_commit:recorded:<40桁SHA>   - 行を新規追加した場合
  release_prep_commit:updated:<40桁SHA>    - 既存行を更新した場合

Errors (stderr):
  error\trecord-release-prep-commit:progress-not-found\t<path>
  error\trecord-release-prep-commit:git-rev-parse-failed
  error\trecord-release-prep-commit:write-failed\t<reason>
  error\trecord-release-prep-commit:commit-failed\t<reason>

Exit code: 0 (success) / 1 (validation / IO error)
EOF
}

print_help_squash_712() {
    cat <<'EOF'
operations-release.sh squash-712 [--dry-run] --cycle <CYCLE>

Operations Phase ステップ 7.12.5 PR レビュー反映コミット Squash 統合のラッパー (Unit 004 / #639)。

Options:
  --cycle <CYCLE>   サイクル名（必須、例: v2.5.2）
  --dry-run         副作用を抑止し、判定結果のみ出力
  -h, --help        このヘルプを表示

Behavior (DR-008 / git reset --soft 方式):
  1. read-config.sh rules.git.squash_enabled を取得
  2. progress.md から "<!-- release_prep_commit: ([0-9a-f]{40})? -->" を 2 段階判定でパース
     - 行存在判定 + 値抽出 + 厳格バリデーション
  3. git log <release_prep_commit>..HEAD --oneline で対象数判定
  4. git reset --soft <release_prep_commit> + git commit -m "chore: ... PR レビュー反映 squash 統合"
  5. 失敗時 git reset --hard ORIG_HEAD で rollback (commit 失敗時のみ)

External signal contract (commit-flow.md 準拠):
  Output (stdout):
    squash:success:<新規コミット SHA>          - 通常系成功
    squash:skipped                              - スキップ系 (理由は stderr "info\treason\t<reason>")
    squash:failed:reason=format_error           - release_prep_commit 値が不正
    squash:failed:reason=git_op_failed:<exit>   - git reset --soft / commit 失敗

  Auxiliary log (stderr):
    info\treason\tsquash_enabled=false           - squash_enabled 設定が false
    info\treason\tsquash_enabled=unset           - squash_enabled 設定が未定義
    info\treason\tread-config.sh failed          - read-config.sh エラー (安全側で skip)
    info\treason\trelease_prep_commit_missing    - slot 行不在 / 値空
    info\treason\tno_commits                     - <release_prep_commit>..HEAD が 0 件
    error\trelease_prep_commit_format_error\t<rawValue>
    error\tsquash_712:reset-soft-failed\t<exit_code>
    error\tsquash_712:commit-failed\t<exit_code>
    error\tsquash_712:rollback-failed\t<details> (rollback 失敗 / fatal)
    recommended_command:<手動 squash 案内>

Exit code:
  0 - success / skipped (block しない)
  1 - failed (Operations Phase block)
EOF
}

# progress.md path 解決（cycle に対応）
__operations_release_progress_path() {
    local cycle="$1"
    printf '%s' ".aidlc/cycles/${cycle}/operations/progress.md"
}

# Unit 003 (#677): cmd_squash_712 の起動時に history/operations.md の dirty 状態を検出する fail-fast ガード。
#
# 設計 SoT: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_003_fix_squash712_history_integration_logical_design.md
#
# 引数: $1 = cycle
# 戻り値: 0 = clean / 1 = dirty（呼び出し元で exit 1 に変換）
# 副作用（dirty 時のみ）:
#   stderr: error\tsquash-712:uncommitted-history\t<path>
#   stderr: recommended_command:git add <path> && git commit -m "<履歴記録メッセージ>" の後に <squash-712 起動コマンド> を再実行してください
#   呼び出し元が stdout に squash:failed:reason=dirty_history を出力
__squash_712_check_history_clean() {
    local cycle="$1"

    # Round 1 MEDIUM #1 部分対応 (Unit 003 / #677): 新規追加ガード経路として最小限のパストラバーサル拒否
    # 包括的な cmd_squash_712 全体への validate_cycle 導入は本 Unit のスコープ外（別 Issue 起票）
    if [[ "$cycle" == *..* ]] || [[ "$cycle" == /* ]] || [[ "$cycle" == *$'\n'* ]]; then
        printf 'error\tsquash-712:invalid-cycle\t%s\n' "$cycle" >&2
        return 1
    fi

    local history_path=".aidlc/cycles/${cycle}/history/operations.md"

    # ファイル不在は dirty 対象外（squash-712 自体は対象 commit が無ければ既存経路で skip される）
    if [[ ! -f "$history_path" ]]; then
        return 0
    fi

    # git status --porcelain で staged / unstaged 双方を検出（任意の非空出力を dirty として扱う）
    local status_output status_ec
    set +e
    status_output=$(git status --porcelain -- "$history_path" 2>&1)
    status_ec=$?
    set -e
    if [[ "$status_ec" -ne 0 ]]; then
        # git 自体が動作しない場合は判定不能とみなし clean 扱い（squash-712 後続経路で別途エラー）
        return 0
    fi

    if [[ -z "$status_output" ]]; then
        return 0
    fi

    # dirty 検出
    printf 'error\tsquash-712:uncommitted-history\t%s\n' "$history_path" >&2
    printf 'recommended_command:git add %s && git commit -m "<履歴記録メッセージ>" の後に <squash-712 起動コマンド> を再実行してください\n' "$history_path" >&2
    return 1
}

# release_prep_commit slot をパース（DomainModel ParseResult 仕様準拠）
# stdout: "missing" / "found:<SHA>" / "format_error:<rawValue>"
# return: 0 (success / always; パース結果は stdout)
__operations_release_parse_release_prep_commit() {
    local progress_file="$1"
    if [[ ! -f "$progress_file" ]]; then
        printf 'missing\n'
        return 0
    fi
    # 2 段階判定: 1) 行存在 (コロン後にスペース or 行末)
    local match_count
    match_count=$(grep -cE '^<!-- release_prep_commit:( |$)' "$progress_file" || true)
    if [[ "$match_count" -eq 0 ]]; then
        printf 'missing\n'
        return 0
    fi
    # 2) 値抽出 + trim
    local raw_value
    raw_value=$(grep -E '^<!-- release_prep_commit:( |$)' "$progress_file" \
        | head -1 \
        | sed -E 's/^<!-- release_prep_commit:[[:space:]]*//; s/[[:space:]]*-->[[:space:]]*$//')
    # 残った両端空白を再 trim
    raw_value=$(printf '%s' "$raw_value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    if [[ -z "$raw_value" ]]; then
        printf 'missing\n'
        return 0
    fi
    if [[ "$raw_value" =~ ^[0-9a-f]{40}$ ]]; then
        printf 'found:%s\n' "$raw_value"
        return 0
    fi
    printf 'format_error:%s\n' "$raw_value"
    return 0
}

cmd_record_release_prep_commit() {
    local cycle=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_help_record_release_prep_commit
                return 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --cycle)
                require_option_value "record-release-prep-commit" "--cycle" "$#" "${2:-}" || return 1
                cycle="$2"
                shift 2
                ;;
            *)
                printf 'record-release-prep-commit:error:unknown-option:%s\n' "$1" >&2
                return 1
                ;;
        esac
    done
    if [[ -z "$cycle" ]]; then
        printf 'record-release-prep-commit:error:cycle-required\n' >&2
        return 1
    fi
    local progress_file
    progress_file=$(__operations_release_progress_path "$cycle")
    if [[ ! -f "$progress_file" ]]; then
        printf 'error\trecord-release-prep-commit:progress-not-found\t%s\n' "$progress_file" >&2
        return 1
    fi
    local head_sha
    if ! head_sha=$(git rev-parse HEAD 2>&1); then
        printf 'error\trecord-release-prep-commit:git-rev-parse-failed\t%s\n' "$head_sha" >&2
        return 1
    fi
    if [[ ! "$head_sha" =~ ^[0-9a-f]{40}$ ]]; then
        printf 'error\trecord-release-prep-commit:git-rev-parse-failed\tinvalid SHA: %s\n' "$head_sha" >&2
        return 1
    fi
    local sha_prefix="${head_sha:0:7}"
    if [[ "$DRY_RUN" = "1" ]]; then
        log_dry_run "update $progress_file with release_prep_commit=$head_sha"
        log_dry_run "git add $progress_file && git commit -m 'chore: [$cycle] release_prep_commit 記録 - $sha_prefix'"
        printf 'release_prep_commit:dry-run:%s\n' "$head_sha"
        return 0
    fi
    # 既存行の有無を確認
    local match_count action
    match_count=$(grep -cE '^<!-- release_prep_commit:( |$)' "$progress_file" || true)
    if [[ "$match_count" -ge 1 ]]; then
        action="updated"
        local tmp_file
        tmp_file=$(mktemp -t aidlc-progress.XXXXXX)
        if ! sed -E "s|^<!-- release_prep_commit:.*-->[[:space:]]*$|<!-- release_prep_commit: ${head_sha} -->|" "$progress_file" > "$tmp_file"; then
            rm -f "$tmp_file"
            printf 'error\trecord-release-prep-commit:write-failed\tsed failed\n' >&2
            return 1
        fi
        mv "$tmp_file" "$progress_file" || {
            rm -f "$tmp_file"
            printf 'error\trecord-release-prep-commit:write-failed\tmv failed\n' >&2
            return 1
        }
    else
        action="recorded"
        # 末尾に追加（ファイル末尾改行の整合確保）
        printf '\n<!-- release_prep_commit: %s -->\n' "$head_sha" >> "$progress_file" || {
            printf 'error\trecord-release-prep-commit:write-failed\tappend failed\n' >&2
            return 1
        }
    fi
    if ! git add "$progress_file" 2>&1; then
        printf 'error\trecord-release-prep-commit:write-failed\tgit add failed\n' >&2
        return 1
    fi
    # 冪等性: ステージに差分がない場合（既に同一 SHA で記録済み等）は git commit を呼ばずに成功扱い
    if git diff --cached --quiet -- "$progress_file"; then
        printf 'release_prep_commit:already-recorded:%s\n' "$head_sha"
        return 0
    fi
    local commit_msg="chore: [${cycle}] release_prep_commit 記録 - ${sha_prefix}"
    if ! git commit -m "$commit_msg" >/dev/null 2>&1; then
        printf 'error\trecord-release-prep-commit:commit-failed\tgit commit failed\n' >&2
        return 1
    fi
    printf 'release_prep_commit:%s:%s\n' "$action" "$head_sha"
    return 0
}

cmd_squash_712() {
    local cycle=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_help_squash_712
                return 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --cycle)
                require_option_value "squash-712" "--cycle" "$#" "${2:-}" || return 1
                cycle="$2"
                shift 2
                ;;
            *)
                printf 'squash-712:error:unknown-option:%s\n' "$1" >&2
                return 1
                ;;
        esac
    done
    if [[ -z "$cycle" ]]; then
        printf 'squash-712:error:cycle-required\n' >&2
        return 1
    fi
    # Step 1: squash_enabled 取得 (commit-flow.md 既存契約準拠 / set -e 抑止で exit code を保持)
    local enabled_output enabled_ec
    set +e
    enabled_output=$("$SCRIPT_DIR/read-config.sh" rules.git.squash_enabled 2>/dev/null)
    enabled_ec=$?
    set -e
    if [[ "$enabled_ec" -eq 0 ]]; then
        if [[ "$enabled_output" = "true" ]]; then
            : # 続行
        elif [[ "$enabled_output" = "false" ]]; then
            printf 'info\treason\tsquash_enabled=false\n' >&2
            printf 'squash:skipped\n'
            return 0
        else
            printf 'info\treason\tsquash_enabled=%s\n' "$enabled_output" >&2
            printf 'squash:skipped\n'
            return 0
        fi
    elif [[ "$enabled_ec" -eq 1 ]]; then
        printf 'info\treason\tsquash_enabled=unset\n' >&2
        printf 'squash:skipped\n'
        return 0
    else
        printf 'info\treason\tread-config.sh failed\n' >&2
        printf 'squash:skipped\n'
        return 0
    fi
    # Unit 003 (#677): history/operations.md の dirty 状態を検出する fail-fast ガード
    # Step 1（squash_enabled 取得）直後・Step 2（release_prep_commit パース）前に配置
    # dry-run 時もこのガードは実行する（実行前検証目的）
    if ! __squash_712_check_history_clean "$cycle"; then
        printf 'squash:failed:reason=dirty_history\n'
        return 1
    fi
    # Step 2: release_prep_commit slot をパース
    local progress_file
    progress_file=$(__operations_release_progress_path "$cycle")
    local parse_result
    parse_result=$(__operations_release_parse_release_prep_commit "$progress_file")
    case "$parse_result" in
        missing)
            printf 'info\treason\trelease_prep_commit_missing\n' >&2
            printf 'squash:skipped\n'
            return 0
            ;;
        format_error:*)
            local raw_value="${parse_result#format_error:}"
            printf 'error\trelease_prep_commit_format_error\t%s\n' "$raw_value" >&2
            printf 'squash:failed:reason=format_error\n'
            return 1
            ;;
        found:*)
            : # 続行
            ;;
        *)
            printf 'error\tsquash_712:parse-failed\tunexpected: %s\n' "$parse_result" >&2
            printf 'squash:failed:reason=parse_failed\n'
            return 1
            ;;
    esac
    local release_prep_commit="${parse_result#found:}"
    # Step 3: 対象コミット数判定
    local commit_count
    commit_count=$(git log "${release_prep_commit}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [[ "$commit_count" -eq 0 ]]; then
        printf 'info\treason\tno_commits\n' >&2
        printf 'squash:skipped\n'
        return 0
    fi
    if [[ "$DRY_RUN" = "1" ]]; then
        log_dry_run "git reset --soft $release_prep_commit"
        log_dry_run "git commit -m 'chore: [$cycle] PR レビュー反映 squash 統合'"
        printf 'squash:dry-run:target_count=%d\n' "$commit_count"
        return 0
    fi
    # Step 4: git reset --soft（set -e 抑止のため subshell + || 構造）
    local reset_soft_output reset_soft_ec
    set +e
    reset_soft_output=$(git reset --soft "$release_prep_commit" 2>&1)
    reset_soft_ec=$?
    set -e
    if [[ "$reset_soft_ec" -ne 0 ]]; then
        printf 'error\tsquash_712:reset-soft-failed\t%d\n' "$reset_soft_ec" >&2
        printf 'recommended_command:git reset --hard <自身で確認した SHA> ; 詳細はログ参照\n' >&2
        printf 'squash:failed:reason=git_op_failed:%d\n' "$reset_soft_ec"
        return 1
    fi
    # Step 5: git commit（set -e 抑止のため一時的に無効化）
    local commit_msg="chore: [${cycle}] PR レビュー反映 squash 統合"
    local commit_output commit_ec
    set +e
    commit_output=$(git commit -m "$commit_msg" 2>&1)
    commit_ec=$?
    set -e
    if [[ "$commit_ec" -ne 0 ]]; then
        # rollback: reset --soft 成功 AND commit 失敗 → ORIG_HEAD で復旧（set -e 抑止）
        local rollback_output rollback_ec
        set +e
        rollback_output=$(git reset --hard ORIG_HEAD 2>&1)
        rollback_ec=$?
        set -e
        printf 'error\tsquash_712:commit-failed\t%d\n' "$commit_ec" >&2
        if [[ "$rollback_ec" -ne 0 ]]; then
            printf 'error\tsquash_712:rollback-failed\t%s\n' "$rollback_output" >&2
            printf 'recommended_command:git reflog で履歴を確認し手動復旧してください\n' >&2
        fi
        printf 'recommended_command:git reset --soft %s ; <レビュー反映を再実行> ; git commit -m "..."\n' "$release_prep_commit" >&2
        printf 'squash:failed:reason=git_op_failed:%d\n' "$commit_ec"
        return 1
    fi
    local new_sha
    new_sha=$(git rev-parse HEAD)
    printf 'squash:success:%s\n' "$new_sha"
    return 0
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
        pr-ready)
            cmd_pr_ready "$@"
            ;;
        verify-git)
            cmd_verify_git "$@"
            ;;
        merge-pr)
            cmd_merge_pr "$@"
            ;;
        record-release-prep-commit)
            cmd_record_release_prep_commit "$@"
            ;;
        squash-712)
            cmd_squash_712 "$@"
            ;;
        *)
            printf 'operations-release:error:unknown-subcommand:%s\n' "$subcommand" >&2
            print_help >&2
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
