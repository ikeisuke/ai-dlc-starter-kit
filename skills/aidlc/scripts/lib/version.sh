#!/usr/bin/env bash
#
# version.sh - バージョン検証共通ライブラリ
#
# 使用方法:
#   source "${SCRIPT_DIR}/../lib/version.sh"  (scripts/ 配下から)
#   source "${LIB_DIR}/version.sh"            (lib/ のパスを持つ場合)
#
# このファイルは関数定義のみを含む。トップレベルで実行されるコードはない。
#

# SemVer パターン定義（X.Y.Z + optional prerelease）
# 例: 1.0.0, 2.3.1, 1.0.0-alpha.1, 2.0.0-rc.1
readonly _SEMVER_PATTERN='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[a-zA-Z0-9.]+)?$'

# SemVer フォーマット検証
#
# 引数:
#   $1 - バージョン文字列（vプレフィックスなし）
# 戻り値:
#   0: 有効なSemVer
#   1: 無効
validate_semver() {
    local version="$1"

    if [[ -z "$version" ]]; then
        return 1
    fi

    if [[ "$version" =~ $_SEMVER_PATTERN ]]; then
        return 0
    fi

    return 1
}

# vプレフィックスを除去してバージョン文字列を正規化
#
# 引数:
#   $1 - バージョン文字列（vプレフィックスあり/なし）
# 出力:
#   stdout: vプレフィックスを除去したバージョン文字列
strip_v_prefix() {
    echo "${1#v}"
}

# config.toml から starter_kit_version を読み取る
#
# 引数:
#   $1 - config.toml のパス
# 出力:
#   stdout: バージョン文字列（取得成功時）
# 戻り値:
#   0: 取得成功
#   1: キー不在またはフォーマット不正
#   2: ファイル読取エラー
read_starter_kit_version() {
    local config_path="$1"

    if [[ ! -f "$config_path" ]]; then
        return 2
    fi

    local version
    version=$(sed -n 's/^[[:space:]]*starter_kit_version[[:space:]]*=[[:space:]]*"\(.*\)"/\1/p' "$config_path") || return 2

    if [[ -z "$version" ]]; then
        return 1
    fi

    echo "$version"
    return 0
}
