#!/usr/bin/env bash
#
# read-version.sh - スキルバージョンの読み取り
#
# v2.6.0 以降、version の SoT は .claude-plugin/marketplace.json の metadata.version
# となっている。本スクリプトは aidlc-setup 内から SoT を読み取るための薄いラッパー。
# コンテキスト独立性のため aidlc プラグインの version.sh は呼ばず、
# jq インラインまたは dasel で完結させる。
#
# 使用方法:
#   ./read-version.sh
#
# 出力:
#   stdout: バージョン文字列（例: 2.6.0）
#
# 終了コード:
#   0: 成功
#   1: コンテンツエラー（metadata.version 不在 / 値が空）
#   2: 実行環境エラー（marketplace.json 不在 / 抽出ツール（dasel/jq）双方不在）
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# aidlc-setup/scripts → リポジトリルートは2階層上
MARKETPLACE_JSON="${SCRIPT_DIR}/../../../.claude-plugin/marketplace.json"

if [[ ! -f "$MARKETPLACE_JSON" ]]; then
  echo "Error: marketplace.json not found at $MARKETPLACE_JSON" >&2
  exit 2
fi

VERSION=""
if command -v dasel >/dev/null 2>&1; then
  VERSION=$(dasel -i json 'metadata.version' < "$MARKETPLACE_JSON" 2>/dev/null) || VERSION=""
  # 引用符除去
  VERSION="${VERSION#\"}"
  VERSION="${VERSION%\"}"
elif command -v jq >/dev/null 2>&1; then
  VERSION=$(jq -r '.metadata.version // empty' "$MARKETPLACE_JSON" 2>/dev/null) || VERSION=""
else
  echo "Error: neither dasel nor jq is available" >&2
  exit 2
fi

# 前後の空白のみトリム（値中の空白は保持してフォーマット異常を検知可能にする）
VERSION="${VERSION#"${VERSION%%[![:space:]]*}"}"
VERSION="${VERSION%"${VERSION##*[![:space:]]}"}"

if [[ -z "$VERSION" ]]; then
  echo "Error: metadata.version is missing or empty in $MARKETPLACE_JSON" >&2
  exit 1
fi

# SemVer 2.0.0 妥当性検証（read_marketplace_version との契約整合）
# パターン: X.Y.Z[-prerelease][+build] / 数値部分は先行 0 禁止
_SEMVER_RE='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][a-zA-Z0-9-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][a-zA-Z0-9-]*))*))?(\+([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*))?$'
if ! [[ "$VERSION" =~ $_SEMVER_RE ]]; then
  echo "Error: metadata.version is not a valid SemVer 2.0.0 ('$VERSION') in $MARKETPLACE_JSON" >&2
  exit 1
fi

printf '%s' "$VERSION"
