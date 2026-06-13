#!/usr/bin/env bash
#
# state-init.sh - atomically create the initial v3 cycle state (.aidlc/state.json)
#
# define フロー Step 4 で初期 state.json（skeleton）を生成する専用スクリプト。
# schema_version / current_cycle を確定し、define_completed=false / release 初期値 /
# updated_at を持つ canonical skeleton を生成する。
#
# 本スクリプトは「create-only」（新規生成専用）であり、既存 state.json を上書きしない。
# 既存 state の field 更新は state-write.sh（atomic-replace / mv）の責務であり、
# 本スクリプトは create-only（ln / target 存在で失敗）で確定する。両者は原子化
# プリミティブが分岐する（init=ln create-only / write=mv atomic-replace）。
#
# Usage:
#   state-init.sh <current_cycle> [file]
#     current_cycle: 対象サイクル識別子（例 v3.0.0 / v3.0.0-alpha.3）。
#                    cycle ディレクトリ名・ブランチ suffix の同一キーになるため、
#                    入力健全性ガードを適用する（許容文字集合 ^[A-Za-z0-9][A-Za-z0-9._-]*$）。
#                    vX.Y.Z 厳密形式の検証は行わない（consumer の任意識別子余地を残す）。
#     file         : 生成先パス（省略時: .aidlc/state.json）
#
# updated_at は生成時に現在 UTC を書く。
# 環境変数 AIDLC_STATE_NOW（ISO 8601 文字列）が設定されていればその値を使う（テスト用）。
#
# 終了コード（AI-DLC 終了コード規約準拠 / 既存 state-*.sh と一致）:
#   0 = 生成完了（status:initialized）
#   1 = バリデーションエラー（引数不足 / current_cycle 入力健全性違反 /
#       対象ファイルが既に存在（create-only 違反） / 生成後 state が invalid）
#   2 = システムエラー（jq 未導入 / 依存スクリプト不備 / mktemp 失敗 / ln 失敗（非存在要因） 等）
#
set -euo pipefail

readonly DEFAULT_STATE_FILE=".aidlc/state.json"
readonly SCHEMA_VERSION="3.0"
# cycle 識別子の許容文字集合。先頭は英数字、以降は英数字 . _ - のみ。
# path separator（/）・空白・制御文字を拒否し、cycle ディレクトリ名・ブランチ suffix
# としての整合性を担保する。
readonly CYCLE_RE='^[A-Za-z0-9][A-Za-z0-9._-]*$'

err() { echo "$@" >&2; }

# SCRIPT_DIR 解決の失敗（dirname / cd / pwd）も exit 2 へ正規化する（終了コード規約 0/1/2 厳守）。
if ! SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; then
    echo "error: cannot resolve script directory" >&2
    exit 2
fi
readonly SCRIPT_DIR
readonly VALIDATE="$SCRIPT_DIR/state-validate.sh"

# --- jq 存在確認（システムエラー） ---
if ! command -v jq >/dev/null 2>&1; then
    err "error: jq not found"
    exit 2
fi

# --- 依存スクリプト確認（システムエラー） ---
# set -euo pipefail のまま依存呼び出しを素通しすると、存在しないコマンドの 127 /
# 実行権限なしの 126 が外部へ漏れ、終了コード規約の 0/1/2 契約を破る。
if [[ ! -x "$VALIDATE" ]]; then
    err "error: dependency not found or not executable: $VALIDATE"
    exit 2
fi

# --- 引数チェック ---
if [[ $# -lt 1 ]]; then
    err "error: current_cycle is required"
    err "usage: state-init.sh <current_cycle> [file]"
    exit 1
fi

current_cycle="$1"
file="${2:-$DEFAULT_STATE_FILE}"

# --- current_cycle 入力健全性ガード（バリデーション） ---
# 空 / path separator / 空白 / 制御文字を拒否する（許容文字集合に一致しなければ exit 1）。
if [[ ! "$current_cycle" =~ $CYCLE_RE ]]; then
    err "error: invalid current_cycle (allowed charset: ${CYCLE_RE}): $current_cycle"
    exit 1
fi

# --- create-only の早期フレンドリーエラー（確定ガードは下記 ln） ---
# -L も判定する: dangling symlink（リンク先不在）は -e が false になるため、
# -e のみだと create-only 違反を取りこぼし、後段で exit 2 に誤分類される。
if [[ -e "$file" || -L "$file" ]]; then
    err "error: target already exists (state-init is create-only): $file"
    exit 1
fi

# --- updated_at の値（テスト時は AIDLC_STATE_NOW で上書き可能） ---
# date 失敗（外部コマンド）も exit 2 へ正規化する。
if [[ -n "${AIDLC_STATE_NOW:-}" ]]; then
    now="$AIDLC_STATE_NOW"
elif ! now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; then
    err "error: failed to get current UTC time"
    exit 2
fi

# --- temp file を対象ファイルと同一ディレクトリに作成（ln の同一 FS 制約を担保） ---
if ! dir="$(dirname "$file")"; then
    err "error: failed to resolve target directory"
    exit 2
fi
tmp="$(mktemp "$dir/.state.json.XXXXXX")" || { err "error: mktemp failed"; exit 2; }
trap 'rm -f "$tmp"' EXIT

# --- canonical skeleton を temp へ書き出す ---
if ! jq -n \
    --arg sv "$SCHEMA_VERSION" \
    --arg cc "$current_cycle" \
    --arg now "$now" '
    {
      schema_version: $sv,
      current_cycle: $cc,
      define_completed: false,
      release: { pr_number: null, ready: false, merge_approved: false },
      updated_at: $now
    }
' > "$tmp"; then
    err "error: jq skeleton generation failed"
    exit 2
fi

# --- 生成後 state を validate（検証 SoT 再利用 / rc を正規化） ---
set +e
"$VALIDATE" "$tmp" >/dev/null 2>&1
rc=$?
set -e
case "$rc" in
    0) : ;; # 有効
    1) err "error: generated state is invalid"; exit 1 ;;
    2) err "error: validator system error"; exit 2 ;;
    *) err "error: validator exited unexpectedly (rc=$rc)"; exit 2 ;; # 126/127 等の漏れ防止
esac

# --- atomic create-only 配置（ln / target 存在で失敗） ---
# mv は無条件上書きで TOCTOU 窓が残るため使わない。ln は同一 FS（temp と target は
# 同一ディレクトリ）でハードリンクを作り、target が既存なら失敗する（macOS BSD / Linux GNU 共通）。
if ln "$tmp" "$file" 2>/dev/null; then
    rm -f "$tmp"
    trap - EXIT  # temp は rm 済み（file は別名で残る）
else
    # ln 失敗。target が存在すれば create-only 違反（exit 1）、それ以外はシステムエラー（exit 2）。
    # dangling symlink も create-only 違反として扱う（-e は辿るため -L を併用）。
    if [[ -e "$file" || -L "$file" ]]; then
        err "error: target already exists (create-only): $file"
        exit 1
    fi
    err "error: ln failed: $file"
    exit 2
fi

echo "status:initialized"
exit 0
