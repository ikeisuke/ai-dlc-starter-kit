#!/usr/bin/env bash
#
# check-setup-type.sh - セットアップ種類を判定
#
# 使用方法:
#   ./check-setup-type.sh
#
# 出力形式:
#   setup_type:{種類}
#   - initial: 初回セットアップ
#   - cycle_start: サイクル開始（バージョン同じ）
#   - upgrade:{project}:{kit}: アップグレード可能
#   - warning_newer:{project}:{kit}: プロジェクトが新しい
#   - migration: 旧形式からの移行
#   - (空): dasel未インストール（AIに委ねる）
#
# エッジケース:
#   - dasel未インストール: setup_type: を出力（AIに委ねる）
#   - 設定ファイルなし: setup_type:initial を出力
#   - 旧形式のみ存在: setup_type:migration を出力
#

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 設定ファイルパス
AIDLC_TOML="docs/aidlc.toml"
PROJECT_TOML="docs/aidlc/project.toml"

# daselの存在確認
if ! command -v dasel >/dev/null 2>&1; then
    echo "setup_type:"
    exit 0
fi

# 設定ファイルの存在確認（aidlc.toml 優先）
if [ -f "$AIDLC_TOML" ]; then
    # 新形式が存在 - check-version.sh を呼び出してバージョン状態を取得
    VERSION_OUTPUT=$("${SCRIPT_DIR}/check-version.sh")

    # version_status: の後の値を抽出
    VERSION_STATUS="${VERSION_OUTPUT#version_status:}"

    # 空値（unknown）の場合
    if [ -z "$VERSION_STATUS" ]; then
        echo "setup_type:"
        exit 0
    fi

    # バージョン状態に基づいて出力
    case "$VERSION_STATUS" in
        "current")
            echo "setup_type:cycle_start"
            ;;
        upgrade_available:*)
            # upgrade_available:{project}:{kit} から {project}:{kit} を抽出
            VERSIONS="${VERSION_STATUS#upgrade_available:}"
            echo "setup_type:upgrade:${VERSIONS}"
            ;;
        project_newer:*)
            # project_newer:{project}:{kit} から {project}:{kit} を抽出
            VERSIONS="${VERSION_STATUS#project_newer:}"
            echo "setup_type:warning_newer:${VERSIONS}"
            ;;
        "not_found")
            # バージョン情報がない = 初回扱い
            echo "setup_type:initial"
            ;;
        *)
            # 未知の状態
            echo "setup_type:initial"
            ;;
    esac
elif [ -f "$PROJECT_TOML" ]; then
    # 旧形式のみ存在
    echo "setup_type:migration"
else
    # どちらもなし
    echo "setup_type:initial"
fi
