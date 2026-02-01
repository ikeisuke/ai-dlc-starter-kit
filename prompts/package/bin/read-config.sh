#!/usr/bin/env bash
#
# read-config.sh - 設定値を読み込み（.localファイルとのマージ対応）
#
# 使用方法:
#   ./read-config.sh <key> [--default <value>]
#
# パラメータ:
#   key       - ドット区切りの設定キー（例: rules.mcp_review.mode）
#   --default - キーが存在しない場合のデフォルト値（文字列のみ）
#
# 終了コード:
#   0 - 値あり（設定値またはデフォルト値を出力）
#   1 - キー不在（デフォルトなし、何も出力しない）
#   2 - エラー（dasel未インストール等）
#
# マージルール:
#   1. docs/aidlc.toml を読み込み（ベース設定）
#   2. docs/aidlc.toml.local が存在すれば読み込み
#   3. .local の値が存在するキーはベースを上書き
#   4. 配列は完全置換（マージしない）
#   5. ネストされたテーブルは再帰的にマージ
#   6. 型不一致時は .local の値が勝つ
#
# 使用例:
#   ./read-config.sh rules.mcp_review.mode
#   ./read-config.sh rules.custom.foo --default "bar"
#

set -euo pipefail

CONFIG_FILE="docs/aidlc.toml"
CONFIG_LOCAL_FILE="docs/aidlc.toml.local"

# 引数パース
KEY=""
DEFAULT_VALUE=""
HAS_DEFAULT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --default)
            if [[ $# -lt 2 ]]; then
                echo "Error: --default requires a value" >&2
                exit 2
            fi
            DEFAULT_VALUE="$2"
            HAS_DEFAULT=true
            shift 2
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 2
            ;;
        *)
            if [[ -z "$KEY" ]]; then
                KEY="$1"
            else
                echo "Error: Multiple keys specified" >&2
                exit 2
            fi
            shift
            ;;
    esac
done

if [[ -z "$KEY" ]]; then
    echo "Error: Key is required" >&2
    echo "Usage: $0 <key> [--default <value>]" >&2
    exit 2
fi

# daselの存在確認
if ! command -v dasel >/dev/null 2>&1; then
    echo "Error: dasel is not installed" >&2
    exit 2
fi

# 設定ファイルの存在確認
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE" >&2
    exit 2
fi

# 設定値を取得（存在チェック付き）
# 戻り値: 0=存在, 1=不在, 2=エラー
# 標準出力: 値（存在する場合）
# 注意: この関数は set -e 環境下でも安全に呼び出せる
get_value() {
    local file="$1"
    local key="$2"
    local result
    local dasel_exit_code
    local err_file="/tmp/aidlc_dasel_err_$$_$RANDOM"

    # daselを実行（エラーはファイルにリダイレクト）
    result=$(cat "$file" 2>"$err_file" | dasel -i toml "$key" 2>>"$err_file") || dasel_exit_code=$?
    dasel_exit_code=${dasel_exit_code:-0}

    # エラー内容を確認
    local err_content=""
    if [[ -f "$err_file" ]]; then
        err_content=$(cat "$err_file" 2>/dev/null) || true
        \rm -f "$err_file" 2>/dev/null || true
    fi

    if [[ $dasel_exit_code -eq 0 ]]; then
        printf '%s\n' "$result"
        return 0
    else
        # daselの終了コード非0は「キー不在」または「エラー」
        # エラー内容に "not found" が含まれていればキー不在
        if [[ "$err_content" == *"not found"* ]]; then
            return 1  # キー不在
        else
            return 2  # その他のエラー（パースエラー等）
        fi
    fi
}

# daselの出力からクォートを除去（先頭・末尾のシングル/ダブルクォート）
strip_quotes() {
    local value="$1"
    # 先頭と末尾がシングルクォートの場合
    if [[ "$value" =~ ^\'.*\'$ ]]; then
        printf '%s\n' "${value:1:${#value}-2}"
    # 先頭と末尾がダブルクォートの場合
    elif [[ "$value" =~ ^\".*\"$ ]]; then
        printf '%s\n' "${value:1:${#value}-2}"
    else
        printf '%s\n' "$value"
    fi
}

# ベース設定から値を取得
BASE_VALUE=""
BASE_EXISTS=false
BASE_ERROR=false

set +e
get_value "$CONFIG_FILE" "$KEY" > /tmp/aidlc_base_value_$$
base_exit_code=$?
set -e

case $base_exit_code in
    0)
        BASE_VALUE=$(cat /tmp/aidlc_base_value_$$)
        BASE_EXISTS=true
        ;;
    1)
        # キー不在（正常）
        ;;
    *)
        # エラー
        BASE_ERROR=true
        ;;
esac
\rm -f /tmp/aidlc_base_value_$$ 2>/dev/null

if [[ "$BASE_ERROR" == "true" ]]; then
    echo "Error: Failed to read base config file" >&2
    exit 2
fi

# .localファイルが存在すれば、そちらの値を優先
LOCAL_EXISTS=false
if [[ -f "$CONFIG_LOCAL_FILE" ]]; then
    set +e
    get_value "$CONFIG_LOCAL_FILE" "$KEY" > /tmp/aidlc_local_value_$$
    local_exit_code=$?
    set -e

    case $local_exit_code in
        0)
            # .localにキーが存在すれば上書き（空文字でも上書き）
            BASE_VALUE=$(cat /tmp/aidlc_local_value_$$)
            LOCAL_EXISTS=true
            BASE_EXISTS=true  # 値は存在する扱い
            ;;
        1)
            # キー不在（.localにはない、ベース値を使用）
            ;;
        *)
            # .localファイルのエラーは警告のみ（ベース値にフォールバック）
            echo "Warning: Failed to read local config file, using base config" >&2
            ;;
    esac
    \rm -f /tmp/aidlc_local_value_$$ 2>/dev/null
fi

# 値の出力
if [[ "$BASE_EXISTS" == "true" ]]; then
    # 値が存在する場合
    strip_quotes "$BASE_VALUE"
    exit 0
else
    # 値が存在しない場合
    if [[ "$HAS_DEFAULT" == "true" ]]; then
        printf '%s\n' "$DEFAULT_VALUE"
        exit 0
    else
        # デフォルトなし、キー不在
        exit 1
    fi
fi
