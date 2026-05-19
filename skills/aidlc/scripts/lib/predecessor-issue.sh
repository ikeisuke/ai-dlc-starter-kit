#!/usr/bin/env bash
# predecessor-issue.sh - Unit 004 predecessor handoff の Issue 検索ライブラリ
#
# 提供する公開関数:
#   predecessor_resolve_issue <prev_cycle>
#       -> stdout に NDJSON 1 行で解決結果を出力
#       -> exit 0=成功（warn 含む / 経路 4 でも 0） / 1=継続不能エラー / 2=引数エラー
#
# 出力 NDJSON フォーマット:
#   {"resolution_path": "milestone_and_label|label_fallback|spool_fallback|v2_5_0_compat|t_issue_milestone_scope|t_issue_label_fallback|warn_continue",
#    "issue_url": "https://...|null",
#    "file_path": "cycles/.../retrospective.md|null",
#    "source_milestone": "v2.5.0|null",
#    "candidates": [{"url": "...", "title": "...", "closedAt": "..."}, ...]}
#
# 新動作経路（v2.6.6 / Unit 004）:
#   t_issue_milestone_scope: 既存 5 経路すべて 0 件 + 同 milestone 内 retrospective ラベル付き T Issue ≥ 1
#   t_issue_label_fallback : 既存 5 経路すべて 0 件 + milestone 無 retrospective ラベル付き T Issue ≥ 1
#   いずれも候補集合のみ返す（issue_url 確定しない / AI agent 側で AskUserQuestion 起動）
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

# SCRIPT_DIR は無条件初期化（read-config.sh パス解決に使用）
# Unit 004 (#659): zsh interactive shell からの `source` 経路でも SCRIPT_DIR を解決できるよう、
# ZSH_VERSION で shell 判定し zsh 用に ${(%):-%N} を使用する（bash 経路は既存ロジック維持）。
# ${(%):-%N} は zsh パラメータ展開（プロンプト展開）で source されたファイルパスを返す。
# bash パーサで ${(%):-%N} を含む式を直接評価するとエラーとなるため、shell 判定で完全に独立したブロックに分岐する。
if [[ -n "${ZSH_VERSION:-}" ]]; then
    # shellcheck disable=SC1083,SC2296
    # zsh パラメータ展開（${(%):-%N}）は shellcheck（bash 前提）で警告となるが、ZSH_VERSION 判定下でのみ評価されるため安全
    __PRED_SCRIPT_DIR=$(cd -- "$(dirname -- "${(%):-%N}")" >/dev/null 2>&1 && pwd)
else
    __PRED_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
fi

# Unit 004 (#643): retrospective-issue.sh への直接 source を撤去し、独立 helper 群を直接 source
# 順序固定: aidlc-paths → aidlc-validate → aidlc-gh → aidlc-spool（全 helper 多重 source ガード適用）
# shellcheck source=aidlc-paths.sh
source "${__PRED_SCRIPT_DIR}/aidlc-paths.sh"
# shellcheck source=aidlc-validate.sh
source "${__PRED_SCRIPT_DIR}/aidlc-validate.sh"
# shellcheck source=aidlc-gh.sh
source "${__PRED_SCRIPT_DIR}/aidlc-gh.sh"
# shellcheck source=aidlc-spool.sh
source "${__PRED_SCRIPT_DIR}/aidlc-spool.sh"

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
#   $6=t_milestone_count (Unit 004 新経路 / T Issue milestone 集計ヒット数 / 未指定=0 = 既存挙動互換)
#   $7=t_label_count (Unit 004 新経路 / T Issue label 集計ヒット数 / 未指定=0 = 既存挙動互換)
# stdout: ResolutionPath (milestone_and_label|label_fallback|spool_fallback|v2_5_0_compat|t_issue_milestone_scope|t_issue_label_fallback|warn_continue)
#
# Unit 004 / v2.6.6:
#   既存 5 経路の判定式・戻り値文字列は完全不変
#   新経路 2 サブ分岐は warn_continue 直前に評価される後段追加
#   $6 / $7 未指定（既存呼出元）は 0 として扱われ、新経路は発火せず warn_continue へ落ちる
_pure_classify_resolution_path() {
    local gh_status="$1"
    local milestone_enabled="$2"
    local query_count="$3"
    local spool_exists="$4"
    local compat_file_exists="$5"
    local t_milestone_count="${6:-0}"
    local t_label_count="${7:-0}"

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

    # 経路 5a (v2.6.6 / Unit 004 新規): 既存 5 経路 0 件 AND gh × T Issue milestone 集計ヒット
    if [[ "$gh_status" == "available" && "$t_milestone_count" -ge 1 ]]; then
        printf 't_issue_milestone_scope\n'
        return 0
    fi

    # 経路 5b (v2.6.6 / Unit 004 新規): 既存 5 経路 0 件 AND gh × T Issue label 集計ヒット
    if [[ "$gh_status" == "available" && "$t_label_count" -ge 1 ]]; then
        printf 't_issue_label_fallback\n'
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

# ─── 純粋関数: closedAt 降順ソート（null 末尾安全 / Unit 004 / v2.6.6 新規）─────────
# 入力（stdin）: gh issue list --json url,title,closedAt の出力 JSON 配列
# stdout: closedAt 降順 / closedAt=null（OPEN Issue）は末尾配置
#
# OPEN な T Issue（closedAt=null）が混入し得る T Issue 集計経路で使用する。
# null → 空文字置換で昇順時に先頭、reverse 後に末尾配置（設計レビュー R1 指摘 #2 対応）
_pure_sort_by_closed_at_desc_null_safe() {
    jq 'sort_by(.closedAt // "") | reverse'
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
        # Unit 004 (v2.6.6): T Issue (`[Retrospective:` prefix) を除外し集約 Issue のみを判別
        # 集約 Issue title canonical: "Retrospective: <cycle>" / T Issue: "[Retrospective: <cycle>] <summary>"
        # T Issue を含む cycle では既存 5 経路を 0 件として後段の新動作経路 (t_issue_*) 評価へ委譲する
        printf '%s\n' "$json" | jq --arg cycle "$prev_cycle" '[ .[] | select(.title == "Retrospective: " + $cycle or (.title | startswith("Retrospective: " + $cycle + " "))) ]' | _pure_sort_by_closed_at_desc
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

# ─── 内部関数: T Issue 用 gh issue list 実行（Unit 004 / v2.6.6 新規）─────────
# 入力: $1=prev_cycle / $2=milestone_scope (true=milestone 限定 / false=label のみ)
# stdout: T Issue title prefix "[Retrospective: <cycle>]" でフィルタした JSON 配列
#         (closedAt 降順 / null は末尾)
# 戻り値: 0=成功 / 1=gh エラー
#
# T Issue タイトル canonical:
#   [Retrospective: <cycle>] <Try 内容を 1 行で>
# 既存 5 経路で扱う集約 Issue title "Retrospective: <cycle>" とは prefix で区別される
# （[ で始まるか否か / startswith マッチで安全）。
__pred_gh_query_t_issue() {
    local prev_cycle="$1"
    local milestone_scope="$2"

    local json
    # --json は既存 5 経路と一致する 3 フィールド (url/title/closedAt) のみ取得し
    # candidates スキーマを統一する（コードレビュー R1 指摘 #1 対応 / NDJSON 下流互換維持）
    if [[ "$milestone_scope" == "true" ]]; then
        json=$(gh issue list --milestone "$prev_cycle" --label retrospective --state all --limit 50 --json url,title,closedAt 2>&1) || {
            __pred_diag "warn" "predecessor_t_issue_gh_error" "gh issue list (t_milestone) failed: $json"
            return 1
        }
    else
        json=$(gh issue list --label retrospective --state all --limit 50 --json url,title,closedAt 2>&1) || {
            __pred_diag "warn" "predecessor_t_issue_gh_error" "gh issue list (t_label) failed: $json"
            return 1
        }
    fi
    # T Issue title canonical: "[Retrospective: <cycle>]" 完全一致 または "[Retrospective: <cycle>] " で始まる
    # （末尾が ] の単独 / ] + 半角スペース + summary に限定し、"[Retrospective: <cycle>]foo" 等の
    #  cycle id 偽装・ノイズ混入を排除する / コードレビュー R1 指摘 #2 対応）
    printf '%s\n' "$json" | jq --arg cycle "$prev_cycle" '
        [ .[]
          | select(
              .title == "[Retrospective: " + $cycle + "]"
              or (.title | startswith("[Retrospective: " + $cycle + "] "))
            )
        ]' | _pure_sort_by_closed_at_desc_null_safe
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
    local compat_path
    # Unit 003 (#638): aidlc-paths.sh helper 経由
    compat_path=$(aidlc_cycle_path "$prev_cycle" "operations/retrospective.md")

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

    # spool / 互換パス事前計算（Unit 003 #638: aidlc-paths.sh helper 経由）
    local spool_path compat_path
    spool_path=$(aidlc_cycle_path "$prev_cycle" "history/retrospective-spool.md")
    compat_path=$(aidlc_cycle_path "$prev_cycle" "operations/retrospective.md")

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

    # 解決経路を分類（既存 5 経路 / 引数 5 個 = 既存挙動）
    local resolution_path
    resolution_path=$(_pure_classify_resolution_path "$gh_status" "$milestone_enabled" "$query_count" "$spool_exists" "$compat_file_exists")

    # ───── Unit 004 (v2.6.6) 新動作経路: 既存 5 経路すべて 0 件のときのみ評価 ─────
    # warn_continue 直前に T Issue 集計経路を試行する。
    # 既存 5 経路 (milestone_and_label / label_fallback / spool_fallback / v2_5_0_compat) のいずれかが
    # ヒットした場合は新経路を評価せず既存挙動を維持（後方互換保護）。
    local t_query_json="[]"
    local t_milestone_count=0
    local t_label_count=0
    if [[ "$resolution_path" == "warn_continue" && "$gh_status" == "available" ]]; then
        local t_query_milestone="[]"
        local t_query_label="[]"
        if t_query_milestone=$(__pred_gh_query_t_issue "$prev_cycle" "true"); then
            t_milestone_count=$(printf '%s' "$t_query_milestone" | jq 'length')
        else
            t_milestone_count=0
        fi
        if [[ "$t_milestone_count" -eq 0 ]]; then
            if t_query_label=$(__pred_gh_query_t_issue "$prev_cycle" "false"); then
                t_label_count=$(printf '%s' "$t_query_label" | jq 'length')
            else
                t_label_count=0
            fi
        fi
        # 純粋関数を再評価（新経路 2 サブ分岐を含む）
        resolution_path=$(_pure_classify_resolution_path "$gh_status" "$milestone_enabled" "$query_count" "$spool_exists" "$compat_file_exists" "$t_milestone_count" "$t_label_count")
        case "$resolution_path" in
            t_issue_milestone_scope) t_query_json="$t_query_milestone" ;;
            t_issue_label_fallback)  t_query_json="$t_query_label" ;;
        esac
    fi

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
        t_issue_milestone_scope|t_issue_label_fallback)
            # Unit 004 (v2.6.6) 新動作経路: T Issue 群候補集合のみ返す
            # issue_url は確定しない（候補集合からの選択は AI agent 側責務 / AskUserQuestion 起動）
            local source_milestone=""
            [[ "$resolution_path" == "t_issue_milestone_scope" ]] && source_milestone="$prev_cycle"
            local t_count
            t_count=$(printf '%s' "$t_query_json" | jq 'length')
            __pred_diag "info" "predecessor_resolved_${resolution_path}" "t_candidates=$t_count (AI agent should AskUserQuestion)"
            __pred_emit_result "$resolution_path" "" "" "$source_milestone" "$t_query_json"
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
