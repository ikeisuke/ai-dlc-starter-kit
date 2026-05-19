#!/bin/bash
# retrospective-fact-extract.sh
#
# AI-DLC retrospective skill §1.1.5 事実テーブル先抽出ステップ向け
# private 実装層（Facade `retrospective-api.sh` から source される）。
#
# 公開 API: なし（全関数 `_retrospective_fact_extract_*` プレフィックスで internal 専用）。
#          公開シンボルは Facade 側の `retrospective_api_extract_facts` のみ。
#
# v2.6.6 / #652 / Unit 003
# 設計参照:
#   .aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_003_fact_extract_helper_domain_model.md
#   .aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_003_fact_extract_helper_logical_design.md
#
# 役割 3 層分離:
#   L1 extractors: _retrospective_fact_extract_decisions / _review_summary / _history / _jsonl_optional
#   L2 renderer:   _retrospective_fact_extract_render_markdown
#   L3 orchestrator: Facade 側 `retrospective_api_extract_facts`（本ファイル外）
#
# 中間形式契約（L1 → L2 stdin）:
#   {kind}|{item_id}|{value}|{source_path}
#   - kind:        decisions / review_summary / history / jsonl
#   - item_id:     安定 ID (snake_case)
#   - value:       文字列。改行禁止 / パイプは `\|` でエスケープ
#   - source_path: repo-relative (cycle 起点)
#
# 機密フィルタ:
#   ERE 採用 (`grep -E` / bash `=~` ERE 準拠)。4 パターン (api_key / bearer_token /
#   secret_kv / conn_string) を _retrospective_fact_extract_mask_secrets で適用。

# 多重 source ガード
if [[ -n "${RETROSPECTIVE_FACT_EXTRACT_SOURCED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
RETROSPECTIVE_FACT_EXTRACT_SOURCED=1

# ─── L1 共通: 機密フィルタ ────────────────────────────────────────────

# _retrospective_fact_extract_mask_secrets
# stdin: 任意 text
# stdout: 機密パターンをマスクした text
# 設計参照: 論理設計「機密フィルタ」セクション（ERE 4 パターン）
_retrospective_fact_extract_mask_secrets() {
    # 各 sed -E は ERE 準拠。BSD/GNU sed 両方で動作する記法に限定。
    # マスク後表現は設計章のテーブル準拠。
    # 値文字クラスは Base64 系（+/=）/ URL safe Base64（_-）/ パディングを許容。
    # コード review Round 1 指摘 #1 (security 高) 反映: `+` `/` `=` を含む実トークンの取りこぼし防止。
    LC_ALL=C sed -E \
        -e 's/((api[_-]?[Kk]ey|API[_-]?KEY|[Aa]pikey|APIKEY))["'"'"':= ]+[A-Za-z0-9._~+/=-]{16,}/\1=****/g' \
        -e 's/([Bb]earer)[ \t]+[A-Za-z0-9._~+/=-]{16,}/\1 ****/g' \
        -e 's/((secret|password|token|SECRET|PASSWORD|TOKEN|Secret|Password|Token))["'"'"':= ]+[A-Za-z0-9._~+/=-]{8,}/\1=****/g' \
        -e 's|(://)[^:@/ ]+:[^@/ ]+@|\1****@|g'
}

# ─── L1 extractors ───────────────────────────────────────────────────

# _retrospective_fact_extract_decisions <cycle_dir>
# stdout: pipe-separated FactRow 行群
#   decisions|dr_count|<N>|inception/decisions.md
#   decisions|dr_titles|<title1>; <title2>; ...|inception/decisions.md  (内部集計 / §1.1.5 互換モード非表示)
#   decisions|dr_root_cause_class|product=<n>;starter=<n>;both=<n>|inception/decisions.md  (内部集計)
# fail-safe: ファイル不在時 → warn (stderr) + value="-（source 不在）" 行を出力
_retrospective_fact_extract_decisions() {
    local _local_fed_cycle_dir="${1:-}"
    local _local_fed_source_rel="inception/decisions.md"
    local _local_fed_source_abs="${_local_fed_cycle_dir%/}/${_local_fed_source_rel}"

    if [[ ! -f "$_local_fed_source_abs" ]]; then
        printf '[warn] _retrospective_fact_extract_decisions: source 不在 (%s)\n' \
            "$_local_fed_source_abs" >&2
        printf 'decisions|dr_count|-（source 不在）|%s\n' "$_local_fed_source_rel"
        return 0
    fi

    # DR 件数: `^## DR-NNN` 形式の見出しをカウント (ERE)
    local _local_fed_dr_count
    _local_fed_dr_count=$(LC_ALL=C grep -cE '^## DR-[0-9]+' "$_local_fed_source_abs" 2>/dev/null || true)
    # grep -c の出力が空のときは 0 にフォールバック
    [[ -z "$_local_fed_dr_count" ]] && _local_fed_dr_count=0

    printf 'decisions|dr_count|%s|%s\n' "$_local_fed_dr_count" "$_local_fed_source_rel"

    # DR タイトル（内部集計のみ / §1.1.5 互換モード非表示）
    local _local_fed_dr_titles
    _local_fed_dr_titles=$(LC_ALL=C grep -E '^## DR-[0-9]+' "$_local_fed_source_abs" 2>/dev/null \
        | LC_ALL=C sed -E 's/^## (DR-[0-9]+:[ ]*)?//' \
        | LC_ALL=C awk 'BEGIN{ORS="; "} {gsub(/\|/, "\\|"); print}' \
        | LC_ALL=C sed -E 's/; $//')
    [[ -z "$_local_fed_dr_titles" ]] && _local_fed_dr_titles="-"
    printf 'decisions|dr_titles|%s|%s\n' "$_local_fed_dr_titles" "$_local_fed_source_rel"

    # 主因 3 分類カウント（内部集計のみ）
    # 主因記述パターン: 「主因切り分け」or「主因」セクション配下に "プロダクト固有" / "AI-DLC Starter Kit 固有" / "両方" を含むかで分類
    local _local_fed_product_count _local_fed_starter_count _local_fed_both_count
    _local_fed_product_count=$(LC_ALL=C grep -cE 'プロダクト固有|product[_-]?specific' "$_local_fed_source_abs" 2>/dev/null || true)
    _local_fed_starter_count=$(LC_ALL=C grep -cE 'AI-DLC[ ]?Starter[ ]?Kit[ ]?固有|starter[_-]?specific' "$_local_fed_source_abs" 2>/dev/null || true)
    _local_fed_both_count=$(LC_ALL=C grep -cE '両方に責任|both[_-]?sides' "$_local_fed_source_abs" 2>/dev/null || true)
    [[ -z "$_local_fed_product_count" ]] && _local_fed_product_count=0
    [[ -z "$_local_fed_starter_count" ]] && _local_fed_starter_count=0
    [[ -z "$_local_fed_both_count" ]] && _local_fed_both_count=0

    printf 'decisions|dr_root_cause_class|product=%s;starter=%s;both=%s|%s\n' \
        "$_local_fed_product_count" "$_local_fed_starter_count" "$_local_fed_both_count" "$_local_fed_source_rel"
}

# _retrospective_fact_extract_review_summary <cycle_dir>
# stdout:
#   review_summary|review_round_total|<N>|construction/units/*-review-summary.md
#   review_summary|review_finding_total|<N>|construction/units/*-review-summary.md
#   review_summary|defer_count|<N>|construction/units/*-review-summary.md
# fail-safe: ファイル不在時 → warn + value="-（source 不在）" 行を出力
_retrospective_fact_extract_review_summary() {
    local _local_fer_cycle_dir="${1:-}"
    local _local_fer_source_rel="construction/units/*-review-summary.md"
    local _local_fer_source_dir="${_local_fer_cycle_dir%/}/construction/units"

    if [[ ! -d "$_local_fer_source_dir" ]]; then
        printf '[warn] _retrospective_fact_extract_review_summary: source ディレクトリ不在 (%s)\n' \
            "$_local_fer_source_dir" >&2
        printf 'review_summary|review_round_total|-（source 不在）|%s\n' "$_local_fer_source_rel"
        printf 'review_summary|review_finding_total|-（source 不在）|%s\n' "$_local_fer_source_rel"
        printf 'review_summary|defer_count|-（source 不在）|%s\n' "$_local_fer_source_rel"
        return 0
    fi

    # glob 展開 (nullglob 相当)
    local _local_fer_files=()
    local _local_fer_file
    for _local_fer_file in "$_local_fer_source_dir"/*-review-summary.md; do
        [[ -f "$_local_fer_file" ]] && _local_fer_files+=("$_local_fer_file")
    done

    if (( ${#_local_fer_files[@]} == 0 )); then
        printf '[warn] _retrospective_fact_extract_review_summary: review-summary ファイル 0 件 (%s)\n' \
            "$_local_fer_source_dir" >&2
        printf 'review_summary|review_round_total|-（source 不在）|%s\n' "$_local_fer_source_rel"
        printf 'review_summary|review_finding_total|-（source 不在）|%s\n' "$_local_fer_source_rel"
        printf 'review_summary|defer_count|-（source 不在）|%s\n' "$_local_fer_source_rel"
        return 0
    fi

    # review round 数合計: `**反復回数**: N` 行から N を抽出して数値合計（複数 Set 対応）
    # フォールバック: 「**反復回数**」記載がなければ「## Set」「## Round」見出し数を 1 round としてカウント
    local _local_fer_round_total=0
    local _local_fer_finding_total=0
    local _local_fer_defer_total=0
    for _local_fer_file in "${_local_fer_files[@]}"; do
        local _local_fer_rounds_sum=0
        local _local_fer_rounds_line
        # 反復回数行から N を抜き出して合計
        while IFS= read -r _local_fer_rounds_line; do
            [[ -z "$_local_fer_rounds_line" ]] && continue
            # 数値部分を抜き出し（先頭の数字シーケンス）
            local _local_fer_rounds_num
            _local_fer_rounds_num=$(printf '%s' "$_local_fer_rounds_line" | LC_ALL=C sed -nE 's/.*\*\*反復回数\*\*:[ ]*([0-9]+).*/\1/p')
            if [[ "$_local_fer_rounds_num" =~ ^[0-9]+$ ]]; then
                _local_fer_rounds_sum=$(( _local_fer_rounds_sum + _local_fer_rounds_num ))
            fi
        done < <(LC_ALL=C grep -E '\*\*反復回数\*\*:' "$_local_fer_file" 2>/dev/null)

        if (( _local_fer_rounds_sum == 0 )); then
            # フォールバック: Set / Round 見出し数を 1 round としてカウント
            local _local_fer_rounds_fallback
            _local_fer_rounds_fallback=$(LC_ALL=C grep -cE '^## Round[ ]|^## Set[ ]' "$_local_fer_file" 2>/dev/null || true)
            [[ -z "$_local_fer_rounds_fallback" ]] && _local_fer_rounds_fallback=0
            _local_fer_rounds_sum=$_local_fer_rounds_fallback
        fi

        _local_fer_round_total=$(( _local_fer_round_total + _local_fer_rounds_sum ))

        # 指摘件数: 「### 指摘一覧」テーブル下の `^\| [0-9]+ \|` で始まる行をカウント (ERE)
        local _local_fer_findings
        _local_fer_findings=$(LC_ALL=C grep -cE '^\|[ ]+[0-9]+[ ]+\|' "$_local_fer_file" 2>/dev/null || true)
        [[ -z "$_local_fer_findings" ]] && _local_fer_findings=0
        _local_fer_finding_total=$(( _local_fer_finding_total + _local_fer_findings ))

        # defer 件数: 「OUT_OF_SCOPE」または「TECHNICAL_BLOCKER」を含む行をカウント
        local _local_fer_defers
        _local_fer_defers=$(LC_ALL=C grep -cE 'OUT_OF_SCOPE|TECHNICAL_BLOCKER' "$_local_fer_file" 2>/dev/null || true)
        [[ -z "$_local_fer_defers" ]] && _local_fer_defers=0
        _local_fer_defer_total=$(( _local_fer_defer_total + _local_fer_defers ))
    done

    printf 'review_summary|review_round_total|%s|%s\n' "$_local_fer_round_total" "$_local_fer_source_rel"
    printf 'review_summary|review_finding_total|%s|%s\n' "$_local_fer_finding_total" "$_local_fer_source_rel"
    printf 'review_summary|defer_count|%s|%s\n' "$_local_fer_defer_total" "$_local_fer_source_rel"
}

# _retrospective_fact_extract_history <cycle_dir> [<max_events>]
# stdout:
#   history|history_event|<timestamp> - <summary>; ...|history/*.md
# 既定 max_events=5
# fail-safe: ディレクトリ不在時 → warn + "-（source 不在）" 行
_retrospective_fact_extract_history() {
    local _local_feh_cycle_dir="${1:-}"
    local _local_feh_max="${2:-5}"
    local _local_feh_source_rel="history/*.md"
    local _local_feh_source_dir="${_local_feh_cycle_dir%/}/history"

    if [[ ! -d "$_local_feh_source_dir" ]]; then
        printf '[warn] _retrospective_fact_extract_history: source ディレクトリ不在 (%s)\n' \
            "$_local_feh_source_dir" >&2
        printf 'history|history_event|-（source 不在）|%s\n' "$_local_feh_source_rel"
        return 0
    fi

    local _local_feh_files=()
    local _local_feh_file
    for _local_feh_file in "$_local_feh_source_dir"/*.md; do
        [[ -f "$_local_feh_file" ]] && _local_feh_files+=("$_local_feh_file")
    done

    if (( ${#_local_feh_files[@]} == 0 )); then
        printf '[warn] _retrospective_fact_extract_history: history ファイル 0 件 (%s)\n' \
            "$_local_feh_source_dir" >&2
        printf 'history|history_event|-（source 不在）|%s\n' "$_local_feh_source_rel"
        return 0
    fi

    # H2 見出し（タイムスタンプ）+ 直後の「- **ステップ**: ...」を 1 イベントとして抽出
    # 簡略化: H2 見出しから ISO 風タイムスタンプを抽出、次の「ステップ」or「実行内容」を summary とする
    local _local_feh_events=()
    for _local_feh_file in "${_local_feh_files[@]}"; do
        # awk で「## 」行から始まる timestamp を取得、次の `- **ステップ**:` または `- **実行内容**:` から summary 抽出
        local _local_feh_extracted
        _local_feh_extracted=$(LC_ALL=C awk '
            /^## [0-9]{4}-[0-9]{2}-[0-9]{2}/ {
                ts = $0
                sub(/^## /, "", ts)
                next_step = ""
                summary_captured = 0
                next
            }
            /^- \*\*ステップ\*\*:/ && ts != "" && summary_captured == 0 {
                step = $0
                sub(/^- \*\*ステップ\*\*:[ ]*/, "", step)
                next_step = step
                summary_captured = 1
                print ts " - " next_step
                ts = ""
            }
        ' "$_local_feh_file" 2>/dev/null)
        if [[ -n "$_local_feh_extracted" ]]; then
            while IFS= read -r _local_feh_line; do
                [[ -n "$_local_feh_line" ]] && _local_feh_events+=("$_local_feh_line")
            done <<< "$_local_feh_extracted"
        fi
    done

    if (( ${#_local_feh_events[@]} == 0 )); then
        printf 'history|history_event|-（イベント抽出なし）|%s\n' "$_local_feh_source_rel"
        return 0
    fi

    # タイムスタンプ昇順ソート + max_events 件で打切り
    local _local_feh_sorted_file
    local _local_feh_prev_umask
    _local_feh_prev_umask=$(umask)
    umask 077
    if ! _local_feh_sorted_file=$(mktemp "${TMPDIR:-/tmp}/aidlc-fed-history.XXXXXX" 2>/dev/null); then
        umask "$_local_feh_prev_umask"
        printf '[warn] _retrospective_fact_extract_history: mktemp 失敗\n' >&2
        printf 'history|history_event|-（抽出失敗）|%s\n' "$_local_feh_source_rel"
        return 0
    fi
    umask "$_local_feh_prev_umask"

    printf '%s\n' "${_local_feh_events[@]}" | LC_ALL=C sort > "$_local_feh_sorted_file"

    local _local_feh_joined=""
    local _local_feh_count=0
    while IFS= read -r _local_feh_line; do
        (( _local_feh_count >= _local_feh_max )) && break
        # パイプエスケープ
        _local_feh_line="${_local_feh_line//|/\\|}"
        if [[ -z "$_local_feh_joined" ]]; then
            _local_feh_joined="$_local_feh_line"
        else
            _local_feh_joined="${_local_feh_joined}; ${_local_feh_line}"
        fi
        _local_feh_count=$(( _local_feh_count + 1 ))
    done < "$_local_feh_sorted_file"

    rm -f "$_local_feh_sorted_file" 2>/dev/null || true

    printf 'history|history_event|%s|%s\n' "$_local_feh_joined" "$_local_feh_source_rel"
}

# _retrospective_fact_extract_jsonl_optional <jsonl_path>
# stdout: jsonl|jsonl_event|<timestamp> - <summary>; ...|<jsonl_path>
# 引数空時: 何も出力しない（既定動作 = jsonl 行を表に追加しない）
# fail-safe: 引数指定 + ファイル不在時 → warn + 出力なし
_retrospective_fact_extract_jsonl_optional() {
    local _local_fej_jsonl_path="${1:-}"

    if [[ -z "$_local_fej_jsonl_path" ]]; then
        # 引数なし: 既定動作（出力なし）
        return 0
    fi

    # コード review Round 1 指摘 #2 (security 中) 反映:
    # path 引数の妥当性検証を強化。`-f` のみではなく以下を必須化:
    #   - 拡張子 `.jsonl` のみ許可（任意ファイル読込経路の遮断）
    #   - 改行 / NULL byte / 制御文字を含むパスを拒否
    # 注: cycle 配下限定はスコープ外（典型パスは ~/.claude/projects/<repo>/ で cycle 外）。
    if [[ "$_local_fej_jsonl_path" != *.jsonl ]]; then
        printf '[warn] _retrospective_fact_extract_jsonl_optional: 拒否 - 拡張子が .jsonl ではない (%s)\n' \
            "$_local_fej_jsonl_path" >&2
        return 0
    fi
    # NULL byte は bash 変数に格納不可のため判定省略。改行 / 制御文字（タブを除く）のみ判定。
    # 制御文字（0x00-0x08, 0x0A-0x1F, 0x7F）を含むパスを拒否（タブは含まれる事があるため除外）。
    if [[ "$_local_fej_jsonl_path" =~ [$'\x01'-$'\x08'$'\x0a'-$'\x1f'$'\x7f'] ]]; then
        printf '[warn] _retrospective_fact_extract_jsonl_optional: 拒否 - パスに制御文字を含む\n' >&2
        return 0
    fi
    # path traversal 防止: `..` セグメントを含むパスを拒否（先頭・中間・末尾いずれも対象）。
    # コード review Round 2 指摘 #1 (security 中) 反映: 任意絶対パス + .jsonl で想定外ロケーションを
    # 読まれる経路を遮断する最低限の防御。caller には canonical な絶対パスでの指定を強制する。
    if [[ "$_local_fej_jsonl_path" == *..* ]]; then
        case "$_local_fej_jsonl_path" in
            *../* | */..* | "..")
                printf '[warn] _retrospective_fact_extract_jsonl_optional: 拒否 - パスに .. セグメントを含む (%s)\n' \
                    "$_local_fej_jsonl_path" >&2
                return 0
                ;;
        esac
    fi

    if [[ ! -f "$_local_fej_jsonl_path" ]]; then
        printf '[warn] _retrospective_fact_extract_jsonl_optional: jsonl ファイル不在 (%s)\n' \
            "$_local_fej_jsonl_path" >&2
        return 0
    fi

    # jsonl 解析: jq が利用可能なら type=event を抽出。なければ簡易フォールバック
    local _local_fej_events=()
    if command -v jq >/dev/null 2>&1; then
        local _local_fej_raw
        _local_fej_raw=$(LC_ALL=C jq -r '
            select(.type == "event" or .event != null) |
            (.timestamp // .ts // "unknown") + " - " + (.summary // .event // .message // "(no summary)")
        ' "$_local_fej_jsonl_path" 2>/dev/null)
        if [[ -n "$_local_fej_raw" ]]; then
            while IFS= read -r _local_fej_line; do
                [[ -n "$_local_fej_line" ]] && _local_fej_events+=("$_local_fej_line")
            done <<< "$_local_fej_raw"
        fi
    else
        # フォールバック: timestamp と summary を grep ベースで抽出
        printf '[warn] _retrospective_fact_extract_jsonl_optional: jq 不在のため簡易抽出のみ\n' >&2
        local _local_fej_line_raw
        while IFS= read -r _local_fej_line_raw; do
            [[ -n "$_local_fej_line_raw" ]] && _local_fej_events+=("$(printf '%s' "$_local_fej_line_raw" | LC_ALL=C head -c 120)")
        done < "$_local_fej_jsonl_path"
    fi

    if (( ${#_local_fej_events[@]} == 0 )); then
        return 0
    fi

    # 機密フィルタ適用 + 結合（最大 5 件まで）
    local _local_fej_joined=""
    local _local_fej_count=0
    local _local_fej_max=5
    local _local_fej_evt
    for _local_fej_evt in "${_local_fej_events[@]}"; do
        (( _local_fej_count >= _local_fej_max )) && break
        local _local_fej_masked
        _local_fej_masked=$(printf '%s' "$_local_fej_evt" | _retrospective_fact_extract_mask_secrets)
        _local_fej_masked="${_local_fej_masked//|/\\|}"
        if [[ -z "$_local_fej_joined" ]]; then
            _local_fej_joined="$_local_fej_masked"
        else
            _local_fej_joined="${_local_fej_joined}; ${_local_fej_masked}"
        fi
        _local_fej_count=$(( _local_fej_count + 1 ))
    done

    # source_path: jsonl は引数のパスをそのまま記録（cycle-relative にはしない）
    # コード review Round 1 指摘 #3 (code 低) 反映: source_path 内のパイプを表構造保護のためエスケープ
    local _local_fej_safe_path="${_local_fej_jsonl_path//|/\\|}"
    printf 'jsonl|jsonl_event|%s|%s\n' "$_local_fej_joined" "$_local_fej_safe_path"
}

# ─── L2 renderer ──────────────────────────────────────────────────────

# _retrospective_fact_extract_render_markdown
# stdin: pipe-separated FactRow 行群 ({kind}|{item_id}|{value}|{source_path})
# stdout: §1.1.5 互換 markdown 表
# 採択フィルタ: dr_titles / dr_root_cause_class は内部集計のため出力しない
# item_id → 表示ラベル変換は本関数が独占（L1 は item_id のみ知る）
_retrospective_fact_extract_render_markdown() {
    # 採択する item_id とその §1.1.5 表示ラベル / 既定行順
    # 並列配列で順序を固定する
    local -a _local_fer_render_order=(
        "dr_count"
        "review_round_total"
        "review_finding_total"
        "defer_count"
        "history_event"
        "jsonl_event"
    )
    local -A _local_fer_render_label=(
        ["dr_count"]="DR 件数"
        ["review_round_total"]="review round 数（合計）"
        ["review_finding_total"]="指摘件数（合計）"
        ["defer_count"]="defer 件数"
        ["history_event"]="時系列イベント（主要なもの）"
        ["jsonl_event"]="時系列イベント（jsonl）"
    )

    # stdin から FactRow を読み込み、item_id をキーに value / source_path を格納
    local -A _local_fer_render_value=()
    local -A _local_fer_render_source=()
    local _local_fer_render_line
    local _local_fer_render_kind _local_fer_render_item _local_fer_render_val _local_fer_render_src
    while IFS='|' read -r _local_fer_render_kind _local_fer_render_item _local_fer_render_val _local_fer_render_src; do
        [[ -z "$_local_fer_render_item" ]] && continue
        # 同一 item_id が複数行ある場合は最後の行を採用（history のように 1 行集約済 / 通常は 1 件）
        _local_fer_render_value["$_local_fer_render_item"]="$_local_fer_render_val"
        _local_fer_render_source["$_local_fer_render_item"]="$_local_fer_render_src"
    done

    # ヘッダ + 区切り行（§1.1.5 互換）
    printf '| 項目 | 値 | 出典 |\n'
    printf '|------|-----|------|\n'

    # 採択リスト順にデータ行を出力
    local _local_fer_render_id
    for _local_fer_render_id in "${_local_fer_render_order[@]}"; do
        # jsonl_event は値が存在する場合のみ出力（opt-in）
        if [[ "$_local_fer_render_id" == "jsonl_event" ]]; then
            [[ -z "${_local_fer_render_value[$_local_fer_render_id]+x}" ]] && continue
        fi
        local _local_fer_render_label_str="${_local_fer_render_label[$_local_fer_render_id]}"
        local _local_fer_render_val_str="${_local_fer_render_value[$_local_fer_render_id]:--}"
        local _local_fer_render_src_str="${_local_fer_render_source[$_local_fer_render_id]:--}"
        # エスケープ復元: 中間形式で `\|` だった箇所を表示時は半角空白に置換（表セル内 | 不可）
        # コード review Round 1 指摘 #3 反映: value だけでなく source_path にも同じ復元処理を適用（同形のエスケープ規約）
        _local_fer_render_val_str="${_local_fer_render_val_str//\\|/ }"
        _local_fer_render_src_str="${_local_fer_render_src_str//\\|/ }"
        printf '| %s | %s | %s |\n' \
            "$_local_fer_render_label_str" "$_local_fer_render_val_str" "$_local_fer_render_src_str"
    done
}
