#!/usr/bin/env bash
# cycle-version-check.sh - Cycle バージョン判定 helper（Unit 004 / #590）
#
# 関数定義のみ提供。source して使用する。
# `sort -V` 不使用（GNU/BSD 差異排除）/ bash 内蔵の major/minor/patch 数値比較で判定。

set -euo pipefail

# aidlc_is_cycle_v25_or_later <cycle>
#   引数: cycle（^v[0-9]+\.[0-9]+\.[0-9]+$ 形式）
#   exit 0: v2.5.0 以降
#   exit 1: v2.5.0 未満
#   exit 2: フォーマット違反 or 引数不足
#
# 副作用なし（標準入力読まない / ファイル書かない / 環境変数依存なし）。
aidlc_is_cycle_v25_or_later() {
    local cycle="${1:-}"
    if [ -z "$cycle" ]; then
        echo "error	cycle-version-check	missing-argument" >&2
        return 2
    fi

    if [[ ! "$cycle" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "error	cycle-version-check	invalid-format:${cycle}" >&2
        return 2
    fi

    # v プレフィックス除去
    local stripped="${cycle#v}"
    local major minor patch
    IFS='.' read -r major minor patch <<<"$stripped"

    # major / minor / patch を順に評価
    if [ "$major" -gt 2 ]; then
        return 0
    elif [ "$major" -lt 2 ]; then
        return 1
    fi
    # major == 2
    if [ "$minor" -gt 5 ]; then
        return 0
    elif [ "$minor" -lt 5 ]; then
        return 1
    fi
    # major == 2, minor == 5
    if [ "$patch" -ge 0 ]; then
        return 0
    fi
    return 1
}

# 直接実行された場合は CLI として動作（subshell で関数呼び出し）
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    aidlc_is_cycle_v25_or_later "$@"
fi
