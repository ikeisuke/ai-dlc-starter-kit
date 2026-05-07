#!/usr/bin/env bash
# aidlc-validate.sh - cycle 命名・存在チェック helper（Unit 004 / #643）
#
# 提供する公開関数:
#   __retro_validate_cycle <cycle> -> 0=valid / 2=invalid（stderr に diag 出力）
#
# 提供する内部公開関数（境界完全分離のため複製）:
#   __retro_diag <level> <code> <detail> - stderr 出力ヘルパ
#
# 多重 source ガード: __AIDLC_VALIDATE_SH_LOADED=1
#
# 本 helper は他 helper を一切 source しない（境界完全分離 / Unit 004 logical_design 参照）

if [[ "${__AIDLC_VALIDATE_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_VALIDATE_SH_LOADED=1

# ─── 診断出力ヘルパ（境界完全分離のため各 helper に複製 / Unit 004 案 A）─────────
__retro_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

# ─── cycle バリデーション（path traversal 防御 / 文字種制限） ─────────
__retro_validate_cycle() {
    # $1: cycle
    # 戻り値: 0=valid, 2=invalid
    local cycle="$1"
    if [[ -z "$cycle" ]]; then
        __retro_diag error cycle_invalid "cycle is empty"
        return 2
    fi
    if [[ ! "$cycle" =~ ^[A-Za-z0-9._-]+$ ]]; then
        __retro_diag error cycle_invalid "cycle contains forbidden chars: $cycle"
        return 2
    fi
    case "$cycle" in
        .|..|*/*|*\\*) __retro_diag error cycle_invalid "cycle is reserved or contains separator: $cycle"; return 2 ;;
    esac
    return 0
}
