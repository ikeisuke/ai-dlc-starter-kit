#!/bin/bash
# retrospective-api.sh
#
# /aidlc-retrospective 独立スキル向け公開 API 層（Facade）
#
# v2.6.0 Unit 005 で新設。`skills/aidlc-retrospective/` から内部 lib の
# 実装詳細に依存しないための単方向境界を提供する。
#
# 設計参照:
#   .aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_005_aidlc_retrospective_skill_extraction_domain_model.md
#   .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_005_aidlc_retrospective_skill_extraction_logical_design.md
#   v2.6.6 / #704 / Unit 002:
#     .aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_002_selfreview_and_classification_guide_domain_model.md
#     .aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_002_selfreview_and_classification_guide_logical_design.md
#
# 出力タイプ規約:
#   タイプ A（key=value 複数行 / 副作用あり）:
#       retrospective_api_create_issue / retrospective_api_record_response
#       retrospective_api_ensure_label / retrospective_api_record_selfreview
#   タイプ B（raw text 1 行 / 純粋値）:
#       retrospective_api_resolve_feedback_mode / retrospective_api_requires_wizard
#       retrospective_api_run_wizard / retrospective_api_check_cap
#       retrospective_api_compose_body / retrospective_api_is_interactive_env
#       retrospective_api_prefill / retrospective_api_update_issue
#       retrospective_api_aggregate_enabled / retrospective_api_evaluate_selfreview_verdict
#   タイプ B'（raw text 複数行 / 純粋値）:
#       retrospective_api_extract_facts (v2.6.6 / #652 / Unit 003)
#
# 終了コード規約（呼出側で統一解釈）:
#   0=成功 / 1=warn(recoverable) / 2=fatal / 3=マージ前完結契約違反 / 4=dialog-required

# 多重 source ガード
if [[ -n "${RETROSPECTIVE_API_SOURCED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
RETROSPECTIVE_API_SOURCED=1

# ─── bootstrap: AIDLC_BASE 解決 ─────────────────────────────────────
# 優先順位: ① 環境変数 AIDLC_BASE → ② 本ファイル絶対パス起点 → ③ git toplevel 起点
_retrospective_api_resolve_base() {
    if [[ -n "${AIDLC_BASE:-}" && -d "$AIDLC_BASE/scripts/lib" ]]; then
        printf '%s\n' "$AIDLC_BASE"
        return 0
    fi
    local self_path
    self_path="${BASH_SOURCE[0]:-}"
    if [[ -n "$self_path" ]]; then
        local self_dir
        self_dir=$(cd "$(dirname "$self_path")" && pwd 2>/dev/null || true)
        if [[ -n "$self_dir" ]]; then
            local candidate="$self_dir/../.."
            if [[ -d "$candidate/scripts/lib" ]]; then
                (cd "$candidate" && pwd)
                return 0
            fi
        fi
    fi
    local toplevel
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -n "$toplevel" && -d "$toplevel/skills/aidlc/scripts/lib" ]]; then
        printf '%s\n' "$toplevel/skills/aidlc"
        return 0
    fi
    return 1
}

_RETROSPECTIVE_API_BASE=$(_retrospective_api_resolve_base) || {
    echo "error: retrospective-api.sh: AIDLC_BASE 解決失敗（AIDLC_BASE 環境変数を設定してください）" >&2
    return 2 2>/dev/null || exit 2
}

# 内部 lib の source（タイプ別関数を再エクスポート可能にする）
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/feedback-mode.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/feedback-mode-wizard.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/retrospective-issue.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/retrospective-llm-draft.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/retrospective-human-review.sh" 2>/dev/null || true
# shellcheck source=/dev/null
. "$_RETROSPECTIVE_API_BASE/scripts/lib/retrospective-fact-extract.sh" 2>/dev/null || true

# ─── 公開 API（タイプ B / 純粋値）───────────────────────────────────

# retrospective_api_resolve_feedback_mode <raw_value>
# stdout: 正規化済 mode（silent / mirror / disabled / interactive / "" → silent fallback）
retrospective_api_resolve_feedback_mode() {
    feedback_mode_normalize "$@"
}

# retrospective_api_is_interactive_env
# stdout: true / false
retrospective_api_is_interactive_env() {
    is_interactive_env "$@"
}

# retrospective_api_requires_wizard <mode> <env_interactive>
# stdout: true / false（wizard 起動要否）
retrospective_api_requires_wizard() {
    feedback_mode_requires_wizard "$@"
}

# retrospective_api_run_wizard
# stdout: wizard で確定した mode
retrospective_api_run_wizard() {
    feedback_mode_wizard "$@"
}

# retrospective_api_check_cap <mode> <current_count> <limit>
# stdout: over=true|false（feedback_cap_check の出力をそのまま中継）
retrospective_api_check_cap() {
    feedback_cap_check "$@"
}

# retrospective_api_compose_body <draft_yaml_path> <kpt_md_path> <cycle>
# stdout: Issue 本文 Markdown
retrospective_api_compose_body() {
    retrospective_body_compose "$@"
}

# retrospective_api_prefill <cycle> <kpt_md_path>
# stdout: prefill draft YAML（cap 超過時は空 / fallback 時も空 YAML）
retrospective_api_prefill() {
    if command -v retrospective_prefill_hook >/dev/null 2>&1; then
        retrospective_prefill_hook "$@"
    else
        # フック未定義時は空 YAML フォールバック
        printf ''
    fi
}

# retrospective_api_extract_facts <cycle_id> [<jsonl_path>]
# v2.6.6 / #652 / Unit 003
# 1 cycle 分の事実テーブルを §1.1.5 互換 markdown 表として stdout に出力する。
# jsonl_path 引数指定時のみ jsonl source を追加抽出する。
#
# 設計参照:
#   .aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_003_fact_extract_helper_domain_model.md
#   .aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_003_fact_extract_helper_logical_design.md
#
# 引数:
#   cycle_id   - 必須 / 例: v2.6.5 / .aidlc/cycles/{cycle_id}/ を base
#   jsonl_path - 任意 / 指定時のみ jsonl source を追加抽出
#
# stdout: §1.1.5 互換 markdown 表（複数行）
# stderr: warn メッセージ
# exit:   0 = 成功 / 2 = fatal（引数不正 / cycle_dir 不在）
#
# 役割: L3 orchestrator。L1 extractors (private lib) を順次起動し、
#       L2 renderer (private lib) に渡して stdout に出力するのみ。
#       抽出ロジック・表示整形ロジックは持たない。
retrospective_api_extract_facts() {
    local _local_extract_facts_cycle="${1:-}"
    local _local_extract_facts_jsonl="${2:-}"

    if [[ -z "$_local_extract_facts_cycle" ]]; then
        printf '[error] retrospective_api_extract_facts: cycle_id 必須引数が空です\n' >&2
        return 2
    fi

    # cycle_id 形式バリデーション: v{major}.{minor}.{patch} を期待（厳格すぎないよう英数字 + . + - を許容）
    if [[ ! "$_local_extract_facts_cycle" =~ ^[A-Za-z0-9._-]+$ ]]; then
        printf '[error] retrospective_api_extract_facts: cycle_id 形式不正 ("%s")\n' \
            "$_local_extract_facts_cycle" >&2
        return 2
    fi

    # cycle_dir 解決: AIDLC_BASE の親（リポジトリルート） + .aidlc/cycles/{cycle_id}
    local _local_extract_facts_repo_root
    _local_extract_facts_repo_root=$(cd "$_RETROSPECTIVE_API_BASE/../.." 2>/dev/null && pwd) || {
        printf '[error] retrospective_api_extract_facts: repo root 解決失敗 (AIDLC_BASE=%s)\n' \
            "$_RETROSPECTIVE_API_BASE" >&2
        return 2
    }
    local _local_extract_facts_cycle_dir="$_local_extract_facts_repo_root/.aidlc/cycles/$_local_extract_facts_cycle"

    if [[ ! -d "$_local_extract_facts_cycle_dir" ]]; then
        printf '[error] retrospective_api_extract_facts: cycle ディレクトリ不在 (%s)\n' \
            "$_local_extract_facts_cycle_dir" >&2
        return 2
    fi

    # L1 extractors を順次起動 → 中間形式行群を一時ファイルに集約
    local _local_extract_facts_intermediate
    local _local_extract_facts_prev_umask
    _local_extract_facts_prev_umask=$(umask)
    umask 077
    if ! _local_extract_facts_intermediate=$(mktemp "${TMPDIR:-/tmp}/aidlc-extract-facts.XXXXXX" 2>/dev/null); then
        umask "$_local_extract_facts_prev_umask"
        printf '[error] retrospective_api_extract_facts: mktemp 失敗\n' >&2
        return 2
    fi
    umask "$_local_extract_facts_prev_umask"

    {
        _retrospective_fact_extract_decisions "$_local_extract_facts_cycle_dir"
        _retrospective_fact_extract_review_summary "$_local_extract_facts_cycle_dir"
        _retrospective_fact_extract_history "$_local_extract_facts_cycle_dir"
        _retrospective_fact_extract_jsonl_optional "$_local_extract_facts_jsonl"
    } > "$_local_extract_facts_intermediate"

    # L2 renderer で markdown 表に整形して stdout
    _retrospective_fact_extract_render_markdown < "$_local_extract_facts_intermediate"

    rm -f "$_local_extract_facts_intermediate" 2>/dev/null || true
    return 0
}

# retrospective_api_aggregate_enabled
# v2.6.6 / #710 / Unit 001
# 集約 Issue 起票 opt-in フラグ (rules.retrospective.aggregate_issue_enabled) の値を返す。
# stdout: 常に "true" または "false" を 1 行
# exit:   常に 0 (hard fail させない / fail-safe)
# fail-safe フォールバック:
#   - read-config.sh exit 1 (キー不在 / 既定動作)            : stdout="false" / warn なし
#   - read-config.sh exit 0 + 不正値 (true|false 以外)       : stdout="false" / stderr warn
#   - read-config.sh exit 2+ (読み取り層エラー)              : stdout="false" / stderr warn
retrospective_api_aggregate_enabled() {
    local _local_aggregate_enabled_value=""
    local _local_aggregate_enabled_rc=0
    local _local_aggregate_enabled_stderr_file
    _local_aggregate_enabled_stderr_file="${TMPDIR:-/tmp}/aidlc-aggregate-enabled-stderr.$$"

    # caller の errexit 状態を変更しないよう、command substitution を if で評価し
    # exit code を直接捕捉する（set +e / set -e で caller 状態を上書きしない）
    if _local_aggregate_enabled_value=$(
        "$_RETROSPECTIVE_API_BASE/scripts/read-config.sh" rules.retrospective.aggregate_issue_enabled 2>"$_local_aggregate_enabled_stderr_file"
    ); then
        _local_aggregate_enabled_rc=0
    else
        _local_aggregate_enabled_rc=$?
    fi

    rm -f "$_local_aggregate_enabled_stderr_file" 2>/dev/null || true

    case "$_local_aggregate_enabled_rc" in
        0)
            case "$_local_aggregate_enabled_value" in
                true|false)
                    printf '%s\n' "$_local_aggregate_enabled_value"
                    return 0
                    ;;
                *)
                    printf '[warn] retrospective_api_aggregate_enabled: read-config.sh が不正値 "%s" を返したため既定 false にフォールバックします\n' \
                        "$_local_aggregate_enabled_value" >&2
                    printf 'false\n'
                    return 0
                    ;;
            esac
            ;;
        1)
            # キー不在 / defaults.toml fallback 失敗時 = 既定動作扱い
            printf 'false\n'
            return 0
            ;;
        *)
            printf '[warn] retrospective_api_aggregate_enabled: read-config.sh が rc=%s を返したため既定 false にフォールバックします\n' \
                "$_local_aggregate_enabled_rc" >&2
            printf 'false\n'
            return 0
            ;;
    esac
}

# retrospective_api_evaluate_selfreview_verdict <a_yes> <b_yes> <c_yes> <rebuttal_count>
# v2.6.6 / #704 / Unit 002
# §1.2.5 Try 構造性セルフレビュー 3 観点応答 + 差し戻し回数から最終 verdict を判定する純粋関数。
# 副作用なし / stdout 1 行 / 不正値は fail-safe で undecidable にフォールバック。
#
# 入力値正規化:
#   true|yes|該当する        -> true
#   false|no|該当しない      -> false
#   undecidable|undef|?      -> undecidable
#   それ以外                  -> warn + undecidable フォールバック
#
# 判定論理（優先順位順 / ドメインモデル §SelfReviewSessionAggregate 不変条件と一致）:
#   1. いずれかが undecidable -> undecidable
#   2. 3 観点すべて false      -> pass
#   3. rebuttal_count >= 3     -> capped
#   4. それ以外                -> rebuttal
#
# stdout: pass | rebuttal | capped | undecidable (1 行 / 末尾改行あり)
# exit:   常に 0 (hard fail させない / fail-safe)
retrospective_api_evaluate_selfreview_verdict() {
    local _local_eval_a_raw="${1:-}"
    local _local_eval_b_raw="${2:-}"
    local _local_eval_c_raw="${3:-}"
    local _local_eval_rebuttal_raw="${4:-}"

    _retrospective_api_normalize_selfreview_aspect() {
        local _local_norm_input="${1:-}"
        case "$_local_norm_input" in
            true|yes|該当する)
                printf 'true'
                ;;
            false|no|該当しない)
                printf 'false'
                ;;
            undecidable|undef|\?)
                printf 'undecidable'
                ;;
            *)
                printf '[warn] retrospective_api_evaluate_selfreview_verdict: 引数不正 ("%s")。undecidable にフォールバックします\n' \
                    "$_local_norm_input" >&2
                printf 'undecidable'
                ;;
        esac
    }

    local _local_eval_a _local_eval_b _local_eval_c
    _local_eval_a=$(_retrospective_api_normalize_selfreview_aspect "$_local_eval_a_raw")
    _local_eval_b=$(_retrospective_api_normalize_selfreview_aspect "$_local_eval_b_raw")
    _local_eval_c=$(_retrospective_api_normalize_selfreview_aspect "$_local_eval_c_raw")

    # rebuttal_count は整数として扱う（非数値は警告 + 0 にフォールバック）
    local _local_eval_rebuttal
    case "$_local_eval_rebuttal_raw" in
        ''|*[!0-9]*)
            printf '[warn] retrospective_api_evaluate_selfreview_verdict: rebuttal_count 不正 ("%s")。0 にフォールバックします\n' \
                "$_local_eval_rebuttal_raw" >&2
            _local_eval_rebuttal=0
            ;;
        *)
            _local_eval_rebuttal="$_local_eval_rebuttal_raw"
            ;;
    esac

    if [[ "$_local_eval_a" == "undecidable" \
       || "$_local_eval_b" == "undecidable" \
       || "$_local_eval_c" == "undecidable" ]]; then
        printf 'undecidable\n'
        return 0
    fi

    if [[ "$_local_eval_a" == "false" \
       && "$_local_eval_b" == "false" \
       && "$_local_eval_c" == "false" ]]; then
        printf 'pass\n'
        return 0
    fi

    if (( _local_eval_rebuttal >= 3 )); then
        printf 'capped\n'
        return 0
    fi

    printf 'rebuttal\n'
    return 0
}

# ─── 公開 API（タイプ A / 副作用あり）────────────────────────────────

# retrospective_api_record_response <cycle> <response>
# stdout: なし（タイプ A の特例 / exit code で判定）
retrospective_api_record_response() {
    retrospective_dialog_token_record_response "$@"
}

# retrospective_api_create_issue <body_path> <mode> <cycle>
# stdout: result=created|spooled|skipped + issue_url= / reason= 等の key=value 行
# exit: 0/1/2/4
retrospective_api_create_issue() {
    retrospective_issue_create "$@"
}

# retrospective_api_update_issue <issue_url> <cycle>
# stdout: なし（hook の warn は stderr）
# exit: 0（hook 失敗時も警告継続）
retrospective_api_update_issue() {
    if command -v retrospective_update_hook >/dev/null 2>&1; then
        retrospective_update_hook "$@" || true
    fi
}

# retrospective_api_ensure_label <label_name>
# v2.6.6 / #704 / Unit 002
# 指定ラベルが repository に存在することを保証する fail-safe helper。
# 不在時は gh label create を 1 回試行（リトライなし）。
# 計画書「公開契約 §1」/ 論理設計「retrospective_api_ensure_label」を SoT として実装。
#
# stdout: 空
# stderr: 失敗時のみ warn 文言
# exit:
#   0 = ラベル存在確認済 (既存 OR 自動作成成功)
#   2 = 自動作成失敗（権限不足等 / fail-fast / 呼び出し側は当該 T Issue 起票を中断）
#   3 = gh CLI 利用不能 (network 断 / PATH 不在等 / fail-fast / 同上)
#
# caller の errexit 状態を保持するため、command substitution を直接展開せず if 評価する。
retrospective_api_ensure_label() {
    local _local_ensure_label_name="${1:-}"

    if [[ -z "$_local_ensure_label_name" ]]; then
        printf '[warn] retrospective_api_ensure_label: ラベル名が指定されていません\n' >&2
        return 2
    fi

    if ! command -v gh >/dev/null 2>&1; then
        printf '[warn] retrospective_api_ensure_label: gh CLI が PATH 上に存在しません (label="%s")\n' \
            "$_local_ensure_label_name" >&2
        return 3
    fi

    local _local_ensure_label_listed=""
    local _local_ensure_label_list_rc=0
    if _local_ensure_label_listed=$(
        gh label list --search "$_local_ensure_label_name" --json name --jq '.[].name' 2>/dev/null
    ); then
        _local_ensure_label_list_rc=0
    else
        _local_ensure_label_list_rc=$?
    fi

    if (( _local_ensure_label_list_rc != 0 )); then
        printf '[warn] retrospective_api_ensure_label: gh label list 失敗 (rc=%s / label="%s") - gh 利用不能と判定します\n' \
            "$_local_ensure_label_list_rc" "$_local_ensure_label_name" >&2
        return 3
    fi

    # gh label list --search は前方一致候補も返す可能性があるため厳密一致を別途判定
    local _local_ensure_label_line
    while IFS= read -r _local_ensure_label_line; do
        if [[ "$_local_ensure_label_line" == "$_local_ensure_label_name" ]]; then
            return 0
        fi
    done <<< "$_local_ensure_label_listed"

    # 不在 -> 1 回だけ作成試行（リトライなし）
    local _local_ensure_label_create_rc=0
    if gh label create "$_local_ensure_label_name" \
        --color BFD4F2 \
        --description "Try 構造性セルフレビュー上限到達" \
        >/dev/null 2>&1; then
        _local_ensure_label_create_rc=0
    else
        _local_ensure_label_create_rc=$?
    fi

    if (( _local_ensure_label_create_rc != 0 )); then
        printf '[warn] retrospective_api_ensure_label: ラベル "%s" の自動作成に失敗しました (rc=%s / 理由: permission_denied 等)\n' \
            "$_local_ensure_label_name" "$_local_ensure_label_create_rc" >&2
        return 2
    fi

    return 0
}

# retrospective_api_record_selfreview <cycle> <try_id> <verdict> <selfreview_capped> <responses_json>
# v2.6.6 / #704 / Unit 002
# §1.2.5 セルフレビュー確定状態を history/operations.md に追記する薄いラッパ (タイプ A)。
# 計画書「公開契約 §2」のログフォーマットを 1 箇所に集約する SoT。
#
# 引数:
#   cycle             - 対象サイクル (例: v2.6.6)
#   try_id            - Try 番号
#   verdict           - pass | rebuttal | capped | undecidable
#   selfreview_capped - true | false (verdict=capped のときのみ true)
#   responses_json    - 応答配列 JSON 文字列 (差し戻し回数 + 1 件 / 各要素 {a,b,c,undecidable})
#
# 内部実装方針:
#   write-history.sh --content-file <一時ファイル> 経由で追記する。
#   コマンド置換 ($(...)) は使用せず、引数文字列に embed しない (Bash ツール経由の安全パターン遵守)。
#
# stdout: 空
# stderr: write-history.sh の出力を中継
# exit:   write-history.sh の戻り値を中継 (0 成功 / 1 引数不正 / 2 I/O 失敗 / 3 ガード拒否)
retrospective_api_record_selfreview() {
    local _local_record_cycle="${1:-}"
    local _local_record_try_id="${2:-}"
    local _local_record_verdict="${3:-}"
    local _local_record_capped="${4:-}"
    local _local_record_responses_json="${5:-}"

    if [[ -z "$_local_record_cycle" || -z "$_local_record_try_id" || -z "$_local_record_verdict" || -z "$_local_record_capped" ]]; then
        printf '[warn] retrospective_api_record_selfreview: 必須引数 (cycle / try_id / verdict / selfreview_capped) が不足しています\n' >&2
        return 1
    fi

    # 公開契約のホワイトリスト検証 (指摘 #2 反映 / v2.6.6 Unit 002 code review Round 1)
    case "$_local_record_verdict" in
        pass|rebuttal|capped|undecidable) ;;
        *)
            printf '[warn] retrospective_api_record_selfreview: verdict 不正 ("%s"). 期待値: pass|rebuttal|capped|undecidable\n' \
                "$_local_record_verdict" >&2
            return 1
            ;;
    esac
    case "$_local_record_capped" in
        true|false) ;;
        *)
            printf '[warn] retrospective_api_record_selfreview: selfreview_capped 不正 ("%s"). 期待値: true|false\n' \
                "$_local_record_capped" >&2
            return 1
            ;;
    esac

    # 公開契約 §3 の相関検証 (指摘 Round 2 #1 反映 / v2.6.6 Unit 002 code review)
    # verdict=capped のときのみ selfreview_capped=true、それ以外は false が不変条件。
    if [[ "$_local_record_verdict" == "capped" && "$_local_record_capped" != "true" ]]; then
        printf '[warn] retrospective_api_record_selfreview: 相関不整合 (verdict=capped かつ selfreview_capped=%s). 期待値: true\n' \
            "$_local_record_capped" >&2
        return 1
    fi
    if [[ "$_local_record_verdict" != "capped" && "$_local_record_capped" == "true" ]]; then
        printf '[warn] retrospective_api_record_selfreview: 相関不整合 (verdict=%s かつ selfreview_capped=true). 期待値: false\n' \
            "$_local_record_verdict" >&2
        return 1
    fi

    local _local_record_aspect_a="-"
    local _local_record_aspect_b="-"
    local _local_record_aspect_c="-"
    local _local_record_rebuttal_count="-"

    # responses_json の末尾要素から最終応答の 3 観点 + 全件数 - 1 を差し戻し回数として復元
    # JSON 解析は jq があれば利用、なければ簡易フォールバック
    if [[ -n "$_local_record_responses_json" ]] && command -v jq >/dev/null 2>&1; then
        local _local_record_last_index
        if _local_record_last_index=$(printf '%s' "$_local_record_responses_json" | jq -r 'length - 1' 2>/dev/null); then
            if [[ "$_local_record_last_index" =~ ^[0-9]+$ ]]; then
                _local_record_rebuttal_count="$_local_record_last_index"
                local _local_record_jq_filter=".[${_local_record_last_index}]"
                local _local_record_last
                if _local_record_last=$(printf '%s' "$_local_record_responses_json" | jq -r "$_local_record_jq_filter" 2>/dev/null); then
                    if [[ -n "$_local_record_last" && "$_local_record_last" != "null" ]]; then
                        # jq の `// "-"` は false / null / 0 / "" を falsy として default 適用してしまうため、
                        # false を維持するには明示的に has() + tostring で扱う必要がある (bats REC9 検出 / v2.6.6 Unit 002 ステップ6)
                        local _local_record_aspect_a_val _local_record_aspect_b_val _local_record_aspect_c_val
                        _local_record_aspect_a_val=$(printf '%s' "$_local_record_last" | jq -r 'if has("a") and (.a != null) then (.a | tostring) else "-" end' 2>/dev/null)
                        _local_record_aspect_b_val=$(printf '%s' "$_local_record_last" | jq -r 'if has("b") and (.b != null) then (.b | tostring) else "-" end' 2>/dev/null)
                        _local_record_aspect_c_val=$(printf '%s' "$_local_record_last" | jq -r 'if has("c") and (.c != null) then (.c | tostring) else "-" end' 2>/dev/null)
                        case "$_local_record_aspect_a_val" in true) _local_record_aspect_a="yes" ;; false) _local_record_aspect_a="no" ;; *) _local_record_aspect_a="$_local_record_aspect_a_val" ;; esac
                        case "$_local_record_aspect_b_val" in true) _local_record_aspect_b="yes" ;; false) _local_record_aspect_b="no" ;; *) _local_record_aspect_b="$_local_record_aspect_b_val" ;; esac
                        case "$_local_record_aspect_c_val" in true) _local_record_aspect_c="yes" ;; false) _local_record_aspect_c="no" ;; *) _local_record_aspect_c="$_local_record_aspect_c_val" ;; esac
                    fi
                fi
            fi
        fi
    fi

    # 一時ファイルは mktemp + umask 077 で予測不能化 (指摘 #1 反映 / v2.6.6 Unit 002 code review Round 1)
    # シンボリックリンク悪用攻撃 (TOCTOU) を防止する。
    local _local_record_tmpfile
    local _local_record_prev_umask
    _local_record_prev_umask=$(umask)
    umask 077
    if ! _local_record_tmpfile=$(mktemp "${TMPDIR:-/tmp}/aidlc-retro-selfreview-record.XXXXXX" 2>/dev/null); then
        umask "$_local_record_prev_umask"
        printf '[warn] retrospective_api_record_selfreview: mktemp 失敗（一時ファイル作成不能）\n' >&2
        return 2
    fi
    umask "$_local_record_prev_umask"

    {
        printf -- '- イベント: AIDLC retrospective セルフレビュー実行\n'
        printf -- '- サイクル: %s\n' "$_local_record_cycle"
        printf -- '- Try ID: try-%s\n' "$_local_record_try_id"
        printf -- '- 観点 A 応答: %s\n' "$_local_record_aspect_a"
        printf -- '- 観点 B 応答: %s\n' "$_local_record_aspect_b"
        printf -- '- 観点 C 応答: %s\n' "$_local_record_aspect_c"
        printf -- '- 差し戻し回数: %s\n' "$_local_record_rebuttal_count"
        printf -- '- 確定 verdict: %s\n' "$_local_record_verdict"
        printf -- '- selfreview_capped: %s\n' "$_local_record_capped"
        printf -- '- 構造課題昇格根拠: -\n'
    } > "$_local_record_tmpfile"

    local _local_record_write_history="$_RETROSPECTIVE_API_BASE/scripts/write-history.sh"
    local _local_record_rc=0
    if [[ ! -x "$_local_record_write_history" ]]; then
        printf '[warn] retrospective_api_record_selfreview: write-history.sh が見つかりません (%s)\n' \
            "$_local_record_write_history" >&2
        rm -f "$_local_record_tmpfile" 2>/dev/null || true
        return 2
    fi

    if bash "$_local_record_write_history" \
        --cycle "$_local_record_cycle" \
        --phase operations \
        --step "Retrospective Try セルフレビュー (try-${_local_record_try_id})" \
        --content-file "$_local_record_tmpfile" >&2; then
        _local_record_rc=0
    else
        _local_record_rc=$?
    fi

    rm -f "$_local_record_tmpfile" 2>/dev/null || true
    return "$_local_record_rc"
}
