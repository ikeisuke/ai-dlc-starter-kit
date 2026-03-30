#!/usr/bin/env bash
#
# toml-reader.sh - dasel v2/v3 互換のTOML値取得共有ライブラリ
#
# bootstrap.sh と read-config.sh の両方から利用可能。
# bootstrap.sh に依存しない（ファイルパスは引数で受け取る）。
#
# 提供する関数:
#   aidlc_detect_dasel_version  - dasel v2/v3 ブラケット記法判定
#   aidlc_read_toml             - 指定ファイルから指定キーの値を取得
#
# 前提: 呼び出し元が set -euo pipefail を設定していること。
#

# --- クォート除去（bootstrap.sh と共有） ---
# bootstrap.sh で既に定義されている場合はスキップ
if ! declare -f aidlc_strip_quotes >/dev/null 2>&1; then
    aidlc_strip_quotes() {
        local val="$1"
        val="${val#"${val%%[![:space:]]*}"}"
        val="${val%"${val##*[![:space:]]}"}"
        val="${val#\"}"
        val="${val%\"}"
        val="${val#\'}"
        val="${val%\'}"
        echo "$val"
    }
fi

# --- dasel バージョン検出 ---
# グローバル変数 _AIDLC_DASEL_BRACKET を設定する
# "true" = v3 ブラケット記法、"false" = v2 ドット記法
# 終了コード: 0=dasel利用可能、2=dasel未インストール
aidlc_detect_dasel_version() {
    if [[ -n "${_AIDLC_DASEL_BRACKET:-}" ]]; then
        return 0  # 既に検出済み
    fi

    if ! command -v dasel >/dev/null 2>&1; then
        return 2
    fi

    _AIDLC_DASEL_BRACKET="false"
    local test_data
    test_data=$(printf '[t]\nv = 1')
    if printf '%s' "$test_data" | dasel -i toml 't.v' >/dev/null 2>&1; then
        if printf '%s' "$test_data" | dasel -i toml 't["v"]' >/dev/null 2>&1; then
            _AIDLC_DASEL_BRACKET="true"
        fi
    fi

    export _AIDLC_DASEL_BRACKET
    return 0
}

# --- TOML値取得 ---
# 指定ファイルから指定キーの値を取得する
# 引数:
#   $1 (file): TOMLファイルパス
#   $2 (key): ドット区切りキー（例: paths.aidlc_dir）
# 出力: stdout に値を出力（クォート除去済み）
# 終了コード: 0=値取得成功、1=キー不在、2=ファイル不在またはdaselエラー
aidlc_read_toml() {
    local file="$1"
    local key="$2"

    # ファイル存在確認
    if [[ ! -f "$file" ]]; then
        return 2
    fi

    # キー入力バリデーション
    if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]]; then
        return 2
    fi

    # dasel バージョン検出（未実施の場合）
    if [[ -z "${_AIDLC_DASEL_BRACKET:-}" ]]; then
        aidlc_detect_dasel_version || return 2
    fi

    # dasel v3 予約語回避: ブラケット記法変換
    local escaped_key
    if [[ "${_AIDLC_DASEL_BRACKET}" == "true" ]]; then
        escaped_key=$(printf '%s' "$key" | sed 's/\.\([^.]*\)/["\1"]/g')
    else
        escaped_key="$key"
    fi

    # dasel 実行
    local result
    local dasel_exit_code
    local err_file
    err_file=$(mktemp) || return 2

    result=$(cat "$file" 2>"$err_file" | dasel -i toml "$escaped_key" 2>>"$err_file") || dasel_exit_code=$?
    dasel_exit_code=${dasel_exit_code:-0}

    local err_content=""
    if [[ -f "$err_file" ]]; then
        err_content=$(cat "$err_file" 2>/dev/null) || true
        \rm -f "$err_file" 2>/dev/null || true
    fi

    if [[ $dasel_exit_code -eq 0 ]]; then
        # クォート除去して出力
        aidlc_strip_quotes "$result"
        return 0
    else
        if [[ "$err_content" == *"not found"* ]]; then
            return 1  # キー不在
        else
            return 2  # その他のエラー
        fi
    fi
}
