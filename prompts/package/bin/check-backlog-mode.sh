#!/usr/bin/env bash
#
# check-backlog-mode.sh - バックログモード設定を確認
#
# 使用方法:
#   ./check-backlog-mode.sh
#
# 出力形式:
#   backlog_mode:{モード値}
#   - git: ローカルファイル駆動（デフォルト）
#   - issue: GitHub Issue駆動
#   - git-only: ローカルファイルのみ
#   - issue-only: GitHub Issueのみ
#   - (空): dasel未インストール（AIが直接読み取り）
#
# エッジケース:
#   - dasel未インストール: backlog_mode: を出力（AIに委ねる）
#   - TOMLファイル不在: backlog_mode:git を出力（デフォルト）
#   - キー欠落/値不正: backlog_mode:git を出力（デフォルト）
#

set -euo pipefail

CONFIG_FILE="docs/aidlc.toml"

# daselの存在確認
if ! command -v dasel >/dev/null 2>&1; then
    echo "backlog_mode:"
    exit 0
fi

# 設定ファイルからバックログモードを取得
# 失敗時は "git" にフォールバック
MODE=$(cat "$CONFIG_FILE" 2>/dev/null | dasel -i toml 'backlog.mode' 2>/dev/null | tr -d "'" || echo "git")

# 空の場合はデフォルト値を使用
[ -z "$MODE" ] && MODE="git"

# 有効な値のみ許可、それ以外は "git" にフォールバック
case "$MODE" in
    git|issue|git-only|issue-only)
        # 有効な値
        ;;
    *)
        MODE="git"
        ;;
esac

echo "backlog_mode:${MODE}"
