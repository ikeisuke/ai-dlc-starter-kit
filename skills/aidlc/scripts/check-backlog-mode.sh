#!/usr/bin/env bash
#
# check-backlog-mode.sh - バックログモード設定を確認
#
# 使用方法:
#   ./check-backlog-mode.sh
#
# 出力形式:
#   backlog_mode:issue（固定）
#
# v2.0.3以降、バックログは常にGitHub Issueに記録されます。
# このスクリプトは後方互換性のために残されていますが、
# 常に "issue" を返します。
#

set -euo pipefail

# resolve-backlog-mode.sh を source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"
source "${SCRIPT_DIR}/resolve-backlog-mode.sh"

MODE=$(resolve_backlog_mode)
echo "backlog_mode:${MODE}"
