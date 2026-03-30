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
AIDLC_PROJECT_ROOT="${AIDLC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}" || {
  echo "error:project-root-not-found" >&2; exit 2
}
AIDLC_PLUGIN_ROOT="${AIDLC_PROJECT_ROOT}/skills/aidlc"
AIDLC_CONFIG="${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
AIDLC_CYCLES="${AIDLC_PROJECT_ROOT}/.aidlc/cycles"

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

# 2. .kiro/skills/ 内のシンボリックリンク（docs/aidlc/ を参照）
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

# 3. .kiro/agents/aidlc.json シンボリックリンク → 実体ファイルに差し替え（削除しない）
if [ -L ".kiro/agents/aidlc.json" ]; then
  target=$(readlink ".kiro/agents/aidlc.json" 2>/dev/null || true)
  if echo "$target" | grep -q "docs/aidlc/"; then
    echo "  Found symlink_kiro_agents: .kiro/agents/aidlc.json -> $target (will materialize)" >&2
    _add_resource "$(jq -n \
      --arg rt "symlink_materialize" \
      --arg p ".kiro/agents/aidlc.json" \
      --arg a "materialize" \
      --arg lt "$target" \
      '{resource_type: $rt, path: $p, action: $a, link_target: $lt, ownership_evidence: {method: "symlink_target", is_owned: true, expected_hash: null, actual_hash: null}}')"
  fi
fi

# 4. .kiro/agents/aidlc-poc.json 実体ファイル（保持、削除しない）

# 5. .aidlc/cycles/backlog/ ディレクトリ（v2.0.3以降: 常に削除候補）
# バックログはGitHub Issue固定のため、ローカルディレクトリは不要
if [ -d ".aidlc/cycles/backlog" ]; then
  echo "  Found backlog_dir: .aidlc/cycles/backlog/ (deprecated, will delete)" >&2
  _add_resource "$(jq -n \
    --arg rt "backlog_dir" \
    --arg p ".aidlc/cycles/backlog/" \
    --arg a "delete" \
    --arg cond "backlog_mode deprecated (v2.0.3)" \
    '{resource_type: $rt, path: $p, action: $a, condition: $cond, ownership_evidence: {method: "known_filename", is_owned: true, expected_hash: null, actual_hash: null}}')"
fi

# 6. .github/ISSUE_TEMPLATE/ のスターターキット由来テンプレート（v2で管理廃止）
# スターターキットの原本と比較し、一致すればスターターキット由来と判定して削除対象にする
_starter_kit_root="$(cd "$AIDLC_PLUGIN_ROOT/../.." && pwd)"
for _tmpl_name in backlog.yml bug.yml feature.yml feedback.yml; do
  _tmpl_path=".github/ISSUE_TEMPLATE/${_tmpl_name}"
  [ -f "$_tmpl_path" ] || continue
  _tmpl_origin="${_starter_kit_root}/.github/ISSUE_TEMPLATE/${_tmpl_name}"
  if [ -f "$_tmpl_origin" ]; then
    _origin_hash=$(_sha256 "$_tmpl_origin")
    _actual_hash=$(_sha256 "$_tmpl_path")
    if [ "$_origin_hash" = "$_actual_hash" ]; then
      echo "  Found starter kit template: $_tmpl_path (hash match, v2 no longer manages)" >&2
      _add_resource "$(jq -n \
        --arg p "$_tmpl_path" --arg eh "$_origin_hash" --arg ah "$_actual_hash" \
        '{resource_type: "starter_kit_template", path: $p, action: "delete", ownership_evidence: {method: "starter_kit_hash", is_owned: true, expected_hash: $eh, actual_hash: $ah}}')"
    else
      echo "  Skipping: $_tmpl_path (modified by user)" >&2
    fi
  else
    echo "  Skipping: $_tmpl_path (no starter kit origin to compare)" >&2
  fi
done

# 7. .claude/skills/ 内のシンボリックリンク（docs/aidlc/ を参照）
if [ -d ".claude/skills" ]; then
  for link in .claude/skills/*/; do
    link="${link%/}"
    [ -L "$link" ] || continue
    target=$(readlink "$link" 2>/dev/null || true)
    if echo "$target" | grep -q "docs/aidlc/"; then
      echo "  Found symlink_claude: $link -> $target" >&2
      _add_resource "$(jq -n \
        --arg rt "symlink_claude" \
        --arg p "$link" \
        --arg a "delete" \
        --arg lt "$target" \
        '{resource_type: $rt, path: $p, action: $a, ownership_evidence: {method: "symlink_target", is_owned: true, expected_hash: null, actual_hash: null}}')"
    fi
  done
fi

# 8. docs/aidlc.toml → .aidlc/config.toml 移動（v1設定ファイル）
if [ -f "docs/aidlc.toml" ] && [ ! -f ".aidlc/config.toml" ]; then
  echo "  Found v1_config_move: docs/aidlc.toml (needs move to .aidlc/config.toml)" >&2
  _add_resource "$(jq -n \
    --arg rt "v1_config_move" \
    --arg p "docs/aidlc.toml" \
    --arg a "move" \
    --arg dest ".aidlc/config.toml" \
    '{resource_type: $rt, path: $p, action: $a, destination: $dest, ownership_evidence: {method: "known_filename", is_owned: true, expected_hash: null, actual_hash: null}}')"
elif [ -f "docs/aidlc.toml" ]; then
  echo "  Found v1_config: docs/aidlc.toml (config.toml already exists, will delete)" >&2
  _add_resource "$(jq -n \
    --arg rt "v1_config" \
    --arg p "docs/aidlc.toml" \
    --arg a "delete" \
    '{resource_type: $rt, path: $p, action: $a, ownership_evidence: {method: "known_filename", is_owned: true, expected_hash: null, actual_hash: null}}')"
fi

# 9. docs/aidlc/ ディレクトリ（v1 AIDLCリソース）
if [ -d "docs/aidlc" ]; then
  echo "  Found v1_dir: docs/aidlc/ (v1 AIDLC directory)" >&2
  _add_resource "$(jq -n \
    --arg rt "v1_dir" \
    --arg p "docs/aidlc/" \
    --arg a "delete" \
    '{resource_type: $rt, path: $p, action: $a, ownership_evidence: {method: "known_filename", is_owned: true, expected_hash: null, actual_hash: null}}')"
fi

# 10. docs/cycles/ → .aidlc/cycles/ 移動
if [ -d "docs/cycles" ]; then
  echo "  Found v1_cycles_move: docs/cycles/ (needs move to .aidlc/cycles/)" >&2
  _add_resource "$(jq -n \
    --arg rt "v1_cycles_move" \
    --arg p "docs/cycles/" \
    --arg a "move_dir" \
    --arg dest ".aidlc/cycles/" \
    '{resource_type: $rt, path: $p, action: $a, destination: $dest, ownership_evidence: {method: "known_filename", is_owned: true, expected_hash: null, actual_hash: null}}')"
fi

# 11. config.toml パス更新チェック（docs/aidlc → skills/aidlc のパス参照）
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

# 12. cycles配下のデータ移行（テンプレート変数 {{aidlc_dir}} への置換が必要なファイル）
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

detected_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --argjson version 1 \
  --arg status "$status" \
  --arg detected_at "$detected_at" \
  --arg source_version "v1" \
  --arg target_version "v2" \
  --argjson resources "$RESOURCES" \
  '{
    version: $version,
    status: $status,
    detected_at: $detected_at,
    source_version: $source_version,
    target_version: $target_version,
    resources: $resources
  }'
