#!/usr/bin/env bash
# サイズチェックスクリプト
# プロンプトファイルのサイズが閾値を超えていないかをチェックする
# Usage: check-size.sh [target_dir] [options]

set -euo pipefail

# デフォルト値
DEFAULT_MAX_BYTES=150000
DEFAULT_MAX_LINES=1000
DEFAULT_TARGET_PATTERN="*.md"
DEFAULT_TARGET_DIR="prompts/package/prompts/"

# グローバル変数
REPO_ROOT=""
VERBOSE=false
TARGET_DIR=""
MAX_BYTES=""
MAX_LINES=""
TARGET_PATTERN=""
ENABLED=true
CLI_OVERRIDE=false
WARNING_COUNT=0
FILE_COUNT=0

# CLI引数から指定された値（load_config後に適用）
CLI_MAX_BYTES=""
CLI_MAX_LINES=""

# 使用法表示
show_usage() {
    cat <<EOF
Usage: $(basename "$0") [target_dir] [options]

プロンプトファイルのサイズが閾値を超えていないかをチェックします。

Arguments:
  target_dir    チェック対象ディレクトリ (デフォルト: prompts/package/prompts/)

Options:
  -v, --verbose           詳細出力モード
  --bytes-threshold N     バイト数閾値を一時的に上書き
  --lines-threshold N     行数閾値を一時的に上書き
  -h, --help              このヘルプを表示

Exit codes:
  0  閾値超過なし、または enabled=false
  1  閾値超過あり
  2  スクリプトエラー

Configuration:
  docs/aidlc.toml の [rules.size_check] セクションで設定可能:
    enabled        = true/false (デフォルト: true)
    max_bytes      = 150000 (デフォルト)
    max_lines      = 1000 (デフォルト)
    target_pattern = "*.md" (デフォルト)
EOF
}

# 設定ファイルから値を読み込む
load_config() {
    local config_file="${REPO_ROOT}/docs/aidlc.toml"

    if [ ! -f "$config_file" ]; then
        # 設定ファイルがない場合はデフォルト値を使用
        ENABLED=true
        MAX_BYTES=$DEFAULT_MAX_BYTES
        MAX_LINES=$DEFAULT_MAX_LINES
        TARGET_PATTERN=$DEFAULT_TARGET_PATTERN
        return
    fi

    # daselが利用可能かチェック
    if command -v dasel >/dev/null 2>&1; then
        # daselで読み込み
        ENABLED=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.enabled' 2>/dev/null | tr -d "'" || echo "true")
        MAX_BYTES=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.max_bytes' 2>/dev/null || echo "$DEFAULT_MAX_BYTES")
        MAX_LINES=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.max_lines' 2>/dev/null || echo "$DEFAULT_MAX_LINES")
        TARGET_PATTERN=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.target_pattern' 2>/dev/null | tr -d "'" || echo "$DEFAULT_TARGET_PATTERN")
    else
        # grepベースのフォールバック（-A 20 で十分な行数を確保）
        ENABLED=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^enabled' | head -1 | sed 's/.*= *//' | tr -d ' "'"'" || echo "true")
        MAX_BYTES=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^max_bytes' | head -1 | sed 's/.*= *//' | tr -d ' ' || echo "$DEFAULT_MAX_BYTES")
        MAX_LINES=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^max_lines' | head -1 | sed 's/.*= *//' | tr -d ' ' || echo "$DEFAULT_MAX_LINES")
        TARGET_PATTERN=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^target_pattern' | head -1 | sed 's/.*= *//' | tr -d ' "'"'" || echo "$DEFAULT_TARGET_PATTERN")
    fi

    # インラインコメントを除去（# 以降を削除）
    ENABLED=$(echo "$ENABLED" | sed 's/#.*//' | tr -d ' ')
    MAX_BYTES=$(echo "$MAX_BYTES" | sed 's/#.*//' | tr -d ' ')
    MAX_LINES=$(echo "$MAX_LINES" | sed 's/#.*//' | tr -d ' ')
    TARGET_PATTERN=$(echo "$TARGET_PATTERN" | sed 's/#.*//' | tr -d ' ')

    # 空の場合はデフォルト値を使用
    if [ -z "$ENABLED" ]; then
        ENABLED=true
    fi
    if [ -z "$MAX_BYTES" ]; then
        MAX_BYTES=$DEFAULT_MAX_BYTES
    fi
    if [ -z "$MAX_LINES" ]; then
        MAX_LINES=$DEFAULT_MAX_LINES
    fi
    if [ -z "$TARGET_PATTERN" ]; then
        TARGET_PATTERN=$DEFAULT_TARGET_PATTERN
    fi
}

# ファイルサイズをチェック
check_file() {
    local file="$1"
    local rel_file="${file#"${REPO_ROOT}/"}"

    # バイト数を取得
    local bytes
    bytes=$(wc -c < "$file" | tr -d ' ')

    # 行数を取得
    local lines
    lines=$(wc -l < "$file" | tr -d ' ')

    local exceeds_bytes=false
    local exceeds_lines=false

    if [ "$bytes" -gt "$MAX_BYTES" ]; then
        exceeds_bytes=true
    fi

    if [ "$lines" -gt "$MAX_LINES" ]; then
        exceeds_lines=true
    fi

    ((FILE_COUNT++)) || true

    if $exceeds_bytes || $exceeds_lines; then
        ((WARNING_COUNT++)) || true

        if $VERBOSE; then
            # 詳細モード: 1行サマリ形式
            echo "  [WARN] $rel_file ($bytes bytes, $lines lines)"
        else
            # 通常モード: 複数行の詳細形式
            echo ""
            echo "WARNING: File size exceeds threshold"
            echo "  File: $rel_file"

            if $exceeds_bytes; then
                echo "  Size: $bytes bytes (threshold: $MAX_BYTES) [EXCEEDED]"
            else
                echo "  Size: $bytes bytes (threshold: $MAX_BYTES)"
            fi

            if $exceeds_lines; then
                echo "  Lines: $lines (threshold: $MAX_LINES) [EXCEEDED]"
            else
                echo "  Lines: $lines (threshold: $MAX_LINES)"
            fi
        fi
    elif $VERBOSE; then
        echo "  [OK] $rel_file ($bytes bytes, $lines lines)"
    fi
}

# メイン処理
main() {
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --bytes-threshold)
                if [[ -n "${2:-}" ]]; then
                    if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                        echo "Error: --bytes-threshold requires a numeric value" >&2
                        exit 2
                    fi
                    CLI_MAX_BYTES="$2"
                    CLI_OVERRIDE=true
                    shift 2
                else
                    echo "Error: --bytes-threshold requires a value" >&2
                    exit 2
                fi
                ;;
            --lines-threshold)
                if [[ -n "${2:-}" ]]; then
                    if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                        echo "Error: --lines-threshold requires a numeric value" >&2
                        exit 2
                    fi
                    CLI_MAX_LINES="$2"
                    CLI_OVERRIDE=true
                    shift 2
                else
                    echo "Error: --lines-threshold requires a value" >&2
                    exit 2
                fi
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                show_usage >&2
                exit 2
                ;;
            *)
                if [ -z "$TARGET_DIR" ]; then
                    TARGET_DIR="$1"
                else
                    echo "Error: Unexpected argument: $1" >&2
                    show_usage >&2
                    exit 2
                fi
                shift
                ;;
        esac
    done

    # リポジトリルート取得
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "Error: Not a git repository. Run this script from within a git repository." >&2
        exit 2
    }

    # 設定読み込み
    load_config

    # CLIオプションで指定された値で上書き
    if [ -n "$CLI_MAX_BYTES" ]; then
        MAX_BYTES="$CLI_MAX_BYTES"
    fi
    if [ -n "$CLI_MAX_LINES" ]; then
        MAX_LINES="$CLI_MAX_LINES"
    fi

    # 設定値の数値バリデーション
    if ! [[ "$MAX_BYTES" =~ ^[0-9]+$ ]]; then
        echo "Error: max_bytes must be a numeric value (got: $MAX_BYTES)" >&2
        exit 2
    fi
    if ! [[ "$MAX_LINES" =~ ^[0-9]+$ ]]; then
        echo "Error: max_lines must be a numeric value (got: $MAX_LINES)" >&2
        exit 2
    fi

    # enabled=false かつ CLIオプションなしの場合は終了
    if [ "$ENABLED" = "false" ] && ! $CLI_OVERRIDE; then
        exit 0
    fi

    # デフォルトターゲットディレクトリ
    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$DEFAULT_TARGET_DIR"
    fi

    # ターゲットディレクトリを絶対パスに変換
    if [[ "$TARGET_DIR" != /* ]]; then
        TARGET_DIR="${REPO_ROOT}/${TARGET_DIR}"
    fi

    # ターゲットディレクトリ存在確認
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Error: Target directory not found: $TARGET_DIR" >&2
        exit 2
    fi

    # 相対パス表示用
    local rel_target="${TARGET_DIR#"${REPO_ROOT}/"}"

    if $VERBOSE; then
        echo "Checking file sizes in ${rel_target}..."
        echo "  Max bytes: $MAX_BYTES"
        echo "  Max lines: $MAX_LINES"
        echo "  Pattern: $TARGET_PATTERN"
        echo ""
    fi

    # 対象ファイルをチェック（通常ファイルのみ、シンボリックリンク除外）
    while IFS= read -r -d '' file; do
        check_file "$file"
    done < <(find "$TARGET_DIR" -type f -name "$TARGET_PATTERN" -print0)

    # サマリー出力
    echo ""
    if [ "$WARNING_COUNT" -eq 1 ]; then
        echo "Size check completed: $WARNING_COUNT warning, $FILE_COUNT files checked"
    else
        echo "Size check completed: $WARNING_COUNT warnings, $FILE_COUNT files checked"
    fi

    # 終了コード
    if [ "$WARNING_COUNT" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
