#!/usr/bin/env bash
#
# retrospective-mirror.sh - mirror モードの retrospective フロー（Unit 005 / #590）
#
# 使用方法:
#   retrospective-mirror.sh detect <retrospective.md>
#     → feedback_mode 解決 + skill_caused=true × mirror_state.state="" の candidate 抽出
#
#   retrospective-mirror.sh send <retrospective.md> <problem_index> <title> <draft_body_path>
#     → gh issue create + retrospective.md の mirror_state.state を sent に更新
#
#   retrospective-mirror.sh record <retrospective.md> <problem_index> <decision>
#     → retrospective.md の mirror_state.state を skipped/pending に更新
#
# 出力（stdout）:
#   detect:  mirror\tcandidate\t<idx>\t<title>\t<draft_path>
#            mirror\tskip\tnot-mirror-mode|no-skill-caused|all-processed
#            summary\tcounts\ttotal=<N>;skill_caused_true=<M>;already-processed=<P>
#   send:    mirror\tsent\t<idx>\t<url>
#            mirror\tsend-failed\t<idx>\t<reason>（recoverable / exit 0）
#   record:  mirror\trecorded\t<idx>\t<decision>
#
# 出力（stderr）:
#   warn\t* / error\t*
#
# 終了コード:
#   0 - 正常 + recoverable failure（送信失敗で次の candidate に進める場合を含む）
#   2 - fatal（schema 不在 / dasel 不在 / retrospective 書き込み失敗 / 引数不正）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=lib/bootstrap.sh
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# 一時ファイル管理（Codex 指摘 #4 対応 / trap-based cleanup）
# - extract / classify の中間ファイルは EXIT 時に必ず削除
# - draft 一時ファイルは送信成功後に保持（ユーザーが手動再送できるよう運用ガイド準拠 / 失敗時のみ trap で削除）
declare -a _CLEANUP_TMPFILES=()
_register_cleanup() {
    _CLEANUP_TMPFILES+=("$1")
}
# shellcheck disable=SC2329  # invoked via `trap _cleanup_tmpfiles EXIT`
_cleanup_tmpfiles() {
    local f
    for f in "${_CLEANUP_TMPFILES[@]:-}"; do
        if [ -n "${f:-}" ] && [ -f "$f" ]; then
            rm -f -- "$f" 2>/dev/null || true
        fi
    done
}
trap '_cleanup_tmpfiles' EXIT

readonly SCHEMA_PATH="${AIDLC_PLUGIN_ROOT}/config/retrospective-schema.yml"
readonly DEFAULT_UPSTREAM_REPO="ikeisuke/ai-dlc-starter-kit"

# dasel 検出（Unit 004 と同方針 / 必須依存）
if ! command -v dasel >/dev/null 2>&1; then
    echo "error	dasel-not-installed	install-required" >&2
    exit 2
fi

if [ ! -f "$SCHEMA_PATH" ]; then
    echo "error	schema-not-found	${SCHEMA_PATH}" >&2
    exit 2
fi

# ─── ヘルパー: スキーマからの動的読み出し ─────────
_dasel_query_yaml() {
    local query="$1"
    dasel query -i yaml "$query" <"$SCHEMA_PATH" 2>/dev/null || echo ""
}

# upstream_repo 解決（不正値はデフォルトフォールバック）
_resolve_upstream_repo() {
    local raw=""
    if raw="$("${SCRIPT_DIR}/read-config.sh" rules.feedback.upstream_repo 2>/dev/null)"; then
        :
    else
        raw=""
    fi
    raw="${raw#\"}"
    raw="${raw%\"}"

    local pattern='^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$'
    if [ -z "$raw" ]; then
        echo "$DEFAULT_UPSTREAM_REPO"
        return 0
    fi
    if [[ "$raw" =~ $pattern ]]; then
        echo "$raw"
    else
        echo "warn	upstream-repo-invalid	${raw}:fallback-to-default" >&2
        echo "$DEFAULT_UPSTREAM_REPO"
    fi
}

# feedback_mode 解決（4 階層マージ / 不正値は silent 同等扱い → スキップ）
_resolve_feedback_mode() {
    local raw=""
    if raw="$("${SCRIPT_DIR}/read-config.sh" rules.retrospective.feedback_mode 2>/dev/null)"; then
        :
    else
        raw=""
    fi
    raw="${raw#\"}"
    raw="${raw%\"}"
    if [ -z "$raw" ]; then
        echo "silent"
        return 0
    fi
    case "$raw" in
        silent|mirror|disabled)
            echo "$raw"
            ;;
        *)
            echo "warn	feedback-mode-invalid	${raw}:treated-as-silent" >&2
            echo "silent"
            ;;
    esac
}

# 検証ルール（Unit 004 schema 互換 / detect で使用）
QUOTE_MIN_LENGTH="$(_dasel_query_yaml 'retrospective_schema.skill_caused_judgment.quote_min_length')"
if [ -z "$QUOTE_MIN_LENGTH" ] || ! [[ "$QUOTE_MIN_LENGTH" =~ ^[0-9]+$ ]]; then
    QUOTE_MIN_LENGTH=10
fi

FORBIDDEN_WORDS=()
while IFS= read -r line; do
    line="${line#- }"
    line="${line//\"/}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -n "$line" ]; then
        FORBIDDEN_WORDS+=("$line")
    fi
done < <(_dasel_query_yaml 'retrospective_schema.skill_caused_judgment.quote_forbidden_words')

# mirror_state スキーマ駆動化（Codex 指摘 #2 対応 / 単一ソース原則維持）
MIRROR_STATE_ENUM=()
while IFS= read -r line; do
    line="${line#- }"
    line="${line//\"/}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -n "$line" ]; then
        MIRROR_STATE_ENUM+=("$line")
    fi
done < <(_dasel_query_yaml 'retrospective_schema.mirror_state.state_enum')
if [ "${#MIRROR_STATE_ENUM[@]}" -eq 0 ]; then
    MIRROR_STATE_ENUM=("sent" "skipped" "pending" "")
fi

# dasel YAML 出力からクォート（"" / ''）を剥がすヘルパー
_strip_quotes() {
    local v="$1"
    v="${v%\"}"; v="${v#\"}"
    v="${v%\'}"; v="${v#\'}"
    echo "$v"
}

ISSUE_URL_PATTERN="$(_strip_quotes "$(_dasel_query_yaml 'retrospective_schema.mirror_state.issue_url_pattern')")"
if [ -z "$ISSUE_URL_PATTERN" ]; then
    ISSUE_URL_PATTERN='^https://github\.com/[^/]+/[^/]+/issues/[0-9]+$'
fi

RECORDED_AT_PATTERN="$(_strip_quotes "$(_dasel_query_yaml 'retrospective_schema.mirror_state.recorded_at_pattern')")"
if [ -z "$RECORDED_AT_PATTERN" ]; then
    RECORDED_AT_PATTERN='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
fi

SEND_FAILURE_REASONS=()
while IFS= read -r line; do
    line="${line#- }"
    line="${line//\"/}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -n "$line" ]; then
        SEND_FAILURE_REASONS+=("$line")
    fi
done < <(_dasel_query_yaml 'retrospective_schema.send_failure_reasons')
if [ "${#SEND_FAILURE_REASONS[@]}" -eq 0 ]; then
    SEND_FAILURE_REASONS=("gh-not-authenticated" "gh-rate-limit" "gh-network-error" "gh-unknown-error")
fi

# decision の許容値はスキーマの state_enum から派生（"" / sent を除く）
_is_valid_decision() {
    local d="$1"
    case "$d" in
        skipped|pending) return 0 ;;
        *) return 1 ;;
    esac
}

# send_failure_reasons の許容値判定（実装側で生成する分類が schema と一致するかの自己検査用）
_is_valid_send_failure_reason() {
    local r="$1"
    local v
    for v in "${SEND_FAILURE_REASONS[@]}"; do
        if [ "$v" = "$r" ]; then
            return 0
        fi
    done
    return 1
}

# ─── extract: Markdown から 6 キー + mirror_state を抽出 ─────────
# 出力: extracted\t<problem_index>\t<key>=<value>
# mirror_state.state / issue_url / recorded_at は欠落時 "" 扱い（後方互換 / Rule 5）
_extract() {
    local path="$1"
    awk '
    BEGIN {
        problem_index = 0
        in_yaml = 0
        in_skill_block = 0
        in_mirror_block = 0
    }
    /^### 問題 [0-9]+:/ {
        problem_index++
        in_yaml = 0
        in_skill_block = 0
        in_mirror_block = 0
        next
    }
    /^### 問題なし/ {
        next
    }
    /^```[Yy][Aa]?[Mm][Ll][[:space:]]*$/ && problem_index > 0 {
        in_yaml = 1
        in_skill_block = 0
        in_mirror_block = 0
        next
    }
    /^```[[:space:]]*$/ && in_yaml == 1 {
        in_yaml = 0
        in_skill_block = 0
        in_mirror_block = 0
        next
    }
    in_yaml == 1 {
        line = $0
        # コメント除去
        sub(/[ \t]+#.*$/, "", line)
        # ブロック先頭判定
        if (line ~ /^skill_caused_judgment:[[:space:]]*$/) {
            in_skill_block = 1
            in_mirror_block = 0
            next
        }
        if (line ~ /^mirror_state:[[:space:]]*$/) {
            in_skill_block = 0
            in_mirror_block = 1
            next
        }
        # トップレベル他キー（インデントなし）→ ブロック終了
        if (line ~ /^[A-Za-z]/) {
            in_skill_block = 0
            in_mirror_block = 0
        }
        # ネストキー抽出
        if (in_skill_block == 1 || in_mirror_block == 1) {
            sub(/^[ \t]+/, "", line)
            if (line == "") next
            kv_pos = index(line, ":")
            if (kv_pos == 0) next
            key = substr(line, 1, kv_pos - 1)
            val = substr(line, kv_pos + 1)
            sub(/^[ \t]+/, "", val)
            gsub(/^"|"$/, "", val)
            if (in_mirror_block == 1) {
                # mirror_state プレフィックス付与
                printf "extracted\t%d\tmirror_state.%s=%s\n", problem_index, key, val
            } else {
                printf "extracted\t%d\t%s=%s\n", problem_index, key, val
            }
        }
    }
    END {
        printf "summary\tproblems\ttotal=%d\n", problem_index
    }
    ' "$path"
}

# ─── Unit 006: 氾濫緩和（重複検出 + サイクル毎上限）────────────────────
# 純粋関数フィルタ層（_filter_dedup_and_cap）+ 設定解決 / 正規化サポート

# Python 3 利用可否チェック（NFKC 正規化 / Jaccard / 編集距離計算で必須）
# 不在時 → exit 2 fatal（NfkcUnavailablePolicy = Fatal / DR-006 fatal 系統）
_check_python3() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "error	nfkc-unavailable	python3-required" >&2
        return 2
    fi
    return 0
}

# 文字列正規化（trim + collapse_whitespace + NFKC / Python 3 必須）
# 純粋性レベル: ビジネス副作用なし（python3 サブプロセス呼び出しあり）
_normalize_text() {
    local s="$1"
    if [ -z "$s" ]; then
        echo ""
        return 0
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        echo "error	nfkc-unavailable	python3-required" >&2
        return 2
    fi
    printf '%s' "$s" | python3 -c '
import sys, unicodedata, re
text = sys.stdin.read()
text = unicodedata.normalize("NFKC", text)
text = text.strip()
text = re.sub(r"\s+", " ", text)
sys.stdout.write(text)
' 2>/dev/null
}

# Jaccard 整数化（文字 bigram ベース / マルチバイト対応のため Python 3 経由）
# 出力: Integer 0..1000（= Jaccard係数 × 1000、切り捨て丸め）
# 純粋性レベル: ビジネス副作用なし
# セキュリティ: 入力文字列は stdin にて NUL 区切りで渡す（環境変数経由を避け /proc/*/environ 露出を抑止）
_jaccard_bigram_milli() {
    local a="$1" b="$2"
    if [ -z "$a" ] || [ -z "$b" ]; then
        echo 0
        return 0
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        echo "error	nfkc-unavailable	python3-required" >&2
        return 2
    fi
    printf '%s\0%s' "$a" "$b" | python3 -c '
import sys
data = sys.stdin.buffer.read().decode("utf-8", errors="replace")
parts = data.split("\x00", 1)
a = parts[0]
b = parts[1] if len(parts) > 1 else ""
def bigrams(s):
    if len(s) < 2:
        return {s} if s else set()
    return {s[i:i+2] for i in range(len(s)-1)}
A = bigrams(a)
B = bigrams(b)
union = len(A | B)
if union == 0:
    print(0)
else:
    inter = len(A & B)
    print(int(inter * 1000 / union))
' 2>/dev/null
}

# 編集距離整数化（Levenshtein 距離 / マルチバイト対応のため Python 3 経由）
# 出力: Integer 0..100（= edit_distance × 100 / min_len、切り捨て丸め）
# 両方空文字時は 0 を返す
# セキュリティ: 入力文字列は stdin にて NUL 区切りで渡す（環境変数経由を避ける）
_edit_distance_ratio_pct() {
    local a="$1" b="$2"
    if [ -z "$a" ] && [ -z "$b" ]; then
        echo 0
        return 0
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        echo "error	nfkc-unavailable	python3-required" >&2
        return 2
    fi
    printf '%s\0%s' "$a" "$b" | python3 -c '
import sys
data = sys.stdin.buffer.read().decode("utf-8", errors="replace")
parts = data.split("\x00", 1)
a = parts[0]
b = parts[1] if len(parts) > 1 else ""
la, lb = len(a), len(b)
if la == 0 or lb == 0:
    print(100 if (la + lb) > 0 else 0)
else:
    if la < lb:
        a, b, la, lb = b, a, lb, la
    prev = list(range(lb + 1))
    for i in range(1, la + 1):
        curr = [i] + [0]*lb
        for j in range(1, lb + 1):
            cost = 0 if a[i-1] == b[j-1] else 1
            curr[j] = min(curr[j-1] + 1, prev[j] + 1, prev[j-1] + cost)
        prev = curr
    dist = prev[lb]
    min_len = min(la, lb)
    print(int(dist * 100 / min_len))
' 2>/dev/null
}

# flood_mitigation 設定解決
# 出力: stdout 1 行 TSV 構造化出力
#   config\t<feedback_max_per_cycle>\t<jaccard_milli>\t<edit_dist_pct>\t<nfkc_policy>\t<cap_strategy>
# 純粋性レベル: ビジネス副作用なし（dasel / read-config.sh 呼び出しあり）
_resolve_flood_mitigation_config() {
    # schema からデフォルト値読み込み
    local default_max default_jaccard default_edit_pct default_policy default_cap
    default_max="$(_dasel_query_yaml 'retrospective_schema.flood_mitigation.feedback_max_per_cycle_default')"
    default_jaccard="$(_dasel_query_yaml 'retrospective_schema.flood_mitigation.dedup_jaccard_threshold_milli')"
    default_edit_pct="$(_dasel_query_yaml 'retrospective_schema.flood_mitigation.dedup_edit_distance_ratio_pct')"
    default_policy="$(_strip_quotes "$(_dasel_query_yaml 'retrospective_schema.flood_mitigation.nfkc_unavailable_policy')")"
    default_cap="$(_strip_quotes "$(_dasel_query_yaml 'retrospective_schema.flood_mitigation.cap_strategy')")"

    [ -z "$default_max" ] && default_max=3
    [ -z "$default_jaccard" ] && default_jaccard=700
    [ -z "$default_edit_pct" ] && default_edit_pct=30
    [ -z "$default_policy" ] && default_policy="fatal"
    [ -z "$default_cap" ] && default_cap="skip-and-record"

    # 4 階層マージで feedback_max_per_cycle 取得
    local raw_max=""
    if raw_max="$("${SCRIPT_DIR}/read-config.sh" rules.retrospective.feedback_max_per_cycle 2>/dev/null)"; then
        :
    else
        raw_max=""
    fi
    raw_max="${raw_max#\"}"
    raw_max="${raw_max%\"}"

    local resolved_max="$default_max"
    if [ -n "$raw_max" ]; then
        if [[ "$raw_max" =~ ^[0-9]+$ ]]; then
            resolved_max="$raw_max"
        else
            echo "warn	feedback-max-per-cycle-invalid	${raw_max}:fallback-to-default" >&2
        fi
    fi

    # schema 値も範囲検証（後方互換: 値が壊れていれば default 同値に戻す）
    local resolved_jaccard="$default_jaccard"
    if [[ "$default_jaccard" =~ ^[0-9]+$ ]] && [ "$default_jaccard" -ge 0 ] && [ "$default_jaccard" -le 1000 ]; then
        resolved_jaccard="$default_jaccard"
    else
        echo "warn	jaccard-threshold-invalid	${default_jaccard}:fallback-to-700" >&2
        resolved_jaccard=700
    fi

    local resolved_edit_pct="$default_edit_pct"
    if [[ "$default_edit_pct" =~ ^[0-9]+$ ]] && [ "$default_edit_pct" -ge 0 ] && [ "$default_edit_pct" -le 100 ]; then
        resolved_edit_pct="$default_edit_pct"
    else
        echo "warn	edit-distance-pct-invalid	${default_edit_pct}:fallback-to-30" >&2
        resolved_edit_pct=30
    fi

    printf 'config\t%s\t%s\t%s\t%s\t%s\n' \
        "$resolved_max" "$resolved_jaccard" "$resolved_edit_pct" "$default_policy" "$default_cap"
}

# Pass A: 引用箇所完全一致による重複統合
# 入力: stdin に 6 列 TSV（candidate\t<idx>\t<state>\t<sc>\t<title>\t<normalized_quote>）
# 出力: 各行を以下のいずれかでタグ付けして stdout 出力（同 6 列 + status 列追加）
#   candidate\t<idx>\t...\t<quote>\tpassing                  : 通過
#   candidate\t<idx>\t...\t<quote>\tdedup-merged:<rep_idx>:quote-exact-match : 統合
# 純粋性レベル: 完全純粋（awk 内のみで完結）
_dedup_pass_a() {
    awk -F'\t' '
    $1 == "candidate" {
        idx = $2
        quote = $6
        # quote が "-"（プレースホルダ）なら統合キーにしない（個別通過）
        if (quote == "-" || quote == "") {
            key = "__SOLO__:" NR
        } else {
            key = quote
        }
        if (!(key in first_idx)) {
            first_idx[key] = idx
            tags[NR] = "passing"
            order[++cnt] = NR
            rows[NR] = $0
        } else {
            tags[NR] = "dedup-merged:" first_idx[key] ":quote-exact-match"
            order[++cnt] = NR
            rows[NR] = $0
        }
    }
    END {
        for (i = 1; i <= cnt; i++) {
            n = order[i]
            printf "%s\t%s\n", rows[n], tags[n]
        }
    }
    '
}

# Pass B: タイトル類似度（Jaccard / 編集距離）による重複統合
# 入力: Pass A の出力（7 列: 6 列 candidate + status）
# 出力: 7 列（status 列を更新）
#   passing → そのまま passing or dedup-merged:<rep_idx>:title-jaccard|title-edit-distance
# 純粋性レベル: 完全純粋（_jaccard_bigram_milli / _edit_distance_ratio_pct はビジネス副作用なしレベル → 全体としてはビジネス副作用なしに格下げ）
_dedup_pass_b() {
    local jaccard_milli="$1"
    local edit_dist_pct="$2"

    # 一旦全行を配列に読み込み、passing 行同士を比較する
    local lines=()
    local line
    while IFS= read -r line; do
        lines+=("$line")
    done

    local n="${#lines[@]}"
    if [ "$n" -eq 0 ]; then
        return 0
    fi

    # 各行を分解して passing 配列と全行配列を構築
    # row_quote は本 Pass では参照しないため row_idx / row_title / row_status / row_full のみ保持
    local -a row_idx row_title row_status row_full
    local i
    for ((i=0; i<n; i++)); do
        local fields="${lines[i]}"
        local _kind _state _sc _quote
        IFS=$'\t' read -r _kind idx _state _sc title _quote status <<<"$fields"
        row_idx[i]="$idx"
        row_title[i]="$title"
        row_status[i]="$status"
        row_full[i]="$fields"
    done

    # passing 行の representative を idx 昇順で確定し、各 passing 行を比較
    # i < j の関係で passing[i] が passing[j] の代表となる場合 j を dedup-merged にする
    local j
    for ((i=0; i<n; i++)); do
        if [ "${row_status[i]}" != "passing" ]; then continue; fi
        local title_i="${row_title[i]}"
        local idx_i="${row_idx[i]}"
        for ((j=i+1; j<n; j++)); do
            if [ "${row_status[j]}" != "passing" ]; then continue; fi
            local title_j="${row_title[j]}"
            local jaccard
            jaccard="$(_jaccard_bigram_milli "$title_i" "$title_j")"
            if [ "$jaccard" -ge "$jaccard_milli" ]; then
                row_status[j]="dedup-merged:${idx_i}:title-jaccard"
                continue
            fi
            local edit_pct
            edit_pct="$(_edit_distance_ratio_pct "$title_i" "$title_j")"
            if [ "$edit_pct" -le "$edit_dist_pct" ]; then
                row_status[j]="dedup-merged:${idx_i}:title-edit-distance"
            fi
        done
    done

    # 結果を再構築して出力（元の 6 列 + 更新 status）
    for ((i=0; i<n; i++)); do
        local fields_full="${row_full[i]}"
        local kind idx_re state sc title quote _old
        IFS=$'\t' read -r kind idx_re state sc title quote _old <<<"$fields_full"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$kind" "$idx_re" "$state" "$sc" "$title" "$quote" "${row_status[i]}"
    done
}

# Cap フィルタ: idx 昇順で max 件まで passing → 残りは cap-exceeded
# 入力: stdin に Pass B 出力（7 列）
# 出力: 7 列（status 列を更新）
#   passing → 通過 max 件まで残し、超過分は cap-exceeded:<count>:<max>
# 純粋性レベル: 完全純粋（awk のみ）
_cap_filter() {
    local max="$1"
    # cap-exceeded payload は計画契約に従い "count;max"（セミコロン区切り）
    # status 列内では cap-exceeded:<count>;<max> 形式で表現する
    awk -F'\t' -v max="$max" '
    BEGIN { passed = 0 }
    $1 == "candidate" {
        if ($7 == "passing") {
            passed++
            if (passed > max) {
                $7 = "cap-exceeded:" passed ";" max
            }
        }
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6, $7
    }
    '
}

# フィルタオーケストレーション（Pass A → Pass B → Cap）
# 入力: stdin に 6 列 TSV（_classify_candidates の sc=true && state=- 限定行）
# 出力: 7 列 TSV（status 列で passing / dedup-merged:<rep>:<reason> / cap-exceeded:<n>:<max> を区別）
# 純粋性レベル: ビジネス副作用なし（_dedup_pass_b 経由で python3 サブプロセス呼び出しあり）
_filter_dedup_and_cap() {
    local max="$1"
    local jaccard_milli="$2"
    local edit_dist_pct="$3"
    _dedup_pass_a | _dedup_pass_b "$jaccard_milli" "$edit_dist_pct" | _cap_filter "$max"
}

# skill_caused 派生値計算 + mirror_state 状態判定 + 引用箇所抽出（Unit 006 拡張）
# 入力: extract 出力（TSV）, retrospective.md パス（title 抽出のため）
# 出力: candidate\t<idx>\t<state>\t<skill_caused>\t<normalized_title>\t<normalized_quote>
#       （state="-"/sent/skipped/pending、skill_caused=true/false）
#
# 純粋性レベル: ビジネス副作用なし
#  - retrospective.md 読み取りあり（_extract_title）
#  - python3 サブプロセス呼び出しあり（_normalize_text）
#  - ファイル / 永続ストア更新なし
_classify_candidates() {
    local extract_input="$1"
    local path="${2:-}"
    local fw_joined=""
    local fw_n="${#FORBIDDEN_WORDS[@]}"
    if [ "$fw_n" -gt 0 ]; then
        local _i
        for _i in "${FORBIDDEN_WORDS[@]}"; do
            if [ -z "$fw_joined" ]; then
                fw_joined="$_i"
            else
                fw_joined="${fw_joined}|${_i}"
            fi
        done
    fi

    # awk で 5 列の中間表現を出力: candidate\t<idx>\t<state>\t<sc>\t<raw_quote>
    # raw_quote は q*_quote のうち最初の non-empty（skill_caused=true 寄与候補）。空時は "-" プレースホルダ
    local intermediate
    intermediate="$(awk -F'\t' -v qmin="$QUOTE_MIN_LENGTH" -v fwords="$fw_joined" '
    BEGIN {
        fw_n = split(fwords, fw_arr, "|")
        for (i = 1; i <= fw_n; i++) {
            forbidden[i] = fw_arr[i]
        }
    }
    $1 == "extracted" {
        idx = $2
        kv = $3
        eq_pos = index(kv, "=")
        if (eq_pos == 0) next
        key = substr(kv, 1, eq_pos - 1)
        val = substr(kv, eq_pos + 1)
        composite = idx SUBSEP key
        problems[composite] = val
        if (!(idx in seen)) {
            seen[idx] = 1
            order[++problem_total] = idx
        }
    }
    END {
        for (i = 1; i <= problem_total; i++) {
            idx = order[i]
            sc = "false"
            chosen_quote = ""
            for (qn = 1; qn <= 3; qn++) {
                qprefix = "q" qn
                ans_key = qprefix "_answer"
                quote_key = qprefix "_quote"
                ans = problems[idx SUBSEP ans_key]
                quote = problems[idx SUBSEP quote_key]
                if (ans == "yes") {
                    if (length(quote) >= qmin + 0) {
                        forbid_match = 0
                        if (length(quote) <= qmin + 0) {
                            for (j = 1; j <= fw_n; j++) {
                                if (quote == forbidden[j]) {
                                    forbid_match = 1
                                    break
                                }
                            }
                        }
                        if (forbid_match == 0) {
                            sc = "true"
                            chosen_quote = quote
                            break
                        }
                    }
                }
            }
            state_key = idx SUBSEP "mirror_state.state"
            state_val = (state_key in problems) ? problems[state_key] : ""
            if (state_val == "") state_val = "-"
            if (chosen_quote == "") chosen_quote = "-"
            printf "candidate\t%d\t%s\t%s\t%s\n", idx, state_val, sc, chosen_quote
        }
    }
    ' <<<"$extract_input")"

    # bash 後処理: title と normalized_quote を補強して 6 列出力
    if [ -z "$intermediate" ]; then
        return 0
    fi
    local kind idx state sc raw_quote
    while IFS=$'\t' read -r kind idx state sc raw_quote; do
        if [ "$kind" != "candidate" ]; then
            continue
        fi
        local title=""
        if [ -n "$path" ] && [ -f "$path" ]; then
            title="$(_extract_title "$path" "$idx" 2>/dev/null || true)"
        fi
        if [ -z "$title" ]; then
            title="（タイトル不明）"
        fi
        local normalized_title normalized_quote
        normalized_title="$(_normalize_text "$title")"
        if [ "$raw_quote" = "-" ]; then
            normalized_quote="-"
        else
            normalized_quote="$(_normalize_text "$raw_quote")"
            if [ -z "$normalized_quote" ]; then
                normalized_quote="-"
            fi
        fi
        # title が正規化後空になった場合のガード
        if [ -z "$normalized_title" ]; then
            normalized_title="（タイトル不明）"
        fi
        printf 'candidate\t%s\t%s\t%s\t%s\t%s\n' "$idx" "$state" "$sc" "$normalized_title" "$normalized_quote"
    done <<<"$intermediate"
}

# 問題タイトルを retrospective.md から取得
_extract_title() {
    local path="$1"
    local idx="$2"
    awk -v idx="$idx" '
    BEGIN {
        problem_count = 0
    }
    /^### 問題 [0-9]+:/ {
        problem_count++
        if (problem_count == idx) {
            # "### 問題 N: タイトル" → "タイトル"
            sub(/^### 問題 [0-9]+: */, "", $0)
            print
            exit
        }
    }
    ' "$path"
}

# 問題セクション本文（タイトル直下〜次の ### または ## まで）を取得
_extract_problem_body() {
    local path="$1"
    local idx="$2"
    awk -v idx="$idx" '
    BEGIN {
        problem_count = 0
        in_target = 0
    }
    /^### 問題 [0-9]+:/ {
        problem_count++
        if (problem_count == idx) {
            in_target = 1
            next
        } else if (in_target == 1) {
            in_target = 0
            exit
        } else {
            in_target = 0
        }
        next
    }
    /^### / {
        if (in_target == 1) {
            in_target = 0
            exit
        }
    }
    /^## / {
        if (in_target == 1) {
            in_target = 0
            exit
        }
    }
    in_target == 1 {
        print
    }
    ' "$path"
}

# サイクル名を retrospective.md から推定（path の親ディレクトリ名 = cycles/<cycle>/operations/）
_resolve_cycle_from_path() {
    local path="$1"
    local cycle
    cycle="$(echo "$path" | sed -E 's|.*/cycles/([^/]+)/operations/.*|\1|')"
    if [ -z "$cycle" ] || [ "$cycle" = "$path" ]; then
        echo ""
    else
        echo "$cycle"
    fi
}

# IssueDraft 生成
_generate_draft() {
    local path="$1"
    local idx="$2"
    local cycle="$3"
    local title="$4"
    local out_path="$5"

    local body
    body="$(_extract_problem_body "$path" "$idx")"

    {
        printf '[mirror-reason] cycle=%s; problem_index=%d\n\n' "$cycle" "$idx"
        printf '**検出元**: mirror（v2.5.0+ / cycle: %s / problem_index: %d）\n\n' "$cycle" "$idx"
        printf '**問題タイトル**: %s\n\n' "$title"
        printf '**問題本文（retrospective.md より転記）**:\n\n'
        printf '%s\n\n' "$body"
        printf -- '---\n'
        printf '> このドラフトは AI-DLC v2.5.0+ の mirror モードで自動生成されました。\n'
        printf '> 元の retrospective: `.aidlc/cycles/%s/operations/retrospective.md` の問題 %d\n' "$cycle" "$idx"
    } >"$out_path"
}

# ─── detect サブコマンド ─────────
_detect() {
    local path="$1"

    if [ ! -f "$path" ]; then
        echo "error	retrospective-not-found	${path}" >&2
        return 2
    fi

    local feedback_mode
    feedback_mode="$(_resolve_feedback_mode)"

    if [ "$feedback_mode" != "mirror" ]; then
        echo "mirror	skip	not-mirror-mode"
        return 0
    fi

    # Python 3 必須前提チェック（Unit 006 / NFKC 正規化 / Jaccard / 編集距離計算）
    if ! _check_python3; then
        return 2
    fi

    # extract → classify（trap で EXIT 時に自動削除）
    local extract_tmp
    extract_tmp="$(mktemp /tmp/retrospective-mirror-extract.XXXXXX)"
    _register_cleanup "$extract_tmp"
    _extract "$path" >"$extract_tmp"

    local classify_tmp
    classify_tmp="$(mktemp /tmp/retrospective-mirror-classify.XXXXXX)"
    _register_cleanup "$classify_tmp"
    _classify_candidates "$(cat "$extract_tmp")" "$path" >"$classify_tmp"

    local cycle
    cycle="$(_resolve_cycle_from_path "$path")"
    if [ -z "$cycle" ]; then
        cycle="unknown-cycle"
    fi

    # Unit 006: flood_mitigation 設定解決
    local config_line cfg_kind cfg_max cfg_jaccard cfg_edit
    local _cfg_policy _cfg_cap
    config_line="$(_resolve_flood_mitigation_config)"
    # cfg_policy / cfg_cap は v2.5.0 では未使用（Unit 007 以降で利用予定 / 単一ソース宣言として保持）
    IFS=$'\t' read -r cfg_kind cfg_max cfg_jaccard cfg_edit _cfg_policy _cfg_cap <<<"$config_line"
    if [ "$cfg_kind" != "config" ]; then
        echo "error	config-resolve-failed	flood-mitigation" >&2
        return 2
    fi

    # フィルタ層への入力（sc=true && state="-"（Empty）の行のみ）
    local filter_input_tmp filter_output_tmp
    filter_input_tmp="$(mktemp /tmp/retrospective-mirror-filter-in.XXXXXX)"
    _register_cleanup "$filter_input_tmp"
    filter_output_tmp="$(mktemp /tmp/retrospective-mirror-filter-out.XXXXXX)"
    _register_cleanup "$filter_output_tmp"

    # candidate 行（6 列）を処理: total / skill_caused_true / already_processed のカウント + フィルタ入力構築
    local total=0
    local skill_caused_true=0
    local already_processed=0
    local kind idx state sc title norm_quote
    while IFS=$'\t' read -r kind idx state sc title norm_quote; do
        if [ "$kind" != "candidate" ]; then
            continue
        fi
        if [ "$state" = "-" ]; then
            state=""
        fi
        total=$((total + 1))
        if [ "$sc" = "true" ]; then
            skill_caused_true=$((skill_caused_true + 1))
            if [ -n "$state" ]; then
                already_processed=$((already_processed + 1))
                continue
            fi
            # フィルタ入力に 6 列で書き出し（state を "-" プレースホルダで保持）
            printf 'candidate\t%s\t-\t%s\t%s\t%s\n' "$idx" "$sc" "$title" "$norm_quote" >>"$filter_input_tmp"
        fi
    done <"$classify_tmp"

    # フィルタ層実行（Pass A → Pass B → Cap）
    _filter_dedup_and_cap "$cfg_max" "$cfg_jaccard" "$cfg_edit" <"$filter_input_tmp" >"$filter_output_tmp"

    # フィルタ結果を処理: passing は emit candidate（draft 生成）、それ以外は dedup-merged / cap-exceeded 行を出力
    local emitted_candidate=0
    local dedup_merged=0
    local cap_exceeded=0
    local f_kind f_idx f_title f_status
    local _f_state _f_sc _f_quote
    while IFS=$'\t' read -r f_kind f_idx _f_state _f_sc f_title _f_quote f_status; do
        if [ "$f_kind" != "candidate" ]; then
            continue
        fi
        case "$f_status" in
            passing)
                local draft_path draft_base
                draft_base="$(mktemp "/tmp/retrospective-mirror-draft.${f_idx}.XXXXXX")"
                draft_path="${draft_base}.md"
                mv -- "$draft_base" "$draft_path"
                _generate_draft "$path" "$f_idx" "$cycle" "$f_title" "$draft_path" || {
                    rm -f -- "$draft_path" 2>/dev/null || true
                    echo "error	draft-generation-failed	${f_idx}" >&2
                    return 2
                }
                printf 'mirror\tcandidate\t%s\t%s\t%s\n' "$f_idx" "$f_title" "$draft_path"
                emitted_candidate=1
                ;;
            dedup-merged:*)
                # status: dedup-merged:<rep_idx>:<reason>
                local rep_idx
                rep_idx="$(echo "$f_status" | cut -d: -f2)"
                printf 'mirror\tdedup-merged\t%s\t%s\n' "$f_idx" "$rep_idx"
                dedup_merged=$((dedup_merged + 1))
                ;;
            cap-exceeded:*)
                # status: cap-exceeded:<count>;<max>（計画契約 / セミコロン区切り）
                local count_max
                count_max="${f_status#cap-exceeded:}"
                # count_max は "<count>;<max>" 形式 → そのまま payload に流用
                printf 'mirror\tcap-exceeded\t%s\t%s\n' "$f_idx" "$count_max"
                cap_exceeded=$((cap_exceeded + 1))
                ;;
        esac
    done <"$filter_output_tmp"

    # 中間ファイルは trap で EXIT 時にクリーンアップされる（明示削除も保持し、早期解放）
    rm -f -- "$extract_tmp" "$classify_tmp" "$filter_input_tmp" "$filter_output_tmp" 2>/dev/null || true

    if [ "$emitted_candidate" -eq 0 ] && [ "$dedup_merged" -eq 0 ] && [ "$cap_exceeded" -eq 0 ]; then
        if [ "$skill_caused_true" -eq 0 ]; then
            echo "mirror	skip	no-skill-caused"
        else
            echo "mirror	skip	all-processed"
        fi
    fi

    printf 'summary\tcounts\ttotal=%d;skill_caused_true=%d;already-processed=%d;dedup-merged=%d;cap-exceeded=%d\n' \
        "$total" "$skill_caused_true" "$already_processed" "$dedup_merged" "$cap_exceeded"
    return 0
}

# ─── mirror_state 書き込み（_safe_transform 相当） ─────────
# `### 問題 <idx>:` 直下の YAML ブロック内 mirror_state ブロックを書き換える
# mirror_state ブロック欠落時は新規追加（後方互換 / Rule 5）
_rewrite_mirror_state() {
    local path="$1"
    local idx="$2"
    local new_state="$3"
    local new_url="$4"
    local new_recorded_at="$5"

    local tmp
    tmp="$(mktemp "${path}.tmp.XXXXXX")"

    awk -v idx="$idx" -v new_state="$new_state" -v new_url="$new_url" -v new_at="$new_recorded_at" '
    # 状態管理（ブロック再生成の禁止 / Codex Round 1 指摘 #1 対応）:
    #   block_existed : 現在処理中の問題ブロック内で mirror_state: ヘッダを既に検出した
    #   has_state / has_url / has_at : 各キーが現在問題のブロック内で書き換え済み
    #   updated_target: 対象 idx について 3 キー全て書き換え完了（プロブレム遷移後もリセットしない / Round 2 指摘 #1 対応）
    BEGIN {
        problem_count = 0
        in_target = 0
        in_yaml = 0
        in_mirror_block = 0
        block_existed = 0
        has_state = 0
        has_url = 0
        has_at = 0
        updated_target = 0
        last_indent = "  "
    }
    function flush_missing_keys(    indent) {
        # 既存ブロックで欠落キーのみ補完（ブロック再生成は禁止）
        indent = last_indent
        if (has_state == 0) {
            printf "%sstate: \"%s\"\n", indent, new_state
            has_state = 1
        }
        if (has_url == 0) {
            printf "%sissue_url: \"%s\"\n", indent, new_url
            has_url = 1
        }
        if (has_at == 0) {
            printf "%srecorded_at: \"%s\"\n", indent, new_at
            has_at = 1
        }
    }
    function check_target_completion() {
        # 対象 idx について 3 キー揃ったら updated_target を確定
        if (in_target == 1 && has_state == 1 && has_url == 1 && has_at == 1) {
            updated_target = 1
        }
    }
    /^### 問題 [0-9]+:/ {
        # 直前の問題が target だった場合、ここで完了確認
        check_target_completion()
        problem_count++
        in_target = (problem_count == idx) ? 1 : 0
        in_yaml = 0
        in_mirror_block = 0
        block_existed = 0
        has_state = 0
        has_url = 0
        has_at = 0
        print; next
    }
    in_target == 1 && /^```[Yy][Aa]?[Mm][Ll][[:space:]]*$/ {
        in_yaml = 1
        in_mirror_block = 0
        print; next
    }
    in_target == 1 && in_yaml == 1 && /^```[[:space:]]*$/ {
        # コードブロック終了
        if (in_mirror_block == 1 && block_existed == 1) {
            # 既存ブロックで欠落キーのみ補完
            flush_missing_keys()
        } else if (block_existed == 0) {
            # mirror_state ブロック自体が欠落 → 新規追加（後方互換 / Rule 5）
            printf "mirror_state:\n"
            printf "%sstate: \"%s\"\n", last_indent, new_state
            printf "%sissue_url: \"%s\"\n", last_indent, new_url
            printf "%srecorded_at: \"%s\"\n", last_indent, new_at
            has_state = 1; has_url = 1; has_at = 1
            block_existed = 1
        }
        check_target_completion()
        in_yaml = 0
        in_mirror_block = 0
        print; next
    }
    in_target == 1 && in_yaml == 1 && /^mirror_state:[[:space:]]*$/ {
        in_mirror_block = 1
        block_existed = 1
        print; next
    }
    in_target == 1 && in_yaml == 1 && in_mirror_block == 1 {
        # インデント取得
        if (match($0, /^[ \t]+/)) {
            last_indent = substr($0, 1, RLENGTH)
        }
        # mirror_state 配下のキー（インデント付き）の書き換え
        if ($0 ~ /^[ \t]+state:/) {
            printf "%sstate: \"%s\"\n", last_indent, new_state
            has_state = 1
            next
        }
        if ($0 ~ /^[ \t]+issue_url:/) {
            printf "%sissue_url: \"%s\"\n", last_indent, new_url
            has_url = 1
            next
        }
        if ($0 ~ /^[ \t]+recorded_at:/) {
            printf "%srecorded_at: \"%s\"\n", last_indent, new_at
            has_at = 1
            next
        }
        # 別キー（非インデント or 別ブロックヘッダ）が現れたら mirror_state ブロック終了
        # 欠落キーを補完してから現在行を出力
        if ($0 ~ /^[A-Za-z]/) {
            flush_missing_keys()
            in_mirror_block = 0
            print; next
        }
        print; next
    }
    in_target == 1 && in_yaml == 1 {
        # YAML ブロック内 / mirror_state 以外のキーを記録（インデント取得用）
        if (match($0, /^[ \t]+/)) {
            last_indent = substr($0, 1, RLENGTH)
        }
        print; next
    }
    { print }
    END {
        # ファイル末尾で対象 idx の更新が未確定の場合に最終チェック
        check_target_completion()
        # updated_target = 1 で対象 idx の 3 キー全て書き換え完了
        if (updated_target == 1) {
            exit 0
        }
        exit 1
    }
    ' "$path" >"$tmp"
    local awk_rc=$?

    if [ "$awk_rc" -ne 0 ]; then
        rm -f -- "$tmp"
        return 1
    fi

    if mv -- "$tmp" "$path"; then
        return 0
    else
        rm -f -- "$tmp"
        return 1
    fi
}

# ISO8601 タイムスタンプ
_iso8601_now() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# パストラバーサル対策（Unit 004 と同方針 / AIDLC_CYCLES 配下の retrospective.md のみ許可）
_validate_apply_path() {
    local path="$1"
    if [ -z "${AIDLC_CYCLES:-}" ]; then
        echo "error	bootstrap-failed	cannot-resolve-AIDLC_CYCLES" >&2
        return 2
    fi
    local resolved_target=""
    local resolved_root=""
    if command -v realpath >/dev/null 2>&1; then
        resolved_target="$(realpath "$path" 2>/dev/null || true)"
        resolved_root="$(realpath "$AIDLC_CYCLES" 2>/dev/null || true)"
    else
        resolved_target="$(python3 -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$path" 2>/dev/null || true)"
        resolved_root="$(python3 -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$AIDLC_CYCLES" 2>/dev/null || true)"
    fi
    if [ -z "$resolved_target" ] || [ -z "$resolved_root" ]; then
        echo "error	path-resolution-failed	${path}" >&2
        return 2
    fi
    if [[ "$resolved_target" != "$resolved_root"/* ]]; then
        echo "error	apply-path-not-allowed	must-be-under-aidlc-cycles:${path}" >&2
        return 2
    fi
    if [ "$(basename "$resolved_target")" != "retrospective.md" ]; then
        echo "error	apply-filename-not-allowed	must-be-retrospective.md:${path}" >&2
        return 2
    fi
    return 0
}

# ─── send サブコマンド ─────────
_send() {
    local path="$1"
    local idx="$2"
    local title="$3"
    local body_path="$4"

    if [ ! -f "$path" ]; then
        echo "error	retrospective-not-found	${path}" >&2
        return 2
    fi
    if [ ! -f "$body_path" ]; then
        echo "error	draft-body-not-found	${body_path}" >&2
        return 2
    fi
    if [ -z "$title" ]; then
        echo "error	missing-title	send" >&2
        return 2
    fi
    if ! [[ "$idx" =~ ^[0-9]+$ ]]; then
        echo "error	invalid-problem-index	${idx}" >&2
        return 2
    fi

    if ! _validate_apply_path "$path"; then
        return 2
    fi

    local upstream_repo
    upstream_repo="$(_resolve_upstream_repo)"

    # gh auth status 事前チェック（recoverable failure として扱う）
    if ! command -v gh >/dev/null 2>&1; then
        printf 'mirror\tsend-failed\t%s\tgh-not-installed\n' "$idx"
        return 0
    fi
    if ! gh auth status >/dev/null 2>&1; then
        printf 'mirror\tsend-failed\t%s\tgh-not-authenticated\n' "$idx"
        return 0
    fi

    # gh issue create 実行
    local gh_stdout gh_stderr gh_rc
    local gh_stderr_tmp
    gh_stderr_tmp="$(mktemp /tmp/retrospective-mirror-gh-stderr.XXXXXX)"
    _register_cleanup "$gh_stderr_tmp"
    set +e
    gh_stdout="$(gh issue create --repo "$upstream_repo" --title "$title" --body-file "$body_path" 2>"$gh_stderr_tmp")"
    gh_rc=$?
    set -e
    gh_stderr="$(cat "$gh_stderr_tmp" || true)"
    rm -f -- "$gh_stderr_tmp" 2>/dev/null || true

    if [ "$gh_rc" -ne 0 ]; then
        # recoverable failure 分類（schema の send_failure_reasons と整合させる）
        local reason="gh-unknown-error"
        if echo "$gh_stderr" | grep -qiE 'rate.?limit|abuse.?detection'; then
            reason="gh-rate-limit"
        elif echo "$gh_stderr" | grep -qiE 'timeout|timed out|temporary failure|connection refused|could not resolve|network is unreachable'; then
            reason="gh-network-error"
        elif echo "$gh_stderr" | grep -qiE 'authentication|not authenticated|gh auth'; then
            reason="gh-not-authenticated"
        fi
        # 自己検査: 分類値が schema の send_failure_reasons に含まれるか確認（ドリフト検出）
        if ! _is_valid_send_failure_reason "$reason"; then
            echo "warn	send-failure-reason-not-in-schema	${reason}" >&2
            reason="gh-unknown-error"
        fi
        printf 'mirror\tsend-failed\t%s\t%s\n' "$idx" "$reason"
        return 0
    fi

    # Issue URL 抽出（gh issue create は通常 stdout に URL を 1 行で返す）
    local issue_url
    issue_url="$(echo "$gh_stdout" | grep -Eo 'https://github\.com/[^/]+/[^/]+/issues/[0-9]+' | head -1 || true)"
    if [ -z "$issue_url" ]; then
        printf 'mirror\tsend-failed\t%s\tgh-unknown-error\n' "$idx"
        return 0
    fi
    # スキーマパターンで URL 検証（書き込み前の最終チェック）
    if ! [[ "$issue_url" =~ $ISSUE_URL_PATTERN ]]; then
        echo "warn	issue-url-pattern-mismatch	${issue_url}" >&2
        printf 'mirror\tsend-failed\t%s\tgh-unknown-error\n' "$idx"
        return 0
    fi

    local recorded_at
    recorded_at="$(_iso8601_now)"
    # スキーマパターンで recorded_at を検証（ローカル date -u の異常検出）
    if ! [[ "$recorded_at" =~ $RECORDED_AT_PATTERN ]]; then
        echo "error	recorded-at-pattern-mismatch	${recorded_at}" >&2
        return 2
    fi

    # backup → rewrite → rollback パターン
    local backup
    backup="$(mktemp "${path}.bak.XXXXXX")" || {
        echo "error	backup-mktemp-failed	${path}" >&2
        return 2
    }
    if ! cp -p -- "$path" "$backup"; then
        rm -f -- "$backup"
        echo "error	backup-failed	${path}" >&2
        return 2
    fi

    if ! _rewrite_mirror_state "$path" "$idx" "sent" "$issue_url" "$recorded_at"; then
        # rollback
        if mv -- "$backup" "$path"; then
            echo "error	apply-failed	rollback-completed" >&2
        else
            echo "error	apply-failed	rollback-failed:${backup}" >&2
        fi
        return 2
    fi

    rm -f -- "$backup"
    printf 'mirror\tsent\t%s\t%s\n' "$idx" "$issue_url"
    return 0
}

# ─── record サブコマンド ─────────
_record() {
    local path="$1"
    local idx="$2"
    local decision="$3"

    if [ ! -f "$path" ]; then
        echo "error	retrospective-not-found	${path}" >&2
        return 2
    fi
    if ! [[ "$idx" =~ ^[0-9]+$ ]]; then
        echo "error	invalid-problem-index	${idx}" >&2
        return 2
    fi
    if ! _is_valid_decision "$decision"; then
        echo "error	invalid-decision	${decision}" >&2
        return 2
    fi

    if ! _validate_apply_path "$path"; then
        return 2
    fi

    local recorded_at
    recorded_at="$(_iso8601_now)"

    local backup
    backup="$(mktemp "${path}.bak.XXXXXX")" || {
        echo "error	backup-mktemp-failed	${path}" >&2
        return 2
    }
    if ! cp -p -- "$path" "$backup"; then
        rm -f -- "$backup"
        echo "error	backup-failed	${path}" >&2
        return 2
    fi

    if ! _rewrite_mirror_state "$path" "$idx" "$decision" "" "$recorded_at"; then
        if mv -- "$backup" "$path"; then
            echo "error	apply-failed	rollback-completed" >&2
        else
            echo "error	apply-failed	rollback-failed:${backup}" >&2
        fi
        return 2
    fi

    rm -f -- "$backup"
    printf 'mirror\trecorded\t%s\t%s\n' "$idx" "$decision"
    return 0
}

# ─── 引数ディスパッチ ─────────
# source 経由で関数のみロードするテスト用途では BASH_SOURCE[0] != $0 となるため、
# 直接実行時のみディスパッチを行う（Unit 006 ユニットテスト追加に伴うガード）
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    SUBCOMMAND="${1:-}"
    case "$SUBCOMMAND" in
        detect)
            if [ "$#" -lt 2 ]; then
                echo "error	usage	retrospective-mirror.sh detect <retrospective.md>" >&2
                exit 2
            fi
            _detect "$2"
            exit $?
            ;;
        send)
            if [ "$#" -lt 5 ]; then
                echo "error	usage	retrospective-mirror.sh send <retrospective.md> <problem_index> <title> <draft_body_path>" >&2
                exit 2
            fi
            _send "$2" "$3" "$4" "$5"
            exit $?
            ;;
        record)
            if [ "$#" -lt 4 ]; then
                echo "error	usage	retrospective-mirror.sh record <retrospective.md> <problem_index> <decision>" >&2
                exit 2
            fi
            _record "$2" "$3" "$4"
            exit $?
            ;;
        "")
            echo "error	usage	retrospective-mirror.sh detect|send|record ..." >&2
            exit 2
            ;;
        *)
            echo "error	unknown-subcommand	${SUBCOMMAND}" >&2
            exit 2
            ;;
    esac
fi
