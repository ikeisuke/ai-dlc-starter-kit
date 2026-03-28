#!/usr/bin/env bash
#
# migrate-detect.sh - v1環境検出・manifest JSON生成
#
# 使用方法:
#   ./migrate-detect.sh
#
# 出力:
#   stdout: manifest JSON
#     - status="v1_detected": v1環境検出、resources非空
#     - status="already_v2": v2環境、resources空配列
#   stderr: 検出プロセスの診断メッセージ
#
# 終了コード:
#   0: 成功
#   2: エラー
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# jq の存在確認
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed. Please install jq to use this script." >&2
  exit 2
fi

# sha256 コマンド（クロスプラットフォーム）
_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "no-sha256-command" >&2
    exit 2
  fi
}

# 既知ファイルのSHA256ハッシュ（スターターキット原本）
declare -A KNOWN_HASHES=(
  [".kiro/agents/aidlc-poc.json"]="96eb617a9cb67269894fcc59c91fecca5e759e2cd6f14b3cd973dbe33c1df5a9"
  [".github/ISSUE_TEMPLATE/backlog.yml"]="be2cec6babb3ec3b43106ddc22cef6e268d7e5c21a947bc4c191b8507910935f"
)

# --- 検出対象の収集 ---

RESOURCES="[]"

_add_resource() {
  local json="$1"
  RESOURCES=$(echo "$RESOURCES" | jq --argjson r "$json" '. + [$r]')
}

cd "${AIDLC_PROJECT_ROOT}"

echo "Detecting v1 artifacts..." >&2

# 1. .agents/skills/ 内のシンボリックリンク（docs/aidlc/ を参照）
if [ -d ".agents/skills" ]; then
  for link in .agents/skills/*/; do
    link="${link%/}"
    [ -L "$link" ] || continue
    target=$(readlink "$link" 2>/dev/null || true)
    if echo "$target" | grep -q "docs/aidlc/"; then
      echo "  Found symlink_agents: $link -> $target" >&2
      _add_resource "$(jq -n \
        --arg rt "symlink_agents" \
        --arg p "$link" \
        --arg a "delete" \
        --arg lt "$target" \
        '{resource_type: $rt, path: $p, action: $a, ownership_evidence: {method: "symlink_target", is_owned: true, expected_hash: null, actual_hash: null}}')"
    fi
  done
fi

# 2. .kiro/skills/ 内のシンボリックリンク
if [ -d ".kiro/skills" ]; then
  for link in .kiro/skills/*/; do
    link="${link%/}"
    [ -L "$link" ] || continue
    target=$(readlink "$link" 2>/dev/null || true)
    if echo "$target" | grep -q "docs/aidlc/"; then
      echo "  Found symlink_kiro: $link -> $target" >&2
      _add_resource "$(jq -n \
        --arg rt "symlink_kiro" \
        --arg p "$link" \
        --arg a "delete" \
        '{resource_type: $rt, path: $p, action: $a, ownership_evidence: {method: "symlink_target", is_owned: true, expected_hash: null, actual_hash: null}}')"
    fi
  done
fi

# 3. .kiro/agents/aidlc.json シンボリックリンク
if [ -L ".kiro/agents/aidlc.json" ]; then
  target=$(readlink ".kiro/agents/aidlc.json" 2>/dev/null || true)
  if echo "$target" | grep -q "docs/aidlc/"; then
    echo "  Found symlink_kiro: .kiro/agents/aidlc.json -> $target" >&2
    _add_resource "$(jq -n \
      --arg rt "symlink_kiro" \
      --arg p ".kiro/agents/aidlc.json" \
      --arg a "delete" \
      '{resource_type: $rt, path: $p, action: $a, ownership_evidence: {method: "symlink_target", is_owned: true, expected_hash: null, actual_hash: null}}')"
  fi
fi

# 4. .kiro/agents/aidlc-poc.json 実体ファイル（ハッシュ検証）
if [ -f ".kiro/agents/aidlc-poc.json" ] && [ ! -L ".kiro/agents/aidlc-poc.json" ]; then
  actual_hash=$(_sha256 ".kiro/agents/aidlc-poc.json")
  expected_hash="${KNOWN_HASHES[".kiro/agents/aidlc-poc.json"]}"
  if [ "$actual_hash" = "$expected_hash" ]; then
    echo "  Found file_kiro: .kiro/agents/aidlc-poc.json (hash match)" >&2
    _add_resource "$(jq -n \
      --arg rt "file_kiro" \
      --arg p ".kiro/agents/aidlc-poc.json" \
      --arg a "delete" \
      --arg eh "$expected_hash" \
      --arg ah "$actual_hash" \
      '{resource_type: $rt, path: $p, action: $a, ownership_evidence: {method: "content_hash", is_owned: true, expected_hash: $eh, actual_hash: $ah}}')"
  else
    echo "  Skipping file_kiro: .kiro/agents/aidlc-poc.json (hash mismatch, user-edited)" >&2
  fi
fi

# 5. .aidlc/cycles/backlog/ ディレクトリ（backlog_mode判定）
if [ -d ".aidlc/cycles/backlog" ]; then
  # backlog_mode を読み取り
  backlog_mode=""
  if command -v dasel >/dev/null 2>&1 && [ -f "${AIDLC_CONFIG}" ]; then
    backlog_mode=$(dasel -f "${AIDLC_CONFIG}" -r toml 'rules.backlog.mode' 2>/dev/null | tr -d '"' || true)
  fi
  backlog_mode="${backlog_mode:-issue-only}"

  case "$backlog_mode" in
    issue|issue-only)
      echo "  Found backlog_dir: .aidlc/cycles/backlog/ (mode=$backlog_mode, will delete)" >&2
      _add_resource "$(jq -n \
        --arg rt "backlog_dir" \
        --arg p ".aidlc/cycles/backlog/" \
        --arg a "delete" \
        --arg cond "backlog_mode in [issue, issue-only]" \
        '{resource_type: $rt, path: $p, action: $a, condition: $cond, ownership_evidence: {method: "known_filename", is_owned: true, expected_hash: null, actual_hash: null}}')"
      ;;
    *)
      echo "  Skipping backlog_dir: .aidlc/cycles/backlog/ (mode=$backlog_mode, keeping)" >&2
      ;;
  esac
fi

# 6. .github/ISSUE_TEMPLATE/ 内のスターターキット由来テンプレート
if [ -d ".github/ISSUE_TEMPLATE" ]; then
  for tmpl_name in backlog.yml; do
    tmpl_path=".github/ISSUE_TEMPLATE/$tmpl_name"
    [ -f "$tmpl_path" ] || continue
    [ -L "$tmpl_path" ] && continue  # シンボリックリンクはスキップ
    actual_hash=$(_sha256 "$tmpl_path")
    expected_hash="${KNOWN_HASHES["$tmpl_path"]:-}"
    if [ -n "$expected_hash" ] && [ "$actual_hash" = "$expected_hash" ]; then
      echo "  Found github_template: $tmpl_path (hash match)" >&2
      _add_resource "$(jq -n \
        --arg rt "github_template" \
        --arg p "$tmpl_path" \
        --arg a "delete" \
        --arg eh "$expected_hash" \
        --arg ah "$actual_hash" \
        '{resource_type: $rt, path: $p, action: $a, ownership_evidence: {method: "content_hash", is_owned: true, expected_hash: $eh, actual_hash: $ah}}')"
    else
      echo "  Skipping github_template: $tmpl_path (hash mismatch or unknown, user-edited)" >&2
    fi
  done
fi

# 7. config.toml パス更新チェック（docs/aidlc → skills/aidlc のパス参照）
if [ -f "${AIDLC_CONFIG}" ]; then
  if grep -q 'docs/aidlc' "${AIDLC_CONFIG}" 2>/dev/null; then
    echo "  Found config_update: .aidlc/config.toml (contains docs/aidlc references)" >&2
    _add_resource "$(jq -n \
      --arg rt "config_update" \
      --arg p ".aidlc/config.toml" \
      --arg a "update" \
      '{resource_type: $rt, path: $p, action: $a, ownership_evidence: null}')"
  fi
fi

# 8. cycles配下のデータ移行（テンプレート変数 {{aidlc_dir}} への置換が必要なファイル）
if [ -d "${AIDLC_CYCLES}" ]; then
  while IFS= read -r -d '' file; do
    rel_path="${file#"${AIDLC_PROJECT_ROOT}/"}"
    if grep -q 'docs/aidlc' "$file" 2>/dev/null; then
      echo "  Found data_migration: $rel_path (contains docs/aidlc references)" >&2
      _add_resource "$(jq -n \
        --arg rt "data_migration" \
        --arg p "$rel_path" \
        --arg a "migrate" \
        '{resource_type: $rt, path: $p, action: $a, ownership_evidence: null}')"
    fi
  done < <(find "${AIDLC_CYCLES}" -name "*.md" -type f -print0 2>/dev/null)
fi

# --- manifest JSON 生成 ---

resource_count=$(echo "$RESOURCES" | jq 'length')
if [ "$resource_count" -gt 0 ]; then
  status="v1_detected"
  echo "Detected $resource_count v1 artifacts to migrate." >&2
else
  status="already_v2"
  echo "No v1 artifacts detected. Already v2." >&2
fi

# backlog_mode を取得（manifest に含める）
manifest_backlog_mode=""
if command -v dasel >/dev/null 2>&1 && [ -f "${AIDLC_CONFIG}" ]; then
  manifest_backlog_mode=$(dasel -f "${AIDLC_CONFIG}" -r toml 'rules.backlog.mode' 2>/dev/null | tr -d '"' || true)
fi
manifest_backlog_mode="${manifest_backlog_mode:-issue-only}"

detected_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --argjson version 1 \
  --arg status "$status" \
  --arg detected_at "$detected_at" \
  --arg source_version "v1" \
  --arg target_version "v2" \
  --arg backlog_mode "$manifest_backlog_mode" \
  --argjson resources "$RESOURCES" \
  '{
    version: $version,
    status: $status,
    detected_at: $detected_at,
    source_version: $source_version,
    target_version: $target_version,
    backlog_mode: $backlog_mode,
    resources: $resources
  }'
