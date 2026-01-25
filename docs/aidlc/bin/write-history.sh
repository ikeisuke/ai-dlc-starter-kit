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
#   --content <CONTENT>     実行内容（必須）
#   --artifacts <PATHS>     成果物パス（オプション、複数回指定可能）
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
# エラー出力形式（引数エラー時）:
#   error:<理由>
#

set -euo pipefail

# グローバル変数
CYCLE=""
PHASE=""
UNIT=""
UNIT_NAME=""
UNIT_SLUG=""
STEP=""
CONTENT=""
ARTIFACTS=()
DRY_RUN=false

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
  --content <CONTENT>     実行内容（必須）
  --artifacts <PATHS>     成果物パス（オプション、複数回指定可能）
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
  history:docs/cycles/v1.8.0/history/construction_unit06.md:appended
EOF
}

# サイクル名を検証（空文字とパス区切り文字を拒否）
validate_cycle() {
    local cycle="$1"
    # 空文字チェック
    if [[ -z "$cycle" ]]; then
        return 1
    fi
    # パス区切り文字を拒否（ディレクトリトラバーサル防止）
    if [[ "$cycle" == */* ]]; then
        return 1
    fi
    return 0
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

    local base_path="docs/cycles/${cycle}/history"

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
                    echo "error:--cycle requires a value" >&2
                    exit 1
                fi
                CYCLE="$2"
                shift 2
                ;;
            --phase)
                if [[ -z "${2:-}" ]]; then
                    echo "error:--phase requires a value" >&2
                    exit 1
                fi
                PHASE="$2"
                shift 2
                ;;
            --unit)
                if [[ -z "${2:-}" ]]; then
                    echo "error:--unit requires a value" >&2
                    exit 1
                fi
                UNIT="$2"
                shift 2
                ;;
            --unit-name)
                if [[ -z "${2:-}" ]]; then
                    echo "error:--unit-name requires a value" >&2
                    exit 1
                fi
                UNIT_NAME="$2"
                shift 2
                ;;
            --unit-slug)
                if [[ -z "${2:-}" ]]; then
                    echo "error:--unit-slug requires a value" >&2
                    exit 1
                fi
                UNIT_SLUG="$2"
                shift 2
                ;;
            --step)
                if [[ -z "${2:-}" ]]; then
                    echo "error:--step requires a value" >&2
                    exit 1
                fi
                STEP="$2"
                shift 2
                ;;
            --content)
                if [[ -z "${2:-}" ]]; then
                    echo "error:--content requires a value" >&2
                    exit 1
                fi
                CONTENT="$2"
                shift 2
                ;;
            --artifacts)
                if [[ -z "${2:-}" ]]; then
                    echo "error:--artifacts requires a value" >&2
                    exit 1
                fi
                ARTIFACTS+=("$2")
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                echo "error:unknown-option:$1"
                exit 1
                ;;
            *)
                echo "error:unexpected-argument:$1"
                exit 1
                ;;
        esac
    done

    # 必須引数のバリデーション
    if [[ -z "$CYCLE" ]]; then
        echo "error:--cycle is required" >&2
        exit 1
    fi

    if ! validate_cycle "$CYCLE"; then
        echo "error:Invalid cycle name. Cannot be empty or contain '/'" >&2
        exit 1
    fi

    if [[ -z "$PHASE" ]]; then
        echo "error:--phase is required" >&2
        exit 1
    fi

    if ! validate_phase "$PHASE"; then
        echo "error:Invalid phase. Must be inception, construction, or operations" >&2
        exit 1
    fi

    if [[ -z "$STEP" ]]; then
        echo "error:--step is required" >&2
        exit 1
    fi

    if [[ -z "$CONTENT" ]]; then
        echo "error:--content is required" >&2
        exit 1
    fi

    # constructionフェーズの場合、Unit関連引数が必須
    if [[ "$PHASE" == "construction" ]]; then
        if [[ -z "$UNIT" ]]; then
            echo "error:--unit is required for construction phase" >&2
            exit 1
        fi

        if ! validate_unit "$UNIT"; then
            echo "error:Invalid unit number. Must be 1-99" >&2
            exit 1
        fi

        if [[ -z "$UNIT_NAME" ]]; then
            echo "error:--unit-name is required for construction phase" >&2
            exit 1
        fi

        if [[ -z "$UNIT_SLUG" ]]; then
            echo "error:--unit-slug is required for construction phase" >&2
            exit 1
        fi
    fi

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
            echo "error:failed-to-create-directory:$dir" >&2
            exit 2
        fi
    fi

    # タイムスタンプ取得
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')

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
            echo "error:failed-to-create-file:$filepath" >&2
            exit 2
        fi
        echo "" >> "$filepath"
    fi

    # エントリをフォーマットして追記
    local entry
    entry=$(format_entry "$timestamp" "$phase_display" "$unit_display" "$STEP" "$CONTENT" "${ARTIFACTS[@]}")

    if ! echo "$entry" >> "$filepath" 2>/dev/null; then
        echo "history:${filepath}:error"
        echo "error:failed-to-append-to-file:$filepath" >&2
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
