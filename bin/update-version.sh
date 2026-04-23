#!/usr/bin/env bash
#
# update-version.sh - version.txtとaidlc.tomlのバージョン番号を一括更新
#
# 使用方法:
#   ./update-version.sh --version <version> [--dry-run]
#
# パラメータ:
#   --version <version>: バージョン番号（必須。vプレフィックス付き可: v1.16.2 → 1.16.2）
#   --dry-run: 実際の書き込みを行わず、変更内容を表示
#
# 更新対象:
#   - version.txt（プロジェクトルート）
#   - .aidlc/config.toml の starter_kit_version
#   - skills/aidlc/version.txt
#   - skills/aidlc-setup/version.txt
#
# 出力形式:
#   - 成功: "version_update:success" + 詳細行
#   - dry-run: "version_update:dry-run" + 詳細行
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

# SemVerフォーマット検証（共通関数使用）
if ! validate_semver "$VERSION"; then
    echo "error:invalid-version-format"
    exit 1
fi

# 対象ファイルの存在確認
if [[ ! -f "version.txt" ]]; then
    echo "error:version-txt-not-found"
    exit 1
fi

if [[ ! -f ".aidlc/config.toml" ]]; then
    echo "error:config-toml-not-found"
    exit 1
fi

# スキル内version.txtの存在確認（存在する場合のみ更新対象に含める）
_skill_aidlc_version=""
_skill_setup_version=""
if [[ -f "skills/aidlc/version.txt" ]]; then
    _skill_aidlc_version="skills/aidlc/version.txt"
fi
if [[ -f "skills/aidlc-setup/version.txt" ]]; then
    _skill_setup_version="skills/aidlc-setup/version.txt"
fi

# 現在の値を取得
_current_version_txt=$(cat version.txt) || {
    echo "error:version-txt-read-failed"
    exit 1
}

# .aidlc/config.toml の妥当性検証専用読み取り（変数値は出力に使用しない）
# starter_kit_version 行の読取可能性・一意性・引用符付き非空値を検証し、
# unreadable / invalid format / duplicate key を検出する既存契約を維持する。
_rc=0
_current_aidlc_toml=$(read_starter_kit_version ".aidlc/config.toml") || _rc=$?
if [[ "$_rc" -ne 0 ]]; then
    if [[ "$_rc" -eq 2 ]]; then
        echo "error:config-toml-read-failed"
    else
        echo "error:invalid-config-toml-format"
    fi
    exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo "version_update:dry-run"
    echo "version_txt_current:${_current_version_txt}"
    echo "version_txt_new:${VERSION}"
    if [[ -n "$_skill_aidlc_version" ]]; then
        echo "skill_aidlc_version_current:$(cat "$_skill_aidlc_version")"
        echo "skill_aidlc_version_new:${VERSION}"
    fi
    if [[ -n "$_skill_setup_version" ]]; then
        echo "skill_setup_version_current:$(cat "$_skill_setup_version")"
        echo "skill_setup_version_new:${VERSION}"
    fi
    exit 0
fi

# アトミック更新: 同一ディレクトリに一時ファイルを作成（mvの同一FS前提を満たす）
_tmp_version=$(mktemp ./version.txt.XXXXXX) || { echo "error:mktemp-failed"; exit 1; }
_tmp_skill_aidlc=""
_tmp_skill_setup=""
if [[ -n "$_skill_aidlc_version" ]]; then
    _tmp_skill_aidlc=$(mktemp "$_skill_aidlc_version.XXXXXX") || { \rm -f "$_tmp_version"; echo "error:mktemp-failed"; exit 1; }
fi
if [[ -n "$_skill_setup_version" ]]; then
    _tmp_skill_setup=$(mktemp "$_skill_setup_version.XXXXXX") || { \rm -f "$_tmp_version" "$_tmp_skill_aidlc"; echo "error:mktemp-failed"; exit 1; }
fi
trap '\rm -f "$_tmp_version" "$_tmp_skill_aidlc" "$_tmp_skill_setup" "${_bak_version:-}"' EXIT

# 一時ファイル作成（全対象）
printf '%s\n' "$VERSION" > "$_tmp_version" || { echo "error:version-txt-write-failed"; exit 1; }
if [[ -n "$_tmp_skill_aidlc" ]]; then
    printf '%s\n' "$VERSION" > "$_tmp_skill_aidlc" || { echo "error:skill-aidlc-version-write-failed"; exit 1; }
fi
if [[ -n "$_tmp_skill_setup" ]]; then
    printf '%s\n' "$VERSION" > "$_tmp_skill_setup" || { echo "error:skill-setup-version-write-failed"; exit 1; }
fi

# バックアップ作成（全対象を反映前に取得）
_bak_version=$(mktemp) || { echo "error:mktemp-failed"; exit 1; }
\cp version.txt "$_bak_version" || { echo "error:backup-failed"; exit 1; }
_bak_skill_aidlc=""
_bak_skill_setup=""
if [[ -n "$_skill_aidlc_version" ]]; then
    _bak_skill_aidlc=$(mktemp) || { echo "error:mktemp-failed"; exit 1; }
    \cp "$_skill_aidlc_version" "$_bak_skill_aidlc" || { echo "error:backup-failed"; exit 1; }
fi
if [[ -n "$_skill_setup_version" ]]; then
    _bak_skill_setup=$(mktemp) || { echo "error:mktemp-failed"; exit 1; }
    \cp "$_skill_setup_version" "$_bak_skill_setup" || { echo "error:backup-failed"; exit 1; }
fi

# 全対象を一括反映（同一FS上のmvでアトミック）
_rollback() {
    \cp "$_bak_version" version.txt 2>/dev/null || true
    [[ -n "$_bak_skill_aidlc" ]] && \cp "$_bak_skill_aidlc" "$_skill_aidlc_version" 2>/dev/null || true
    [[ -n "$_bak_skill_setup" ]] && \cp "$_bak_skill_setup" "$_skill_setup_version" 2>/dev/null || true
    \rm -f "$_bak_version" "$_bak_skill_aidlc" "$_bak_skill_setup"
}

\mv "$_tmp_version" version.txt || { echo "error:version-txt-write-failed"; _rollback; exit 1; }
if [[ -n "$_tmp_skill_aidlc" ]]; then
    \mv "$_tmp_skill_aidlc" "$_skill_aidlc_version" || { echo "error:skill-aidlc-version-write-failed"; _rollback; exit 1; }
fi
if [[ -n "$_tmp_skill_setup" ]]; then
    \mv "$_tmp_skill_setup" "$_skill_setup_version" || { echo "error:skill-setup-version-write-failed"; _rollback; exit 1; }
fi
\rm -f "$_bak_version" "$_bak_skill_aidlc" "$_bak_skill_setup"

# 結果出力
echo "version_update:success"
echo "version_txt:${VERSION}"
[[ -n "$_skill_aidlc_version" ]] && echo "skill_aidlc_version:${VERSION}"
[[ -n "$_skill_setup_version" ]] && echo "skill_setup_version:${VERSION}"
