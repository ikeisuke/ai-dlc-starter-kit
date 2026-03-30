#!/usr/bin/env bash
#
# resolve-backlog-mode.sh - バックログモード解決共通ロジック
#
# 使用方法:
#   source resolve-backlog-mode.sh
#   mode=$(resolve_backlog_mode)
#
# 公開関数:
#   resolve_backlog_mode - 常に "issue" を返す（バックログはGitHub Issue固定）
#
# v2.0.3以降、backlog_mode設定は廃止されました。
# 旧設定（[rules.backlog].mode または [backlog].mode）が残っている場合は
# stderrに警告を出力しますが、戻り値は常に "issue" です。
#

# バックログモードを解決（常に "issue" を返す）
# 引数: なし
# stdout: "issue"（固定）
# stderr: 旧設定が残っている場合に警告
resolve_backlog_mode() {
    local config_file="${AIDLC_CONFIG:-}"

    # 設定ファイルが存在しない場合はそのまま返す
    if [[ -f "$config_file" ]]; then
        # 旧設定の検出（警告のため）
        local has_old_setting=false

        if grep -qE '^\[rules\.backlog\]' "$config_file" 2>/dev/null; then
            has_old_setting=true
        elif grep -qE '^\[backlog\]' "$config_file" 2>/dev/null; then
            has_old_setting=true
        fi

        if [[ "$has_old_setting" == true ]]; then
            echo "Warning: [rules.backlog] setting is deprecated (v2.0.3). Backlog is now always managed via GitHub Issues. You can safely remove the [rules.backlog] section from your config.toml." >&2
        fi
    fi

    echo "issue"
    return 0
}
