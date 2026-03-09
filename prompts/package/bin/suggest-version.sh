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
# all_cycles:v1.12.0,v1.12.1,feature-auth

set -euo pipefail

# ブランチ名からバージョン推測
# 出力: "version\tcycle_name" 形式（TAB区切り）
# 例: "v1.0.0\t" (名前なし), "v1.0.0\twaf" (名前付き)
get_branch_version() {
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")

    if [[ "$branch" =~ ^cycle/(([^/]+/)?(v([0-9]+\.[0-9]+\.[0-9]+)))$ ]]; then
        # BASH_REMATCH[1] = "waf/v1.0.0" or "v1.0.0" (全体)
        # BASH_REMATCH[2] = "waf/" or "" (名前部分+スラッシュ)
        # BASH_REMATCH[3] = "v1.0.0" (v付きバージョン)
        # BASH_REMATCH[4] = "1.0.0" (数字部分のみ)
        local cycle_name="${BASH_REMATCH[2]%/}"  # 末尾スラッシュを除去
        printf '%s\t%s' "${BASH_REMATCH[3]}" "${cycle_name}"
    else
        printf '\t'
    fi
}

# 最新サイクルを取得
# 引数: $1=サイクル名（名前付きの場合）。空文字の場合は名前なし（従来動作）
get_latest_cycle() {
    local cycle_name="${1:-}"
    local cycles scan_dir
    if [[ -n "$cycle_name" ]]; then
        # 名前付き: docs/cycles/[name]/v*/ をスキャン
        scan_dir="docs/cycles/${cycle_name}"
    else
        # 名前なし: docs/cycles/v*/ をスキャン（従来動作）
        scan_dir="docs/cycles"
    fi

    cycles=$(ls -d "${scan_dir}"/v*/ 2>/dev/null | grep -E '/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)/$' | sort -V | tail -1 || echo "")

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
    # SemVer拡張部分を除去（prerelease: -xxx, build metadata: +xxx）
    local base_version
    base_version=$(printf '%s' "$version" | sed 's/^v//' | sed 's/[-+].*//')
    # v1.2.3 -> 1 2 3
    printf '%s' "$base_version" | tr '.' ' '
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
        *)
            echo "error: unknown version type: $type" >&2
            return 1
            ;;
    esac
}

# 全サイクルを列挙（SemVer・非SemVer問わず）
# 名前付きサイクルは [name]/vX.X.X 形式で含む
get_all_cycles() {
    local result=()
    local dir_name parent_name

    for dir in docs/cycles/*/; do
        [[ ! -d "$dir" ]] && continue
        dir_name=$(basename "$dir")
        # 非サイクルディレクトリを除外
        case "$dir_name" in
            backlog|backlog-completed) continue ;;
        esac
        # 名前付きサイクルのサブディレクトリをチェック
        if [[ "$dir_name" =~ ^v[0-9] ]]; then
            # 従来形式のバージョンディレクトリ
            result+=("$dir_name")
        else
            # 名前ディレクトリの場合、中のバージョンディレクトリを列挙
            local has_version_subdir=false
            for subdir in "${dir}"*/; do
                [[ ! -d "$subdir" ]] && continue
                local sub_name
                sub_name=$(basename "$subdir")
                if [[ "$sub_name" =~ ^v[0-9] ]]; then
                    result+=("${dir_name}/${sub_name}")
                    has_version_subdir=true
                fi
            done
            # バージョンサブディレクトリがない場合のみ名前ディレクトリ自体を含める
            if [[ "$has_version_subdir" == false ]]; then
                result+=("$dir_name")
            fi
        fi
    done

    # カンマ区切りで出力
    local IFS=','
    echo "${result[*]}"
}

# メイン処理
main() {
    local branch_version latest_cycle all_cycles
    local suggested_patch suggested_minor suggested_major

    local branch_info cycle_name
    branch_info=$(get_branch_version)
    branch_version="${branch_info%%	*}"   # TAB前: バージョン
    cycle_name="${branch_info#*	}"        # TAB後: サイクル名
    latest_cycle=$(get_latest_cycle "$cycle_name")
    all_cycles=$(get_all_cycles)

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
    echo "all_cycles:${all_cycles}"
}

main "$@"
