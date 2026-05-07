#!/usr/bin/env bash
# retrospective-issue.sh - Unit 002 共有関数 + 命名規約定数 + mirror_state 正規化 + spool I/O
#
# 提供する公開関数:
#   retrospective_body_compose <draft_yaml_path> <kpt_md_path> <cycle>
#       -> Markdown 本文を stdout に出力
#   retrospective_issue_create <body_path> <feedback_mode> <cycle>
#       -> key=value 形式の結果を stdout に出力
#   retrospective_dialog_token_record_response <cycle> <response>  (Unit 001 / #647)
#       -> 対話確認トークン発行（${TMPDIR:-/tmp}/aidlc-retro-confirmed-${cycle}.flag）
#   retrospective_dialog_token_verify <cycle>  (Unit 001 / #647)
#       -> 対話確認トークン検証（exit 4 で起票ブロック、reason 値で詳細分類）
#
# 提供する命名規約定数:
#   RETROSPECTIVE_LABEL                  = "retrospective"
#   MIRROR_STATE_LABEL_PREFIX            = "mirror-state:"
#   RETROSPECTIVE_ISSUE_TITLE_TEMPLATE   = "Retrospective: %s"
#   RETROSPECTIVE_SPOOL_HEADER           = "<!-- retrospective-spool v1 -->"
#   RETROSPECTIVE_SPOOL_VERSION          = "1"
#   MIRROR_REPO                          = "ikeisuke/ai-dlc-starter-kit"
#
# 提供する内部公開関数（BATS テスト等から直接呼び出し可）:
#   _pure_compose_body <draft_yaml_string> <kpt_md_string> <cycle>
#   _normalize_legacy_to_canonical <prefix> <state_arg> <error_reason>
#   _normalize_canonical_to_label <canonical>
#   _normalize_label_to_canonical <label>
#   _normalize_reconcile <label_canonical> <yaml_canonical>
#
# exit code 規約:
#   0 - 成功 / 受理可能経路（created / skipped / spooled）
#   1 - failed（再送可能失敗 / ランタイム異常）
#   2 - 引数エラー / fatal
#
# stderr フォーマット: <level>\t<code>\t<detail>  (level=info|warn|error)

# 多重 source ガード
if [[ "${__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED=1

# Unit 003 (#638): aidlc-paths.sh helper を source（aidlc_cycle_path 提供）
__RETRO_ISSUE_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
# shellcheck source=aidlc-paths.sh
source "${__RETRO_ISSUE_SCRIPT_DIR}/aidlc-paths.sh"

# Unit 004 (#643): 横依存解消のため独立 helper 群を source（順序固定）
# shellcheck source=aidlc-validate.sh
source "${__RETRO_ISSUE_SCRIPT_DIR}/aidlc-validate.sh"
# shellcheck source=aidlc-gh.sh
source "${__RETRO_ISSUE_SCRIPT_DIR}/aidlc-gh.sh"
# shellcheck source=aidlc-spool.sh
source "${__RETRO_ISSUE_SCRIPT_DIR}/aidlc-spool.sh"

# ─── 命名規約定数 ─────────
# Unit 004 (#643): aidlc-spool.sh で先に readonly される可能性があるため、未定義時のみ readonly する
readonly RETROSPECTIVE_LABEL="retrospective"
readonly MIRROR_STATE_LABEL_PREFIX="mirror-state:"
readonly RETROSPECTIVE_ISSUE_TITLE_TEMPLATE="Retrospective: %s"
if [[ -z "${RETROSPECTIVE_SPOOL_HEADER:-}" ]]; then
    readonly RETROSPECTIVE_SPOOL_HEADER="<!-- retrospective-spool v1 -->"
fi
readonly RETROSPECTIVE_SPOOL_VERSION="1"
readonly MIRROR_REPO="ikeisuke/ai-dlc-starter-kit"

# Unit 001 (#647): 対話確認トークン TTL（秒、環境変数で上書き可）
: "${AIDLC_RETRO_TOKEN_TTL_SECONDS:=300}"

# ─── 診断出力ヘルパ ─────────
__retro_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

# ─── ツール解決ヘルパ ─────────
__retro_sha256() {
    # stdin -> sha256 hex -> stdout
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | cut -d' ' -f1
    else
        shasum -a 256 | cut -d' ' -f1
    fi
}

__retro_base64_encode() {
    # stdin -> base64 (no newlines) -> stdout
    base64 | tr -d '\n'
}

__retro_base64_decode() {
    # stdin -> decoded -> stdout
    base64 -d 2>/dev/null || base64 -D
}

__retro_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr 'A-Z' 'a-z'
    else
        # /dev/urandom フォールバック（UUID v4 形式）
        local hex
        hex=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
        printf '%s-%s-4%s-%s%s-%s\n' \
            "${hex:0:8}" "${hex:8:4}" "${hex:13:3}" \
            "8" "${hex:17:3}" "${hex:20:12}"
    fi
}

__retro_iso8601() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# cycle バリデーション関数（__retro_validate_cycle）は Unit 004 (#643) で aidlc-validate.sh に移管済

# ─── 排他ロックヘルパ（mkdir ベース、macOS / Linux 両対応） ─────────
__retro_lock_acquire() {
    # $1: lock_dir
    # 5 秒タイムアウトでリトライ
    local lock_dir="$1"
    local i=0
    while ! mkdir "$lock_dir" 2>/dev/null; do
        i=$((i + 1))
        if [[ $i -ge 50 ]]; then
            __retro_diag error spool_lock_timeout "$lock_dir"
            return 1
        fi
        sleep 0.1
    done
    return 0
}

__retro_lock_release() {
    rmdir "$1" 2>/dev/null || true
}

# ─── mirror_state 正規化（公開 / 双方向変換）─────────

_normalize_canonical_to_label() {
    # $1: canonical 値
    # 出力: label 文字列、空 canonical の場合は空出力
    case "$1" in
        "")
            ;;
        "pending"|"created"|"error")
            printf '%s%s\n' "$MIRROR_STATE_LABEL_PREFIX" "$1"
            ;;
        "skipped:max_exceeded")
            printf '%sskipped-max-exceeded\n' "$MIRROR_STATE_LABEL_PREFIX"
            ;;
        "skipped:duplicate")
            printf '%sskipped-duplicate\n' "$MIRROR_STATE_LABEL_PREFIX"
            ;;
        *)
            __retro_diag warn mirror_state_unknown "canonical=$1"
            printf '%serror\n' "$MIRROR_STATE_LABEL_PREFIX"
            ;;
    esac
    return 0
}

_normalize_label_to_canonical() {
    # $1: label 文字列（mirror-state:xxx）
    case "$1" in
        "")
            printf '\n'
            ;;
        "${MIRROR_STATE_LABEL_PREFIX}pending")
            printf 'pending\n'
            ;;
        "${MIRROR_STATE_LABEL_PREFIX}created"|"${MIRROR_STATE_LABEL_PREFIX}sent")
            # legacy "sent" は created と等価扱い（後方互換）
            printf 'created\n'
            ;;
        "${MIRROR_STATE_LABEL_PREFIX}error")
            printf 'error\n'
            ;;
        "${MIRROR_STATE_LABEL_PREFIX}skipped-max-exceeded")
            printf 'skipped:max_exceeded\n'
            ;;
        "${MIRROR_STATE_LABEL_PREFIX}skipped-duplicate")
            printf 'skipped:duplicate\n'
            ;;
        *)
            __retro_diag warn mirror_state_label_unknown "label=$1"
            printf 'error\n'
            ;;
    esac
    return 0
}

_normalize_legacy_to_canonical() {
    # $1: prefix (sent | send-failed | recorded)
    # $2: state_arg (recorded:pending / recorded:skipped の引数 or 空)
    # $3: error_reason (send-failed の reason or 空)
    local prefix="${1:-}"
    local state_arg="${2:-}"
    case "$prefix" in
        sent)
            printf 'created\n'
            ;;
        send-failed)
            printf 'error\n'
            ;;
        recorded)
            case "$state_arg" in
                pending)
                    __retro_diag warn legacy_recorded_pending "旧 recorded:pending を canonical=created 互換扱い（非保証マッピング）"
                    printf 'created\n'
                    ;;
                skipped)
                    __retro_diag warn legacy_recorded_skipped "旧 recorded:skipped を canonical=skipped:max_exceeded 互換扱い（非保証マッピング / コンテキスト不明）"
                    printf 'skipped:max_exceeded\n'
                    ;;
                *)
                    __retro_diag warn legacy_recorded_unknown "state_arg=$state_arg"
                    printf 'error\n'
                    ;;
            esac
            ;;
        *)
            __retro_diag warn legacy_prefix_unknown "prefix=$prefix"
            printf 'error\n'
            ;;
    esac
    return 0
}

_normalize_reconcile() {
    # $1: label_canonical（label 経路から得た値、空文字可）
    # $2: yaml_canonical（YAML 経路から得た値）
    # 出力: 採用された canonical 値
    local label_value="${1:-}"
    local yaml_value="${2:-}"
    if [[ -z "$label_value" ]]; then
        printf '%s\n' "$yaml_value"
        return 0
    fi
    if [[ "$label_value" != "$yaml_value" ]]; then
        __retro_diag warn mirror_state_reconcile_mismatch "label=$label_value yaml=$yaml_value (label 採用)"
    fi
    printf '%s\n' "$label_value"
    return 0
}

# ─── feedback_mode → RetrospectiveTarget 翻訳 ─────────
__retro_resolve_target() {
    # $1: feedback_mode（5 値正規化済 or 解決済 4 値）
    # 出力: local | mirror | both | none
    case "$1" in
        local-issue-only|local_only)
            printf 'local\n'
            ;;
        mirror-only|mirror_only)
            printf 'mirror\n'
            ;;
        local-and-mirror|both)
            printf 'both\n'
            ;;
        disabled)
            printf 'none\n'
            ;;
        interactive)
            # interactive は disabled に縮退（保守的）
            __retro_diag warn target_interactive_treated_as_disabled "feedback_mode=interactive を target=none に縮退"
            printf 'none\n'
            ;;
        *)
            __retro_diag error feedback_mode_unknown "$1"
            return 2
            ;;
    esac
    return 0
}

# ─── 純粋関数: 本文構築（文字列入力→文字列出力）─────────

_pure_compose_body() {
    # $1: draft_yaml_string
    # $2: kpt_md_string
    # $3: cycle
    # 出力: Markdown 本文を stdout
    local draft_yaml="${1:-}"
    local kpt_md="${2:-}"
    local cycle="${3:-}"

    if [[ -z "$cycle" ]]; then
        __retro_diag error compose_args "cycle is empty"
        return 2
    fi

    # 本文ヘッダ
    printf '# Retrospective: %s\n\n' "$cycle"

    # KPT セクション
    if [[ -n "$kpt_md" ]]; then
        printf '%s' "$kpt_md"
        # 末尾改行保証
        case "$kpt_md" in
            *$'\n') ;;
            *) printf '\n' ;;
        esac
        printf '\n'
    fi

    # Problem セクション + draft YAML から問題項目を展開
    printf '## 問題項目（Problem）\n\n'
    if [[ -z "$draft_yaml" ]]; then
        printf '### 問題なし\n\n本サイクルでは特筆すべきプロセス問題は発生しなかった。\n\n'
    else
        # YAML を jq で JSON に変換せず、awk で簡易パース
        # 段階的パース: problem_drafts[] の各要素を処理
        printf '%s' "$draft_yaml" | __retro_yaml_to_problems
        local rc=$?
        if [[ $rc -ne 0 ]]; then
            return 2
        fi
    fi

    # 末尾 mirror_state + human_reviewed YAML ブロック
    cat <<'EOF'
## メタデータ

```yaml
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
human_reviewed: false
```
EOF
    return 0
}

# YAML draft を Problem セクションに変換する awk ヘルパ
__retro_yaml_to_problems() {
    # stdin: draft YAML (Intent §6.3 スキーマ)
    # stdout: Markdown Problem セクション
    awk '
    BEGIN {
        problem_count = 0
        in_drafts = 0
        in_judgment = 0
        # problem ごとのフィールド
        delete pid
        delete pcause
        delete preason
        delete q1a
        delete q1q
        delete q2a
        delete q2q
        delete q3a
        delete q3q
        delete pconf
    }
    function strip(s) {
        sub(/^[ \t]+/, "", s)
        sub(/[ \t]+$/, "", s)
        # クォート除去
        if (length(s) >= 2 && substr(s,1,1) == "\"" && substr(s,length(s),1) == "\"") {
            s = substr(s, 2, length(s) - 2)
        }
        return s
    }
    /^problem_drafts:/ {
        in_drafts = 1
        next
    }
    in_drafts == 0 { next }
    /^[[:space:]]*-[[:space:]]+problem_id:/ {
        # 新しい problem 開始
        problem_count++
        line = $0
        sub(/^[[:space:]]*-[[:space:]]+problem_id:[[:space:]]*/, "", line)
        pid[problem_count] = strip(line)
        in_judgment = 0
        next
    }
    /^[[:space:]]+primary_cause:/ {
        line = $0
        sub(/^[[:space:]]+primary_cause:[[:space:]]*/, "", line)
        pcause[problem_count] = strip(line)
        next
    }
    /^[[:space:]]+primary_cause_reason:/ {
        line = $0
        sub(/^[[:space:]]+primary_cause_reason:[[:space:]]*/, "", line)
        preason[problem_count] = strip(line)
        next
    }
    /^[[:space:]]+skill_caused_judgment:/ {
        in_judgment = 1
        next
    }
    in_judgment == 1 && /^[[:space:]]+q1_answer:/ {
        line = $0
        sub(/^[[:space:]]+q1_answer:[[:space:]]*/, "", line)
        q1a[problem_count] = strip(line)
        next
    }
    in_judgment == 1 && /^[[:space:]]+q1_quote:/ {
        line = $0
        sub(/^[[:space:]]+q1_quote:[[:space:]]*/, "", line)
        q1q[problem_count] = strip(line)
        next
    }
    in_judgment == 1 && /^[[:space:]]+q2_answer:/ {
        line = $0
        sub(/^[[:space:]]+q2_answer:[[:space:]]*/, "", line)
        q2a[problem_count] = strip(line)
        next
    }
    in_judgment == 1 && /^[[:space:]]+q2_quote:/ {
        line = $0
        sub(/^[[:space:]]+q2_quote:[[:space:]]*/, "", line)
        q2q[problem_count] = strip(line)
        next
    }
    in_judgment == 1 && /^[[:space:]]+q3_answer:/ {
        line = $0
        sub(/^[[:space:]]+q3_answer:[[:space:]]*/, "", line)
        q3a[problem_count] = strip(line)
        next
    }
    in_judgment == 1 && /^[[:space:]]+q3_quote:/ {
        line = $0
        sub(/^[[:space:]]+q3_quote:[[:space:]]*/, "", line)
        q3q[problem_count] = strip(line)
        next
    }
    /^[[:space:]]+confidence:/ {
        in_judgment = 0
        line = $0
        sub(/^[[:space:]]+confidence:[[:space:]]*/, "", line)
        pconf[problem_count] = strip(line)
        next
    }
    END {
        for (i = 1; i <= problem_count; i++) {
            cause = (pcause[i] != "") ? pcause[i] : "product"
            reason = preason[i]
            cause_label_product = (cause == "product" || cause == "both") ? "yes" : "no"
            cause_label_aidlc   = (cause == "ai_dlc" || cause == "both") ? "yes" : "no"
            cause_label_both    = (cause == "both") ? "yes" : "no"

            printf "### 問題 %s: (タイトル未記入)\n\n", pid[i]
            printf "**何が起きたか**: (詳細未記入)\n\n"
            printf "**なぜ起きたか**: %s\n\n", reason
            printf "**損失と影響**: (詳細未記入)\n\n"
            printf "**主因切り分け**:\n\n"
            printf "| 主因分類 | 該当 | 反映先 |\n"
            printf "|----------|------|-------|\n"
            printf "| プロダクト固有 | %s | |\n", cause_label_product
            printf "| AI-DLC Starter Kit 固有 | %s | |\n", cause_label_aidlc
            printf "| 両方に責任 | %s | |\n\n", cause_label_both
            printf "**skill 起因判定**:\n\n"
            printf "```yaml\n"
            printf "skill_caused_judgment:\n"
            printf "  q1_answer: \"%s\"\n", (q1a[i] != "") ? q1a[i] : "no"
            printf "  q1_quote: \"%s\"\n", q1q[i]
            printf "  q2_answer: \"%s\"\n", (q2a[i] != "") ? q2a[i] : "no"
            printf "  q2_quote: \"%s\"\n", q2q[i]
            printf "  q3_answer: \"%s\"\n", (q3a[i] != "") ? q3a[i] : "no"
            printf "  q3_quote: \"%s\"\n", q3q[i]
            if (pconf[i] != "") {
                printf "confidence: \"%s\"\n", pconf[i]
            }
            printf "```\n\n"
        }
    }
    '
}

# ─── 公開関数: 本文構築（path 渡し → _pure_compose_body 委譲） ─────────

retrospective_body_compose() {
    # $1: draft_yaml_path
    # $2: kpt_md_path
    # $3: cycle
    if [[ $# -lt 3 ]]; then
        __retro_diag error compose_args "retrospective_body_compose requires 3 arguments"
        return 2
    fi
    local draft_yaml_path="$1"
    local kpt_md_path="$2"
    local cycle="$3"

    if ! __retro_validate_cycle "$cycle"; then
        return 2
    fi

    local draft_yaml=""
    local kpt_md=""

    if [[ -n "$draft_yaml_path" && -f "$draft_yaml_path" ]]; then
        if ! draft_yaml="$(cat "$draft_yaml_path")"; then
            __retro_diag error compose_read_failed "draft_yaml_path=$draft_yaml_path"
            return 1
        fi
    fi
    if [[ -n "$kpt_md_path" && -f "$kpt_md_path" ]]; then
        if ! kpt_md="$(cat "$kpt_md_path")"; then
            __retro_diag error compose_read_failed "kpt_md_path=$kpt_md_path"
            return 1
        fi
    fi

    _pure_compose_body "$draft_yaml" "$kpt_md" "$cycle"
}

# ─── Spool 操作 ─────────

__retro_spool_path() {
    # $1: cycle
    # Unit 003 (#638): aidlc-paths.sh helper 経由で path 解決
    # AIDLC_PROJECT_ROOT 指定時は <root>/.aidlc/..、未指定時は cwd 相対 .aidlc/..
    local cycle="$1"
    aidlc_cycle_path "$cycle" "history/retrospective-spool.md"
}

__retro_spool_lock_dir() {
    printf '%s.lock\n' "$1"
}

__retro_spool_init() {
    # $1: spool_path
    local spool_path="$1"
    local dir
    dir=$(dirname "$spool_path")
    mkdir -p "$dir"
    cat > "$spool_path" <<EOF
$RETROSPECTIVE_SPOOL_HEADER

# Retrospective Spool

> このファイルは \`retrospective-resend.sh\` 専用の機械可読スプールです。手動編集禁止。
> 機械パース対象は下記 \`ndjson\` fenced block のみ。block 外の Markdown は人間向け参考情報。

## 機械可読エントリ（NDJSON / 1 行 1 エントリ / 追記専用）

\`\`\`ndjson
\`\`\`
EOF
}

_spool_append() {
    # $1: spool_path
    # $2: entry_json (1 行の JSON)
    local spool_path="$1"
    local entry_json="$2"
    local lock_dir
    lock_dir=$(__retro_spool_lock_dir "$spool_path")

    # ロック取得前に親ディレクトリを作成（mkdir-based lock の前提条件）
    local spool_dir
    spool_dir=$(dirname "$spool_path")
    mkdir -p "$spool_dir" 2>/dev/null || {
        __retro_diag error spool_dir_mkfail "$spool_dir"
        return 1
    }

    if ! __retro_lock_acquire "$lock_dir"; then
        return 1
    fi

    local tmp_path="${spool_path}.tmp.$$"
    # ロック取得済 → サブシェルで trap してリーク防止
    (
        trap '__retro_lock_release "$lock_dir"; rm -f "$tmp_path"' EXIT INT TERM

        if [[ ! -f "$spool_path" ]]; then
            __retro_spool_init "$spool_path"
        fi

        awk -v entry="$entry_json" '
        BEGIN { in_block = 0; injected = 0 }
        /^```ndjson[[:space:]]*$/ && in_block == 0 {
            in_block = 1
            print
            next
        }
        /^```[[:space:]]*$/ && in_block == 1 && injected == 0 {
            print entry
            injected = 1
            in_block = 0
            print
            next
        }
        { print }
        END {
            if (injected == 0) {
                print "```ndjson"
                print entry
                print "```"
            }
        }
        ' "$spool_path" > "$tmp_path" || exit 1

        mv "$tmp_path" "$spool_path" || exit 1
        # mv 成功後は tmp_path は存在しないので trap の rm -f は no-op
        exit 0
    )
    local rc=$?
    return $rc
}

# NDJSON spool パース関数（_spool_extract_entries）は Unit 004 (#643) で aidlc-spool.sh に移管済

_spool_remove_by_id() {
    # $1: spool_path
    # $2: id
    local spool_path="$1"
    local target_id="$2"
    local lock_dir
    lock_dir=$(__retro_spool_lock_dir "$spool_path")

    if ! __retro_lock_acquire "$lock_dir"; then
        return 1
    fi

    if [[ ! -f "$spool_path" ]]; then
        __retro_lock_release "$lock_dir"
        return 0
    fi

    local tmp_path="${spool_path}.tmp.$$"
    (
        trap '__retro_lock_release "$lock_dir"; rm -f "$tmp_path"' EXIT INT TERM

        awk -v target="$target_id" '
        BEGIN { in_block = 0 }
        /^```ndjson[[:space:]]*$/ && in_block == 0 { in_block = 1; print; next }
        /^```[[:space:]]*$/ && in_block == 1 { in_block = 0; print; next }
        in_block == 1 {
            line = $0
            if (match(line, /"id":"[^"]*"/)) {
                id_field = substr(line, RSTART, RLENGTH)
                sub(/^"id":"/, "", id_field)
                sub(/"$/, "", id_field)
                if (id_field == target) {
                    next
                }
            }
            print
            next
        }
        { print }
        ' "$spool_path" > "$tmp_path" || exit 1

        mv "$tmp_path" "$spool_path" || exit 1
        exit 0
    )
    local rc=$?
    return $rc
}

# ─── gh I/O ─────────

# gh CLI 可用性チェック関数（__retro_gh_status）は Unit 004 (#643) で aidlc-gh.sh に移管済

__retro_gh_owner_repo_local() {
    # 出力: OWNER/REPO（git remote get-url origin から抽出）
    local url
    url=$(git remote get-url origin 2>/dev/null) || {
        __retro_diag error git_origin_failed ""
        return 1
    }
    # https://github.com/owner/repo.git or git@github.com:owner/repo.git
    local owner_repo
    owner_repo=$(printf '%s' "$url" | sed -E 's#^.*github\.com[:/]##; s#\.git$##')
    printf '%s\n' "$owner_repo"
}

_gh_find_duplicate() {
    # $1: title
    # $2: cycle
    # 出力: existing_issue_url | (空)
    local title="$1"
    local cycle="$2"
    local result
    result=$(gh issue list \
        --label "$RETROSPECTIVE_LABEL" \
        --milestone "$cycle" \
        --state all \
        --search "in:title \"$title\"" \
        --json url,title \
        --limit 100 2>/dev/null) || {
        __retro_diag warn duplicate_search_failed "title=$title cycle=$cycle"
        printf '\n'
        return 0
    }
    # jq でタイトル完全一致の最初の URL を取得
    printf '%s' "$result" | jq -r --arg t "$title" '.[] | select(.title == $t) | .url' | head -n 1
}

_gh_create_issue() {
    # $1: repo (OWNER/REPO)
    # $2: title
    # $3: body_path
    # $4: cycle (milestone)
    # 出力: issue_url
    # 戻り値: 0=成功 / 非0=失敗
    local repo="$1"
    local title="$2"
    local body_path="$3"
    local cycle="$4"
    local pending_label="${MIRROR_STATE_LABEL_PREFIX}pending"

    gh issue create \
        --repo "$repo" \
        --title "$title" \
        --body-file "$body_path" \
        --label "$RETROSPECTIVE_LABEL,$pending_label" \
        --milestone "$cycle" 2>/dev/null
}

_gh_relabel_created() {
    # $1: repo
    # $2: issue_url
    # 戻り値: 0=成功, 1=最終失敗
    # 最大 3 回リトライ（指数バックオフ: 0.2s / 0.5s / 1.0s）
    local repo="$1"
    local issue_url="$2"
    local pending_label="${MIRROR_STATE_LABEL_PREFIX}pending"
    local created_label="${MIRROR_STATE_LABEL_PREFIX}created"
    local i
    local sleeps=(0.2 0.5 1.0)
    for i in 0 1 2; do
        if gh issue edit "$issue_url" \
            --repo "$repo" \
            --add-label "$created_label" \
            --remove-label "$pending_label" >/dev/null 2>&1; then
            return 0
        fi
        __retro_diag warn relabel_retry "issue=$issue_url attempt=$((i+1))"
        sleep "${sleeps[$i]}"
    done
    __retro_diag error relabel_failed "issue=$issue_url"
    return 1
}

# ─── Spool エントリ構築 ─────────

__retro_build_spool_entry() {
    # $1: cycle
    # $2: feedback_mode
    # $3: target
    # $4: retry_target
    # $5: attempt_reason
    # $6: body_path
    # $7: local_created_url (or empty)
    # $8: mirror_created_url (or empty)
    # 出力: 1 行の JSON
    local cycle="$1"
    local feedback_mode="$2"
    local target="$3"
    local retry_target="$4"
    local attempt_reason="$5"
    local body_path="$6"
    local local_created="${7:-}"
    local mirror_created="${8:-}"

    local id
    id=$(__retro_uuid)
    local attempted_at
    attempted_at=$(__retro_iso8601)
    local body_b64
    body_b64=$(__retro_base64_encode < "$body_path")
    local body_sha256
    body_sha256=$(__retro_sha256 < "$body_path")

    local local_arg="null"
    local mirror_arg="null"
    [[ -n "$local_created" ]] && local_arg="$local_created"
    [[ -n "$mirror_created" ]] && mirror_arg="$mirror_created"

    jq -nc \
        --arg id "$id" \
        --arg version "$RETROSPECTIVE_SPOOL_VERSION" \
        --arg cycle "$cycle" \
        --arg feedback_mode "$feedback_mode" \
        --arg attempted_at "$attempted_at" \
        --arg target "$target" \
        --arg retry_target "$retry_target" \
        --arg local_created "$local_arg" \
        --arg mirror_created "$mirror_arg" \
        --arg attempt_reason "$attempt_reason" \
        --arg body_b64 "$body_b64" \
        --arg body_sha256 "$body_sha256" \
        '{
            id: $id,
            version: $version,
            cycle: $cycle,
            feedback_mode: $feedback_mode,
            attempted_at: $attempted_at,
            target: $target,
            retry_target: $retry_target,
            partial_state: {
                local_created: (if $local_created == "null" then null else $local_created end),
                mirror_created: (if $mirror_created == "null" then null else $mirror_created end)
            },
            attempt_reason: $attempt_reason,
            body_b64: $body_b64,
            body_sha256: $body_sha256
        }'
}

# ─── Unit 001 (#647): 対話確認トークン（発行 / 検証）─────────
#
# 振り返り Issue 起票時の対話必須ガード（実行時ガード）。AI エージェントの
# auto mode 動作下で対話を経ない `gh issue create` を構造的に防止する。
# 詳細は `.aidlc/cycles/v2.5.3/design-artifacts/logical-designs/unit_001_retro_dialog_guard_logical_design.md` を参照。

__retro_dialog_token_path() {
    # $1: cycle
    # 出力: トークンファイルパス（${TMPDIR:-/tmp}/aidlc-retro-confirmed-${cycle}.flag）
    local cycle="$1"
    local tmpdir="${TMPDIR:-/tmp}"
    # TMPDIR の末尾スラッシュ除去
    tmpdir="${tmpdir%/}"
    printf '%s/aidlc-retro-confirmed-%s.flag\n' "$tmpdir" "$cycle"
}

__retro_iso8601_to_epoch() {
    # $1: ISO 8601 タイムスタンプ（UTC / 例: 2026-05-07T05:30:00Z）
    # 出力: epoch 秒（成功時）
    # 戻り値: 0=成功 / 1=parse 失敗
    local ts="$1"
    # 厳密な regex 検証（Z 終端必須 / mm/dd/HH/MM/SS の桁数固定）
    if ! [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
        return 1
    fi
    # GNU date を試行
    local epoch
    if epoch=$(date -u -d "$ts" +%s 2>/dev/null) && [[ -n "$epoch" ]]; then
        printf '%s\n' "$epoch"
        return 0
    fi
    # BSD date にフォールバック
    if epoch=$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$ts" +%s 2>/dev/null) && [[ -n "$epoch" ]]; then
        printf '%s\n' "$epoch"
        return 0
    fi
    return 1
}

retrospective_dialog_token_record_response() {
    # $1: cycle (必須、許可文字: ^[A-Za-z0-9._-]+$)
    # $2: response (必須、approved | denied)
    # 戻り値: 0=成功 / 1=引数不正 / 2=書き込み失敗
    if [[ $# -lt 2 ]]; then
        __retro_diag error missing_args "cycle and response required"
        return 1
    fi
    local cycle="$1"
    local response="$2"

    # cycle バリデーション（既存ヘルパ流用、path traversal 防御）
    if ! __retro_validate_cycle "$cycle" 2>/dev/null; then
        __retro_diag error invalid_cycle "$cycle"
        return 1
    fi

    # response バリデーション
    if [[ "$response" != "approved" && "$response" != "denied" ]]; then
        __retro_diag error invalid_response "$response"
        return 1
    fi

    local token_path
    token_path=$(__retro_dialog_token_path "$cycle")

    local timestamp
    timestamp=$(__retro_iso8601)

    # umask 077 でユーザーのみ読み書き可（0600）
    local previous_umask
    previous_umask=$(umask)
    umask 077
    if ! { printf '%s\n%s\n' "$timestamp" "$response" > "$token_path"; } 2>/dev/null; then
        umask "$previous_umask"
        __retro_diag error write_failed "$token_path"
        return 2
    fi
    umask "$previous_umask"

    return 0
}

retrospective_dialog_token_verify() {
    # $1: cycle (必須)
    # 戻り値: 0=検証成功 / 1=引数不正 / 4=業務拒否または I/O 異常
    # stderr 出力: error\t<reason>\t[<detail>]
    #   reason 値:
    #     業務拒否系: dialog_required (token_missing / token_stale / token_denied)
    #     I/O 異常系: dialog_required (token_io_error / token_parse_error)
    #
    # 内部 bypass (resend 専用): retrospective-resend.sh が spool 退避済みエントリの再送経路で、
    # 過去の対話確認を流用するため `AIDLC_RETRO_RESEND_INTERNAL_BYPASS` を set する。
    # この変数は **resend 内部 sentinel** として扱い、外部から set してはならない（外部ドキュメントには露出しない）。
    # 加えて、resend スクリプトは常に AIDLC_RETRO_FORCE_TARGET を set してから retrospective_issue_create
    # を呼び出すため、本 bypass の有効化条件として AIDLC_RETRO_FORCE_TARGET の併設を必須化することで
    # 「環境変数 1 つ set するだけでガードを迂回できる」リスクを抑える（resend 経路の構造的検証）。
    #
    # **構造的ガード（v2.5.3 Codex review 指摘対応）**: env var 2 個併設だけでは AI agent や
    # accidental shell environment leakage 経由で bypass される懸念があるため、`BASH_SOURCE`
    # chain に `retrospective-resend.sh` が含まれることを追加で必須化する。これにより、resend.sh
    # からの呼び出し経路でない場合は bypass フラグが set されていても通常検証にフォールスルーする。
    if [[ "${AIDLC_RETRO_RESEND_INTERNAL_BYPASS:-}" == "1" && -n "${AIDLC_RETRO_FORCE_TARGET:-}" ]]; then
        local __retro_resend_chain=0
        local __retro_i
        for (( __retro_i=1; __retro_i<${#BASH_SOURCE[@]}; __retro_i++ )); do
            if [[ "${BASH_SOURCE[__retro_i]:-}" == */retrospective-resend.sh ]]; then
                __retro_resend_chain=1
                break
            fi
        done
        if [[ "$__retro_resend_chain" == "1" ]]; then
            return 0
        fi
        __retro_diag warn bypass_attempted_outside_resend_chain ""
    fi

    if [[ $# -lt 1 ]]; then
        __retro_diag error missing_args "cycle required"
        return 1
    fi
    local cycle="$1"

    if ! __retro_validate_cycle "$cycle" 2>/dev/null; then
        __retro_diag error invalid_cycle "$cycle"
        return 1
    fi

    local token_path
    token_path=$(__retro_dialog_token_path "$cycle")

    # トークン不在 → token_missing
    if [[ ! -f "$token_path" ]]; then
        __retro_diag error dialog_required "token_missing"
        return 4
    fi

    # 読み取り権限確認
    if [[ ! -r "$token_path" ]]; then
        __retro_diag error dialog_required "token_io_error"
        return 4
    fi

    # ファイル形式: 行 1=ISO 8601 タイムスタンプ、行 2=response（approved | denied）
    local line1 line2
    if ! IFS= read -r line1 < "$token_path"; then
        __retro_diag error dialog_required "token_io_error"
        return 4
    fi
    if ! line2=$(sed -n '2p' "$token_path" 2>/dev/null); then
        __retro_diag error dialog_required "token_io_error"
        return 4
    fi

    # 行 1 を厳密な ISO 8601 形式として検証 + epoch 化（mtime に依存しない）
    local issued_epoch
    if ! issued_epoch=$(__retro_iso8601_to_epoch "$line1"); then
        __retro_diag error dialog_required "token_parse_error"
        return 4
    fi

    # 行 2 の response 値チェック
    if [[ "$line2" != "approved" && "$line2" != "denied" ]]; then
        __retro_diag error dialog_required "token_parse_error"
        return 4
    fi

    # TTL 切れ判定（行 1 タイムスタンプ epoch ベース、ファイル mtime には依存しない）
    local ttl="${AIDLC_RETRO_TOKEN_TTL_SECONDS:-300}"
    if ! [[ "$ttl" =~ ^[0-9]+$ ]]; then
        ttl=300
    fi
    local now
    now=$(date -u +%s)
    local age=$(( now - issued_epoch ))
    if (( age > ttl )); then
        __retro_diag error dialog_required "token_stale"
        return 4
    fi

    # response が denied なら token_denied
    if [[ "$line2" == "denied" ]]; then
        __retro_diag error dialog_required "token_denied"
        return 4
    fi

    return 0
}

# ─── 公開関数: Issue 起票 ─────────

retrospective_issue_create() {
    # $1: body_path
    # $2: feedback_mode (5 値正規化済)
    # $3: cycle
    # 拡張環境変数（オプショナル）:
    #   AIDLC_RETRO_FORCE_TARGET   - "local" | "mirror" | "both"（指定時 feedback_mode 由来 target を上書き、resend 用途）
    #   AIDLC_RETRO_CURRENT_COUNT  - 現サイクルの起票済 retrospective Issue 数
    #   AIDLC_RETRO_LIMIT          - feedback_max_per_cycle（current_count と両方指定で cap 判定実施）
    #   AIDLC_RETRO_SKIP_LOCAL     - "1" の時 local 起票をスキップ（resend で partial_state.local_created あり時用）
    if [[ $# -lt 3 ]]; then
        __retro_diag error create_args "retrospective_issue_create requires 3 arguments"
        return 2
    fi
    local body_path="$1"
    local feedback_mode="$2"
    local cycle="$3"

    if [[ ! -f "$body_path" ]]; then
        __retro_diag error body_not_found "$body_path"
        return 2
    fi

    # cycle バリデーション（path traversal 防御）
    if ! __retro_validate_cycle "$cycle"; then
        return 2
    fi

    # target 解決（force_target 指定時はそれを採用）
    local target
    if [[ -n "${AIDLC_RETRO_FORCE_TARGET:-}" ]]; then
        case "${AIDLC_RETRO_FORCE_TARGET}" in
            local|mirror|both) target="$AIDLC_RETRO_FORCE_TARGET" ;;
            none) target="none" ;;
            *)
                __retro_diag error force_target_invalid "$AIDLC_RETRO_FORCE_TARGET"
                return 2
                ;;
        esac
    else
        if ! target=$(__retro_resolve_target "$feedback_mode"); then
            return 2
        fi
    fi

    # disabled / interactive→none で skip
    if [[ "$target" == "none" ]]; then
        printf 'result=skipped\nreason=mode-disabled\nmirror_state=\n'
        return 0
    fi

    # cap 判定（環境変数で current_count / limit が両方与えられた場合のみ）
    if [[ -n "${AIDLC_RETRO_CURRENT_COUNT:-}" && -n "${AIDLC_RETRO_LIMIT:-}" ]]; then
        if [[ "$AIDLC_RETRO_CURRENT_COUNT" =~ ^[0-9]+$ && "$AIDLC_RETRO_LIMIT" =~ ^[0-9]+$ ]]; then
            if [[ "$AIDLC_RETRO_CURRENT_COUNT" -ge "$AIDLC_RETRO_LIMIT" ]]; then
                printf 'result=skipped\nreason=cap-exceeded\nmirror_state=skipped:max_exceeded\n'
                return 0
            fi
        else
            __retro_diag warn cap_args_invalid "current=$AIDLC_RETRO_CURRENT_COUNT limit=$AIDLC_RETRO_LIMIT"
        fi
    fi

    # title
    local title
    printf -v title "$RETROSPECTIVE_ISSUE_TITLE_TEMPLATE" "$cycle"

    # gh_status
    local gh_status
    gh_status=$(__retro_gh_status)

    # gh 不可なら spool 経路
    if [[ "$gh_status" != "available" ]]; then
        local spool_path
        spool_path=$(__retro_spool_path "$cycle")
        local entry
        entry=$(__retro_build_spool_entry "$cycle" "$feedback_mode" "$target" "$target" "gh-not-available" "$body_path" "" "")
        if ! _spool_append "$spool_path" "$entry"; then
            __retro_diag error spool_append_failed "$spool_path"
            printf 'result=failed\nreason=spool-write-failed\nmirror_state=error\n'
            return 1
        fi
        printf 'result=spooled\nspool_path=%s\nmirror_state=pending\n' "$spool_path"
        return 0
    fi

    # local リポ解決
    local local_repo=""
    if [[ "$target" == "local" || "$target" == "both" ]]; then
        if ! local_repo=$(__retro_gh_owner_repo_local); then
            __retro_diag error local_repo_resolve_failed ""
            printf 'result=failed\nreason=local-repo-resolve-failed\nmirror_state=error\n'
            return 1
        fi
    fi

    # メタ開発リポ縮退: local と mirror が同一なら local のみ
    if [[ "$target" == "both" && "$local_repo" == "$MIRROR_REPO" ]]; then
        __retro_diag info target_collapsed_to_local "local_repo=$local_repo == MIRROR_REPO=$MIRROR_REPO"
        target="local"
    fi

    # 重複検出（local 側 / mirror 側 / both は両方）
    # both 時は 1 Issue = 1 Milestone 制約準拠で local → mirror の順に検査し、
    # いずれかにヒットすれば skip（mirror 側に既存があるのに local 側だけ無くて
    # mirror に重複起票してしまう codex review 指摘 P2 対応）。
    local existing_url=""
    case "$target" in
        local)
            existing_url=$(GH_REPO="$local_repo" _gh_find_duplicate "$title" "$cycle" 2>/dev/null || true)
            ;;
        mirror)
            existing_url=$(GH_REPO="$MIRROR_REPO" _gh_find_duplicate "$title" "$cycle" 2>/dev/null || true)
            ;;
        both)
            existing_url=$(GH_REPO="$local_repo" _gh_find_duplicate "$title" "$cycle" 2>/dev/null || true)
            if [[ -z "$existing_url" ]]; then
                existing_url=$(GH_REPO="$MIRROR_REPO" _gh_find_duplicate "$title" "$cycle" 2>/dev/null || true)
            fi
            ;;
    esac
    if [[ -n "$existing_url" ]]; then
        printf 'result=skipped\nreason=duplicate\nexisting_issue_url=%s\nmirror_state=skipped:duplicate\n' "$existing_url"
        return 0
    fi

    # Unit 001 (#647): 対話確認トークン検証（gh issue create 直前の実行時ガード）
    # AskUserQuestion 応答を経ずに起票しようとする経路を構造的にブロックする。
    # 適用範囲: target != none（local / mirror / both）の全経路で verify 必須。
    # 真理表は logical_design.md「feedback_mode / target 別の verify 呼出真理表」を SoT として参照。
    # - target=none（disabled / silent）: 既に early return 済のため verify 到達なし
    # - spool 経路（gh 不可）: 起票実行前に return 済のため verify 到達なし
    # - 重複検出 hit 時: 既に return 済のため verify 到達なし
    # - ここに到達: target=local/mirror/both + gh available + 重複なし + 起票実行直前
    local verify_rc=0
    retrospective_dialog_token_verify "$cycle" || verify_rc=$?
    if [[ "$verify_rc" -ne 0 ]]; then
        printf 'result=failed\nreason=dialog-required\nmirror_state=blocked\nverify_exit=%s\n' "$verify_rc"
        return "$verify_rc"
    fi

    # 起票
    local local_url=""
    local mirror_url=""
    # resend 時に partial_state.local_created があれば AIDLC_RETRO_SKIP_LOCAL=1 でスキップ
    local skip_local="${AIDLC_RETRO_SKIP_LOCAL:-}"

    if [[ "$target" == "local" || "$target" == "both" ]]; then
        if [[ "$skip_local" == "1" ]]; then
            __retro_diag info local_skipped_resend "AIDLC_RETRO_SKIP_LOCAL=1（partial_state.local_created あり）"
        elif local_url=$(_gh_create_issue "$local_repo" "$title" "$body_path" "$cycle"); then
            if ! _gh_relabel_created "$local_repo" "$local_url"; then
                # ラベル付け替え失敗 → spool 退避（issue は既に存在するので再起票せず再ラベルだけ retry 用）
                local entry
                entry=$(__retro_build_spool_entry "$cycle" "$feedback_mode" "$target" "$target" "relabel-failed-local" "$body_path" "$local_url" "")
                local spool_path
                spool_path=$(__retro_spool_path "$cycle")
                _spool_append "$spool_path" "$entry" || true
                printf 'result=failed\nreason=relabel-failed-local\nmirror_state=pending\nlocal_issue_url=%s\nspool_path=%s\n' "$local_url" "$spool_path"
                return 1
            fi
        else
            __retro_diag warn local_create_failed "$local_repo"
            local entry
            entry=$(__retro_build_spool_entry "$cycle" "$feedback_mode" "$target" "$target" "gh-create-failed" "$body_path" "" "")
            local spool_path
            spool_path=$(__retro_spool_path "$cycle")
            _spool_append "$spool_path" "$entry" || true
            printf 'result=failed\nreason=local-create-failed\nmirror_state=error\nspool_path=%s\n' "$spool_path"
            return 1
        fi
    fi

    if [[ "$target" == "mirror" || "$target" == "both" ]]; then
        if mirror_url=$(_gh_create_issue "$MIRROR_REPO" "$title" "$body_path" "$cycle"); then
            if ! _gh_relabel_created "$MIRROR_REPO" "$mirror_url"; then
                local entry
                entry=$(__retro_build_spool_entry "$cycle" "$feedback_mode" "$target" "mirror" "relabel-failed-mirror" "$body_path" "$local_url" "$mirror_url")
                local spool_path
                spool_path=$(__retro_spool_path "$cycle")
                _spool_append "$spool_path" "$entry" || true
                printf 'result=failed\nreason=relabel-failed-mirror\nmirror_state=pending\nmirror_issue_url=%s\nspool_path=%s\n' "$mirror_url" "$spool_path"
                if [[ -n "$local_url" ]]; then
                    printf 'local_issue_url=%s\n' "$local_url"
                fi
                return 1
            fi
        else
            __retro_diag warn mirror_create_failed "$MIRROR_REPO"
            local entry
            local reason="gh-create-failed"
            if [[ "$target" == "both" && -n "$local_url" ]]; then
                reason="mirror-failed-after-local-created"
                entry=$(__retro_build_spool_entry "$cycle" "$feedback_mode" "$target" "mirror" "$reason" "$body_path" "$local_url" "")
            else
                entry=$(__retro_build_spool_entry "$cycle" "$feedback_mode" "$target" "$target" "$reason" "$body_path" "" "")
            fi
            local spool_path
            spool_path=$(__retro_spool_path "$cycle")
            _spool_append "$spool_path" "$entry" || true
            printf 'result=failed\nreason=%s\nmirror_state=error\n' "$reason"
            if [[ -n "$local_url" ]]; then
                printf 'local_issue_url=%s\n' "$local_url"
            fi
            printf 'spool_path=%s\n' "$spool_path"
            return 1
        fi
    fi

    # 全成功
    case "$target" in
        local)
            printf 'result=created\ntarget=local\nissue_url=%s\nmirror_state=created\n' "$local_url"
            ;;
        mirror)
            printf 'result=created\ntarget=mirror\nissue_url=%s\nmirror_state=created\n' "$mirror_url"
            ;;
        both)
            if [[ "$skip_local" == "1" ]]; then
                printf 'result=created\ntarget=mirror\nissue_url=%s\nmirror_state=created\n' "$mirror_url"
            else
                printf 'result=created\ntarget=both\nlocal_issue_url=%s\nmirror_issue_url=%s\nmirror_state=created\n' "$local_url" "$mirror_url"
            fi
            ;;
    esac
    return 0
}
