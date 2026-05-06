#!/usr/bin/env bash
# aidlc-paths.sh - AI-DLC cycle path 解決 helper（Unit 003 / #638）
#
# 提供する公開関数:
#   aidlc_cycle_path <cycle> <subpath>
#       -> stdout に解決済み path を 1 行で出力
#
# 動作仕様:
#   AIDLC_PROJECT_ROOT 設定時 (非空):
#       <AIDLC_PROJECT_ROOT>/.aidlc/cycles/<cycle>/<subpath>
#   AIDLC_PROJECT_ROOT 未設定 / 空文字時:
#       .aidlc/cycles/<cycle>/<subpath>  (cwd 相対)
#
#   helper は単純な path 連結のみを行う（DR-007）。
#   trim・絶対パス化・正規化・存在チェックは呼び出し側責務。
#
# exit code 規約 (retrospective 系既存と整合):
#   0 - 成功
#   2 - 引数エラー (cycle 空 / subpath 未指定)
#
# stderr フォーマット: <level>\t<code>\t<detail>  (level=info|warn|error)

# 多重 source ガード
if [[ "${__AIDLC_PATHS_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_PATHS_SH_LOADED=1

# ─── 公開関数: aidlc_cycle_path ─────────
aidlc_cycle_path() {
    if [[ $# -lt 1 ]] || [[ -z "${1:-}" ]]; then
        printf 'error\taidlc_paths_invalid_cycle\t%s\n' "aidlc_cycle_path requires <cycle>" >&2
        return 2
    fi
    if [[ $# -lt 2 ]] || [[ -z "${2:-}" ]]; then
        printf 'error\taidlc_paths_invalid_subpath\t%s\n' "aidlc_cycle_path requires <subpath>" >&2
        return 2
    fi

    local cycle="$1"
    local subpath="$2"

    if [[ -n "${AIDLC_PROJECT_ROOT:-}" ]]; then
        printf '%s/.aidlc/cycles/%s/%s\n' "$AIDLC_PROJECT_ROOT" "$cycle" "$subpath"
    else
        printf '.aidlc/cycles/%s/%s\n' "$cycle" "$subpath"
    fi
}
