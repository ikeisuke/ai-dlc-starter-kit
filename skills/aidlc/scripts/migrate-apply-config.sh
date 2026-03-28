#!/usr/bin/env bash
#
# migrate-apply-config.sh - config.toml パス参照の更新
#
# 使用方法:
#   ./migrate-apply-config.sh --manifest <path> --backup-dir <path>
#
# 出力:
#   stdout: journal JSON（phase: "config"）
#   stderr: 適用処理の診断メッセージ
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

# config_update リソースを処理
resource_count=$(jq '.resources | length' "$MANIFEST")
for i in $(seq 0 $((resource_count - 1))); do
  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  [[ "$resource_type" != "config_update" ]] && continue

  path=$(jq -r ".resources[$i].path" "$MANIFEST")

  if [[ ! -f "$path" ]]; then
    echo "  Config file not found: $path" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "error", detail: "file not found"}')"
    continue
  fi

  echo "  Updating paths in $path ..." >&2

  # docs/aidlc → skills/aidlc に置換（paths.aidlc_dir の値）
  if grep -q 'docs/aidlc' "$path"; then
    # 安全な一時ファイルパターン
    tmp=$(mktemp)
    sed 's|"docs/aidlc"|"skills/aidlc"|g; s|docs/aidlc|skills/aidlc|g' "$path" > "$tmp" && mv "$tmp" "$path"
    echo "  Updated: $path (docs/aidlc → skills/aidlc)" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "success", detail: "Updated paths.aidlc_dir: docs/aidlc -> skills/aidlc"}')"
  else
    echo "  Skipped: $path (no docs/aidlc references)" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "skipped", detail: "no docs/aidlc references found"}')"
  fi
done

# journal JSON 出力
jq -n --arg phase "config" --argjson applied "$APPLIED" \
  '{phase: $phase, applied: $applied}'
