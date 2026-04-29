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

# skill_caused 派生値計算 + mirror_state 状態判定
# 入力: extract 出力（TSV）
# 出力: candidate\t<idx>\t<state>\t<skill_caused>（state="" / sent / skipped / pending、skill_caused=true/false）
_classify_candidates() {
    local extract_input="$1"
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

    awk -F'\t' -v qmin="$QUOTE_MIN_LENGTH" -v fwords="$fw_joined" '
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
            # skill_caused 派生計算
            sc = "false"
            for (qn = 1; qn <= 3; qn++) {
                qprefix = "q" qn
                ans_key = qprefix "_answer"
                quote_key = qprefix "_quote"
                ans = problems[idx SUBSEP ans_key]
                quote = problems[idx SUBSEP quote_key]
                if (ans == "yes") {
                    if (length(quote) >= qmin + 0) {
                        # 禁止語単独 + qmin 以下チェックは validate スクリプトでダウングレード済みのはず
                        # ここでは長さのみ確認（validate --apply で q*_answer は no になるため）
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
                            break
                        }
                    }
                }
            }
            # mirror_state.state（欠落時は "-" プレースホルダー / bash の IFS=tab で空フィールド折り畳み回避）
            state_key = idx SUBSEP "mirror_state.state"
            state_val = (state_key in problems) ? problems[state_key] : ""
            if (state_val == "") state_val = "-"
            printf "candidate\t%d\t%s\t%s\n", idx, state_val, sc
        }
    }
    ' <<<"$extract_input"
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

    # extract → classify（trap で EXIT 時に自動削除）
    local extract_tmp
    extract_tmp="$(mktemp /tmp/retrospective-mirror-extract.XXXXXX)"
    _register_cleanup "$extract_tmp"
    _extract "$path" >"$extract_tmp"

    local classify_tmp
    classify_tmp="$(mktemp /tmp/retrospective-mirror-classify.XXXXXX)"
    _register_cleanup "$classify_tmp"
    _classify_candidates "$(cat "$extract_tmp")" >"$classify_tmp"

    local cycle
    cycle="$(_resolve_cycle_from_path "$path")"
    if [ -z "$cycle" ]; then
        cycle="unknown-cycle"
    fi

    # candidate 行（candidate\t<idx>\t<state>\t<skill_caused>）を処理
    local total=0
    local skill_caused_true=0
    local already_processed=0
    local emitted_candidate=0

    while IFS=$'\t' read -r kind idx state sc; do
        if [ "$kind" != "candidate" ]; then
            continue
        fi
        # state プレースホルダー "-" は空文字に戻す
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
            # candidate として出力 + draft 生成
            local title
            title="$(_extract_title "$path" "$idx")"
            if [ -z "$title" ]; then
                title="（タイトル不明）"
            fi
            local draft_path draft_base
            # macOS BSD mktemp は template の末尾の X 群しか置換しないため、
            # .md 拡張子は mktemp 後にリネームで付与する
            draft_base="$(mktemp "/tmp/retrospective-mirror-draft.${idx}.XXXXXX")"
            draft_path="${draft_base}.md"
            mv -- "$draft_base" "$draft_path"
            # draft のライフサイクル（Codex 指摘 #4 / セキュリティ運用ガイド）:
            # - draft は detect の EXIT trap で削除しない（後続の send が別プロセスで参照するため）
            # - 正常系: Step 5 の全候補処理完了後、ユーザーが任意で `rm /tmp/retrospective-mirror-draft.*` で削除
            # - draft 本文は機密情報を含まない前提（retrospective.md は git 管理対象 / 公開リポジトリ向け要約）
            # - 万一 detect が _generate_draft で失敗した場合は draft_path がここで生成されているため、明示エラー時に削除する
            _generate_draft "$path" "$idx" "$cycle" "$title" "$draft_path" || {
                rm -f -- "$draft_path" 2>/dev/null || true
                echo "error	draft-generation-failed	${idx}" >&2
                return 2
            }
            printf 'mirror\tcandidate\t%s\t%s\t%s\n' "$idx" "$title" "$draft_path"
            emitted_candidate=1
        fi
    done <"$classify_tmp"

    # 中間ファイルは trap で EXIT 時にクリーンアップされる（明示削除も保持し、早期解放）
    rm -f -- "$extract_tmp" "$classify_tmp" 2>/dev/null || true

    if [ "$emitted_candidate" -eq 0 ]; then
        if [ "$skill_caused_true" -eq 0 ]; then
            echo "mirror	skip	no-skill-caused"
        else
            echo "mirror	skip	all-processed"
        fi
    fi

    printf 'summary\tcounts\ttotal=%d;skill_caused_true=%d;already-processed=%d\n' \
        "$total" "$skill_caused_true" "$already_processed"
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
