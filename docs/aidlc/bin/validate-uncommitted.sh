#!/usr/bin/env bash
#
# validate-uncommitted.sh - 未コミット変更の検出
#
# 使用方法:
#   ./validate-uncommitted.sh
#
# 出力形式:
#   status:{ok|warning|error}
#   - ok: 未コミット変更なし
#   - warning: 未コミット変更あり
#   - error: 検証失敗
#
#   warning時の追加出力:
#   files_count:{件数}
#   file:{porcelain行}（複数行可）
#
#   error時の追加出力:
#   error:{git-status-failed}
#
# 終了コード:
#   0: 正常終了（ok/warning）
#   1: エラー
#

set -euo pipefail

FILES=$(git status --porcelain 2>/dev/null) || {
    echo "status:error"
    echo "error:git-status-failed"
    echo "Error: git status --porcelain failed" >&2
    exit 1
}

if [ -z "$FILES" ]; then
    echo "status:ok"
else
    COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
    echo "status:warning"
    echo "files_count:${COUNT}"
    echo "$FILES" | while IFS= read -r line; do
        echo "file:${line}"
    done
fi
