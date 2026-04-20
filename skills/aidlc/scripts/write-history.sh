#!/usr/bin/env bash
#
# write-history.sh - 履歴ファイルへの追記を標準化されたフォーマットで行う
#
# 使用方法:
#   ./write-history.sh [OPTIONS]
#
# OPTIONS:
#   --cycle <VERSION>       サイクルバージョン（必須、例: v1.8.0）
#   --phase <PHASE>         フェーズ名（必須、inception/construction/operations）
#   --unit <NUMBER>         Unit番号（constructionフェーズの場合必須、例: 6）
#   --unit-name <NAME>      Unit名（constructionフェーズの場合必須）
#   --unit-slug <SLUG>      Unitスラッグ（constructionフェーズの場合必須）
#   --step <STEP>           ステップ名（必須）
#   --content <CONTENT>     実行内容（必須、--content-fileと排他）
#   --content-file <PATH>   実行内容をファイルから読み込み（--contentと排他）
#   --artifacts <PATHS>     成果物パス（オプション、複数回指定可能）
#   --operations-stage <S>  Operations Phase のステージ（pre-merge|post-merge、省略可）
#                           post-merge は即拒否（exit 3、Unit 002 / DR-001）
#                           未定義値は引数不正（exit 1）
#   -h, --help              ヘルプを表示
#   --dry-run               ファイル追記せず、状態のみ表示
#
# 出力形式（stdout）:
#   history:<ファイルパス>:<状態>
#   - created: 新規ファイル作成＋追記成功
#   - appended: 既存ファイルへの追記成功
#   - would-create: 新規作成予定（--dry-runモード）
#   - would-append: 追記予定（--dry-runモード）
#   - error: 処理失敗
#
# エラー出力形式:
#   error:<code>:<message>
#
# 終了コード:
#   0 = 成功
#   1 = 引数不正（未指定値・不正値・排他違反 等）
#   2 = I/O 失敗（ファイル作成失敗 等）
#   3 = Operations Phase post-merge ガード拒否（Unit 002 / DR-001）
#       post-merge 判定は以下の順で評価される:
#         (a) 第一条件: --phase operations --operations-stage post-merge
#         (b) 第二条件: --phase operations AND completion_gate_ready=true
#                      AND gh pr view で state=MERGED AND mergedAt!=null
#                      AND number 一致
#       拒否時は機械可読メッセージ
#         error:post-merge-history-write-forbidden:<reason_code>:<diagnostics>
#       を stdout と stderr の両方に重複出力する（Unit 定義 / Story 1.2 準拠）
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"
source "${SCRIPT_DIR}/lib/validate.sh"

# グローバル変数
CYCLE=""
PHASE=""
UNIT=""
UNIT_NAME=""
UNIT_SLUG=""
STEP=""
CONTENT=""
CONTENT_FILE=""
ARTIFACTS=()
DRY_RUN=false
OPERATIONS_STAGE=""

# ガード判定用のグローバル（main が事前取得、evaluate_post_merge_guard が参照）
GUARD_COMPLETION_GATE_READY=""
GUARD_PR_NUMBER_FROM_PROGRESS=""
GUARD_PR_STATE=""
GUARD_PR_MERGED_AT=""
GUARD_PR_NUMBER=""
GUARD_PR_IS_DRAFT=""
GUARD_PR_QUERY_DONE=false

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: write-history.sh [OPTIONS]

履歴ファイルへの追記を標準化されたフォーマットで行います。

OPTIONS:
  --cycle <VERSION>       サイクルバージョン（必須、例: v1.8.0）
  --phase <PHASE>         フェーズ名（必須、inception/construction/operations）
  --unit <NUMBER>         Unit番号（constructionフェーズの場合必須、例: 6）
  --unit-name <NAME>      Unit名（constructionフェーズの場合必須）
  --unit-slug <SLUG>      Unitスラッグ（constructionフェーズの場合必須）
  --step <STEP>           ステップ名（必須）
  --content <CONTENT>     実行内容（必須、--content-fileと排他）
  --content-file <PATH>   実行内容をファイルから読み込み（--contentと排他）
  --artifacts <PATHS>     成果物パス（オプション、複数回指定可能）
  --operations-stage <S>  Operations Phase のステージ（pre-merge|post-merge、省略可）
                          post-merge は即拒否（exit 3）
                          未定義値は引数不正（exit 1）
  -h, --help              このヘルプを表示
  --dry-run               ファイル追記せず、状態のみ表示

出力形式（stdout）:
  history:<ファイルパス>:<状態>

状態:
  created       - 新規ファイル作成＋追記成功
  appended      - 既存ファイルへの追記成功
  would-create  - 新規作成予定（--dry-runモード）
  would-append  - 追記予定（--dry-runモード）
  error         - 処理失敗

終了コード:
  0 = 成功
  1 = 引数不正
  2 = I/O 失敗
  3 = Operations Phase post-merge ガード拒否（Unit 002 / DR-001）

例:
  $ write-history.sh \
      --cycle v1.8.0 \
      --phase construction \
      --unit 6 \
      --unit-slug write-history \
      --unit-name "履歴記録スクリプト" \
      --step "Unit完了" \
      --content "履歴記録スクリプトの設計・実装を完了" \
      --artifacts "prompts/package/bin/write-history.sh"
  history:.aidlc/cycles/v1.8.0/history/construction_unit06.md:appended
EOF
}


# フェーズを検証
validate_phase() {
    local phase="$1"
    case "$phase" in
        inception|construction|operations)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Operations Stage を検証（空文字=未指定は呼び出し側で扱う）
# 許容値: pre-merge, post-merge
validate_operations_stage() {
    local stage="$1"
    case "$stage" in
        pre-merge|post-merge)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# operations/progress.md から固定スロット値を読み取る
# §5.3.5 grammar の意図的サブセット: 独立行 key=value のみ対応
# （1 行カンマ区切り併記・grammar version HTML コメント検証は非対応）
#
# 引数:
#   $1 - cycle（例: v2.3.6）
#   $2 - key（例: completion_gate_ready, pr_number）
# 標準出力: 値（見つからない場合は空）
# 戻り値: 0=取得成功, 1=不在/不正/対応外記法（undecidable 扱い）
read_progress_slot() {
    local cycle="$1"
    local key="$2"
    local progress_file="${AIDLC_CYCLES}/${cycle}/operations/progress.md"

    if [[ ! -f "$progress_file" ]]; then
        return 1
    fi

    local value
    # 独立行 key=value のみ対応。行頭スペース無し、コメント行（# で始まる）は無視。
    # §5.3.5 の「`#` 以降はコメント」に準拠し、インラインコメント（値の後の `# ...`）も除去する。
    # 値前後のスペースをトリム。重複時は最初の出現を採用（grep 先頭ヒット）。
    value=$(grep -E "^${key}[[:space:]]*=" "$progress_file" 2>/dev/null | head -n 1 | sed -E "s/^${key}[[:space:]]*=[[:space:]]*//" | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/[[:space:]]+$//') || return 1

    if [[ -z "$value" ]]; then
        return 1
    fi

    echo "$value"
    return 0
}

# gh pr view で PR 状態を取得し、正規化済みシェル変数セットで返す
# §5.3.6 GitHubPullRequestGateway 信頼境界契約に準拠
#
# 引数:
#   $1 - pr_number（正の整数）
# 副作用（成功時）:
#   GUARD_PR_STATE, GUARD_PR_MERGED_AT, GUARD_PR_NUMBER, GUARD_PR_IS_DRAFT を設定
# 副作用（undecidable 時）:
#   上記 4 変数を "undecidable" に設定
# 戻り値: 0=成功, 1=undecidable
# 呼び出し回数: 1 判定プロセスあたり最大 1 回（GUARD_PR_QUERY_DONE でガード）
query_pr_state() {
    local pr_number="$1"

    # 既に呼び出し済みならスキップ（前回の結果を保持）
    if [[ "$GUARD_PR_QUERY_DONE" == "true" ]]; then
        return 0
    fi
    GUARD_PR_QUERY_DONE=true

    # undecidable 初期化
    GUARD_PR_STATE="undecidable"
    GUARD_PR_MERGED_AT="undecidable"
    GUARD_PR_NUMBER="undecidable"
    GUARD_PR_IS_DRAFT="undecidable"

    # pr_number 検証
    if ! [[ "$pr_number" =~ ^[1-9][0-9]*$ ]]; then
        return 1
    fi

    # gh / jq の可用性確認
    if ! command -v gh >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # gh pr view 実行（set -euo pipefail 下でも失敗を吸収）
    # AIDLC_PROJECT_ROOT 経由の外部呼び出しでも対象リポジトリを判定できるよう
    # サブシェルで AIDLC_PROJECT_ROOT に cd してから実行する（gh は cwd ベースで
    # リポジトリを解決するため、cwd 未変更だと外部ディレクトリからの呼び出しが
    # undecidable となり post-merge ガードがバイパスされる）。
    local json
    json=$(cd "$AIDLC_PROJECT_ROOT" 2>/dev/null && gh pr view "$pr_number" --json isDraft,state,mergedAt,number 2>/dev/null) || return 1

    if [[ -z "$json" ]]; then
        return 1
    fi

    # JSON パース
    # `| tostring` を使う理由: `// "null"` は jq の仕様により false / 0 / null すべてで
    # フォールバックが発動し、boolean の false を null と誤認する。tostring は null を
    # 明示的に "null" 文字列化するため、欠損判定と false 値を区別できる。
    local parsed_is_draft parsed_state parsed_merged_at parsed_number
    parsed_is_draft=$(echo "$json" | jq -r '.isDraft | tostring' 2>/dev/null) || return 1
    parsed_state=$(echo "$json" | jq -r '.state | tostring' 2>/dev/null) || return 1
    parsed_merged_at=$(echo "$json" | jq -r '.mergedAt | tostring' 2>/dev/null) || return 1
    parsed_number=$(echo "$json" | jq -r '.number | tostring' 2>/dev/null) || return 1

    # 必須フィールド欠損チェック
    if [[ "$parsed_is_draft" == "null" || "$parsed_state" == "null" || "$parsed_number" == "null" ]]; then
        return 1
    fi

    # state 許容値チェック
    case "$parsed_state" in
        OPEN|CLOSED|MERGED) ;;
        *) return 1 ;;
    esac

    # number 一致チェック（repo 取り違え防止）
    if [[ "$parsed_number" != "$pr_number" ]]; then
        return 1
    fi

    # 正規化済み値を設定
    GUARD_PR_STATE="$parsed_state"
    GUARD_PR_MERGED_AT="$parsed_merged_at"
    GUARD_PR_NUMBER="$parsed_number"
    GUARD_PR_IS_DRAFT="$parsed_is_draft"

    return 0
}

# post-merge 拒否メッセージを stdout と stderr の両方に重複出力する
# 機械可読形式: error:post-merge-history-write-forbidden:<reason_code>:<diagnostics>
#
# 引数:
#   $1 - reason_code（例: explicit_stage, fallback_merged_confirmed）
#   $2 - diagnostics（例: "stage=post-merge" / "completion_gate_ready=true,pr=581,state=MERGED"）
emit_post_merge_rejection() {
    local reason_code="$1"
    local diagnostics="$2"
    local payload="post-merge-history-write-forbidden:${reason_code}:${diagnostics}"

    # stdout（既存 emit_error パターン互換）
    emit_error "$payload"
    # stderr（Unit 定義 / Story 1.2 準拠）
    echo "error:${payload}" 1>&2
}

# Operations Phase の post-merge 誤呼び出しを判定する（DR-001）
# 正規化済み入力のみを受領し、外部データソースへの再アクセスは行わない。
#
# 引数: （$1 以降は main 側で取得した正規化済み値）
#   $1 - phase（inception|construction|operations）
#   $2 - operations_stage（pre-merge|post-merge|空文字）
#   $3 - completion_gate_ready（"true"|"false"|"undecidable"|空文字）
#   $4 - pr_number_from_progress（整数文字列 or 空文字）
#   $5 - pr_state（"OPEN"|"CLOSED"|"MERGED"|"undecidable"|空文字）
#   $6 - pr_merged_at（タイムスタンプ or "null"|"undecidable"|空文字）
#   $7 - pr_number_gh（整数文字列 or "undecidable"|空文字）
# 戻り値: 0=pass（従来動作継続）, 3=reject（caller は exit 3 する）
evaluate_post_merge_guard() {
    local phase="$1"
    local stage="$2"
    local completion_gate_ready="$3"
    local pr_number_from_progress="$4"
    local pr_state="$5"
    local pr_merged_at="$6"
    local pr_number_gh="$7"

    # 1. operations フェーズ以外は常に pass
    if [[ "$phase" != "operations" ]]; then
        return 0
    fi

    # 2. 第一条件: --operations-stage post-merge
    if [[ "$stage" == "post-merge" ]]; then
        emit_post_merge_rejection "explicit_stage" "stage=post-merge"
        return 3
    fi

    # 3. --operations-stage pre-merge は明示的に pass（第二条件をスキップ）
    if [[ "$stage" == "pre-merge" ]]; then
        return 0
    fi

    # 4. 第二条件（AND フォールバック）: stage 未指定時のみ評価
    # a. completion_gate_ready が true でなければ pass
    if [[ "$completion_gate_ready" != "true" ]]; then
        return 0
    fi

    # b. pr_number_from_progress が正整数でなければ pass
    if ! [[ "$pr_number_from_progress" =~ ^[1-9][0-9]*$ ]]; then
        return 0
    fi

    # c. GitHub 実態確認: state=MERGED AND mergedAt!=null AND number 一致
    if [[ "$pr_state" != "MERGED" ]]; then
        return 0
    fi
    if [[ -z "$pr_merged_at" || "$pr_merged_at" == "null" || "$pr_merged_at" == "undecidable" ]]; then
        return 0
    fi
    if [[ "$pr_number_gh" != "$pr_number_from_progress" ]]; then
        return 0
    fi

    # 全条件成立 → reject
    emit_post_merge_rejection "fallback_merged_confirmed" "completion_gate_ready=true,pr=${pr_number_from_progress},state=MERGED"
    return 3
}

# Unit番号を検証（1〜99）
validate_unit() {
    local unit="$1"
    if [[ "$unit" =~ ^[0-9]+$ ]] && [[ "$unit" -ge 1 ]] && [[ "$unit" -le 99 ]]; then
        return 0
    else
        return 1
    fi
}

# ファイルパスを解決
resolve_filepath() {
    local cycle="$1"
    local phase="$2"
    local unit="$3"

    local base_path="${AIDLC_CYCLES}/${cycle}/history"

    case "$phase" in
        inception)
            echo "${base_path}/inception.md"
            ;;
        construction)
            local unit_padded
            unit_padded=$(printf "%02d" "$unit")
            echo "${base_path}/construction_unit${unit_padded}.md"
            ;;
        operations)
            echo "${base_path}/operations.md"
            ;;
    esac
}

# フェーズ表示名を取得
get_phase_display_name() {
    local phase="$1"
    case "$phase" in
        inception)
            echo "Inception Phase"
            ;;
        construction)
            echo "Construction Phase"
            ;;
        operations)
            echo "Operations Phase"
            ;;
    esac
}

# ファイルヘッダーを生成
generate_header() {
    local phase="$1"
    local unit="$2"

    case "$phase" in
        inception)
            echo "# Inception Phase 履歴"
            ;;
        construction)
            local unit_padded
            unit_padded=$(printf "%02d" "$unit")
            echo "# Construction Phase 履歴: Unit ${unit_padded}"
            ;;
        operations)
            echo "# Operations Phase 履歴"
            ;;
    esac
}

# 履歴エントリをフォーマット
format_entry() {
    local timestamp="$1"
    local phase_display="$2"
    local unit_display="$3"
    local step="$4"
    local content="$5"
    shift 5
    local artifacts=("$@")

    echo "## ${timestamp}"
    echo ""
    echo "- **フェーズ**: ${phase_display}"

    if [[ -n "$unit_display" ]]; then
        echo "- **Unit**: ${unit_display}"
    fi

    echo "- **ステップ**: ${step}"
    echo "- **実行内容**: ${content}"

    if [[ ${#artifacts[@]} -gt 0 ]]; then
        echo "- **成果物**:"
        for artifact in "${artifacts[@]}"; do
            echo "  - \`${artifact}\`"
        done
    fi

    echo ""
    echo "---"
}

# メイン処理
main() {
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --cycle)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-cycle-value" "--cycle requires a value"
                    exit 1
                fi
                CYCLE="$2"
                shift 2
                ;;
            --phase)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-phase-value" "--phase requires a value"
                    exit 1
                fi
                PHASE="$2"
                shift 2
                ;;
            --unit)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-unit-value" "--unit requires a value"
                    exit 1
                fi
                UNIT="$2"
                shift 2
                ;;
            --unit-name)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-unit-name-value" "--unit-name requires a value"
                    exit 1
                fi
                UNIT_NAME="$2"
                shift 2
                ;;
            --unit-slug)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-unit-slug-value" "--unit-slug requires a value"
                    exit 1
                fi
                UNIT_SLUG="$2"
                shift 2
                ;;
            --step)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-step-value" "--step requires a value"
                    exit 1
                fi
                STEP="$2"
                shift 2
                ;;
            --content)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-content-value" "--content requires a value"
                    exit 1
                fi
                CONTENT="$2"
                shift 2
                ;;
            --content-file)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-content-file-value" "--content-file requires a value"
                    exit 1
                fi
                CONTENT_FILE="$2"
                shift 2
                ;;
            --artifacts)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-artifacts-value" "--artifacts requires a value"
                    exit 1
                fi
                ARTIFACTS+=("$2")
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --operations-stage)
                if [[ -z "${2:-}" ]]; then
                    emit_error "missing-operations-stage-value" "--operations-stage requires a value"
                    exit 1
                fi
                if ! validate_operations_stage "$2"; then
                    emit_error "invalid-operations-stage" "Invalid --operations-stage value. Must be pre-merge or post-merge"
                    exit 1
                fi
                OPERATIONS_STAGE="$2"
                shift 2
                ;;
            -*)
                emit_error "unknown-option" "Unknown option: $1"
                exit 1
                ;;
            *)
                emit_error "unexpected-argument" "Unexpected argument: $1"
                exit 1
                ;;
        esac
    done

    # 必須引数のバリデーション
    if [[ -z "$CYCLE" ]]; then
        emit_error "missing-cycle" "--cycle is required"
        exit 1
    fi

    if ! validate_cycle "$CYCLE"; then
        emit_error "invalid-cycle-name" "Invalid cycle name: ${CYCLE}"
        exit 1
    fi

    if [[ -z "$PHASE" ]]; then
        emit_error "missing-phase" "--phase is required"
        exit 1
    fi

    if ! validate_phase "$PHASE"; then
        emit_error "invalid-phase" "Invalid phase. Must be inception, construction, or operations"
        exit 1
    fi

    if [[ -z "$STEP" ]]; then
        emit_error "missing-step" "--step is required"
        exit 1
    fi

    # --content と --content-file の排他チェック・ファイル読み込み
    if [[ -n "${CONTENT_FILE:-}" ]]; then
        if [[ -n "$CONTENT" ]]; then
            emit_error "content-mutually-exclusive" "--content and --content-file are mutually exclusive"
            exit 1
        fi
        if [[ ! -f "$CONTENT_FILE" ]]; then
            emit_error "content-file-not-found" "File not found: $CONTENT_FILE"
            exit 1
        fi
        if [[ ! -s "$CONTENT_FILE" ]]; then
            emit_error "content-file-empty" "File is empty: $CONTENT_FILE"
            exit 1
        fi
        CONTENT="$(cat "$CONTENT_FILE")"
    fi

    if [[ -z "$CONTENT" ]]; then
        emit_error "missing-content" "--content is required"
        exit 1
    fi

    # constructionフェーズの場合、Unit関連引数が必須
    if [[ "$PHASE" == "construction" ]]; then
        if [[ -z "$UNIT" ]]; then
            emit_error "missing-unit-construction" "--unit is required for construction phase"
            exit 1
        fi

        if ! validate_unit "$UNIT"; then
            emit_error "invalid-unit-number" "Invalid unit number. Must be 1-99"
            exit 1
        fi

        if [[ -z "$UNIT_NAME" ]]; then
            emit_error "missing-unit-name" "--unit-name is required for construction phase"
            exit 1
        fi

        if [[ -z "$UNIT_SLUG" ]]; then
            emit_error "missing-unit-slug" "--unit-slug is required for construction phase"
            exit 1
        fi
    fi

    # ============================================================
    # Operations Phase post-merge ガード判定（Unit 002 / DR-001）
    # ============================================================
    # 事前データ取得は第二条件フォールバック対象時のみ実施する
    # （--operations-stage 明示時 / non-operations phase 時は gh を呼ばない）
    if [[ "$PHASE" == "operations" && "$OPERATIONS_STAGE" != "post-merge" && "$OPERATIONS_STAGE" != "pre-merge" ]]; then
        GUARD_COMPLETION_GATE_READY=$(read_progress_slot "$CYCLE" "completion_gate_ready") || GUARD_COMPLETION_GATE_READY=""
        GUARD_PR_NUMBER_FROM_PROGRESS=$(read_progress_slot "$CYCLE" "pr_number") || GUARD_PR_NUMBER_FROM_PROGRESS=""

        if [[ "$GUARD_COMPLETION_GATE_READY" == "true" ]] && [[ "$GUARD_PR_NUMBER_FROM_PROGRESS" =~ ^[1-9][0-9]*$ ]]; then
            query_pr_state "$GUARD_PR_NUMBER_FROM_PROGRESS" || true
        fi
    fi

    # ガード評価
    local guard_result=0
    if evaluate_post_merge_guard \
        "$PHASE" \
        "$OPERATIONS_STAGE" \
        "$GUARD_COMPLETION_GATE_READY" \
        "$GUARD_PR_NUMBER_FROM_PROGRESS" \
        "$GUARD_PR_STATE" \
        "$GUARD_PR_MERGED_AT" \
        "$GUARD_PR_NUMBER"; then
        guard_result=0
    else
        guard_result=$?
    fi

    if [[ "$guard_result" -eq 3 ]]; then
        exit 3
    fi
    # ============================================================

    # ファイルパス解決
    local filepath
    filepath=$(resolve_filepath "$CYCLE" "$PHASE" "$UNIT")

    # ファイル存在確認
    local is_new_file=false
    if [[ ! -f "$filepath" ]]; then
        is_new_file=true
    fi

    # dry-runモード
    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ "$is_new_file" == "true" ]]; then
            echo "history:${filepath}:would-create"
        else
            echo "history:${filepath}:would-append"
        fi
        exit 0
    fi

    # ディレクトリ作成（存在しない場合）
    local dir
    dir=$(dirname "$filepath")
    if [[ ! -d "$dir" ]]; then
        if ! mkdir -p "$dir" 2>/dev/null; then
            echo "history:${filepath}:error"
            emit_error "failed-create-directory" "Failed to create directory: $dir"
            exit 2
        fi
    fi

    # タイムスタンプ取得（ISO 8601形式）
    # set -euo pipefail 下でも date/sed 失敗時にフォールバックできるよう
    # || true でパイプライン失敗を吸収する
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null | sed 's/\([+-][0-9][0-9]\)\([0-9][0-9]\)$/\1:\2/') || true
    if [[ -z "$timestamp" ]]; then
        timestamp="1970-01-01T00:00:00+00:00"
    fi

    # フェーズ表示名取得
    local phase_display
    phase_display=$(get_phase_display_name "$PHASE")

    # Unit表示名生成（constructionの場合のみ）
    local unit_display=""
    if [[ "$PHASE" == "construction" ]]; then
        local unit_padded
        unit_padded=$(printf "%02d" "$UNIT")
        unit_display="${unit_padded}-${UNIT_SLUG}（${UNIT_NAME}）"
    fi

    # 新規ファイルの場合はヘッダーを追加
    if [[ "$is_new_file" == "true" ]]; then
        local header
        header=$(generate_header "$PHASE" "$UNIT")
        if ! echo "$header" > "$filepath" 2>/dev/null; then
            echo "history:${filepath}:error"
            emit_error "failed-create-file" "Failed to create file: $filepath"
            exit 2
        fi
        echo "" >> "$filepath"
    fi

    # エントリをフォーマットして追記
    local entry
    entry=$(format_entry "$timestamp" "$phase_display" "$unit_display" "$STEP" "$CONTENT" "${ARTIFACTS[@]}")

    if ! echo "$entry" >> "$filepath" 2>/dev/null; then
        echo "history:${filepath}:error"
        emit_error "failed-append-file" "Failed to append to file: $filepath"
        exit 2
    fi

    # 成功出力
    if [[ "$is_new_file" == "true" ]]; then
        echo "history:${filepath}:created"
    else
        echo "history:${filepath}:appended"
    fi

    exit 0
}

main "$@"
