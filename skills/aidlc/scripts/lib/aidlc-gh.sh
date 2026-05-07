#!/usr/bin/env bash
# aidlc-gh.sh - gh CLI 可用性チェック helper（Unit 004 / #643）
#
# 提供する公開関数:
#   __retro_gh_status -> stdout: available | unavailable | not-installed
#
# 提供する内部公開関数（境界完全分離のため複製）:
#   __retro_diag <level> <code> <detail> - stderr 出力ヘルパ
#
# 多重 source ガード: __AIDLC_GH_SH_LOADED=1
#
# 本 helper は他 helper を一切 source しない（境界完全分離）

if [[ "${__AIDLC_GH_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_GH_SH_LOADED=1

# ─── 診断出力ヘルパ（境界完全分離のため各 helper に複製） ─────────
__retro_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

# ─── gh I/O ─────────
__retro_gh_status() {
    # 出力: available | unavailable | not-installed
    if ! command -v gh >/dev/null 2>&1; then
        printf 'not-installed\n'
        return 0
    fi
    if gh auth status >/dev/null 2>&1; then
        printf 'available\n'
    else
        printf 'unavailable\n'
    fi
}
