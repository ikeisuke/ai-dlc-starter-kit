#!/usr/bin/env bash
# check-defaults-sync.sh - defaults.toml の正本とコピーの同期チェック
#
# 正本 (skills/aidlc/config/defaults.toml) と
# コピー (skills/aidlc-setup/config/defaults.toml) の
# TOML設定値部分が一致することを検証する。
# コメント行(#)と空行の差異は許容する。
#
# 終了コード:
#   0 - 一致
#   1 - 不一致
#   2 - ファイル不在

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SOURCE="${REPO_ROOT}/skills/aidlc/config/defaults.toml"
COPY="${REPO_ROOT}/skills/aidlc-setup/config/defaults.toml"

if [ ! -f "$SOURCE" ]; then
    echo "error:not-found:$SOURCE"
    exit 2
fi

if [ ! -f "$COPY" ]; then
    echo "error:not-found:$COPY"
    exit 2
fi

# コメント行（先頭空白許容）と空行を除外して比較
diff_result=$(diff <(grep -v '^[[:space:]]*#' "$SOURCE" | grep -v '^[[:space:]]*$') \
                   <(grep -v '^[[:space:]]*#' "$COPY" | grep -v '^[[:space:]]*$') || true)

if [ -z "$diff_result" ]; then
    echo "sync:ok"
    exit 0
else
    echo "sync:mismatch"
    echo ""
    echo "以下の設定値に差分があります:"
    echo "$diff_result"
    echo ""
    echo "正本: $SOURCE"
    echo "コピー: $COPY"
    echo "正本の内容をコピーに同期してください。"
    exit 1
fi
