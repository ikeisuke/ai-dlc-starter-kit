#!/usr/bin/env bash
#
# resolve-backlog-mode.sh - バックログモード解決共通ロジック
#
# 使用方法:
#   source resolve-backlog-mode.sh
#   mode=$(resolve_backlog_mode)
#
# 公開関数:
#   resolve_backlog_mode - バックログモードを解決してstdoutに出力
#
# 解決優先順序:
#   1. rules.backlog.mode（新キー）が有効値 → 採用
#   2. rules.backlog.mode が不正値/未定義 → backlog.mode（旧キー）を評価
#   3. backlog.mode が有効値 → 採用
#   4. backlog.mode も不正値/未定義 → デフォルト "git"
#   5. 新旧両方存在かつ値不一致 → stderrに警告（新キーの値を使用）
#

# 有効なバックログモード値
_VALID_BACKLOG_MODES="git issue git-only issue-only"

# 値が有効なバックログモードか検証
# 引数: $1=値
# 戻り値: 0=有効, 1=無効
_is_valid_backlog_mode() {
    local value="$1"
    case "$value" in
        git|issue|git-only|issue-only)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# daselで設定値を読み取る
# 引数: $1=設定ファイル, $2=キー
# 戻り値: 0=成功, 1=失敗
# stdout: 読み取った値（クォート除去済み）
_read_toml_value_dasel() {
    local file="$1"
    local key="$2"
    local result
    result=$(cat "$file" 2>/dev/null | dasel -i toml "$key" 2>/dev/null | tr -d "'" | tr -d '"') || return 1
    [[ -n "$result" ]] && echo "$result" || return 1
}

# grep/sedで設定値を読み取る（dasel未インストール時のフォールバック）
# 引数: $1=設定ファイル, $2=セクション名（[rules.backlog] or [backlog]）
# 戻り値: 0=成功, 1=失敗
# stdout: 読み取った値
_read_toml_value_grep() {
    local file="$1"
    local section="$2"
    local result

    # セクションから次のセクション（または末尾）までを抽出し、mode = の値を取得
    result=$(sed -n "/^\\[${section}\\]/,/^\\[/p" "$file" 2>/dev/null \
        | grep -E '^[[:space:]]*mode[[:space:]]*=' \
        | head -1 \
        | awk -F'=' '{gsub(/#.*$/, "", $2); gsub(/[" \t'\''"]/, "", $2); print $2}') || return 1
    [[ -n "$result" ]] && echo "$result" || return 1
}

# バックログモードを解決
# 引数: なし
# stdout: git, issue, git-only, issue-only のいずれか（デフォルト: git）
# stderr: 新旧キー競合時の警告
resolve_backlog_mode() {
    local config_file="docs/aidlc.toml"
    local new_value=""
    local old_value=""
    local has_dasel=false

    # 設定ファイルが存在しない場合はデフォルト
    if [[ ! -f "$config_file" ]]; then
        echo "git"
        return 0
    fi

    # dasel利用可否判定
    if command -v dasel >/dev/null 2>&1; then
        has_dasel=true
    fi

    # 新キー（rules.backlog.mode）の読み取り
    if [[ "$has_dasel" == true ]]; then
        new_value=$(_read_toml_value_dasel "$config_file" "rules.backlog.mode") || new_value=""
    else
        new_value=$(_read_toml_value_grep "$config_file" "rules\\.backlog") || new_value=""
    fi

    # 旧キー（backlog.mode）の読み取り
    if [[ "$has_dasel" == true ]]; then
        old_value=$(_read_toml_value_dasel "$config_file" "backlog.mode") || old_value=""
    else
        old_value=$(_read_toml_value_grep "$config_file" "backlog") || old_value=""
    fi

    # 新旧競合チェック（両方存在かつ値不一致の場合に警告）
    if [[ -n "$new_value" && -n "$old_value" && "$new_value" != "$old_value" ]]; then
        if _is_valid_backlog_mode "$new_value" && _is_valid_backlog_mode "$old_value"; then
            echo "Warning: Both [rules.backlog].mode and [backlog].mode exist with different values. Using [rules.backlog].mode." >&2
        fi
    fi

    # 新キーが有効値なら採用
    if _is_valid_backlog_mode "$new_value"; then
        echo "$new_value"
        return 0
    fi

    # 旧キーが有効値なら採用
    if _is_valid_backlog_mode "$old_value"; then
        echo "$old_value"
        return 0
    fi

    # 最終フォールバック
    echo "git"
    return 0
}
