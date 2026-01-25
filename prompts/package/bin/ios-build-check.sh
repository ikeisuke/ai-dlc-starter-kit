#!/bin/bash
# ios-build-check.sh - iOSプロジェクトのビルド番号を確認
#
# 使用方法:
#   docs/aidlc/bin/ios-build-check.sh [project.pbxproj path]
#
# 引数なしの場合、project.pbxprojを自動検索（Pods/DerivedData除外）
#
# 出力形式:
#   status:found|not-found|multiple
#   current_build:123        # status=foundの場合
#   previous_build:122       # status=foundの場合
#   comparison:updated|same|unknown  # status=foundの場合
#   files:file1,file2,...    # status=multipleの場合
#
# 終了コード:
#   0: 成功
#   1: エラー

set -euo pipefail

# デフォルトブランチを取得
get_default_branch() {
    local branch
    branch=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
    if [[ -n "$branch" ]]; then
        echo "$branch"
        return 0
    fi
    if git show-ref --verify "refs/remotes/origin/main" >/dev/null 2>&1; then
        echo "main"
        return 0
    fi
    if git show-ref --verify "refs/remotes/origin/master" >/dev/null 2>&1; then
        echo "master"
        return 0
    fi
    echo ""
    return 0
}

# CURRENT_PROJECT_VERSIONを抽出
extract_build_number() {
    local file="$1"
    local version
    # 最初のCURRENT_PROJECT_VERSIONを取得し、値を抽出
    version=$(grep "CURRENT_PROJECT_VERSION" "$file" 2>/dev/null | head -1 | sed 's/.*= *\([^;]*\);.*/\1/' | tr -d ' "')
    # 変数参照（$を含む）の場合は空を返す
    if [[ "$version" == *'$'* ]]; then
        echo ""
        return 0
    fi
    echo "$version"
}

# project.pbxprojファイルを検索
find_project_files() {
    find . -name "project.pbxproj" \
        -not -path "*/Pods/*" \
        -not -path "*/DerivedData/*" \
        -not -path "*/.build/*" \
        2>/dev/null || true
}

main() {
    local project_file="${1:-}"
    local files
    local file_count
    local default_branch
    local current_build
    local previous_build
    local git_path

    # 引数がない場合は自動検索
    if [[ -z "$project_file" ]]; then
        files=$(find_project_files)
        if [[ -z "$files" ]]; then
            file_count=0
        else
            file_count=$(echo "$files" | wc -l | tr -d ' ')
        fi

        if [[ "$file_count" -eq 0 ]]; then
            echo "status:not-found"
            exit 0
        elif [[ "$file_count" -gt 1 ]]; then
            echo "status:multiple"
            echo "files:$(echo "$files" | tr '\n' ',' | sed 's/,$//')"
            exit 0
        else
            project_file="$files"
        fi
    fi

    # ファイル存在確認
    if [[ ! -f "$project_file" ]]; then
        echo "status:not-found"
        exit 0
    fi

    echo "status:found"
    echo "file:$project_file"

    # 現在のビルド番号を取得
    current_build=$(extract_build_number "$project_file")
    echo "current_build:${current_build:-unknown}"

    # デフォルトブランチを取得
    default_branch=$(get_default_branch)
    if [[ -z "$default_branch" ]]; then
        echo "previous_build:unknown"
        echo "comparison:unknown"
        exit 0
    fi

    # gitパスに変換（./を除去）
    git_path="${project_file#./}"

    # デフォルトブランチのビルド番号を取得
    previous_build=$(git show "origin/$default_branch:$git_path" 2>/dev/null | grep "CURRENT_PROJECT_VERSION" | head -1 | sed 's/.*= *\([^;]*\);.*/\1/' | tr -d ' "' || echo "")

    # 変数参照の場合は空に
    if [[ "$previous_build" == *'$'* ]]; then
        previous_build=""
    fi

    echo "previous_build:${previous_build:-unknown}"

    # 比較結果
    if [[ -z "$current_build" ]] || [[ -z "$previous_build" ]]; then
        echo "comparison:unknown"
    elif [[ "$current_build" == "$previous_build" ]]; then
        echo "comparison:same"
    else
        echo "comparison:updated"
    fi
}

main "$@"
