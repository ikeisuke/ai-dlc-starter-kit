#!/usr/bin/env bash
# aidlc-spool.sh - NDJSON spool パース helper（Unit 004 / #643）
#
# 提供する公開関数:
#   _spool_extract_entries <spool_path> -> stdout: NDJSON 各行
#
# 提供する内部公開関数（境界完全分離のため複製）:
#   __retro_diag <level> <code> <detail> - stderr 出力ヘルパ
#
# 提供する命名規約定数（spool ヘッダ参照のため）:
#   RETROSPECTIVE_SPOOL_HEADER
#
# 多重 source ガード: __AIDLC_SPOOL_SH_LOADED=1
#
# 本 helper は他 helper を一切 source しない（境界完全分離）

if [[ "${__AIDLC_SPOOL_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_SPOOL_SH_LOADED=1

# ─── 命名規約定数 ─────────
# retrospective-issue.sh と同じ readonly 定数を本 helper でも宣言（重複代入を避けるため readonly チェック）
if [[ -z "${RETROSPECTIVE_SPOOL_HEADER:-}" ]]; then
    readonly RETROSPECTIVE_SPOOL_HEADER="<!-- retrospective-spool v1 -->"
fi

# ─── 診断出力ヘルパ（境界完全分離のため各 helper に複製） ─────────
__retro_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

# ─── NDJSON spool パース ─────────
_spool_extract_entries() {
    # $1: spool_path
    # 出力: NDJSON 各行を stdout
    # 戻り値: 0=成功 / 2=spool 不在 or ヘッダ不一致
    local spool_path="$1"
    if [[ ! -f "$spool_path" ]]; then
        __retro_diag error spool_not_found "$spool_path"
        return 2
    fi

    # ヘッダ確認
    local first_line
    first_line=$(head -n 1 "$spool_path")
    if [[ "$first_line" != "$RETROSPECTIVE_SPOOL_HEADER" ]]; then
        __retro_diag error spool_header_missing "$spool_path"
        return 2
    fi

    awk '
    BEGIN { in_block = 0 }
    /^```ndjson[[:space:]]*$/ && in_block == 0 { in_block = 1; next }
    /^```[[:space:]]*$/ && in_block == 1 { in_block = 0; next }
    in_block == 1 && length($0) > 0 { print }
    ' "$spool_path"
}
