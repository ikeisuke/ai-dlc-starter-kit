#!/usr/bin/env bash
#
# detect-missing-keys.sh - config.toml の欠落キー検出
#
# defaults.toml をスキーマとして config.toml に欠落しているリーフキーを検出する。
#
# 使用方法:
#   ./detect-missing-keys.sh --defaults <path> --config <path> [--dry-run]
#
# 出力形式（stdout、タブ区切り）:
#   missing\t<key>\t<default_value>   欠落キー（値はdasel生出力、クォート除去済み）
#   migrate\t<key>\t<default_value>   旧キーで充足済み、新キーへの移行推奨
#   summary\ttotal\t<N>               欠落キー総数（missing + migrate）
#
# 対応値型: boolean, integer, string, array（dasel生出力をそのまま使用）
# インラインテーブル・ネストテーブルはリーフキー列挙で展開されるため非対象
#
# 終了コード:
#   0: 正常完了（欠落キーの有無に関わらず）
#   1: ファイル不在エラー
#   2: dasel 未インストールまたは実行エラー
#

set -euo pipefail

# --- 引数解析 ---
DEFAULTS_PATH=""
CONFIG_PATH=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --defaults)
            DEFAULTS_PATH="$2"
            shift 2
            ;;
        --config)
            CONFIG_PATH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "error:unknown-arg:$1" >&2
            exit 2
            ;;
    esac
done

if [[ -z "$DEFAULTS_PATH" || -z "$CONFIG_PATH" ]]; then
    echo "error:missing-args:--defaults and --config are required" >&2
    exit 2
fi

# --- ファイル存在確認 ---
if [[ ! -f "$DEFAULTS_PATH" ]]; then
    printf 'error\tdefaults-not-found\t%s\n' "$DEFAULTS_PATH"
    exit 1
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
    printf 'error\tconfig-not-found\t%s\n' "$CONFIG_PATH"
    exit 1
fi

# --- key-aliases.sh の読み込み（エイリアス解決用） ---
# aidlc スキルの lib/ からロード（aidlc-setup と同じプラグインルート配下にある前提）
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_AIDLC_LIB_DIR="${_SCRIPT_DIR}/../../aidlc/scripts/lib"
if [[ -f "${_AIDLC_LIB_DIR}/key-aliases.sh" ]]; then
    source "${_AIDLC_LIB_DIR}/key-aliases.sh"
    _HAS_ALIASES=true
else
    _HAS_ALIASES=false
fi

# --- dasel 存在確認 ---
if ! command -v dasel >/dev/null 2>&1; then
    printf 'error\tdasel-not-found\tdasel is not installed\n'
    exit 2
fi

# --- dasel v2/v3 ブラケット記法検出 ---
USE_BRACKET="false"
_test_data=$(printf '[t]\nv = 1')
if printf '%s' "$_test_data" | dasel -i toml 't.v' >/dev/null 2>&1; then
    if printf '%s' "$_test_data" | dasel -i toml 't["v"]' >/dev/null 2>&1; then
        USE_BRACKET="true"
    fi
fi

# --- dasel キー変換 ---
_dasel_key() {
    local key="$1"
    if [[ "$USE_BRACKET" == "true" ]]; then
        printf '%s' "$key" | sed 's/\.\([^.]*\)/["\1"]/g'
    else
        printf '%s' "$key"
    fi
}

# --- クォート除去 ---
_strip_quotes() {
    local val="$1"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    val="${val#\"}"
    val="${val%\"}"
    val="${val#\'}"
    val="${val%\'}"
    echo "$val"
}

# --- defaults.toml からリーフキーを列挙 ---
# TOML の [section] ヘッダとキー行をパースしてフラットなドット区切りキーを生成
_enumerate_leaf_keys() {
    local file="$1"
    local current_section=""

    while IFS= read -r line; do
        # 空行・コメント行をスキップ
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # セクションヘッダ: [section.name]
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            current_section="${BASH_REMATCH[1]}"
            continue
        fi

        # キー = 値 の行
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*= ]]; then
            local key_name="${BASH_REMATCH[1]}"
            if [[ -n "$current_section" ]]; then
                echo "${current_section}.${key_name}"
            else
                echo "${key_name}"
            fi
        fi
    done < "$file"
}

# --- config.toml の読み取り可能性を事前チェック ---
_config_content=$(cat "$CONFIG_PATH" 2>/dev/null) || {
    printf 'error\tconfig-read-failed\tcannot read %s\n' "$CONFIG_PATH"
    exit 2
}

# dasel でパースできるか検証（トップレベルキーの存在を確認）
if ! printf '%s' "$_config_content" | dasel -i toml '.' >/dev/null 2>&1; then
    printf 'error\tconfig-parse-failed\t%s is not valid TOML\n' "$CONFIG_PATH"
    exit 2
fi

# --- メイン処理 ---
MISSING_COUNT=0

while IFS= read -r leaf_key; do
    [[ -z "$leaf_key" ]] && continue

    # config.toml に存在するか確認
    dasel_key=$(_dasel_key "$leaf_key")
    if ! printf '%s' "$_config_content" | dasel -i toml "$dasel_key" >/dev/null 2>&1; then
        # エイリアス（旧キー）で充足されているか確認
        _status="missing"
        if [[ "$_HAS_ALIASES" == "true" ]]; then
            _legacy_key=$(aidlc_get_legacy_key "$leaf_key")
            if [[ -n "$_legacy_key" ]]; then
                _legacy_dasel_key=$(_dasel_key "$_legacy_key")
                if printf '%s' "$_config_content" | dasel -i toml "$_legacy_dasel_key" >/dev/null 2>&1; then
                    _status="migrate"
                fi
            fi
        fi

        # デフォルト値を取得
        defaults_dasel_key=$(_dasel_key "$leaf_key")
        default_val=""
        default_val=$(cat "$DEFAULTS_PATH" 2>/dev/null | dasel -i toml "$defaults_dasel_key" 2>/dev/null) || default_val="(unknown)"
        default_val=$(_strip_quotes "$default_val")
        printf '%s\t%s\t%s\n' "${_status}" "${leaf_key}" "${default_val}"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done < <(_enumerate_leaf_keys "$DEFAULTS_PATH")

printf 'summary\ttotal\t%s\n' "${MISSING_COUNT}"
exit 0
