#!/usr/bin/env bash
#
# read-version.sh - スキルバージョンの読み取り
#
# 使用方法:
#   ./read-version.sh
#
# 出力:
#   stdout: バージョン文字列（例: 2.0.5）
#
# 終了コード:
#   0: 成功
#   1: version.txt が見つからない
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/../version.txt"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Error: version.txt not found at $VERSION_FILE" >&2
  exit 1
fi

cat "$VERSION_FILE" | tr -d '[:space:]'
