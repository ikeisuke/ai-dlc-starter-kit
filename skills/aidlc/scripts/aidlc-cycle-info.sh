#!/usr/bin/env bash
#
# aidlc-cycle-info.sh - AI-DLCサイクル情報取得
#
# 使用方法:
#   ./aidlc-cycle-info.sh
#
# 出力形式:
#   current_cycle:<version|none>
#   cycle_phase:<inception|construction|operations|unknown>
#   latest_cycle:<version|none>
#   cycle_dir:<path|none>
#

# NOTE: -e は意図的に省略。detect_phase()等でコマンド失敗をハンドリングするため
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# ブランチ名からバージョン抽出
# 入力: cycle/v1.11.1 → 出力: v1.11.1
# 入力: cycle/waf/v1.0.0 → 出力: waf/v1.0.0
# マッチしない場合は空文字
extract_version() {
    local branch="$1"
    if [[ "$branch" =~ ^cycle/(([^/]+/)?(v[0-9]+\.[0-9]+\.[0-9]+))$ ]]; then
        # BASH_REMATCH[1] = "waf/v1.0.0" or "v1.0.0" (全体)
        # BASH_REMATCH[2] = "waf/" or "" (名前部分+スラッシュ)
        # BASH_REMATCH[3] = "v1.0.0" (バージョン部分のみ)
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# 最新サイクルバージョン取得
# .aidlc/cycles/ 内のトップレベルのバージョンディレクトリのみ走査（従来形式）
# 注意: 名前付きサイクル（.aidlc/cycles/[name]/vX.X.X/）は走査対象外。
# current_cycle が名前付きの場合、latest_cycle は異なる系列の値を返す可能性がある
get_latest_cycle() {
    if [[ ! -d "${AIDLC_CYCLES}" ]]; then
        echo ""
        return
    fi
    # バージョン形式のディレクトリのみ抽出し、バージョンソートで最新を取得
    ls -1 "${AIDLC_CYCLES}/" 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || echo ""
}

# フェーズ判定
# 引数: サイクルバージョン
# 出力: inception, construction, operations, または unknown
detect_phase() {
    local version="$1"

    if [[ -z "$version" ]]; then
        echo "unknown"
        return
    fi

    local cycle_dir="${AIDLC_CYCLES}/$version"
    if [[ ! -d "$cycle_dir" ]]; then
        echo "unknown"
        return
    fi

    # フェーズ判定（成果物ファイルの存在で判定）
    if [[ -f "$cycle_dir/operations/progress.md" ]]; then
        echo "operations"
    elif [[ -d "$cycle_dir/story-artifacts/units" ]] && compgen -G "$cycle_dir/story-artifacts/units/*.md" >/dev/null 2>&1; then
        echo "construction"
    else
        echo "inception"
    fi
}

# メイン処理
main() {
    local branch
    branch=$(aidlc_get_current_branch)

    local version
    version=$(extract_version "$branch")

    local latest
    latest=$(get_latest_cycle)

    # current_cycle
    if [[ -n "$version" ]]; then
        echo "current_cycle:$version"
    else
        echo "current_cycle:none"
    fi

    # cycle_name / cycle_version（v1.20.0で追加）
    # センチネル値: 空文字 = 名前なしサイクル、"none" = サイクルブランチ外
    if [[ -n "$version" ]]; then
        if [[ "$version" == */* ]]; then
            # 名前付き: waf/v1.0.0 → cycle_name:waf, cycle_version:v1.0.0
            echo "cycle_name:${version%%/*}"
            echo "cycle_version:${version##*/}"
        else
            # 名前なし: v1.0.0 → cycle_name:(空文字), cycle_version:v1.0.0
            echo "cycle_name:"
            echo "cycle_version:$version"
        fi
    else
        echo "cycle_name:none"
        echo "cycle_version:none"
    fi

    # cycle_phase
    echo "cycle_phase:$(detect_phase "$version")"

    # latest_cycle
    if [[ -n "$latest" ]]; then
        echo "latest_cycle:$latest"
    else
        echo "latest_cycle:none"
    fi

    # cycle_dir
    if [[ -n "$version" ]] && [[ -d "${AIDLC_CYCLES}/$version" ]]; then
        echo "cycle_dir:${AIDLC_CYCLES}/$version"
    else
        echo "cycle_dir:none"
    fi
}

# mainガード: source時は実行しない
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
