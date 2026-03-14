#!/usr/bin/env bash
#
# validate.sh - バリデーション共通ライブラリ
#
# 使用方法:
#   source "${SCRIPT_DIR}/../lib/validate.sh"
#
# このファイルは関数定義のみを含む。トップレベルで実行されるコードはない。
#

# サイクル名を検証
# 許可: 英小文字・数字・ハイフン・ドット・アンダースコアで構成される1〜2セグメントのラベル
# 拒否: 空文字、パストラバーサル(..)、制御文字、空白、先頭スラッシュ
#
# 引数:
#   $1 - サイクル名
# 戻り値:
#   0: 有効
#   1: 無効
validate_cycle() {
    local cycle="$1"

    # 空文字チェック
    if [[ -z "$cycle" ]]; then
        return 1
    fi

    # パストラバーサル防止
    if [[ "$cycle" == *..* ]]; then
        return 1
    fi

    # 空白チェック
    if [[ "$cycle" =~ [[:space:]] ]]; then
        return 1
    fi

    # 制御文字チェック
    if [[ "$cycle" =~ [[:cntrl:]] ]]; then
        return 1
    fi

    # 先頭スラッシュ防止
    if [[ "$cycle" == /* ]]; then
        return 1
    fi

    # 形式チェック（1〜2セグメントの汎用ラベル）
    if [[ ! "$cycle" =~ ^[a-z0-9v][a-z0-9._-]*(/[a-z0-9v][a-z0-9._-]*)?$ ]]; then
        return 1
    fi

    return 0
}
