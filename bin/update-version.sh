#!/usr/bin/env bash
#
# update-version.sh - .claude-plugin/marketplace.json の metadata.version を更新する
#
# 使用方法:
#   ./update-version.sh --version <version> [--dry-run]
#
# パラメータ:
#   --version <version>: バージョン番号（必須。vプレフィックス付き可: v2.6.0 → 2.6.0）
#   --dry-run: 実際の書き込みを行わず、変更内容を表示
#
# 更新対象（version の SoT）:
#   - .claude-plugin/marketplace.json の metadata.version
#
# 注:
#   - 旧仕様（version.txt 系 3 ファイル）の更新は v2.6.0 で廃止された（marketplace.json 一本化）
#   - .aidlc/config.toml.starter_kit_version は本スクリプトの更新対象外
#     （aidlc-setup / aidlc-migrate / 将来のアップグレード経路で更新される）
#
# 出力形式（破壊的変更 / v2.6.0）:
#   - 成功: "version_update:success" + "marketplace_version:<v>"
#   - dry-run: "version_update:dry-run" + "marketplace_version_current:<v>" + "marketplace_version_new:<v>"
#   - エラー: "error:<エラー種別>"
#
# 終了コード:
#   0: 正常終了（更新成功またはdry-run）
#   1: エラー
#

set -euo pipefail

# 共通ライブラリ読み込み
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SCRIPT_DIR}/../skills/aidlc/scripts/lib"
if [[ -f "${_LIB_DIR}/version.sh" ]]; then
    source "${_LIB_DIR}/version.sh"
else
    echo "error:version-lib-not-found"
    exit 1
fi

# デフォルト値
VERSION=""
DRY_RUN=false

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-version-value"
                exit 1
            fi
            VERSION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "error:unknown-option:$1"
            exit 1
            ;;
    esac
done

# バージョン未指定チェック
if [[ -z "$VERSION" ]]; then
    echo "error:missing-version"
    exit 1
fi

# vプレフィックス除去
VERSION="$(strip_v_prefix "$VERSION")"

# SemVer フォーマット検証
if ! validate_semver "$VERSION"; then
    echo "error:invalid-version-format"
    exit 1
fi

# marketplace.json の存在確認
# リポジトリルート絶対パスで参照する（カレントディレクトリ依存を回避）。
# git rev-parse 失敗時はカレントディレクトリ相対にフォールバック（テスト等の非 git 環境対応）。
_repo_root=""
_repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || _repo_root=""
if [[ -n "$_repo_root" ]]; then
    MARKETPLACE_JSON="${_repo_root}/.claude-plugin/marketplace.json"
else
    MARKETPLACE_JSON=".claude-plugin/marketplace.json"
fi
if [[ ! -f "$MARKETPLACE_JSON" ]]; then
    echo "error:marketplace-json-not-found"
    exit 1
fi

# 書き込みには jq を必須とする（dasel v3 の put セレクタ非互換のため）
# 読み取りは lib/version.sh::read_marketplace_version 経由で dasel/jq の両対応
if ! command -v jq >/dev/null 2>&1; then
    echo "error:jq-required-for-write"
    exit 1
fi

# 現在の値を読み取り（lib/version.sh の正本関数経由）
_current_version=""
_rc=0
_current_version=$(read_marketplace_version "$MARKETPLACE_JSON" 2>/dev/null) || _rc=$?
if [[ "$_rc" -ne 0 ]]; then
    if [[ "$_rc" -eq 2 ]]; then
        echo "error:marketplace-json-read-failed"
    else
        echo "error:invalid-marketplace-json-format"
    fi
    exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo "version_update:dry-run"
    echo "marketplace_version_current:${_current_version}"
    echo "marketplace_version_new:${VERSION}"
    exit 0
fi

# アトミック更新: 同一ディレクトリに一時ファイルを作成（mv の同一 FS 前提を満たす）
_tmp_marketplace=$(mktemp "${MARKETPLACE_JSON}.XXXXXX") || { echo "error:mktemp-failed"; exit 1; }
trap 'rm -f "$_tmp_marketplace"' EXIT

# jq で metadata.version を更新（インデント 2 / 末尾改行付与）
if ! jq --indent 2 --arg v "$VERSION" '.metadata.version = $v' "$MARKETPLACE_JSON" > "$_tmp_marketplace"; then
    echo "error:jq-update-failed"
    exit 1
fi

# 末尾改行が無ければ追加（POSIX text file 慣習）
if [[ -s "$_tmp_marketplace" ]] && [[ "$(tail -c1 "$_tmp_marketplace")" != "" ]]; then
    printf '\n' >> "$_tmp_marketplace"
fi

# バックアップ作成（書き込み失敗時の復旧用）
_bak_marketplace=$(mktemp) || { echo "error:mktemp-failed"; exit 1; }
trap 'rm -f "$_tmp_marketplace" "$_bak_marketplace"' EXIT
cp "$MARKETPLACE_JSON" "$_bak_marketplace" || { echo "error:backup-failed"; exit 1; }

# 一括反映（同一 FS 上の mv でアトミック）
if ! mv "$_tmp_marketplace" "$MARKETPLACE_JSON"; then
    echo "error:marketplace-json-write-failed"
    cp "$_bak_marketplace" "$MARKETPLACE_JSON" 2>/dev/null || true
    exit 1
fi

# 結果出力
echo "version_update:success"
echo "marketplace_version:${VERSION}"
