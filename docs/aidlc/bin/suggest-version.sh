#!/usr/bin/env bash
# suggest-version.sh - サイクルバージョンの推測・提案
#
# 機能:
# - ブランチ名からバージョン推測
# - 既存サイクルの一覧取得
# - 次バージョンの候補を提案
#
# 出力形式:
# branch_version:v1.12.1
# latest_cycle:v1.12.0
# suggested_patch:v1.12.1
# suggested_minor:v1.13.0
# suggested_major:v2.0.0

set -euo pipefail

# ブランチ名からバージョン推測
get_branch_version() {
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")

    if [[ "$branch" =~ ^cycle/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        echo "v${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# 最新サイクルを取得
get_latest_cycle() {
    local cycles
    cycles=$(ls -d docs/cycles/v*/ 2>/dev/null | sort -V | tail -1 || echo "")

    if [[ -n "$cycles" ]]; then
        # ディレクトリ名からバージョンを抽出
        basename "$cycles" | sed 's/\/$//'
    else
        echo ""
    fi
}

# バージョンをパース
parse_version() {
    local version="$1"
    # v1.2.3 -> 1 2 3
    echo "$version" | sed 's/^v//' | tr '.' ' '
}

# 次バージョンを計算
# 引数: $1=バージョン, $2=タイプ(patch|minor|major)
calculate_next_version() {
    local version="$1"
    local type="$2"
    local major minor patch

    if [[ -z "$version" ]]; then
        # バージョンがない場合は v1.0.0 を提案
        echo "v1.0.0"
        return
    fi

    read -r major minor patch <<< "$(parse_version "$version")"

    case "$type" in
        patch)
            echo "v${major}.${minor}.$((patch + 1))"
            ;;
        minor)
            echo "v${major}.$((minor + 1)).0"
            ;;
        major)
            echo "v$((major + 1)).0.0"
            ;;
    esac
}

# メイン処理
main() {
    local branch_version latest_cycle
    local suggested_patch suggested_minor suggested_major

    branch_version=$(get_branch_version)
    latest_cycle=$(get_latest_cycle)

    # 次バージョンの計算（最新サイクルがある場合はそれを基準に）
    if [[ -n "$latest_cycle" ]]; then
        suggested_patch=$(calculate_next_version "$latest_cycle" "patch")
        suggested_minor=$(calculate_next_version "$latest_cycle" "minor")
        suggested_major=$(calculate_next_version "$latest_cycle" "major")
    else
        suggested_patch="v1.0.0"
        suggested_minor="v1.0.0"
        suggested_major="v1.0.0"
    fi

    # 出力
    echo "branch_version:${branch_version}"
    echo "latest_cycle:${latest_cycle}"
    echo "suggested_patch:${suggested_patch}"
    echo "suggested_minor:${suggested_minor}"
    echo "suggested_major:${suggested_major}"
}

main "$@"
