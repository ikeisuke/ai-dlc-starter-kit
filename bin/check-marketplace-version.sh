#!/usr/bin/env bash
#
# check-marketplace-version.sh - リリース関連変更が含まれるとき marketplace.json の
# metadata.version が同 PR 内で更新されているかを検証する pre-release ガード
#
# 使用方法:
#   ./check-marketplace-version.sh [--base <ref>] [--current <ref>]
#
# パラメータ:
#   --base <ref>:    比較先 ref（デフォルト: origin/main）
#   --current <ref>: 比較元 ref（デフォルト: HEAD）
#
# トリガー条件（リリース関連変更）:
#   - CHANGELOG.md の編集
#   - .aidlc/operations.md の編集
#   上記が含まれかつ marketplace.json.metadata.version が変更されていない場合に violation
#
# 出力形式:
#   - 合格: "marketplace_version_check:ok" + 詳細
#   - 違反: "marketplace_version_check:violation" + reason + detail
#
# 終了コード:
#   0: 合格（リリース変更なし or version 更新あり）
#   1: 違反（リリース変更あり + version 未更新）
#   2: 実行エラー（git 操作失敗 等）
#

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SCRIPT_DIR}/../skills/aidlc/scripts/lib"
if [[ -f "${_LIB_DIR}/version.sh" ]]; then
    # shellcheck source=../skills/aidlc/scripts/lib/version.sh
    source "${_LIB_DIR}/version.sh"
else
    echo "marketplace_version_check:violation"
    echo "reason:version_lib_not_found"
    echo "detail:lib/version.sh not found"
    exit 2
fi

BASE="origin/main"
CURRENT="HEAD"

while [[ $# -gt 0 ]]; do
    case $1 in
        --base)
            if [[ $# -lt 2 ]]; then
                echo "marketplace_version_check:violation"
                echo "reason:missing_base_value"
                exit 2
            fi
            BASE="$2"
            shift 2
            ;;
        --current)
            if [[ $# -lt 2 ]]; then
                echo "marketplace_version_check:violation"
                echo "reason:missing_current_value"
                exit 2
            fi
            CURRENT="$2"
            shift 2
            ;;
        *)
            echo "marketplace_version_check:violation"
            echo "reason:unknown_option"
            echo "detail:$1"
            exit 2
            ;;
    esac
done

# git ref の解決確認
if ! git rev-parse --verify --quiet "$BASE" >/dev/null; then
    echo "marketplace_version_check:violation"
    echo "reason:base_ref_not_found"
    echo "detail:$BASE"
    exit 2
fi
if ! git rev-parse --verify --quiet "$CURRENT" >/dev/null; then
    echo "marketplace_version_check:violation"
    echo "reason:current_ref_not_found"
    echo "detail:$CURRENT"
    exit 2
fi

# 差分ファイル一覧
_changed=""
_changed=$(git diff --name-only "$BASE" "$CURRENT" 2>/dev/null) || {
    echo "marketplace_version_check:violation"
    echo "reason:git_diff_failed"
    exit 2
}

# リリース関連変更の検出
_release_change_detected=false
_release_paths=""
while IFS= read -r path; do
    case "$path" in
        CHANGELOG.md|.aidlc/operations.md)
            _release_change_detected=true
            _release_paths="${_release_paths}${path} "
            ;;
    esac
done <<< "$_changed"

if [[ "$_release_change_detected" != true ]]; then
    echo "marketplace_version_check:ok"
    echo "detail:no_release_relevant_changes"
    exit 0
fi

# base / current の marketplace.json から metadata.version を抽出
_marketplace_path=".claude-plugin/marketplace.json"

_base_json=$(mktemp) || { echo "marketplace_version_check:violation"; echo "reason:mktemp_failed"; exit 2; }
_current_json=$(mktemp) || { rm -f "$_base_json"; echo "marketplace_version_check:violation"; echo "reason:mktemp_failed"; exit 2; }
trap 'rm -f "$_base_json" "$_current_json"' EXIT

if ! git show "${BASE}:${_marketplace_path}" > "$_base_json" 2>/dev/null; then
    echo "marketplace_version_check:violation"
    echo "reason:marketplace_json_missing_at_base"
    echo "detail:${BASE}:${_marketplace_path}"
    exit 1
fi
if ! git show "${CURRENT}:${_marketplace_path}" > "$_current_json" 2>/dev/null; then
    echo "marketplace_version_check:violation"
    echo "reason:marketplace_json_missing_at_current"
    echo "detail:${CURRENT}:${_marketplace_path}"
    exit 1
fi

_base_version=""
_rc=0
_base_version=$(read_marketplace_version "$_base_json" 2>/dev/null) || _rc=$?
if [[ "$_rc" -ne 0 ]]; then
    echo "marketplace_version_check:violation"
    echo "reason:base_version_extract_failed"
    echo "detail:${BASE}:${_marketplace_path}"
    exit 1
fi

_current_version=""
_rc=0
_current_version=$(read_marketplace_version "$_current_json" 2>/dev/null) || _rc=$?
if [[ "$_rc" -ne 0 ]]; then
    echo "marketplace_version_check:violation"
    echo "reason:current_version_extract_failed"
    echo "detail:${CURRENT}:${_marketplace_path}"
    exit 1
fi

if [[ "$_base_version" == "$_current_version" ]]; then
    echo "marketplace_version_check:violation"
    echo "reason:marketplace_version_unchanged"
    echo "detail:release_relevant_files=${_release_paths%% } base_version=${_base_version} current_version=${_current_version}"
    exit 1
fi

echo "marketplace_version_check:ok"
echo "base_version:${_base_version}"
echo "current_version:${_current_version}"
echo "release_paths:${_release_paths%% }"
