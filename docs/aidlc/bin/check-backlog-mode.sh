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
#
# 解決ロジック:
#   resolve-backlog-mode.sh の resolve_backlog_mode 関数で一元解決。
#   新キー（rules.backlog.mode）優先、旧キー（backlog.mode）フォールバック。
#   dasel未インストール時もgrep/sedで解決し、常に有効値を返す。
#

set -euo pipefail

# resolve-backlog-mode.sh を source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/resolve-backlog-mode.sh"

MODE=$(resolve_backlog_mode)
echo "backlog_mode:${MODE}"
