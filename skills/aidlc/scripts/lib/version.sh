#!/usr/bin/env bash
#
# version.sh - バージョン検証共通ライブラリ + CLI エントリポイント
#
# 使用方法（必須サポート / v2.6.1 Unit 001 以降）:
#   - CLI モード（推奨、AI エージェント / Bash ツール経由）:
#       bash <path>/version.sh <marketplace.json のパス>
#   - subprocess source（互換）:
#       bash -c "source <path>/version.sh; read_marketplace_version <args>"
#   - 他 bash スクリプトからの source（互換）:
#       source "${SCRIPT_DIR}/../lib/version.sh"
#
# 非対象経路（zsh 対話シェルからの手動 source）:
#   zsh command_not_found_handler 競合により OOM クラッシュリスクがあるため避ける。
#   詳細は SKILL.md「バージョン表示」セクションを参照。
#
# 末尾の CLI モードガード（${BASH_SOURCE[0]} == $0）により、bash 直接実行時のみ
# read_marketplace_version() を呼び出す。source 経由時は関数定義のみが取り込まれる。
#

# SemVer 2.0.0 準拠パターン定義（X.Y.Z[-prerelease][+build]）
# https://semver.org/spec/v2.0.0.html
#   - 各数値部分は先行 0 禁止（0 単独は許可）
#   - prerelease: dot-separated identifiers。各 identifier は数値（先行 0 禁止）または英数+ハイフン
#   - build metadata: dot-separated identifiers。各 identifier は英数+ハイフン
# 例（許容）: 1.0.0, 2.3.1, 1.0.0-alpha.1, 2.0.0-rc.1, 1.0.0-0.3.7, 1.0.0+build.123
# 例（拒否）: 1.2.3-., 1.2.3-alpha..1, 01.0.0, 1.0.0-01
# 多重 source 対応: 既に readonly 宣言済みなら再代入をスキップ
if [[ -z "${_SEMVER_PATTERN:-}" ]]; then
    readonly _SEMVER_PATTERN='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][a-zA-Z0-9-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][a-zA-Z0-9-]*))*))?(\+([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*))?$'
fi

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

# marketplace.json から metadata.version を読み取る（正本判定用）
#
# 本関数は version SoT である `.claude-plugin/marketplace.json` の
# `metadata.version` を抽出する。dasel 優先 / jq フォールバックで動作し、
# 両ツール不在時は実行環境エラーとして exit 2 を返す（grep+sed フォールバックは持たない）。
#
# 引数:
#   $1 - marketplace.json のパス
# 出力:
#   stdout: バージョン文字列（取得成功時）
#   stderr: エラー詳細（取得失敗時）
# 戻り値:
#   0: 取得成功
#   1: コンテンツエラー（metadata.version キー不在 / 値が空 / 非 SemVer）
#   2: 実行環境エラー（ファイル不在・読取権限なし・dasel/jq 双方不在）
read_marketplace_version() {
    local json_path="$1"

    if [[ -z "$json_path" ]]; then
        echo "error:missing-json-path" >&2
        return 2
    fi

    if [[ ! -f "$json_path" ]]; then
        echo "error:marketplace-json-not-found" >&2
        return 2
    fi

    if [[ ! -r "$json_path" ]]; then
        echo "error:marketplace-json-read-failed" >&2
        return 2
    fi

    local version=""
    # dasel v3 はセレクタの先頭ドットを許容しない（'metadata.version'）
    # dasel v2 互換のため、まずドットなしで試行する
    if command -v dasel >/dev/null 2>&1; then
        version=$(dasel -i json 'metadata.version' < "$json_path" 2>/dev/null) || version=""
        version=$(aidlc_strip_quotes_safe "$version")
    elif command -v jq >/dev/null 2>&1; then
        version=$(jq -r '.metadata.version' < "$json_path" 2>/dev/null) || version=""
        if [[ "$version" == "null" ]]; then
            version=""
        fi
    else
        echo "error:dasel-and-jq-unavailable" >&2
        return 2
    fi

    if [[ -z "$version" ]]; then
        echo "error:metadata-version-missing-or-empty" >&2
        return 1
    fi

    if ! validate_semver "$version"; then
        echo "error:metadata-version-invalid-semver:${version}" >&2
        return 1
    fi

    echo "$version"
    return 0
}

# 内部ユーティリティ: 引用符除去（dasel 出力対応）
# bootstrap.sh の aidlc_strip_quotes が利用可能ならそれを使い、未定義時は内蔵で処理
aidlc_strip_quotes_safe() {
    local value="$1"
    if declare -F aidlc_strip_quotes >/dev/null 2>&1; then
        aidlc_strip_quotes "$value"
        return
    fi
    # フォールバック実装: 先頭末尾の " と ' を1組だけ除去
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    echo "$value"
}

# config.toml から starter_kit_version を読み取る（検証付き読み取り）
#
# 注意: 本関数の戻り値は config.toml の「ローカルキャッシュ値」であり、
# version の正本ではない。version の正本判定には read_marketplace_version() を使うこと。
# 本関数はアップグレード差分検出（aidlc-setup / aidlc-migrate）等のキャッシュ検証用途に限定する。
#
# キーの一意性（正確に1件存在すること）と値の存在を検証して返す。
#
# 引数:
#   $1 - config.toml のパス
# 出力:
#   stdout: バージョン文字列（取得成功時）
# 戻り値:
#   0: 取得成功
#   1: キー不在、複数キー存在、または値が空（バリデーションエラー）
#   2: ファイル読取エラー
read_starter_kit_version() {
    local config_path="$1"

    if [[ ! -f "$config_path" ]]; then
        return 2
    fi

    if [[ ! -r "$config_path" ]]; then
        return 2
    fi

    # キー一意性検証: starter_kit_version が正確に1件存在することを確認
    local match_count
    match_count=$(grep -c '^[[:space:]]*starter_kit_version[[:space:]]*=' "$config_path" || true)

    if [[ "$match_count" -eq 0 ]]; then
        return 1
    fi

    if [[ "$match_count" -ne 1 ]]; then
        return 1
    fi

    local version
    version=$(sed -n 's/^[[:space:]]*starter_kit_version[[:space:]]*=[[:space:]]*"\(.*\)"/\1/p' "$config_path") || return 2

    if [[ -z "$version" ]]; then
        return 1
    fi

    echo "$version"
    return 0
}

# CLI モードガード（v2.6.1 Unit 001 / Issue #688）:
# `bash version.sh <json_path>` 形式での直接実行時のみ read_marketplace_version() を呼び出す。
# `source` 経由呼び出し時は ${BASH_SOURCE[0]} != $0 となり実行されない（既存挙動を完全維持）。
# zsh 対話シェルから手動 source した場合は zsh command_not_found_handler 競合のリスクがあるため
# SKILL.md の注意書きで非対象経路として案内する（本ガードは関与しない）。
# 引数契約: 第 1 引数のみ使用（marketplace.json のパス）。第 2 引数以降は read_marketplace_version()
# が $1 のみ参照するため安全に無視される。
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    read_marketplace_version "$@"
fi
