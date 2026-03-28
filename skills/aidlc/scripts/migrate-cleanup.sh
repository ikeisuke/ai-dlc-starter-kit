#!/usr/bin/env bash
#
# migrate-cleanup.sh - manifest宣言済みリソースの削除
#
# 使用方法:
#   ./migrate-cleanup.sh --manifest <path> --backup-dir <path>
#
# 出力:
#   stdout: journal JSON（phase: "cleanup"）
#   stderr: 削除処理の診断メッセージ
#
# 終了コード:
#   0: 成功
#   2: エラー
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed." >&2
  exit 2
fi

# 引数パース
MANIFEST=""
BACKUP_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest)
      [[ $# -lt 2 ]] && { echo "Missing value for --manifest" >&2; exit 2; }
      MANIFEST="$2"; shift 2 ;;
    --backup-dir)
      [[ $# -lt 2 ]] && { echo "Missing value for --backup-dir" >&2; exit 2; }
      BACKUP_DIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$MANIFEST" || -z "$BACKUP_DIR" ]]; then
  echo "Usage: $0 --manifest <path> --backup-dir <path>" >&2
  exit 2
fi

cd "${AIDLC_PROJECT_ROOT}"

APPLIED="[]"

_add_applied() {
  APPLIED=$(echo "$APPLIED" | jq --argjson e "$1" '. + [$e]')
}

# パス安全性検証: プロジェクトルート配下の相対パスのみ許可
_validate_path() {
  local p="$1"
  # 絶対パスを拒否
  if [[ "$p" == /* ]]; then
    echo "  ERROR: absolute path rejected: $p" >&2
    return 1
  fi
  # .. を含むパスを拒否
  if [[ "$p" == *..* ]]; then
    echo "  ERROR: path traversal rejected: $p" >&2
    return 1
  fi
  return 0
}

# 削除対象リソースを処理（action=delete のもののみ）
resource_count=$(jq '.resources | length' "$MANIFEST")
for i in $(seq 0 $((resource_count - 1))); do
  action=$(jq -r ".resources[$i].action" "$MANIFEST")
  [[ "$action" != "delete" ]] && continue

  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  path=$(jq -r ".resources[$i].path" "$MANIFEST")

  # パス安全性検証
  if ! _validate_path "$path"; then
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "error", detail: "path validation failed"}')"
    continue
  fi

  # ディレクトリの場合
  if [[ "$path" == */ ]]; then
    if [[ -d "$path" ]]; then
      rm -rf "$path"
      echo "  Deleted directory: $path" >&2
      _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
        '{resource_type: $rt, path: $p, status: "success", detail: "directory deleted"}')"
    else
      echo "  Skipped (not found): $path" >&2
      _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
        '{resource_type: $rt, path: $p, status: "skipped", detail: "directory not found"}')"
    fi
    continue
  fi

  # ファイル/シンボリックリンクの場合
  if [[ -f "$path" ]] || [[ -L "$path" ]]; then
    rm -f "$path"
    echo "  Deleted: $path" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "success", detail: "file deleted"}')"

    # 親ディレクトリが空になった場合は削除
    parent_dir=$(dirname "$path")
    if [[ -d "$parent_dir" ]] && [[ -z "$(ls -A "$parent_dir" 2>/dev/null)" ]]; then
      rmdir "$parent_dir" 2>/dev/null || true
      echo "  Removed empty directory: $parent_dir" >&2
    fi
  else
    echo "  Skipped (not found): $path" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "skipped", detail: "file not found"}')"
  fi
done

# journal JSON 出力
jq -n --arg phase "cleanup" --argjson applied "$APPLIED" \
  '{phase: $phase, applied: $applied}'
