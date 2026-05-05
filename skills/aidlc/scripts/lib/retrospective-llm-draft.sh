#!/usr/bin/env bash
# retrospective-llm-draft.sh - Unit 003 LLM 下書き hook 実装
#
# 提供する公開関数:
#   retrospective_prefill_hook <cycle> <kpt_md_path>
#       -> stdout に Intent §6.3 スキーマの YAML を出力（成功時 / fallback 時）
#       -> exit 0=成功（warn 含む） / 1=ランタイム異常 / 2=引数エラー
#
# 環境変数（main agent 前段手順 / テスト経路）:
#   AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH  - subagent 出力 YAML の一時ファイルパス
#   AIDLC_RETRO_LLM_DRAFT_OVERRIDE      - テストモック用 OVERRIDE パス（AIDLC_TEST_MODE=1 必須）
#   AIDLC_TEST_MODE                     - "1" 設定でテストモード有効
#
# stderr フォーマット: <level>\t<code>\t<detail>  (level=info|warn|error)
#
# 責務分離:
#   - subagent 起動 / AskUserQuestion / 30 秒タイムアウト判定は main agent の責務（本 hook では行わない）
#   - 本 hook は環境変数経由のファイル読取 / スキーマ検証 / skip 判定 / I/O のみ

# 多重 source ガード
if [[ "${__AIDLC_RETROSPECTIVE_LLM_DRAFT_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_RETROSPECTIVE_LLM_DRAFT_SH_LOADED=1

# ─── 診断出力ヘルパ ─────────
__retro_llm_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

# ─── テストモード判定 ─────────
__retro_llm_is_test_mode() {
    [[ "${AIDLC_TEST_MODE:-}" == "1" ]]
}

# ─── 非対話判定 ─────────
__retro_llm_is_interactive() {
    [[ -t 0 ]]
}

# ─── feedback_mode 解決（Unit 001 関数を呼ぶ。未ロード時は disabled で skip）─────────
# Unit 001 の feedback_mode_resolve(mode, env_interactive) を呼び出すため、
# raw mode を read-config.sh から取得 + feedback_mode_normalize で正規化 +
# is_interactive_env で env_interactive を解決し、2 引数を完全に揃えてから呼ぶ。
# read-config.sh / feedback_mode_normalize / is_interactive_env のいずれかが
# 不在の場合は disabled に倒す（安全側 / Unit 001 関数未ロード時と同等の挙動）。
__retro_llm_resolve_feedback_mode() {
    if ! command -v feedback_mode_resolve >/dev/null 2>&1; then
        printf 'disabled\n'
        return 0
    fi

    local script_root
    script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    local raw_mode=""
    if [[ -x "$script_root/read-config.sh" ]]; then
        raw_mode=$("$script_root/read-config.sh" rules.retrospective.feedback_mode 2>/dev/null || true)
    fi

    local mode
    if command -v feedback_mode_normalize >/dev/null 2>&1; then
        mode=$(feedback_mode_normalize "$raw_mode")
    else
        mode="${raw_mode:-disabled}"
    fi

    local env_interactive="false"
    if command -v is_interactive_env >/dev/null 2>&1; then
        env_interactive=$(is_interactive_env)
    elif __retro_llm_is_interactive; then
        env_interactive="true"
    fi

    feedback_mode_resolve "$mode" "$env_interactive"
    return $?
}

# ─── スキーマ検証（簡易 / 必須キーの存在確認 + 値域チェック）─────────
# 戻り値: 0=ok / 1=violation
# 引数: $1 = YAML ファイルパス
# 副作用: violation 時に stderr に warn を出さない（呼出元で出す）
__retro_llm_validate_schema() {
    local path="$1"
    [[ -f "$path" ]] || return 1
    [[ -s "$path" ]] || return 1

    local content
    content=$(cat "$path" 2>/dev/null) || return 1

    # problem_drafts キーが必ず存在すること
    if ! printf '%s\n' "$content" | grep -qE '^problem_drafts:'; then
        return 1
    fi

    # 各 Problem に必須キーが揃っているか（厳密パースは Phase 2 統合テストで yq に委ねる）
    # ここでは簡易的に「primary_cause」「skill_caused_judgment」「q1_answer」がそれぞれ 1 つ以上含まれているかを確認
    local required_keys=("primary_cause:" "primary_cause_reason:" "skill_caused_judgment:" "q1_answer:" "q1_quote:" "q2_answer:" "q2_quote:" "q3_answer:" "q3_quote:")
    local key
    for key in "${required_keys[@]}"; do
        if ! printf '%s\n' "$content" | grep -qE "$key"; then
            return 1
        fi
    done

    # primary_cause の値域チェック（"完全 quoted" または "完全 unquoted" のみ許容 / 片側欠落は不許可）
    local primary_cause_lines
    primary_cause_lines=$(printf '%s\n' "$content" | grep -E '^[[:space:]]*primary_cause:' || true)
    if [[ -n "$primary_cause_lines" ]]; then
        local invalid_primary_cause
        invalid_primary_cause=$(printf '%s\n' "$primary_cause_lines" | grep -vE '^[[:space:]]*primary_cause:[[:space:]]*("(product|ai_dlc|both)"|(product|ai_dlc|both))[[:space:]]*$' || true)
        if [[ -n "$invalid_primary_cause" ]]; then
            return 1
        fi
    fi

    # qN_answer の値域チェック（"完全 quoted" または "完全 unquoted" のみ許容 / 片側欠落は不許可）
    local qN_lines
    qN_lines=$(printf '%s\n' "$content" | grep -E '^[[:space:]]*q[1-3]_answer:' || true)
    if [[ -n "$qN_lines" ]]; then
        local invalid_qN
        invalid_qN=$(printf '%s\n' "$qN_lines" | grep -vE '^[[:space:]]*q[1-3]_answer:[[:space:]]*("(yes|no)"|(yes|no))[[:space:]]*$' || true)
        if [[ -n "$invalid_qN" ]]; then
            return 1
        fi
    fi

    return 0
}

# ─── パス解決（環境変数優先順位 + production ガード）─────────
# stdout: 解決済パス（空文字列なら skip）
# 戻り値: 0=ok / 非0=エラー（呼出元では使わず、stderr 警告のみ）
# 副作用: production 誤設定時に stderr error を出す
__retro_llm_resolve_source_path() {
    local prefill_path="${AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH:-}"
    local override_path="${AIDLC_RETRO_LLM_DRAFT_OVERRIDE:-}"

    # production 誤設定検出: TEST_MODE 未設定 + OVERRIDE 設定済
    if ! __retro_llm_is_test_mode && [[ -n "$override_path" ]]; then
        __retro_llm_diag "error" "llm_draft_override_in_production" \
            "AIDLC_RETRO_LLM_DRAFT_OVERRIDE specified without AIDLC_TEST_MODE=1 (ignored)"
        # OVERRIDE 値を無視して通常経路で評価する
        printf '%s\n' "$prefill_path"
        return 0
    fi

    # テストモード + OVERRIDE 設定済 → OVERRIDE 優先
    if __retro_llm_is_test_mode && [[ -n "$override_path" ]]; then
        __retro_llm_diag "info" "llm_draft_test_override" \
            "using AIDLC_RETRO_LLM_DRAFT_OVERRIDE=$override_path"
        printf '%s\n' "$override_path"
        return 0
    fi

    # 通常経路: PREFILL_PATH を返す（空でも空のまま返す = skip 判定は呼出元）
    printf '%s\n' "$prefill_path"
    return 0
}

# ─── 公開関数: retrospective_prefill_hook ─────────
retrospective_prefill_hook() {
    # 引数検証
    if [[ $# -lt 2 ]]; then
        __retro_llm_diag "error" "llm_draft_missing_args" \
            "expected: retrospective_prefill_hook <cycle> <kpt_md_path>"
        return 2
    fi

    local cycle="$1"
    local kpt_md_path="$2"

    if [[ -z "$cycle" ]]; then
        __retro_llm_diag "error" "llm_draft_missing_args" "cycle is empty"
        return 2
    fi
    if [[ -z "$kpt_md_path" ]]; then
        __retro_llm_diag "error" "llm_draft_missing_args" "kpt_md_path is empty"
        return 2
    fi

    # feedback_mode 解決 → disabled 時は skip
    local mode
    mode=$(__retro_llm_resolve_feedback_mode)
    if [[ "$mode" == "disabled" ]]; then
        __retro_llm_diag "info" "llm_draft_skip_disabled" "feedback_mode=disabled"
        return 0
    fi

    # パス解決（環境変数優先順位 + production ガード）
    local source_path
    source_path=$(__retro_llm_resolve_source_path)

    # PREFILL_PATH / OVERRIDE 未設定（あるいは production 誤設定で OVERRIDE が無視された）
    if [[ -z "$source_path" ]]; then
        # 対話セッション + 環境変数未設定 → AI エージェント前段手順未実施の警告
        if __retro_llm_is_interactive; then
            __retro_llm_diag "warn" "llm_draft_subagent_unavailable" \
                "AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH not set (AI agent pre-step not executed)"
            return 0
        fi
        # 非対話 / CI セッション → skip
        __retro_llm_diag "info" "llm_draft_skip_non_interactive" \
            "tty unavailable and no PREFILL_PATH (CI / non-interactive)"
        return 0
    fi

    # ファイル存在確認
    if [[ ! -f "$source_path" ]]; then
        __retro_llm_diag "error" "llm_draft_io_error" \
            "file not found: $source_path"
        return 1
    fi

    # スキーマ検証
    if ! __retro_llm_validate_schema "$source_path"; then
        __retro_llm_diag "warn" "llm_draft_schema_violation" \
            "schema violation in $source_path (empty stdout fallback)"
        return 0
    fi

    # YAML 内容を stdout に出力（cat ではなく read してリダイレクトで規約遵守）
    if ! cat "$source_path"; then
        __retro_llm_diag "error" "llm_draft_io_error" \
            "failed to read $source_path"
        return 1
    fi

    __retro_llm_diag "info" "llm_draft_subagent_emitted" \
        "emitted YAML from $source_path"
    return 0
}
