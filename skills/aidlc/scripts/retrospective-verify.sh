#!/usr/bin/env bash
# retrospective-verify.sh - Unit 003 機械検証 CLI
#
# 使用方法:
#   retrospective-verify.sh [--cycle <CYCLE>] [--strict] [--dry-run] [--help]
#
# 動作:
#   gh issue list --label retrospective --milestone <CYCLE> --state all で Issue 列挙
#   各 Issue 本文から末尾 YAML ブロックを抽出し、human_reviewed の値で状態判定
#   stdout: <state>\t<issue_number>\t<title> 形式で各 Issue を出力 + 末尾サマリ
#   stderr: <level>\t<code>\t<detail> 形式
#
# exit code:
#   0: 全件 verified または対象 Issue 0 件
#   1: unverified ≥ 1（--strict 時は unverified + skipped ≥ 1）/ ランタイム異常（gh 不可 / Milestone 不在 / cycle 未解決 / I/O）
#   2: 引数エラー（不正なオプション / 必須引数欠落 / 値域違反）

set -uo pipefail

# ─── 診断出力ヘルパ ─────────
__retro_verify_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

# ─── usage 表示 ─────────
__retro_verify_usage() {
    cat <<'EOF'
retrospective-verify.sh - retrospective Issue の human_reviewed 機械検証 CLI

USAGE:
    retrospective-verify.sh [OPTIONS]

OPTIONS:
    --cycle <CYCLE>   検証対象サイクル名（例: v2.5.1）
                      未指定時は [project].cycle 設定 → 最新 open Milestone の順で解決
    --strict          skipped も未確認扱い（旧仕様 Issue を未確認として exit 1 にする）
    --dry-run         副作用なし（gh API 呼び出しは行うが結果集計のみ / stdout レポート出力）
    --help            このヘルプを表示

EXIT CODES:
    0   全件 verified または対象 Issue 0 件
    1   未確認あり / ランタイム異常（gh 不可 / Milestone 不在 / cycle 未解決 / I/O）
    2   引数エラー
EOF
}

# ─── cycle 解決 ─────────
__retro_verify_resolve_cycle() {
    local cli_cycle="$1"
    if [[ -n "$cli_cycle" ]]; then
        printf '%s\n' "$cli_cycle"
        return 0
    fi

    # [project].cycle 設定から取得（read-config.sh があれば）
    local config_cycle=""
    if [[ -x "${SCRIPT_DIR:-}/read-config.sh" ]]; then
        config_cycle=$("${SCRIPT_DIR}/read-config.sh" project.cycle 2>/dev/null || true)
    fi
    if [[ -n "$config_cycle" ]]; then
        printf '%s\n' "$config_cycle"
        return 0
    fi

    # 最新 open Milestone の title を取得（jq で title を抽出）
    local latest_milestone=""
    if command -v gh >/dev/null 2>&1; then
        local open_json
        open_json=$(gh api "repos/{owner}/{repo}/milestones?state=open&per_page=100" 2>/dev/null || true)
        if [[ -n "$open_json" ]]; then
            latest_milestone=$(printf '%s' "$open_json" | jq -r 'if type == "array" and length > 0 then (sort_by(.created_at) | reverse | .[0].title) else "" end' 2>/dev/null || true)
        fi
        if [[ "$latest_milestone" == "null" ]]; then
            latest_milestone=""
        fi
    fi
    if [[ -n "$latest_milestone" ]]; then
        printf '%s\n' "$latest_milestone"
        return 0
    fi

    return 1
}

# ─── 末尾 YAML ブロック抽出 ─────────
# 引数: $1=Issue 本文
# stdout: 末尾の ```yaml ... ``` フェンス内のみ（複数あれば最後 / 不在時は空）
__retro_verify_extract_tail_yaml() {
    local body="$1"
    # 末尾の ```yaml ブロックを抽出（複数フェンスの場合は最後のみ）
    printf '%s\n' "$body" | awk '
        BEGIN { in_block = 0; last = "" }
        /^```yaml[[:space:]]*$/ { in_block = 1; last = ""; next }
        /^```[[:space:]]*$/ {
            if (in_block) { in_block = 0; tail = last }
            next
        }
        in_block { last = (last == "" ? $0 : last "\n" $0) }
        END { if (tail != "") print tail }
    '
}

# ─── Issue 状態判定 ─────────
# 引数: $1=Issue 本文（複数行 / Markdown）/ $2=Issue 番号（YAML パース警告ログ用）
# stdout: "verified" / "unverified" / "skipped"
# 副作用: YAML パース失敗時に stderr warn
__retro_verify_classify_state() {
    local body="$1"
    local issue_number="${2:-?}"

    # 末尾 ```yaml フェンスを抽出（YAML ブロック存在判定 / marker 抽出 / yq パース検証で共用）
    local tail_yaml=""
    tail_yaml=$(__retro_verify_extract_tail_yaml "$body")

    # フェンスなし = 旧仕様 Issue / 検証対象外 → skipped（body 全体 grep への誤検出フォールバックは廃止）
    if [[ -z "$tail_yaml" ]]; then
        printf 'skipped\n'
        return 0
    fi

    # tail_yaml に新仕様の特徴的キー（mirror_state / skill_caused_judgment）がない → 旧仕様 → skipped
    if ! printf '%s\n' "$tail_yaml" | grep -qE '^(mirror_state:|skill_caused_judgment:)' 2>/dev/null; then
        printf 'skipped\n'
        return 0
    fi

    # YAML パース検証（yq 利用可能時のみ）
    if command -v yq >/dev/null 2>&1; then
        if ! printf '%s\n' "$tail_yaml" | yq eval '.' - >/dev/null 2>&1; then
            __retro_verify_diag "warn" "verify_yaml_parse_failed" \
                "tail YAML block parse failed in issue #$issue_number (treating as unverified)"
            printf 'unverified\n'
            return 0
        fi
    fi

    # human_reviewed キー抽出（tail_yaml 限定）
    local marker_line
    marker_line=$(printf '%s\n' "$tail_yaml" | grep -E '^human_reviewed:' | head -1)

    if [[ -z "$marker_line" ]]; then
        # 末尾 YAML に human_reviewed キー欠落 → unverified
        printf 'unverified\n'
        return 0
    fi

    # human_reviewed: true → verified / false (or 非 bool) → unverified
    if printf '%s\n' "$marker_line" | grep -qE '^human_reviewed:[[:space:]]*true[[:space:]]*$'; then
        printf 'verified\n'
    else
        printf 'unverified\n'
    fi
    return 0
}

# ─── 引数パース ─────────
main() {
    local cli_cycle=""
    local strict=0
    local dry_run=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cycle)
                if [[ $# -lt 2 ]] || [[ -z "${2:-}" ]]; then
                    __retro_verify_diag "error" "verify_invalid_args" "--cycle requires a value"
                    return 2
                fi
                cli_cycle="$2"
                shift 2
                ;;
            --strict)
                strict=1
                shift
                ;;
            --dry-run)
                dry_run=1
                shift
                ;;
            --help|-h)
                __retro_verify_usage
                return 0
                ;;
            *)
                __retro_verify_diag "error" "verify_invalid_args" "unknown option: $1"
                return 2
                ;;
        esac
    done

    # cycle 解決
    local cycle
    if ! cycle=$(__retro_verify_resolve_cycle "$cli_cycle"); then
        __retro_verify_diag "error" "verify_cycle_unresolved" \
            "no --cycle given, no [project].cycle config, no open milestone"
        return 1
    fi

    # gh 利用可能性チェック
    if ! command -v gh >/dev/null 2>&1; then
        __retro_verify_diag "error" "verify_gh_unavailable" "gh command not found"
        return 1
    fi

    # Milestone 存在確認（cycle は --arg で受け渡し / jq 式注入を防止）
    local milestone_json
    milestone_json=$(gh api "repos/{owner}/{repo}/milestones?state=all&per_page=100" 2>&1) || {
        __retro_verify_diag "error" "verify_gh_unavailable" "gh api failed: $milestone_json"
        return 1
    }
    local milestone_check
    milestone_check=$(printf '%s' "$milestone_json" | jq --arg cycle "$cycle" '[.[] | select(.title == $cycle) | .number] | length' 2>&1) || {
        __retro_verify_diag "error" "verify_gh_unavailable" "jq filter failed: $milestone_check"
        return 1
    }
    if [[ "$milestone_check" == "0" ]]; then
        __retro_verify_diag "error" "verify_milestone_not_found" \
            "milestone with title '$cycle' not found"
        return 1
    fi

    # Issue 列挙
    local issues_json
    if ! issues_json=$(gh issue list --label retrospective --milestone "$cycle" --state all --json number,title,body --limit 200 2>&1); then
        __retro_verify_diag "error" "verify_gh_unavailable" "gh issue list failed: $issues_json"
        return 1
    fi

    # 各 Issue を判定
    local verified_count=0
    local unverified_count=0
    local skipped_count=0
    local total
    total=$(printf '%s' "$issues_json" | jq -r '. | length' 2>/dev/null || printf '0\n')

    if [[ "$total" == "0" ]]; then
        printf 'summary\tverified=0\tunverified=0\tskipped=0\n'
        __retro_verify_diag "info" "verify_summary" "no retrospective issues found for $cycle"
        return 0
    fi

    local i
    for ((i = 0; i < total; i++)); do
        local issue_number
        local issue_title
        local issue_body
        issue_number=$(printf '%s' "$issues_json" | jq -r ".[$i].number")
        issue_title=$(printf '%s' "$issues_json" | jq -r ".[$i].title")
        issue_body=$(printf '%s' "$issues_json" | jq -r ".[$i].body")

        local state
        state=$(__retro_verify_classify_state "$issue_body" "$issue_number")

        printf '%s\t%s\t%s\n' "$state" "$issue_number" "$issue_title"

        case "$state" in
            verified) verified_count=$((verified_count + 1)) ;;
            unverified) unverified_count=$((unverified_count + 1)) ;;
            skipped) skipped_count=$((skipped_count + 1)) ;;
        esac
    done

    # サマリ出力
    printf 'summary\tverified=%d\tunverified=%d\tskipped=%d\n' \
        "$verified_count" "$unverified_count" "$skipped_count"

    if [[ "$dry_run" -eq 1 ]]; then
        __retro_verify_diag "info" "verify_summary" \
            "[dry-run] verified=$verified_count unverified=$unverified_count skipped=$skipped_count"
    else
        __retro_verify_diag "info" "verify_summary" \
            "verified=$verified_count unverified=$unverified_count skipped=$skipped_count"
    fi

    # exit code 判定
    if [[ "$strict" -eq 1 ]]; then
        if [[ $((unverified_count + skipped_count)) -gt 0 ]]; then
            return 1
        fi
    else
        if [[ "$unverified_count" -gt 0 ]]; then
            return 1
        fi
    fi
    return 0
}

# SCRIPT_DIR 解決（read-config.sh のために）
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

# 直接実行時のみ main を起動（source 経由ではない場合）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
