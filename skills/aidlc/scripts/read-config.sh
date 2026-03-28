#!/usr/bin/env bash
#
# read-config.sh - 設定値を読み込み（4階層マージ対応）
#
# 使用方法:
#   ./read-config.sh <key>
#   ./read-config.sh --keys <key1> [key2] ...
#
# パラメータ:
#   key       - ドット区切りの設定キー（例: rules.reviewing.mode）
#   --keys    - 複数キー一括指定（位置引数と排他）
#
# 終了コード:
#   0 - 値あり（設定値を出力）
#   1 - キー不在（何も出力しない）
#   2 - エラー（dasel未インストール等）
#
# 設定ファイル階層（優先度: 低→高）:
#   0. <script_dir>/../config/defaults.toml - デフォルト値定義（オプション）
#   1. ~/.aidlc/config.toml - ユーザー共通設定（オプション）
#   2. .aidlc/config.toml - プロジェクト共有設定（必須）
#   3. .aidlc/config.local.toml - 個人設定（オプション、旧名 .aidlc/config.toml.local もフォールバック）
#
# マージルール:
#   - 単一キーの値を取得（ファイル全体のマージではない）
#   - 後から読み込んだファイルにキーが存在すれば上書き
#   - 葉キー（末端の値）を問い合わせた場合のみ有効
#   - 親テーブルを直接取得した場合は最後のファイルの値が返される
#
# 使用例:
#   ./read-config.sh rules.reviewing.mode
#   ./read-config.sh --keys rules.reviewing.mode rules.reviewing.tools rules.history.level
#

set -euo pipefail

# bootstrap.sh で環境変数を設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"
source "${SCRIPT_DIR}/lib/validate.sh"

# 設定ファイルパス（優先度順: 低→高）
DEFAULTS_CONFIG_FILE="${AIDLC_DEFAULTS}"
HOME_CONFIG_FILE="${HOME:+$HOME/.aidlc/config.toml}"
PROJECT_CONFIG_FILE="${AIDLC_CONFIG}"
LOCAL_CONFIG_FILE="${AIDLC_LOCAL_CONFIG}"
LOCAL_CONFIG_FILE_LEGACY="${AIDLC_LOCAL_CONFIG_LEGACY}"

# 引数パース
KEY=""
MODE="single"  # single | batch
KEYS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --keys)
            MODE="batch"
            shift
            # --keys の後、次の -* オプションまたは引数終端までをキーとして読み取る
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                KEYS+=("$1")
                shift
            done
            ;;
        -*)
            emit_error "unknown-option" "Unknown option: $1"
            exit 1
            ;;
        *)
            if [[ -z "$KEY" ]]; then
                KEY="$1"
            else
                emit_error "multiple-keys" "Multiple keys specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# 排他チェック
if [[ "$MODE" == "batch" && -n "$KEY" ]]; then
    emit_error "keys-positional-exclusive" "--keys and positional key are mutually exclusive"
    exit 1
fi

if [[ "$MODE" == "batch" && ${#KEYS[@]} -eq 0 ]]; then
    emit_error "keys-requires-keys" "--keys requires at least one key"
    exit 1
fi

if [[ "$MODE" == "single" && -z "$KEY" ]]; then
    emit_error "missing-key" "Key is required"
    echo "Usage: $0 <key>" >&2
    echo "       $0 --keys <key1> [key2] ..." >&2
    exit 1
fi

# daselの存在確認
if ! command -v dasel >/dev/null 2>&1; then
    emit_error "dasel-not-installed" "dasel is not installed"
    exit 2
fi

# プロジェクト設定ファイルの存在確認（必須）
if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
    emit_error "config-file-not-found" "Config file not found: $PROJECT_CONFIG_FILE"
    exit 2
fi

# デフォルト設定ファイルの存在確認（オプション、診断メッセージ）
if [[ ! -f "$DEFAULTS_CONFIG_FILE" ]]; then
    echo "Warning: defaults.toml not found: $DEFAULTS_CONFIG_FILE (default values will not be applied)" >&2
fi

# toml-reader.sh の共有ライブラリを利用（bootstrap.sh 経由で既にロード済み）
# dasel v2/v3 互換ロジックは toml-reader.sh の aidlc_detect_dasel_version / aidlc_read_toml に委譲
# bootstrap.sh が toml-reader.sh を source し、_AIDLC_DASEL_BRACKET を設定済み

# 設定値を取得（存在チェック付き）— toml-reader.sh の aidlc_read_toml に委譲
# 戻り値: 0=存在, 1=不在, 2=エラー
# 標準出力: 値（存在する場合）
get_value() {
    local file="$1"
    local key="$2"

    # キー入力バリデーション
    if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]]; then
        emit_error "invalid-key-format" "Invalid key format: $key"
        return 2
    fi

    aidlc_read_toml "$file" "$key"
}

# クォート除去 — toml-reader.sh の aidlc_strip_quotes に委譲
strip_quotes() {
    aidlc_strip_quotes "$1"
}

# ============================================================
# resolve_key: 単一キーの値を4階層マージで解決する
# 引数: key（文字列）
# 標準出力: 解決された値（strip_quotes適用済み）
# 戻り値: 0=存在, 1=不在, 2=エラー
# ============================================================
resolve_key() {
    local key="$1"
    local final_value=""
    local value_exists=false

    # 0. デフォルト値から取得（オプション、優先度: 最低）
    if [[ -f "$DEFAULTS_CONFIG_FILE" ]]; then
        local defaults_value
        set +e
        defaults_value=$(get_value "$DEFAULTS_CONFIG_FILE" "$key")
        local defaults_exit_code=$?
        set -e

        case $defaults_exit_code in
            0)
                final_value="$defaults_value"
                value_exists=true
                ;;
            1)
                # キー不在（正常）
                ;;
            *)
                # デフォルト値ファイルのエラーは警告のみ（スキップ）
                echo "Warning: Failed to read defaults config file, skipping" >&2
                ;;
        esac
    fi

    # 1. HOME設定から値を取得（オプション、優先度: 低）
    if [[ -n "$HOME_CONFIG_FILE" && -f "$HOME_CONFIG_FILE" ]]; then
        local home_value
        set +e
        home_value=$(get_value "$HOME_CONFIG_FILE" "$key")
        local home_exit_code=$?
        set -e

        case $home_exit_code in
            0)
                final_value="$home_value"
                value_exists=true
                ;;
            1)
                # キー不在（正常）
                ;;
            *)
                # HOME設定ファイルのエラーは警告のみ（スキップ）
                echo "Warning: Failed to read home config file, skipping" >&2
                ;;
        esac
    fi

    # 2. プロジェクト設定から値を取得（必須、優先度: 中）
    local project_value
    set +e
    project_value=$(get_value "$PROJECT_CONFIG_FILE" "$key")
    local project_exit_code=$?
    set -e

    case $project_exit_code in
        0)
            final_value="$project_value"
            value_exists=true
            ;;
        1)
            # キー不在（正常）
            ;;
        *)
            # プロジェクト設定ファイルのエラーは致命的
            emit_error "project-config-read-failed" "Failed to read project config file"
            return 2
            ;;
    esac

    # 3. LOCAL設定から値を取得（オプション、優先度: 高）
    # 新名（aidlc.local.toml）を優先、旧名（aidlc.toml.local）にフォールバック
    local local_file=""
    if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
        local_file="$LOCAL_CONFIG_FILE"
    elif [[ -f "$LOCAL_CONFIG_FILE_LEGACY" ]]; then
        local_file="$LOCAL_CONFIG_FILE_LEGACY"
        echo "Warning: ${LOCAL_CONFIG_FILE_LEGACY} is deprecated. Please rename to ${LOCAL_CONFIG_FILE}" >&2
    fi

    if [[ -n "$local_file" ]]; then
        local local_value
        set +e
        local_value=$(get_value "$local_file" "$key")
        local local_exit_code=$?
        set -e

        case $local_exit_code in
            0)
                # .localにキーが存在すれば上書き（空文字でも上書き）
                final_value="$local_value"
                value_exists=true
                ;;
            1)
                # キー不在（.localにはない、前の値を使用）
                ;;
            *)
                # .localファイルのエラーは警告のみ（前の値にフォールバック）
                echo "Warning: Failed to read local config file, using previous value" >&2
                ;;
        esac
    fi

    # 値の出力
    if [[ "$value_exists" == "true" ]]; then
        strip_quotes "$final_value"
        return 0
    else
        return 1
    fi
}

# ============================================================
# メイン処理
# ============================================================
if [[ "$MODE" == "single" ]]; then
    # 単一キーモード（従来互換）
    set +e
    resolved_value=$(resolve_key "$KEY")
    resolve_exit_code=$?
    set -e

    case $resolve_exit_code in
        0)
            printf '%s\n' "$resolved_value"
            exit 0
            ;;
        1)
            # キー不在
            exit 1
            ;;
        *)
            exit 2
            ;;
    esac
else
    # バッチモード（--keys）
    found_count=0
    output_buffer=""

    for key in "${KEYS[@]}"; do
        set +e
        resolved_value=$(resolve_key "$key")
        resolve_exit_code=$?
        set -e

        case $resolve_exit_code in
            0)
                output_buffer+="${key}:${resolved_value}"$'\n'
                found_count=$((found_count + 1))
                ;;
            1)
                # キー不在 → スキップ（他のキーに影響しない）
                ;;
            *)
                # エラー → 即時終了（部分出力を防ぐ）
                exit 2
                ;;
        esac
    done

    if [[ $found_count -gt 0 ]]; then
        # 末尾の改行を除いて出力
        printf '%s\n' "${output_buffer%$'\n'}"
        exit 0
    else
        exit 1
    fi
fi
