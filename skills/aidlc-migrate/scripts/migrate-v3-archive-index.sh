#!/usr/bin/env bash
#
# migrate-v3-archive-index.sh - v2 cycles の所在 index 生成（archive-only migration）
#
# 使用方法:
#   ./migrate-v3-archive-index.sh [--output <file>]
#
# 既定: --output .aidlc/v2-archive.md
# --output は project root からの相対パスのみ受理する
# （絶対パス / `..` / symlink 脱出は lib/path-guard.sh により拒否 / exit 1）
#
# 動作:
#   .aidlc/cycles/ 直下のディレクトリのうち、v3 フラット構造マーカー（work-items/）を
#   持たないものを archive 対象（v2 以前の cycle）として index に列挙する。
#   内容変換は行わない（所在の参照用 index のみ / migration.md §2 archive-only）。
#   再実行時はファイル全体を再生成する（追記しない / 冪等）。
#
# 出力:
#   stdout: status:generated:count=<n>
#
# 終了コード:
#   0: 成功（対象 0 件を含む）
#   1: 入力エラー（引数不正）
#   2: システムエラー（git リポジトリ外 / mktemp・書き込み失敗）
#

set -euo pipefail

usage() {
  echo "usage: migrate-v3-archive-index.sh [--output <file>]" >&2
}

OUTPUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output) shift; OUTPUT="${1:-}" ;;
    *) usage; exit 1 ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AIDLC_PROJECT_ROOT="${AIDLC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}" || {
  echo "error:project-root-not-found" >&2; exit 2
}
# 環境変数override時の安全性検証: gitリポジトリであることを確認
if ! git -C "$AIDLC_PROJECT_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "error:invalid-project-root:$AIDLC_PROJECT_ROOT" >&2; exit 2
fi

# パス境界検証（絶対パス / `..` / symlink 脱出を拒否）
# shellcheck source=lib/path-guard.sh
source "${SCRIPT_DIR}/lib/path-guard.sh"
_aidlc_migrate_path_guard_init || exit 2

CYCLES_DIR="${AIDLC_PROJECT_ROOT}/.aidlc/cycles"
OUTPUT="${OUTPUT:-.aidlc/v2-archive.md}"

output_rc=0
_aidlc_migrate_validate_path "$OUTPUT" "output" "migrate-v3-archive-index" || output_rc=$?
if [ "$output_rc" -eq 1 ]; then
  echo "error:path-rejected:output:${OUTPUT}" >&2
  exit 1
elif [ "$output_rc" -ne 0 ]; then
  echo "error:path-validation-failed:output:${OUTPUT}" >&2
  exit 2
fi
OUTPUT="${AIDLC_PROJECT_ROOT}/${OUTPUT}"
# output がディレクトリの場合、mv がディレクトリ内への移動として成功してしまうため事前拒否
if [ -d "$OUTPUT" ]; then
  echo "error:output-is-directory:$OUTPUT" >&2
  exit 1
fi

# テスト時刻固定（state-init.sh の AIDLC_STATE_NOW と同型の契約）
GENERATED_AT="${AIDLC_MIGRATE_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

_mark() {
  # $1 = 条件式の結果（0 = 存在）
  if [ "$1" -eq 0 ]; then
    printf '✓'
  else
    printf '-'
  fi
}

# archive 対象 cycle の表行を収集する
ROWS=""
COUNT=0
if [ -d "$CYCLES_DIR" ]; then
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    # cycle 名の許容文字集合検証（state-init.sh の cycle id ガードと同型）。
    # `|`・改行・制御文字等による Markdown table 構造の改変を防ぐ。改行入りディレクトリ名は
    # read の行分割で断片化するが、断片も本ガードで弾かれるか実在判定（-d）で除外される。
    case "$name" in
      *[!A-Za-z0-9._-]*|.*)
        echo "warn:skipped-invalid-cycle-name:${name//[^A-Za-z0-9._-]/_}" >&2
        continue
        ;;
    esac
    d="${CYCLES_DIR}/${name}"
    [ -d "$d" ] || continue
    # v3 フラット構造マーカー（work-items/）を持つ cycle は対象外
    if [ -d "${d}/work-items" ]; then
      continue
    fi
    intent=1
    if [ -f "${d}/requirements/intent.md" ] || [ -f "${d}/inception/intent.md" ]; then
      intent=0
    fi
    units=1
    if [ -d "${d}/story-artifacts/units" ]; then
      units=0
    fi
    progress=1
    if [ -f "${d}/progress.md" ] || [ -f "${d}/construction/progress.md" ]; then
      progress=0
    fi
    history=1
    if [ -d "${d}/history" ]; then
      history=0
    fi
    release_notes=1
    if [ -f "${d}/operations/release_notes.md" ]; then
      release_notes=0
    fi
    ROWS="${ROWS}| ${name} | $(_mark "$intent") | $(_mark "$units") | $(_mark "$progress") | $(_mark "$history") | $(_mark "$release_notes") |
"
    COUNT=$((COUNT + 1))
  done < <(find "$CYCLES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | LC_ALL=C sort)
fi

_generate_index() {
  cat <<EOF
# v2 アーカイブ index

- generated_at: ${GENERATED_AT}
- 本ファイルは aidlc-migrate（v2 → v3 / archive-only）が生成した参照用 index である。
- v2 以前のサイクル資産は \`.aidlc/cycles/\` 配下に参照用として残置され、v3 ツールからの内容操作は不可。
- v2 → v3 は片方向移行（rollback 不可）であり、v2 runtime 互換は保証されない。
- 再実行時は本ファイル全体が再生成される（追記されない）。

## archive 対象 cycle（${COUNT} 件）

EOF
  if [ "$COUNT" -gt 0 ]; then
    cat <<EOF
| cycle | intent | units | progress | history | release_notes |
|-------|--------|-------|----------|---------|---------------|
EOF
    printf '%s' "$ROWS"
  else
    echo "（archive 対象の cycle はありません）"
  fi
}

output_dir="$(dirname "$OUTPUT")"
if ! mkdir -p "$output_dir"; then
  echo "error:output-dir-create-failed:$output_dir" >&2
  exit 2
fi
tmp="$(mktemp "${output_dir}/.migrate-v3-archive-index.XXXXXX")" || {
  echo "error:mktemp-failed" >&2
  exit 2
}
if ! _generate_index > "$tmp"; then
  rm -f "$tmp"
  echo "error:write-failed" >&2
  exit 2
fi
if ! mv "$tmp" "$OUTPUT"; then
  rm -f "$tmp"
  echo "error:replace-failed:$OUTPUT" >&2
  exit 2
fi

echo "status:generated:count=${COUNT}"
