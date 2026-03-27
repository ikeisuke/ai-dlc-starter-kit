#!/usr/bin/env bash
#
# resolve-starter-kit-path.sh - スターターキットパス解決スクリプト
#
# スクリプトの実行位置からAI-DLCスターターキットのルートパスを解決する。
# メタ開発モード（prompts/package/bin/ から実行）と
# 利用プロジェクトモード（skills/aidlc/scripts/ から実行）の両方に対応。
#
# 使用方法:
#   STARTER_KIT_ROOT=$(resolve-starter-kit-path.sh)
#
# 出力（stdout）:
#   成功時: スターターキットのルート絶対パス
#   エラー時: なし（stderrにエラーメッセージ）
#
# 終了コード:
#   0: 成功
#   1: パス解決失敗
#
# 環境変数:
#   AIDLC_STARTER_KIT_PATH: 利用プロジェクトモード時のスターターキットパス（必須）
#

set -euo pipefail

# スクリプト自身のディレクトリを取得（symlink解決済み）
resolve_script_dir() {
    local source="${BASH_SOURCE[0]:-$0}"

    # symlink を解決（macOS互換: readlink -f は使わない）
    while [[ -L "$source" ]]; do
        local dir
        dir="$(cd "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        # 相対パスの場合、元のディレクトリからの相対パスとして解決
        [[ "$source" != /* ]] && source="$dir/$source"
    done

    cd "$(dirname "$source")" && pwd
}

main() {
    local script_dir
    script_dir=$(resolve_script_dir)

    # パス構造からコンテキストを判定
    if [[ "$script_dir" == */prompts/package/bin ]]; then
        # メタ開発モード: スクリプトの3階層上がスターターキットルート
        local starter_kit_root
        starter_kit_root="$(cd "$script_dir/../../.." && pwd)"
        echo "$starter_kit_root"
        return 0

    elif [[ "$script_dir" == */docs/aidlc/bin ]]; then
        # 利用プロジェクトモード: 環境変数からスターターキットパスを取得
        if [[ -z "${AIDLC_STARTER_KIT_PATH:-}" ]]; then
            echo "Error: AIDLC_STARTER_KIT_PATH is not set" >&2
            echo "Error: Set AIDLC_STARTER_KIT_PATH to the AI-DLC starter kit root directory" >&2
            return 1
        fi

        if [[ ! -d "$AIDLC_STARTER_KIT_PATH" ]]; then
            echo "Error: AIDLC_STARTER_KIT_PATH directory does not exist: $AIDLC_STARTER_KIT_PATH" >&2
            return 1
        fi

        # 絶対パスに正規化して出力
        local resolved_path
        resolved_path="$(cd "$AIDLC_STARTER_KIT_PATH" && pwd)"
        echo "$resolved_path"
        return 0

    else
        echo "Error: cannot resolve starter kit path from $script_dir" >&2
        echo "Error: script must be located in prompts/package/bin/ or skills/aidlc/scripts/" >&2
        return 1
    fi
}

main "$@"
