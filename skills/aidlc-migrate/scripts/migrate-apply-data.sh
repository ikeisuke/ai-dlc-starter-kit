#!/usr/bin/env bash
#
# migrate-apply-data.sh - cycles配下のデータ移行
#
# 使用方法:
#   ./migrate-apply-data.sh --manifest <path>
#
# 出力:
#   stdout: journal JSON（phase: "data"）
#   stderr: 移行処理の診断メッセージ
#
# 終了コード:
#   0: 成功
#   2: エラー
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIDLC_PROJECT_ROOT="${AIDLC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}" || {
  echo "error:project-root-not-found" >&2; exit 2
}

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed." >&2
  exit 2
fi

# 引数パース
MANIFEST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest)
      [[ $# -lt 2 ]] && { echo "Missing value for --manifest" >&2; exit 2; }
      MANIFEST="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$MANIFEST" ]]; then
  echo "Usage: $0 --manifest <path>" >&2
  exit 2
fi

cd "${AIDLC_PROJECT_ROOT}"

APPLIED="[]"

_add_applied() {
  APPLIED=$(echo "$APPLIED" | jq --argjson e "$1" '. + [$e]')
}

# move_dir リソースを処理（docs/cycles/ → .aidlc/cycles/ 等）
resource_count=$(jq '.resources | length' "$MANIFEST")
for i in $(seq 0 $((resource_count - 1))); do
  action=$(jq -r ".resources[$i].action" "$MANIFEST")
  [[ "$action" != "move_dir" ]] && continue

  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  path=$(jq -r ".resources[$i].path" "$MANIFEST")
  dest=$(jq -r ".resources[$i].destination" "$MANIFEST")

  if [[ ! -d "$path" ]]; then
    echo "  Source directory not found: $path" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "error", detail: "source directory not found"}')"
    continue
  fi

  mkdir -p "$dest"
  # 既存ファイルは上書きしない（-n）でコピー
  cp -Rn "$path"/* "$dest"/ 2>/dev/null || true
  rm -rf "$path"
  echo "  Moved: $path → $dest" >&2
  _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" --arg d "$dest" \
    '{resource_type: $rt, path: $p, status: "success", detail: ("moved to " + $d)}')"
done

# data_migration リソースを処理
for i in $(seq 0 $((resource_count - 1))); do
  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  [[ "$resource_type" != "data_migration" ]] && continue

  path=$(jq -r ".resources[$i].path" "$MANIFEST")

  if [[ ! -f "$path" ]]; then
    echo "  Data file not found: $path" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "error", detail: "file not found"}')"
    continue
  fi

  echo "  Migrating data: $path ..." >&2

  # docs/aidlc パス参照を {{aidlc_dir}} テンプレート変数に置換
  if grep -q 'docs/aidlc' "$path"; then
    tmp=$(mktemp)
    sed 's|docs/aidlc|{{aidlc_dir}}|g' "$path" > "$tmp" && mv "$tmp" "$path"
    echo "  Migrated: $path (docs/aidlc → {{aidlc_dir}})" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "success", detail: "Replaced docs/aidlc with {{aidlc_dir}}"}')"
  else
    echo "  Skipped: $path (no docs/aidlc references)" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "skipped", detail: "no docs/aidlc references found"}')"
  fi
done

# .aidlc/cycles/ 配下のプロジェクト共通ファイルを .aidlc/ 直下に移動
for shared_file in rules.md operations.md; do
  old_path=".aidlc/cycles/${shared_file}"
  new_path=".aidlc/${shared_file}"
  if [[ -f "$old_path" ]] && [[ ! -f "$new_path" ]]; then
    mv "$old_path" "$new_path"
    echo "  Moved: $old_path → $new_path" >&2
    _add_applied "$(jq -n --arg p "$old_path" --arg d "$new_path" \
      '{resource_type: "file_relocation", path: $p, status: "success", detail: ("moved to " + $d)}')"
  fi
done

# journal JSON 出力
jq -n --arg phase "data" --argjson applied "$APPLIED" \
  '{phase: $phase, applied: $applied}'
