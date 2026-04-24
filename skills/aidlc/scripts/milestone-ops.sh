#!/usr/bin/env bash
#
# milestone-ops.sh - GitHub Milestone 操作ユーティリティ
#
# Inception/Operations Phase の Milestone 関連処理を集約。
# bash プロンプト内 $() / バックティック禁止ルールに準拠するため、
# ステップ md ファイルからは subcommand 経由でのみ呼び出される。
#
# 使用方法:
#   ./milestone-ops.sh ensure-create <CYCLE>
#   ./milestone-ops.sh verify-or-create <CYCLE>
#   ./milestone-ops.sh close <CYCLE>
#   ./milestone-ops.sh link-issues-from-units <CYCLE> [--mode inception|operations]
#   ./milestone-ops.sh link-pr <CYCLE> [PR_NUMBER]
#   ./milestone-ops.sh early-link <CYCLE> <ISSUE_NUMBERS_NEWLINE_DELIMITED>
#
# 終了コード:
#   0 - 正常完了
#   1 - エラー（5 ケース判定で停止 / link-failed 集約 / 権限不足 等）
#   2 - 引数不正
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=lib/bootstrap.sh
source "${SCRIPT_DIR}/lib/bootstrap.sh"

usage() {
    cat <<EOF
Usage: milestone-ops.sh <subcommand> <CYCLE> [args...]

Subcommands:
  ensure-create <CYCLE>
      Inception 05-completion §1-1 用。5 ケース判定 + open=0 closed=0 時に新規作成。
      stdout: milestone:<CYCLE>:created|exists:number=<N>
      stderr: ERROR メッセージ
      exit: 0 / 1

  verify-or-create <CYCLE>
      Operations 01-setup §11-1 用。5 ケース判定 + open=0 closed=0 時に fallback 作成。
      stdout: milestone:<CYCLE>:exists|fallback-created:number=<N>
      stderr: ERROR / WARNING
      exit: 0 / 1

  close <CYCLE>
      Operations 04-completion §5.5 用。5 ケース判定 + open=1 時に close 実行。
      stdout: milestone:<CYCLE>:closed|already-closed:number=<N>
      stderr: ERROR
      exit: 0 / 1

  link-issues-from-units <CYCLE> --milestone-number <N> --mode inception|operations
      Unit 定義ファイル群から関連 Issue を抽出し、Milestone に一括紐付け。
      mode=inception: gh issue edit 主経路 + gh api PATCH フォールバック
      mode=operations: gh api PATCH のみ（既存紐付け済み多数前提）
      stdout: issue:<N>:linked|already-linked|other-milestone|... 1 行 / Issue
      stderr: ERROR / WARNING
      exit: 0 / 1（link-failed 集約あり）

  link-pr <CYCLE> --milestone-number <N> [--pr-number <N>]
      現ブランチ PR（または指定 PR）の Milestone 紐付けを冪等補完。
      stdout: pr:<N>:linked|already-linked|other-milestone|not-found-or-not-open
      stderr: ERROR / WARNING
      exit: 0 / 1

  early-link <CYCLE> --milestone-number <N> --issues <newline_delimited>
      Inception 02-preparation ステップ 16 用先行紐付け（open=1 closed=0 のみ動作）。
      stdout: issue:<N>:linked-early|link-failed-early:will-retry-in-05-completion
      exit: 0（失敗は 05-completion 1-2 で再試行）

Common environment:
  GH_REPO_OWNER / GH_REPO_NAME を指定すれば dynamic resolve をスキップ可。
EOF
}

# --- ヘルパー関数 ---

# 依存コマンドのチェック（gh / jq は必須）
# 不在時は明示的なエラーメッセージで案内（jq: command not found のような不親切なメッセージを避ける）
require_dependencies() {
    local missing=""
    if ! command -v gh >/dev/null 2>&1; then
        missing="${missing}gh "
    fi
    if ! command -v jq >/dev/null 2>&1; then
        missing="${missing}jq "
    fi
    if [ -n "$missing" ]; then
        echo "ERROR: milestone-ops.sh requires the following commands to be installed and on PATH: ${missing}" >&2
        echo "ERROR: Install with: brew install gh jq （macOS）/ apt install gh jq （Debian/Ubuntu）/ etc." >&2
        echo "ERROR: または .aidlc/config.toml の [rules.github].milestone_enabled=false に切り替えて Milestone 機能を opt-out できます。" >&2
        exit 2
    fi
}

resolve_owner_repo() {
    if [ -n "${GH_REPO_OWNER:-}" ] && [ -n "${GH_REPO_NAME:-}" ]; then
        OWNER="$GH_REPO_OWNER"
        REPO="$GH_REPO_NAME"
        return 0
    fi
    OWNER=$(gh repo view --json owner --jq .owner.login)
    REPO=$(gh repo view --json name --jq .name)
}

# Milestone 一覧（state=all、--paginate で全ページ）から CYCLE タイトル一致を絞り込む
# 出力: stdout に JSON array、グローバル変数 OPEN_COUNT / CLOSED_COUNT に件数
#
# 注: `gh api --paginate ... --jq ...` は --jq をページごとに適用するため、
# 100 件超のリポでは複数の JSON 配列が連結された不正な JSON が返る。
# そのため --jq は使わず、jq -s (slurp) でページを 1 つの配列に統合してから絞り込む。
lookup_milestones() {
    local cycle="$1"
    MILESTONE_LOOKUP=$(gh api --paginate "repos/${OWNER}/${REPO}/milestones?state=all&per_page=100" \
        | jq -s --arg cycle "$cycle" '[.[][] | select(.title == $cycle) | {number, state}]')
    OPEN_COUNT=$(printf '%s' "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "open")] | length')
    CLOSED_COUNT=$(printf '%s' "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "closed")] | length')
}

# Unit 定義ファイル群から関連 Issue 番号を抽出（label-cycle-issues.sh 由来 5 形式対応）
# 注: units/ ディレクトリが空 / 不在の場合は何も出力せず exit 0（呼び出し側で no-issues-to-link 扱い）
extract_issue_numbers_from_units() {
    local cycle="$1"
    local units_dir="${AIDLC_CYCLES}/${cycle}/story-artifacts/units"
    if [ ! -d "$units_dir" ]; then
        return 0
    fi
    # nullglob 相当: 一致 0 件でもリテラルパターンを awk に渡さないため、find で明示列挙
    local files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$units_dir" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null)
    if [ ${#files[@]} -eq 0 ]; then
        return 0
    fi
    awk '
        /^## 関連Issue/ { in_section = 1; next }
        /^## / { in_section = 0 }
        in_section {
            lower_line = tolower($0)
            if (match(lower_line, /^[[:space:]]*(- )?(closes|fixes) #[0-9]+/)) {
                line = $0
                if (match(line, /#[0-9]+/)) {
                    num = substr(line, RSTART + 1, RLENGTH - 1)
                    if (num != "") print num
                }
            } else if (match(lower_line, /^[[:space:]]*- #[0-9]+/)) {
                line = $0
                if (match(line, /#[0-9]+/)) {
                    num = substr(line, RSTART + 1, RLENGTH - 1)
                    if (num != "") print num
                }
            }
        }
    ' "${files[@]}" 2>/dev/null | sort -n | uniq
}

# --- subcommand 実装 ---

cmd_ensure_create() {
    local cycle="$1"
    resolve_owner_repo
    lookup_milestones "$cycle"

    if [ "$CLOSED_COUNT" -ge 1 ]; then
        echo "ERROR: Milestone ${cycle} の closed が ${CLOSED_COUNT} 件あります。過去サイクルとの命名衝突の可能性。手動確認してください: gh api --paginate \"repos/<owner>/<repo>/milestones?state=all&per_page=100\"" >&2
        exit 1
    elif [ "$OPEN_COUNT" -ge 2 ]; then
        echo "ERROR: Milestone ${cycle} の open が ${OPEN_COUNT} 件あります。重複作成の可能性。手動で 1 件に整理してください。" >&2
        exit 1
    elif [ "$OPEN_COUNT" -eq 1 ]; then
        local milestone_number
        milestone_number=$(printf '%s' "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "open") | .number')
        echo "milestone:${cycle}:exists:number=${milestone_number}"
    else
        local milestone_number
        milestone_number=$(gh api --method POST "repos/${OWNER}/${REPO}/milestones" \
            -f title="${cycle}" \
            --jq .number)
        echo "milestone:${cycle}:created:number=${milestone_number}"
    fi
}

cmd_verify_or_create() {
    local cycle="$1"
    resolve_owner_repo
    lookup_milestones "$cycle"

    if [ "$CLOSED_COUNT" -ge 1 ]; then
        echo "ERROR: Milestone ${cycle} の closed が ${CLOSED_COUNT} 件あります。同名 closed Milestone がある場合の意図確認を必須化（誤再オープン防止）。手動確認: gh api --paginate \"repos/<owner>/<repo>/milestones?state=all&per_page=100\"" >&2
        exit 1
    elif [ "$OPEN_COUNT" -ge 2 ]; then
        echo "ERROR: Milestone ${cycle} の open が ${OPEN_COUNT} 件あります。重複候補を確認: gh api --paginate \"repos/<owner>/<repo>/milestones?state=all&per_page=100\"" >&2
        exit 1
    elif [ "$OPEN_COUNT" -eq 1 ]; then
        local milestone_number
        milestone_number=$(printf '%s' "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "open") | .number')
        echo "milestone:${cycle}:exists:number=${milestone_number}"
    else
        echo "WARNING: Milestone ${cycle} が不在です。Inception スキップ漏れの可能性があります。fallback で作成します。" >&2
        local milestone_number
        milestone_number=$(gh api --method POST "repos/${OWNER}/${REPO}/milestones" \
            -f title="${cycle}" \
            --jq .number)
        echo "milestone:${cycle}:fallback-created:number=${milestone_number}"
    fi
}

cmd_close() {
    local cycle="$1"
    resolve_owner_repo
    lookup_milestones "$cycle"

    if [ "$CLOSED_COUNT" -eq 1 ] && [ "$OPEN_COUNT" -eq 0 ]; then
        local closed_number
        closed_number=$(printf '%s' "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "closed") | .number')
        echo "milestone:${cycle}:already-closed:number=${closed_number}"
    elif [ "$CLOSED_COUNT" -ge 1 ]; then
        echo "ERROR: Milestone ${cycle} の closed が ${CLOSED_COUNT} 件 + open が ${OPEN_COUNT} 件あります（多重 closed または混在状態）。同名 closed Milestone がある場合の意図確認を必須化（誤再オープン防止）。手動確認: gh api --paginate \"repos/<owner>/<repo>/milestones?state=all&per_page=100\"" >&2
        exit 1
    elif [ "$OPEN_COUNT" -ge 2 ]; then
        echo "ERROR: Milestone ${cycle} の open が ${OPEN_COUNT} 件あります（重複作成の可能性）。重複候補を確認: gh api --paginate \"repos/<owner>/<repo>/milestones?state=all&per_page=100\"" >&2
        exit 1
    elif [ "$OPEN_COUNT" -eq 1 ]; then
        local milestone_number
        milestone_number=$(printf '%s' "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "open") | .number')
        local err_log="/tmp/milestone-close-error.$$.log"
        if gh api "repos/${OWNER}/${REPO}/milestones/${milestone_number}" --method PATCH -f state=closed --jq '.state' 2>"$err_log" >/dev/null; then
            echo "milestone:${cycle}:closed:number=${milestone_number}"
            rm -f "$err_log"
        else
            local err_detail
            err_detail=$(cat "$err_log")
            rm -f "$err_log"
            echo "ERROR: Milestone close 失敗: ${err_detail}。手動で次のコマンドを実行してください: gh api repos/${OWNER}/${REPO}/milestones/${milestone_number} --method PATCH -f state=closed" >&2
            exit 1
        fi
    else
        echo "ERROR: Milestone ${cycle} が見つかりません（open / closed のいずれにも存在しない）。01-setup.md ステップ11 の fallback 作成が未実行 or 手動作業漏れの可能性。手動確認: gh api --paginate \"repos/<owner>/<repo>/milestones?state=all&per_page=100\"" >&2
        exit 1
    fi
}

cmd_link_issues_from_units() {
    local cycle="$1"
    shift
    local milestone_number=""
    local mode=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --milestone-number) milestone_number="$2"; shift 2 ;;
            --mode) mode="$2"; shift 2 ;;
            *) echo "Error: unknown option: $1" >&2; exit 2 ;;
        esac
    done
    if [ -z "$milestone_number" ] || [ -z "$mode" ]; then
        echo "Error: --milestone-number and --mode are required" >&2
        exit 2
    fi
    if [ "$mode" != "inception" ] && [ "$mode" != "operations" ]; then
        echo "Error: --mode must be inception or operations" >&2
        exit 2
    fi

    resolve_owner_repo

    local issue_numbers
    issue_numbers=$(extract_issue_numbers_from_units "$cycle")

    if [ -z "$issue_numbers" ]; then
        echo "milestone:${cycle}:no-issues-to-link"
        return 0
    fi

    local link_failed=""
    local current_milestone
    local view_rc
    while read -r issue; do
        if [ -z "$issue" ]; then continue; fi
        # `set -e` 配下でも個別 Issue 単位で失敗を集約するため `|| view_rc=$?` で exit 抑制
        view_rc=0
        current_milestone=$(gh issue view "$issue" --json milestone --jq '.milestone.title // empty' 2>/dev/null) || view_rc=$?
        if [ "$view_rc" -ne 0 ]; then
            # Issue 不在 / 権限不足 / typo 等で view 自体が失敗 → link-failed として集約
            echo "issue:${issue}:view-failed:rc=${view_rc}" >&2
            link_failed="${link_failed}issue:${issue} "
            continue
        fi
        if [ -n "$current_milestone" ] && [ "$current_milestone" != "$cycle" ]; then
            if [ "$mode" = "inception" ]; then
                echo "WARNING: issue:${issue} は他の Milestone （${current_milestone}）に紐付け済みです。1 Issue = 1 Milestone 制約のため、付け替えが必要な場合は (a) 新サイクルへ付け替え / (b) Backlog に戻して保持 の 2 択をユーザーに確認してから手動で付け替えてください" >&2
            else
                echo "WARNING: issue:${issue} は他の Milestone （${current_milestone}）に紐付け済みです。1 Issue = 1 Milestone 制約のため、付け替えが必要な場合は Inception の手順 (a) 新サイクルへ付け替え / (b) Backlog に戻して保持 の判断を Operations 担当者に委ねます" >&2
            fi
            echo "issue:${issue}:other-milestone:current=${current_milestone}:skip-overwrite"
            continue
        elif [ "$current_milestone" = "$cycle" ]; then
            echo "issue:${issue}:already-linked:milestone=${cycle}"
            continue
        fi
        # empty Milestone の場合のみ新規紐付け
        # 注: gh / gh api の通常出力は machine-readable な status stream を汚染するため /dev/null へ捨てる
        if [ "$mode" = "inception" ]; then
            # 主経路: gh issue edit、フォールバック: gh api PATCH
            if gh issue edit "$issue" --milestone "$cycle" >/dev/null 2>&1; then
                echo "issue:${issue}:linked:milestone=${cycle}"
            elif gh api --method PATCH "repos/${OWNER}/${REPO}/issues/${issue}" -F "milestone=${milestone_number}" >/dev/null 2>&1; then
                echo "issue:${issue}:linked:milestone=${cycle}:via-api"
            else
                echo "issue:${issue}:link-failed" >&2
                link_failed="${link_failed}issue:${issue} "
            fi
        else
            # operations: PATCH 直接（既存紐付け済み多数前提で番号指定が確実）
            if gh api --method PATCH "repos/${OWNER}/${REPO}/issues/${issue}" -F "milestone=${milestone_number}" >/dev/null 2>&1; then
                echo "issue:${issue}:linked:milestone=${cycle}:via-api"
            else
                echo "issue:${issue}:link-failed" >&2
                link_failed="${link_failed}issue:${issue} "
            fi
        fi
    done <<< "$issue_numbers"

    if [ -n "$link_failed" ]; then
        if [ "$mode" = "inception" ]; then
            echo "ERROR: Milestone 紐付けに失敗した Issue があります: ${link_failed}" >&2
            echo "ERROR: 失敗原因（権限不足 / Issue アクセス不可 等）を解消してから本ステップを再実行してください。紐付け未達のまま進むと Operations Phase のサイクル可視化が不完全になります。" >&2
        else
            # operations モードでは LINK_FAILED を後段で集約するため、ここでは return のみ
            # （呼び出し側で link-pr 実行後に集約判定を行う設計）
            echo "milestone-link-failed:${link_failed}" >&2
        fi
        exit 1
    fi
}

cmd_link_pr() {
    local cycle="$1"
    shift
    local milestone_number=""
    local pr_number=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --milestone-number) milestone_number="$2"; shift 2 ;;
            --pr-number) pr_number="$2"; shift 2 ;;
            *) echo "Error: unknown option: $1" >&2; exit 2 ;;
        esac
    done
    if [ -z "$milestone_number" ]; then
        echo "Error: --milestone-number is required" >&2
        exit 2
    fi

    resolve_owner_repo

    if [ -z "$pr_number" ]; then
        local current_branch
        current_branch=$(git branch --show-current)
        pr_number=$(gh pr list --head "$current_branch" --state open --json number --jq '.[0].number // empty')
    fi

    if [ -z "$pr_number" ]; then
        echo "pr:not-found-or-not-open"
        return 0
    fi

    local pr_milestone
    local pr_view_rc=0
    pr_milestone=$(gh pr view "$pr_number" --json milestone --jq '.milestone.title // empty' 2>/dev/null) || pr_view_rc=$?
    if [ "$pr_view_rc" -ne 0 ]; then
        echo "pr:${pr_number}:view-failed:rc=${pr_view_rc}" >&2
        echo "pr-link-failed:pr:${pr_number}" >&2
        exit 1
    fi
    if [ -z "$pr_milestone" ]; then
        if gh api --method PATCH "repos/${OWNER}/${REPO}/issues/${pr_number}" -F "milestone=${milestone_number}" >/dev/null 2>&1; then
            echo "pr:${pr_number}:linked:milestone=${cycle}:via-api"
        else
            echo "pr:${pr_number}:link-failed" >&2
            echo "pr-link-failed:pr:${pr_number}" >&2
            exit 1
        fi
    elif [ "$pr_milestone" = "$cycle" ]; then
        echo "pr:${pr_number}:already-linked:milestone=${cycle}"
    else
        echo "WARNING: pr:${pr_number} は他の Milestone （${pr_milestone}）に紐付け済みです。1 Issue = 1 Milestone 制約のため、付け替えが必要な場合は Operations 担当者に委ねます" >&2
        echo "pr:${pr_number}:other-milestone:current=${pr_milestone}:skip-overwrite"
    fi
}

cmd_early_link() {
    local cycle="$1"
    shift
    local milestone_number=""
    local issues=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --milestone-number) milestone_number="$2"; shift 2 ;;
            --issues) issues="$2"; shift 2 ;;
            *) echo "Error: unknown option: $1" >&2; exit 2 ;;
        esac
    done
    if [ -z "$milestone_number" ]; then
        echo "Error: --milestone-number is required" >&2
        exit 2
    fi
    if [ -z "$issues" ]; then
        echo "early-link:no-issues-provided"
        return 0
    fi

    resolve_owner_repo
    lookup_milestones "$cycle"

    if [ "$OPEN_COUNT" -eq 1 ] && [ "$CLOSED_COUNT" -eq 0 ]; then
        local current_milestone
        local view_rc
        while read -r issue; do
            if [ -z "$issue" ]; then continue; fi
            # 既存 Milestone を確認（1 Issue = 1 Milestone 制約のため、付け替えは行わない）
            # link-issues-from-units と同じ冪等補完原則を 02-preparation 段階でも適用
            # `set -e` 配下でも個別 Issue 単位で失敗を集約するため `|| view_rc=$?` で exit 抑制
            view_rc=0
            current_milestone=$(gh issue view "$issue" --json milestone --jq '.milestone.title // empty' 2>/dev/null) || view_rc=$?
            if [ "$view_rc" -ne 0 ]; then
                # 本ステップは exit 0 を維持し、05-completion ステップ1 で再試行（同じ view 失敗が出れば link-failed として exit 1）
                echo "issue:${issue}:view-failed-early:rc=${view_rc}:will-retry-in-05-completion" >&2
                continue
            fi
            if [ -n "$current_milestone" ] && [ "$current_milestone" != "$cycle" ]; then
                echo "WARNING: issue:${issue} は他の Milestone （${current_milestone}）に紐付け済みです。1 Issue = 1 Milestone 制約のため、本ステップでは付け替えず警告のみ。05-completion ステップ1 でも同様にスキップされます。付け替えが必要な場合は (a) 新サイクルへ付け替え / (b) Backlog に戻して保持 の 2 択をユーザーに確認してから手動で付け替えてください" >&2
                echo "issue:${issue}:other-milestone:current=${current_milestone}:skip-overwrite"
                continue
            elif [ "$current_milestone" = "$cycle" ]; then
                echo "issue:${issue}:already-linked:milestone=${cycle}"
                continue
            fi
            # empty Milestone の場合のみ先行紐付け（gh の通常出力は status stream を汚染するため /dev/null へ捨てる）
            if gh issue edit "$issue" --milestone "$cycle" >/dev/null 2>&1; then
                echo "issue:${issue}:linked-early:milestone=${cycle}"
            else
                echo "issue:${issue}:link-failed-early:will-retry-in-05-completion" >&2
            fi
        done <<< "$issues"
    else
        echo "early-link:skip:open=${OPEN_COUNT}:closed=${CLOSED_COUNT}:reason=defer-to-05-completion"
    fi
}

# --- main ---

if [ $# -lt 2 ]; then
    usage >&2
    exit 2
fi

subcommand="$1"
cycle="$2"
shift 2

# 全 subcommand 実行前に依存コマンド（gh / jq）の有無をチェック
require_dependencies

case "$subcommand" in
    ensure-create)         cmd_ensure_create "$cycle" "$@" ;;
    verify-or-create)      cmd_verify_or_create "$cycle" "$@" ;;
    close)                 cmd_close "$cycle" "$@" ;;
    link-issues-from-units) cmd_link_issues_from_units "$cycle" "$@" ;;
    link-pr)               cmd_link_pr "$cycle" "$@" ;;
    early-link)            cmd_early_link "$cycle" "$@" ;;
    -h|--help|help)        usage; exit 0 ;;
    *)
        echo "Error: unknown subcommand: $subcommand" >&2
        usage >&2
        exit 2
        ;;
esac
