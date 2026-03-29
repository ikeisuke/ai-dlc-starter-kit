#!/usr/bin/env bash
#
# migrate-apply-config.sh - config.toml パス参照の更新
#
# 使用方法:
#   ./migrate-apply-config.sh --manifest <path>
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

# v1_config_move リソースを処理（docs/aidlc.toml → .aidlc/config.toml）
resource_count=$(jq '.resources | length' "$MANIFEST")
for i in $(seq 0 $((resource_count - 1))); do
  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  [[ "$resource_type" != "v1_config_move" ]] && continue

  path=$(jq -r ".resources[$i].path" "$MANIFEST")
  dest=$(jq -r ".resources[$i].destination" "$MANIFEST")

  if [[ ! -f "$path" ]]; then
    echo "  Source config not found: $path" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "error", detail: "source file not found"}')"
    continue
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$path" "$dest"
  rm -f "$path"
  echo "  Moved: $path → $dest" >&2
  _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" --arg d "$dest" \
    '{resource_type: $rt, path: $p, status: "success", detail: ("moved to " + $d)}')"
done

# config_update リソースを処理
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

# v1→v2 コンテンツマイグレーション: 廃止セクション削除
config_dest=".aidlc/config.toml"
if [[ -f "$config_dest" ]]; then
  # [paths] セクション削除（v2ではプラグインモデルのため不要）
  if grep -q '^\[paths\]' "$config_dest"; then
    tmp=$(mktemp)
    awk '/^\[paths\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip' "$config_dest" > "$tmp" && mv "$tmp" "$config_dest"
    echo "  Removed: [paths] section (deprecated in v2)" >&2
    _add_applied "$(jq -n '{resource_type: "config_content_migrate", path: ".aidlc/config.toml", status: "success", detail: "removed deprecated [paths] section"}')"
  fi

  # [inception.dependabot] セクション削除（v1.13.0で廃止）
  if grep -q '^\[inception\.dependabot\]' "$config_dest"; then
    tmp=$(mktemp)
    awk '/^\[inception\.dependabot\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip' "$config_dest" > "$tmp" && mv "$tmp" "$config_dest"
    echo "  Removed: [inception.dependabot] section (deprecated in v1.13.0)" >&2
    _add_applied "$(jq -n '{resource_type: "config_content_migrate", path: ".aidlc/config.toml", status: "success", detail: "removed deprecated [inception.dependabot] section"}')"
  fi

  # migrate-config.sh を実行して不足セクション補完・リネーム移行
  migrate_script="${SCRIPT_DIR}/migrate-config.sh"
  if [[ -x "$migrate_script" ]]; then
    echo "  Running migrate-config.sh for content migration..." >&2
    migrate_output=$("$migrate_script" --config "$config_dest" 2>&1) || true
    echo "  migrate-config.sh completed" >&2
    _add_applied "$(jq -n --arg detail "$migrate_output" '{resource_type: "config_content_migrate", path: ".aidlc/config.toml", status: "success", detail: ("migrate-config.sh: " + $detail)}')"
  fi
fi

# AGENTS.md / CLAUDE.md からv1/旧v2のAI-DLC参照行を削除
# スキル機構で自動発見されるため、AGENTS.md/CLAUDE.mdへの参照は不要
for ref_file in AGENTS.md CLAUDE.md; do
  if [[ -f "$ref_file" ]] && grep -q '@docs/aidlc/prompts/\|@skills/aidlc/\|@\.aidlc/' "$ref_file"; then
    tmp=$(mktemp)
    grep -v '@docs/aidlc/prompts/\|@skills/aidlc/AGENTS\|@skills/aidlc/CLAUDE\|@\.aidlc/AGENTS\|@\.aidlc/CLAUDE' "$ref_file" > "$tmp" && mv "$tmp" "$ref_file"
    echo "  Cleaned: $ref_file (removed AI-DLC references, handled by skill mechanism)" >&2
    _add_applied "$(jq -n --arg p "$ref_file" '{resource_type: "ref_cleanup", path: $p, status: "success", detail: "removed AI-DLC references (skill mechanism handles discovery)"}')"
  fi
done

# journal JSON 出力
jq -n --arg phase "config" --argjson applied "$APPLIED" \
  '{phase: $phase, applied: $applied}'
