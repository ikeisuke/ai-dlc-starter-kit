#!/usr/bin/env bash
# サイズチェックスクリプト
# プロンプトファイルのサイズが閾値を超えていないかをチェックする
# Usage: check-size.sh [target_dir] [options]

set -euo pipefail

# デフォルト値
DEFAULT_MAX_BYTES=150000
DEFAULT_MAX_LINES=1000
DEFAULT_MAX_TOKENS=40000
DEFAULT_TARGET_PATTERN="*.md"
DEFAULT_TARGET_DIR="skills/aidlc/steps/"

# グローバル変数
REPO_ROOT=""
VERBOSE=false
TARGET_DIR=""
MAX_BYTES=""
MAX_LINES=""
MAX_TOKENS=""
TARGET_PATTERN=""
ENABLED=true
CLI_OVERRIDE=false
WARNING_COUNT=0
FILE_COUNT=0
TIKTOKEN_AVAILABLE=""

# CLI引数から指定された値（load_config後に適用）
CLI_MAX_BYTES=""
CLI_MAX_LINES=""
CLI_MAX_TOKENS=""

# 使用法表示
show_usage() {
    cat <<EOF
Usage: $(basename "$0") [target_dir] [options]

プロンプトファイルのサイズが閾値を超えていないかをチェックします。

Arguments:
  target_dir    チェック対象ディレクトリ (デフォルト: skills/aidlc/steps/)

Options:
  -v, --verbose           詳細出力モード
  --bytes-threshold N     バイト数閾値を一時的に上書き
  --lines-threshold N     行数閾値を一時的に上書き
  --tokens-threshold N    トークン数閾値を一時的に上書き
  -h, --help              このヘルプを表示

Exit codes:
  0  閾値超過なし、または enabled=false
  1  閾値超過あり
  2  スクリプトエラー

Configuration:
  .aidlc/config.toml の [rules.size_check] セクションで設定可能:
    enabled        = true/false (デフォルト: true)
    max_bytes      = 150000 (デフォルト)
    max_lines      = 1000 (デフォルト)
    max_tokens     = 40000 (デフォルト)
    target_pattern = "*.md" (デフォルト)
EOF
}

# tiktoken利用可否を判定
check_tiktoken() {
    if [ -n "$TIKTOKEN_AVAILABLE" ]; then
        return
    fi
    if python3 -c "import tiktoken" 2>/dev/null; then
        TIKTOKEN_AVAILABLE=true
    else
        TIKTOKEN_AVAILABLE=false
    fi
}

# tiktokenでトークン数を一括計測（バッチ処理）
# 引数: ファイルパスリスト（改行区切り）
# 出力: "filepath\ttoken_count" 形式（1行ずつ）
batch_count_tokens_tiktoken() {
    python3 - <<'PYEOF' "$@" 2>/dev/null
import sys
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
for filepath in sys.argv[1:]:
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            text = f.read()
        print(f"{filepath}\t{len(enc.encode(text))}")
    except Exception:
        print(f"{filepath}\t-1")
PYEOF
}

# トークンキャッシュ（連想配列）
declare -A TOKEN_CACHE

# キャッシュからトークン数を取得（なければ近似計算）
get_token_count() {
    local file="$1"
    if [[ -v TOKEN_CACHE["$file"] ]]; then
        echo "${TOKEN_CACHE["$file"]}"
    else
        count_tokens_estimate "$file"
    fi
}

# tiktokenバッチ結果をキャッシュに格納
load_tiktoken_cache() {
    local files=("$@")
    local result
    result=$(batch_count_tokens_tiktoken "${files[@]}")
    while IFS=$'\t' read -r filepath count; do
        if [ "$count" != "-1" ]; then
            TOKEN_CACHE["$filepath"]="$count"
        fi
    done <<< "$result"
}

# 近似計算でトークン数を概算
# 日本語バイト比率を検出し、加重平均でトークン数を算出
count_tokens_estimate() {
    local file="$1"
    local bytes
    bytes=$(wc -c < "$file" | tr -d ' ')

    if [ "$bytes" -eq 0 ]; then
        echo "0"
        return
    fi

    # ASCII文字数を取得（日本語/非ASCII比率の推定用）
    local ascii_bytes
    ascii_bytes=$(LC_ALL=C tr -cd '\000-\177' < "$file" | wc -c | tr -d ' ')

    local non_ascii_bytes=$((bytes - ascii_bytes))

    # トークン概算:
    # - 英語（ASCII）: 約4バイト/トークン
    # - 日本語（非ASCII）: 約3バイト/トークン（UTF-8で3バイト/文字、約1文字/トークン）
    local ascii_tokens=0
    local non_ascii_tokens=0

    if [ "$ascii_bytes" -gt 0 ]; then
        ascii_tokens=$(( (ascii_bytes + 3) / 4 ))
    fi
    if [ "$non_ascii_bytes" -gt 0 ]; then
        non_ascii_tokens=$(( (non_ascii_bytes + 2) / 3 ))
    fi

    echo $((ascii_tokens + non_ascii_tokens))
}

# 設定ファイルから値を読み込む
load_config() {
    local config_file="${REPO_ROOT}/.aidlc/config.toml"

    if [ ! -f "$config_file" ]; then
        # 設定ファイルがない場合はデフォルト値を使用
        ENABLED=true
        MAX_BYTES=$DEFAULT_MAX_BYTES
        MAX_LINES=$DEFAULT_MAX_LINES
        MAX_TOKENS=$DEFAULT_MAX_TOKENS
        TARGET_PATTERN=$DEFAULT_TARGET_PATTERN
        return
    fi

    # daselが利用可能かチェック
    if command -v dasel >/dev/null 2>&1; then
        # daselで読み込み
        ENABLED=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.enabled' 2>/dev/null | tr -d "'" || echo "true")
        MAX_BYTES=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.max_bytes' 2>/dev/null || echo "$DEFAULT_MAX_BYTES")
        MAX_LINES=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.max_lines' 2>/dev/null || echo "$DEFAULT_MAX_LINES")
        MAX_TOKENS=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.max_tokens' 2>/dev/null || echo "$DEFAULT_MAX_TOKENS")
        TARGET_PATTERN=$(cat "$config_file" 2>/dev/null | dasel -i toml 'rules.size_check.target_pattern' 2>/dev/null | tr -d "'" || echo "$DEFAULT_TARGET_PATTERN")
    else
        # grepベースのフォールバック（-A 20 で十分な行数を確保）
        ENABLED=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^enabled' | head -1 | sed 's/.*= *//' | tr -d ' "'"'" || echo "true")
        MAX_BYTES=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^max_bytes' | head -1 | sed 's/.*= *//' | tr -d ' ' || echo "$DEFAULT_MAX_BYTES")
        MAX_LINES=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^max_lines' | head -1 | sed 's/.*= *//' | tr -d ' ' || echo "$DEFAULT_MAX_LINES")
        MAX_TOKENS=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^max_tokens' | head -1 | sed 's/.*= *//' | tr -d ' ' || echo "$DEFAULT_MAX_TOKENS")
        TARGET_PATTERN=$(grep -A 20 '^\[rules\.size_check\]' "$config_file" 2>/dev/null | grep '^target_pattern' | head -1 | sed 's/.*= *//' | tr -d ' "'"'" || echo "$DEFAULT_TARGET_PATTERN")
    fi

    # インラインコメントを除去（# 以降を削除）
    ENABLED=$(echo "$ENABLED" | sed 's/#.*//' | tr -d ' ')
    MAX_BYTES=$(echo "$MAX_BYTES" | sed 's/#.*//' | tr -d ' ')
    MAX_LINES=$(echo "$MAX_LINES" | sed 's/#.*//' | tr -d ' ')
    MAX_TOKENS=$(echo "$MAX_TOKENS" | sed 's/#.*//' | tr -d ' ')
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
    if [ -z "$MAX_TOKENS" ]; then
        MAX_TOKENS=$DEFAULT_MAX_TOKENS
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

    # トークン数を取得（キャッシュまたは近似計算）
    local tokens
    local token_method
    if [ "$TIKTOKEN_AVAILABLE" = "true" ]; then
        tokens=$(get_token_count "$file")
        token_method=""
    else
        tokens=$(count_tokens_estimate "$file")
        token_method=" (estimated)"
    fi

    local exceeds_bytes=false
    local exceeds_lines=false
    local exceeds_tokens=false

    if [ "$bytes" -gt "$MAX_BYTES" ]; then
        exceeds_bytes=true
    fi

    if [ "$lines" -gt "$MAX_LINES" ]; then
        exceeds_lines=true
    fi

    if [ "$tokens" -gt "$MAX_TOKENS" ]; then
        exceeds_tokens=true
    fi

    ((FILE_COUNT++)) || true

    if $exceeds_bytes || $exceeds_lines || $exceeds_tokens; then
        ((WARNING_COUNT++)) || true

        if $VERBOSE; then
            # 詳細モード: 1行サマリ形式
            echo "  [WARN] $rel_file ($bytes bytes, $lines lines, $tokens tokens${token_method})"
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

            if $exceeds_tokens; then
                echo "  Tokens: $tokens${token_method} (threshold: $MAX_TOKENS) [EXCEEDED]"
            else
                echo "  Tokens: $tokens${token_method} (threshold: $MAX_TOKENS)"
            fi
        fi
    elif $VERBOSE; then
        echo "  [OK] $rel_file ($bytes bytes, $lines lines, $tokens tokens${token_method})"
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
            --tokens-threshold)
                if [[ -n "${2:-}" ]]; then
                    if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                        echo "Error: --tokens-threshold requires a numeric value" >&2
                        exit 2
                    fi
                    CLI_MAX_TOKENS="$2"
                    CLI_OVERRIDE=true
                    shift 2
                else
                    echo "Error: --tokens-threshold requires a value" >&2
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
    if [ -n "$CLI_MAX_TOKENS" ]; then
        MAX_TOKENS="$CLI_MAX_TOKENS"
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
    if ! [[ "$MAX_TOKENS" =~ ^[0-9]+$ ]]; then
        echo "Error: max_tokens must be a numeric value (got: $MAX_TOKENS)" >&2
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

    # tiktoken可用性の事前チェック・表示
    check_tiktoken
    if $VERBOSE; then
        echo "Checking file sizes in ${rel_target}..."
        echo "  Max bytes: $MAX_BYTES"
        echo "  Max lines: $MAX_LINES"
        echo "  Max tokens: $MAX_TOKENS"
        if [ "$TIKTOKEN_AVAILABLE" = "true" ]; then
            echo "  Token counter: tiktoken (cl100k_base)"
        else
            echo "  Token counter: estimate (byte-based approximation)"
        fi
        echo "  Pattern: $TARGET_PATTERN"
        echo ""
    fi

    # 対象ファイルを収集
    local -a target_files=()
    while IFS= read -r -d '' file; do
        target_files+=("$file")
    done < <(find "$TARGET_DIR" -type f -name "$TARGET_PATTERN" -print0)

    # tiktoken利用可能時はバッチ処理でトークン数を事前計測
    if [ "$TIKTOKEN_AVAILABLE" = "true" ] && [ ${#target_files[@]} -gt 0 ]; then
        load_tiktoken_cache "${target_files[@]}"
    fi

    # 各ファイルをチェック
    for file in "${target_files[@]}"; do
        check_file "$file"
    done

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
