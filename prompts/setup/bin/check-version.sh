#!/usr/bin/env bash
#
# check-version.sh - プロジェクトとスターターキットのバージョンを比較
#
# 使用方法:
#   ./check-version.sh
#
# 出力形式:
#   version_status:{状態}
#   - current: 同じバージョン
#   - upgrade_available:{project}:{kit}: アップグレード可能
#   - project_newer:{project}:{kit}: プロジェクトが新しい
#   - not_found: バージョン情報取得不可
#   - (空): dasel未インストール（AIに委ねる）
#
# エッジケース:
#   - dasel未インストール: version_status: を出力（AIに委ねる）
#   - バージョン情報なし: version_status:not_found を出力
#   - 空文字バージョン: version_status:not_found を出力
#

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 設定ファイルパス
CONFIG_FILE="docs/aidlc.toml"
VERSION_FILE="${SCRIPT_DIR}/../../../version.txt"

# daselの存在確認
if ! command -v dasel >/dev/null 2>&1; then
    echo "version_status:"
    exit 0
fi

# スターターキットのバージョンを取得
if [ ! -f "$VERSION_FILE" ]; then
    echo "version_status:not_found"
    exit 0
fi

KIT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')
if [ -z "$KIT_VERSION" ]; then
    echo "version_status:not_found"
    exit 0
fi

# セマンティックバージョン形式の検証（数字とドットのみ）
if ! echo "$KIT_VERSION" | grep -qE '^[0-9]+(\.[0-9]+){0,2}$'; then
    echo "version_status:not_found"
    exit 0
fi

# プロジェクトのバージョンを取得
if [ ! -f "$CONFIG_FILE" ]; then
    echo "version_status:not_found"
    exit 0
fi

PROJECT_VERSION=$(cat "$CONFIG_FILE" 2>/dev/null | dasel -i toml 'starter_kit_version' 2>/dev/null | tr -d "'" || echo "")

# 空文字、null、または無効なバージョン形式の場合は not_found
if [ -z "$PROJECT_VERSION" ] || [ "$PROJECT_VERSION" = "null" ]; then
    echo "version_status:not_found"
    exit 0
fi

# セマンティックバージョン形式の検証（数字とドットのみ）
if ! echo "$PROJECT_VERSION" | grep -qE '^[0-9]+(\.[0-9]+){0,2}$'; then
    echo "version_status:not_found"
    exit 0
fi

# バージョンを正規化（1.9 → 1.9.0）
normalize_version() {
    local version="$1"
    local parts
    IFS='.' read -ra parts <<< "$version"

    local major="${parts[0]:-0}"
    local minor="${parts[1]:-0}"
    local patch="${parts[2]:-0}"

    echo "${major}.${minor}.${patch}"
}

# セマンティックバージョン比較
# 戻り値: -1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
compare_versions() {
    local v1="$1"
    local v2="$2"

    local v1_normalized
    local v2_normalized
    v1_normalized=$(normalize_version "$v1")
    v2_normalized=$(normalize_version "$v2")

    local v1_parts
    local v2_parts
    IFS='.' read -ra v1_parts <<< "$v1_normalized"
    IFS='.' read -ra v2_parts <<< "$v2_normalized"

    for i in 0 1 2; do
        local p1="${v1_parts[$i]:-0}"
        local p2="${v2_parts[$i]:-0}"

        if [ "$p1" -lt "$p2" ]; then
            echo "-1"
            return
        elif [ "$p1" -gt "$p2" ]; then
            echo "1"
            return
        fi
    done

    echo "0"
}

# バージョン比較を実行
RESULT=$(compare_versions "$PROJECT_VERSION" "$KIT_VERSION")

case "$RESULT" in
    "0")
        echo "version_status:current"
        ;;
    "-1")
        echo "version_status:upgrade_available:${PROJECT_VERSION}:${KIT_VERSION}"
        ;;
    "1")
        echo "version_status:project_newer:${PROJECT_VERSION}:${KIT_VERSION}"
        ;;
esac
