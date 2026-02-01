#!/usr/bin/env bash
#
# read-config.sh - 設定値を読み込み（3階層マージ対応）
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
# 設定ファイル階層（優先度: 低→高）:
#   1. ~/.aidlc/config.toml - ユーザー共通設定（オプション）
#   2. docs/aidlc.toml - プロジェクト共有設定（必須）
#   3. docs/aidlc.toml.local - 個人設定（オプション）
#
# マージルール:
#   - 単一キーの値を取得（ファイル全体のマージではない）
#   - 後から読み込んだファイルにキーが存在すれば上書き
#   - 葉キー（末端の値）を問い合わせた場合のみ有効
#   - 親テーブルを直接取得した場合は最後のファイルの値が返される
#
# 使用例:
#   ./read-config.sh rules.mcp_review.mode
#   ./read-config.sh rules.custom.foo --default "bar"
#

set -euo pipefail

# 設定ファイルパス（優先度順: 低→高）
HOME_CONFIG_FILE="${HOME:+$HOME/.aidlc/config.toml}"
PROJECT_CONFIG_FILE="docs/aidlc.toml"
LOCAL_CONFIG_FILE="docs/aidlc.toml.local"

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

# プロジェクト設定ファイルの存在確認（必須）
if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $PROJECT_CONFIG_FILE" >&2
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

# 最終的な値を保持する変数
FINAL_VALUE=""
VALUE_EXISTS=false

# ============================================================
# 1. HOME設定から値を取得（オプション、優先度: 低）
# ============================================================
if [[ -n "$HOME_CONFIG_FILE" && -f "$HOME_CONFIG_FILE" ]]; then
    set +e
    get_value "$HOME_CONFIG_FILE" "$KEY" > /tmp/aidlc_home_value_$$
    home_exit_code=$?
    set -e

    case $home_exit_code in
        0)
            FINAL_VALUE=$(cat /tmp/aidlc_home_value_$$)
            VALUE_EXISTS=true
            ;;
        1)
            # キー不在（正常）
            ;;
        *)
            # HOME設定ファイルのエラーは警告のみ（スキップ）
            echo "Warning: Failed to read home config file, skipping" >&2
            ;;
    esac
    \rm -f /tmp/aidlc_home_value_$$ 2>/dev/null
fi

# ============================================================
# 2. プロジェクト設定から値を取得（必須、優先度: 中）
# ============================================================
set +e
get_value "$PROJECT_CONFIG_FILE" "$KEY" > /tmp/aidlc_project_value_$$
project_exit_code=$?
set -e

case $project_exit_code in
    0)
        FINAL_VALUE=$(cat /tmp/aidlc_project_value_$$)
        VALUE_EXISTS=true
        ;;
    1)
        # キー不在（正常）
        ;;
    *)
        # プロジェクト設定ファイルのエラーは致命的
        echo "Error: Failed to read project config file" >&2
        \rm -f /tmp/aidlc_project_value_$$ 2>/dev/null
        exit 2
        ;;
esac
\rm -f /tmp/aidlc_project_value_$$ 2>/dev/null

# ============================================================
# 3. LOCAL設定から値を取得（オプション、優先度: 高）
# ============================================================
if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
    set +e
    get_value "$LOCAL_CONFIG_FILE" "$KEY" > /tmp/aidlc_local_value_$$
    local_exit_code=$?
    set -e

    case $local_exit_code in
        0)
            # .localにキーが存在すれば上書き（空文字でも上書き）
            FINAL_VALUE=$(cat /tmp/aidlc_local_value_$$)
            VALUE_EXISTS=true
            ;;
        1)
            # キー不在（.localにはない、前の値を使用）
            ;;
        *)
            # .localファイルのエラーは警告のみ（前の値にフォールバック）
            echo "Warning: Failed to read local config file, using previous value" >&2
            ;;
    esac
    \rm -f /tmp/aidlc_local_value_$$ 2>/dev/null
fi

# ============================================================
# 値の出力
# ============================================================
if [[ "$VALUE_EXISTS" == "true" ]]; then
    # 値が存在する場合
    strip_quotes "$FINAL_VALUE"
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
