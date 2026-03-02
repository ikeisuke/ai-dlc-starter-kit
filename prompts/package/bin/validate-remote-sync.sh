#!/usr/bin/env bash
#
# validate-remote-sync.sh - 互換ラッパー（非推奨）
#
# このスクリプトは validate-git.sh remote-sync に委譲します。
# 今後は validate-git.sh remote-sync を直接使用してください。
#

set -euo pipefail

if [ "${AIDLC_SUPPRESS_DEPRECATION:-}" != "1" ]; then
    echo "deprecated:validate-remote-sync.sh:use validate-git.sh remote-sync" >&2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/validate-git.sh" remote-sync
