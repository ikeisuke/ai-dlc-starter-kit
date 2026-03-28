#!/usr/bin/env bash
#
# bootstrap.sh - 共通初期化ライブラリ
#
# 全スクリプトの冒頭で source して使用する。
# 前提: 呼び出し元が set -euo pipefail を設定していること。
#
# 提供する環境変数:
#   AIDLC_PROJECT_ROOT      - プロジェクトルート（外部注入可能）
#   AIDLC_PLUGIN_ROOT       - プラグインルート（skills/aidlc/）
#   AIDLC_CONFIG            - プロジェクト設定ファイルパス
#   AIDLC_LOCAL_CONFIG      - ローカル設定ファイルパス
#   AIDLC_LOCAL_CONFIG_LEGACY - レガシーローカル設定ファイルパス
#   AIDLC_CYCLES            - サイクルデータディレクトリ
#   AIDLC_DEFAULTS          - デフォルト設定ファイルパス

# --- AIDLC_PROJECT_ROOT ---
# 外部指定（依存注入）があればそちらを使用、なければ自動解決
if [ -z "${AIDLC_PROJECT_ROOT:-}" ]; then
  AIDLC_PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "error:project-root-not-found" >&2; exit 1
  }
fi

# --- AIDLC_PLUGIN_ROOT ---
# 内部専用: bootstrap.sh自身の位置から skills/aidlc/ を算出
# BASH_SOURCE[0] = skills/aidlc/scripts/lib/bootstrap.sh
# → dirname → skills/aidlc/scripts/lib/
# → /../.. → skills/aidlc/
AIDLC_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# --- 派生パス ---
AIDLC_CONFIG="${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
AIDLC_LOCAL_CONFIG="${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
AIDLC_LOCAL_CONFIG_LEGACY="${AIDLC_PROJECT_ROOT}/.aidlc/config.toml.local"
AIDLC_CYCLES="${AIDLC_PROJECT_ROOT}/.aidlc/cycles"
AIDLC_DEFAULTS="${AIDLC_PLUGIN_ROOT}/config/defaults.toml"

export AIDLC_PROJECT_ROOT AIDLC_PLUGIN_ROOT
export AIDLC_CONFIG AIDLC_LOCAL_CONFIG AIDLC_LOCAL_CONFIG_LEGACY
export AIDLC_CYCLES AIDLC_DEFAULTS

# --- 共通ユーティリティ関数 ---

# 現在のgitブランチを取得
# 出力: ブランチ名、detached HEAD時は空文字
# 使用例: branch=$(aidlc_get_current_branch)
aidlc_get_current_branch() {
    local branch=""
    branch=$(git branch --show-current 2>/dev/null) || branch=""
    if [[ -z "$branch" ]]; then
        local abbrev_ref
        abbrev_ref=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || abbrev_ref=""
        if [[ "$abbrev_ref" != "HEAD" ]]; then
            branch="$abbrev_ref"
        fi
    fi
    echo "$branch"
}

# dasel/TOML出力からクォートを除去
# 引数: $1 - クォート除去対象の文字列
# 出力: クォート除去済み文字列
aidlc_strip_quotes() {
    local val="$1"
    # 両端の空白除去
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    # 両端の引用符除去（シングル・ダブル）
    val="${val#\"}"
    val="${val%\"}"
    val="${val#\'}"
    val="${val%\'}"
    echo "$val"
}
