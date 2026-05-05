#!/usr/bin/env bash
# predecessor-issue.sh - Unit 004 predecessor handoff の Issue 検索ライブラリ
#
# 提供する公開関数:
#   predecessor_resolve_issue <prev_cycle>
#       -> stdout に NDJSON 1 行で解決結果を出力
#       -> exit 0=成功（warn 含む / 経路 4 でも 0） / 1=継続不能エラー / 2=引数エラー
#
# 出力 NDJSON フォーマット:
#   {"resolution_path": "milestone_and_label|label_fallback|spool_fallback|v2_5_0_compat|warn_continue",
#    "issue_url": "https://...|null",
#    "file_path": "cycles/.../retrospective.md|null",
#    "source_milestone": "v2.5.0|null",
#    "candidates": [{"url": "...", "title": "...", "closedAt": "..."}, ...]}
#
# stderr フォーマット: <level>\t<code>\t<detail>  (level=info|warn|error)
#
# 責務分離（重要）:
#   - 本関数は候補集合 + 推奨候補（closedAt 降順ソート）+ 解決経路の確定までを純ロジックで行う
#   - 複数件ヒット時の AskUserQuestion 起動 / ユーザー選択は 01-setup §4a の AI エージェント側責務
#   - 本関数は対話 I/O を一切行わない

# 多重 source ガード
if [[ "${__AIDLC_PREDECESSOR_ISSUE_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_PREDECESSOR_ISSUE_SH_LOADED=1

# SCRIPT_DIR は無条件初期化（retrospective-issue.sh が事前 source 済でも read-config.sh パス解決に使用）
__PRED_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

# Unit 002 ライブラリを source（`__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries` 借用）
if [[ -z "${__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED:-}" ]]; then
    # shellcheck source=/dev/null
    source "${__PRED_SCRIPT_DIR}/retrospective-issue.sh"
fi

# ─── 診断出力ヘルパ ─────────
__pred_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

# ─── 純粋関数: 解決経路分類 ─────────
# 入力:
#   $1=gh_status (available|unavailable|not-installed)
#   $2=milestone_enabled (true|false)
#   $3=query_count (Issue 検索ヒット数 / gh 不可時は -1)
#   $4=spool_exists (true|false)
#   $5=compat_file_exists (true|false)
# stdout: ResolutionPath (milestone_and_label|label_fallback|spool_fallback|v2_5_0_compat|warn_continue)
_pure_classify_resolution_path() {
    local gh_status="$1"
    local milestone_enabled="$2"
    local query_count="$3"
    local spool_exists="$4"
    local compat_file_exists="$5"

    # 経路 1: gh × milestone 検索ヒット
    if [[ "$gh_status" == "available" && "$milestone_enabled" == "true" && "$query_count" -ge 1 ]]; then
        printf 'milestone_and_label\n'
        return 0
    fi

    # 経路 1': gh × label fallback ヒット
    if [[ "$gh_status" == "available" && "$milestone_enabled" == "false" && "$query_count" -ge 1 ]]; then
        printf 'label_fallback\n'
        return 0
    fi

    # 経路 2: 経路 1/1' で 0 件 OR gh 不可、AND spool 存在
    if [[ "$spool_exists" == "true" ]]; then
        printf 'spool_fallback\n'
        return 0
    fi

    # 経路 3: 1/1'/2 すべて 0 件 AND 互換ファイル存在
    if [[ "$compat_file_exists" == "true" ]]; then
        printf 'v2_5_0_compat\n'
        return 0
    fi

    # 経路 4: 全経路 0 件
    printf 'warn_continue\n'
}

# ─── 純粋関数: gh issue list 引数生成 ─────────
# stdout: スペース区切りの引数列（NUL 区切りでなく単純スペース / 値に空白なし前提）
_pure_format_query_args() {
    local prev_cycle="$1"
    local milestone_enabled="$2"

    if [[ "$milestone_enabled" == "true" ]]; then
        printf -- '--milestone %s --label retrospective --state all --limit 50\n' "$prev_cycle"
    else
        printf -- '--label retrospective --state all --limit 50\n'
    fi
}

# ─── 純粋関数: closedAt 降順ソート（並び替えのみ / 自動採用しない）─────────
# 入力（stdin）: gh issue list --json url,title,closedAt の出力 JSON 配列
# stdout: closedAt 降順でソートした JSON 配列
_pure_sort_by_closed_at_desc() {
    jq 'sort_by(.closedAt) | reverse'
}

# ─── 内部関数: gh issue list 実行 ─────────
# 入力: $1=prev_cycle / $2=milestone_enabled
# stdout: gh issue list --json url,title,closedAt の JSON 配列（closedAt 降順ソート済）
# 戻り値: 0=成功 / 1=gh エラー
#
# 注: milestone_enabled=false 時は milestone でクエリ絞り込みできないため、
# title が "Retrospective: <prev_cycle>" を含むものに jq で post-filter する
# （Issue title canonical: lib/retrospective-issue.sh `RETROSPECTIVE_ISSUE_TITLE_TEMPLATE="Retrospective: %s"`）
__pred_gh_query() {
    local prev_cycle="$1"
    local milestone_enabled="$2"

    local json
    if [[ "$milestone_enabled" == "true" ]]; then
        json=$(gh issue list --milestone "$prev_cycle" --label retrospective --state all --limit 50 --json url,title,closedAt 2>&1) || {
            __pred_diag "warn" "predecessor_gh_error" "gh issue list (milestone) failed: $json"
            return 1
        }
        printf '%s\n' "$json" | _pure_sort_by_closed_at_desc
    else
        json=$(gh issue list --label retrospective --state all --limit 50 --json url,title,closedAt 2>&1) || {
            __pred_diag "warn" "predecessor_gh_error" "gh issue list (label fallback) failed: $json"
            return 1
        }
        # label fallback: title で prev_cycle を完全一致絞り込み（v2.5.0 と v2.5.0-rc1 の誤マッチ防止）
        # canonical title format: "Retrospective: <cycle>"（lib/retrospective-issue.sh L41）
        printf '%s\n' "$json" | jq --arg cycle "$prev_cycle" '[ .[] | select(.title == "Retrospective: " + $cycle or (.title | startswith("Retrospective: " + $cycle + " "))) ]' | _pure_sort_by_closed_at_desc
    fi
}

# ─── 内部関数: spool ファイルから issue_url を抽出 ─────────
# 入力: $1=spool_path
# stdout: 1 件の issue_url（複数あれば末尾優先）/ 取得失敗時は空文字
# 戻り値: 0=成功（空文字でも 0）/ 1=I/O エラー / 2=ヘッダ不正
#
# Unit 002 spool schema:
#   .partial_state.local_created  - local 起票成功時の URL（ない場合 null）
#   .partial_state.mirror_created - mirror 起票成功時の URL（ない場合 null）
# 旧版互換: .issue_url（v2.5.0 以前の互換 / 現行 schema にはないが parse fallback として残す）
#
# 優先順位: partial_state.local_created → partial_state.mirror_created → issue_url（旧版互換）
# 全 null の場合は空文字を返す（gh-not-available 等で URL 未確定の状態）
__pred_read_spool_issue_url() {
    local spool_path="$1"

    [[ -f "$spool_path" ]] || return 0

    local entries
    entries=$(_spool_extract_entries "$spool_path" 2>&1)
    local rc=$?
    if [[ "$rc" -ne 0 ]]; then
        __pred_diag "warn" "predecessor_spool_invalid" "spool extract failed (rc=$rc): $entries"
        return 2
    fi

    # NDJSON 各行から URL 抽出（partial_state.local_created 優先 / mirror_created → 旧 issue_url の順で fallback）
    # 最後の非 null URL を採用（spool 末尾優先 / Unit 002 append 順 invariant に依存）
    local last_url
    last_url=$(printf '%s\n' "$entries" | jq -r '
        (.partial_state.local_created // .partial_state.mirror_created // .issue_url // empty)
        | select(. != null and . != "")
    ' 2>/dev/null | tail -1)
    if [[ -z "$last_url" ]]; then
        return 0
    fi

    printf '%s\n' "$last_url"
}

# ─── 内部関数: v2.5.0 互換ファイル確認 ─────────
# 入力: $1=prev_cycle
# stdout: ファイルパス（存在時）/ 空文字（不在時）
__pred_read_compat_file() {
    local prev_cycle="$1"
    local compat_path=".aidlc/cycles/${prev_cycle}/operations/retrospective.md"

    if [[ -f "$compat_path" ]]; then
        printf '%s\n' "$compat_path"
    fi
}

# ─── 内部関数: NDJSON 結果出力 ─────────
# 入力: $1=resolution_path / $2=issue_url / $3=file_path / $4=source_milestone / $5=candidates_json
__pred_emit_result() {
    local resolution_path="$1"
    local issue_url="$2"
    local file_path="$3"
    local source_milestone="$4"
    local candidates_json="${5:-[]}"

    # null/値の判定
    local issue_url_json="null"
    [[ -n "$issue_url" ]] && issue_url_json=$(printf '%s' "$issue_url" | jq -R .)
    local file_path_json="null"
    [[ -n "$file_path" ]] && file_path_json=$(printf '%s' "$file_path" | jq -R .)
    local source_milestone_json="null"
    [[ -n "$source_milestone" ]] && source_milestone_json=$(printf '%s' "$source_milestone" | jq -R .)

    # JSON 1 行で出力
    jq -c -n \
        --arg rp "$resolution_path" \
        --argjson iu "$issue_url_json" \
        --argjson fp "$file_path_json" \
        --argjson sm "$source_milestone_json" \
        --argjson cd "$candidates_json" \
        '{resolution_path: $rp, issue_url: $iu, file_path: $fp, source_milestone: $sm, candidates: $cd}'
}

# ─── 公開関数: predecessor_resolve_issue ─────────
predecessor_resolve_issue() {
    if [[ $# -lt 1 ]] || [[ -z "${1:-}" ]]; then
        __pred_diag "error" "predecessor_invalid_cycle" "predecessor_resolve_issue requires <prev_cycle>"
        return 2
    fi

    local prev_cycle="$1"

    # prev_cycle 検証（Unit 002 既存関数を借用）
    if ! __retro_validate_cycle "$prev_cycle" 2>/dev/null; then
        __pred_diag "error" "predecessor_invalid_cycle" "invalid prev_cycle: $prev_cycle"
        return 2
    fi

    # gh_status 取得（Unit 002 既存関数を借用）
    local gh_status
    if ! gh_status=$(__retro_gh_status); then
        __pred_diag "error" "predecessor_gh_fatal" "__retro_gh_status execution failed"
        return 1
    fi

    # milestone_enabled を read-config.sh から取得（不在時は true をデフォルト）
    local milestone_enabled="true"
    if [[ -x "${__PRED_SCRIPT_DIR}/../read-config.sh" ]]; then
        local config_value
        config_value=$("${__PRED_SCRIPT_DIR}/../read-config.sh" project.milestone_enabled 2>/dev/null || true)
        if [[ "$config_value" == "false" ]]; then
            milestone_enabled="false"
        fi
    fi

    # spool / 互換パス事前計算
    local spool_path=".aidlc/cycles/${prev_cycle}/history/retrospective-spool.md"
    local compat_path=".aidlc/cycles/${prev_cycle}/operations/retrospective.md"

    local spool_exists="false"
    [[ -f "$spool_path" && -s "$spool_path" ]] && spool_exists="true"
    local compat_file_exists="false"
    [[ -f "$compat_path" ]] && compat_file_exists="true"

    # ───── 経路 1 / 1' 試行（gh available のみ）─────
    local query_json="[]"
    local query_count=-1
    if [[ "$gh_status" == "available" ]]; then
        if query_json=$(__pred_gh_query "$prev_cycle" "$milestone_enabled"); then
            query_count=$(printf '%s' "$query_json" | jq 'length')
        else
            query_count=-1
        fi
    fi

    # 解決経路を分類
    local resolution_path
    resolution_path=$(_pure_classify_resolution_path "$gh_status" "$milestone_enabled" "$query_count" "$spool_exists" "$compat_file_exists")

    # 経路ごとの処理
    case "$resolution_path" in
        milestone_and_label|label_fallback)
            local issue_url=""
            local source_milestone=""
            [[ "$resolution_path" == "milestone_and_label" ]] && source_milestone="$prev_cycle"

            if [[ "$query_count" -eq 1 ]]; then
                issue_url=$(printf '%s' "$query_json" | jq -r '.[0].url')
                if [[ "$resolution_path" == "milestone_and_label" ]]; then
                    __pred_diag "info" "predecessor_resolved_milestone_label" "issue_url=$issue_url"
                else
                    __pred_diag "info" "predecessor_resolved_label_fallback" "issue_url=$issue_url"
                fi
                __pred_emit_result "$resolution_path" "$issue_url" "" "$source_milestone" "$query_json"
            else
                # 複数件: 候補リストを NDJSON で出力 / AskUserQuestion は AI エージェント側
                __pred_diag "info" "predecessor_candidates_emitted" "count=$query_count (AI agent should AskUserQuestion)"
                __pred_emit_result "$resolution_path" "" "" "$source_milestone" "$query_json"
            fi
            return 0
            ;;
        spool_fallback)
            local spool_url
            spool_url=$(__pred_read_spool_issue_url "$spool_path")
            local rc=$?
            if [[ "$rc" -eq 1 ]]; then
                __pred_diag "error" "predecessor_io_error" "spool I/O error: $spool_path"
                return 1
            fi
            if [[ -z "$spool_url" ]]; then
                # spool は存在したが URL 取得不能 → 経路 3 へ移行
                if [[ "$compat_file_exists" == "true" ]]; then
                    __pred_diag "info" "predecessor_resolved_compat" "file_path=$compat_path"
                    __pred_emit_result "v2_5_0_compat" "" "$compat_path" "" "[]"
                    return 0
                fi
                __pred_diag "warn" "predecessor_no_reference" "all paths exhausted (spool URL extraction failed)"
                __pred_emit_result "warn_continue" "" "" "" "[]"
                return 0
            fi
            __pred_diag "info" "predecessor_resolved_spool" "issue_url=$spool_url"
            __pred_emit_result "spool_fallback" "$spool_url" "" "" "[]"
            return 0
            ;;
        v2_5_0_compat)
            __pred_diag "info" "predecessor_resolved_compat" "file_path=$compat_path"
            __pred_emit_result "v2_5_0_compat" "" "$compat_path" "" "[]"
            return 0
            ;;
        warn_continue)
            __pred_diag "warn" "predecessor_no_reference" "all paths returned 0 / continue without predecessor"
            __pred_emit_result "warn_continue" "" "" "" "[]"
            return 0
            ;;
        *)
            __pred_diag "error" "predecessor_io_error" "unexpected resolution_path: $resolution_path"
            return 1
            ;;
    esac
}
