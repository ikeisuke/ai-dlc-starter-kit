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
AIDLC_PROJECT_ROOT="${AIDLC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}" || {
  echo "error:project-root-not-found" >&2; exit 2
}
if ! git -C "$AIDLC_PROJECT_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "error:invalid-project-root:$AIDLC_PROJECT_ROOT" >&2; exit 2
fi

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

  if [[ -f "$dest" ]]; then
    # 宛先が存在する場合、ソースが残っていれば削除（中断リカバリ）
    if [[ -f "$path" ]]; then
      rm -f "$path"
      echo "  Already migrated: $dest (removed stale source: $path)" >&2
      _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" --arg d "$dest" \
        '{resource_type: $rt, path: $p, status: "skipped", detail: ("already exists: " + $d + " (removed stale source)")}')"
    else
      echo "  Already migrated: $dest (skipping)" >&2
      _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" --arg d "$dest" \
        '{resource_type: $rt, path: $p, status: "skipped", detail: ("already exists: " + $d)}')"
    fi
    continue
  fi

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

# Unit 001（v2.5.1）: feedback_mode_migrate リソースを処理
# migrate-feedback-mode.sh が manifest に積み込んだ {from, to, consent_outcome} を読み取り、
# write-config.sh ラッパで .aidlc/config.toml の rules.retrospective.feedback_mode を書き換える。
# 純粋適用層（対話制御は行わない）。書込失敗時は exit ≥ 1 を上位 aidlc-migrate に伝播。
# 診断出力は `<level>\t<code>\t<detail>` 形式（既存部は段階移行のため未統一だが、新規追加分は準拠）。
FEEDBACK_MODE_MIGRATE_FAILED=0
for i in $(seq 0 $((resource_count - 1))); do
  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  [[ "$resource_type" != "feedback_mode_migrate" ]] && continue

  fm_from=$(jq -r ".resources[$i].from" "$MANIFEST")
  fm_to=$(jq -r ".resources[$i].to" "$MANIFEST")
  fm_consent=$(jq -r ".resources[$i].consent_outcome" "$MANIFEST")

  # to が空または null の場合は skip
  if [[ -z "$fm_to" || "$fm_to" == "null" ]]; then
    printf 'warn\tfeedback_mode_to_missing\t%s\n' "from=${fm_from}" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg from "$fm_from" \
      '{resource_type: $rt, from: $from, status: "skipped", detail: "to value missing"}')"
    continue
  fi

  # 入力検証（多層防御 / write-config.sh 側のバリデーションに加えて適用層でも enum チェック）
  case "$fm_to" in
    interactive|local-issue-only|mirror-only|local-and-mirror|disabled) : ;;
    *)
      printf 'error\tfeedback_mode_invalid_to\t%s\n' "$fm_to" >&2
      _add_applied "$(jq -n --arg rt "$resource_type" --arg from "$fm_from" --arg to "$fm_to" \
        '{resource_type: $rt, from: $from, to: $to, status: "error", detail: ("invalid to value: " + $to), reason_code: "feedback_mode_invalid_to"}')"
      FEEDBACK_MODE_MIGRATE_FAILED=1
      continue
      ;;
  esac

  # write-config.sh で rules.retrospective.feedback_mode を新値に書込
  write_config_script="${AIDLC_PROJECT_ROOT}/skills/aidlc/scripts/write-config.sh"
  if [[ ! -x "$write_config_script" ]]; then
    printf 'error\tfeedback_mode_write_config_missing\t%s\n' "$write_config_script" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg from "$fm_from" --arg to "$fm_to" \
      '{resource_type: $rt, from: $from, to: $to, status: "error", detail: "write-config.sh not found", reason_code: "write_config_missing"}')"
    FEEDBACK_MODE_MIGRATE_FAILED=1
    continue
  fi
  fm_write_rc=0
  if "$write_config_script" rules.retrospective.feedback_mode "$fm_to" --scope project >&2; then
    printf 'info\tfeedback_mode_migrated\t%s\n' "from=${fm_from} to=${fm_to} consent=${fm_consent}" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg from "$fm_from" --arg to "$fm_to" --arg consent "$fm_consent" \
      '{resource_type: $rt, from: $from, to: $to, consent_outcome: $consent, status: "success", detail: ("feedback_mode migrated: " + $from + " -> " + $to + " (consent: " + $consent + ")")}')"
  else
    fm_write_rc=$?
    printf 'error\tfeedback_mode_write_failed\texit=%d\n' "$fm_write_rc" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg from "$fm_from" --arg to "$fm_to" --arg rc "$fm_write_rc" \
      '{resource_type: $rt, from: $from, to: $to, status: "error", detail: ("write-config.sh exit " + $rc), reason_code: "feedback_mode_write_failed"}')"
    FEEDBACK_MODE_MIGRATE_FAILED=1
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
  migrate_script_exit_code=0
  if [[ -x "$migrate_script" ]]; then
    echo "  Running migrate-config.sh for content migration..." >&2
    migrate_output=$("$migrate_script" --config "$config_dest" 2>&1) || migrate_script_exit_code=$?
    echo "  migrate-config.sh completed (exit: $migrate_script_exit_code)" >&2
    if [[ "$migrate_script_exit_code" -eq 0 ]]; then
      _add_applied "$(jq -n --arg detail "$migrate_output" '{resource_type: "config_content_migrate", path: ".aidlc/config.toml", status: "success", detail: ("migrate-config.sh: " + $detail)}')"
    else
      _add_applied "$(jq -n --arg detail "$migrate_output" --arg rc "$migrate_script_exit_code" '{resource_type: "config_content_migrate", path: ".aidlc/config.toml", status: "error", detail: ("migrate-config.sh failed (exit " + $rc + "): " + $detail)}')"
    fi
  fi

  # starter_kit_version 更新（migrate-config.sh 成功時のみ）
  # プラグインの version.txt を参照（AIDLC_PROJECT_ROOT は対象リポジトリを指すため使用しない）
  _version_txt="${SCRIPT_DIR}/../../aidlc/version.txt"
  if [[ "$migrate_script_exit_code" -ne 0 ]]; then
    echo "  Skipped: starter_kit_version update (config migration failed)" >&2
    _add_applied "$(jq -n '{resource_type: "version_update", path: ".aidlc/config.toml", status: "skipped", detail: "config migration failed, version update skipped", reason_code: "config_migration_failed"}')"
  elif [[ ! -f "$_version_txt" ]]; then
    echo "  Skipped: starter_kit_version update (version.txt not found)" >&2
    _add_applied "$(jq -n '{resource_type: "version_update", path: ".aidlc/config.toml", status: "skipped", detail: "version.txt not found", reason_code: "canonical_version_unavailable"}')"
  else
    _canonical_version=$(cat "$_version_txt" | tr -d '[:space:]')
    if [[ -z "$_canonical_version" ]]; then
      echo "  Skipped: starter_kit_version update (version.txt is empty)" >&2
      _add_applied "$(jq -n '{resource_type: "version_update", path: ".aidlc/config.toml", status: "skipped", detail: "version.txt is empty", reason_code: "canonical_version_unavailable"}')"
    else
      # sed で starter_kit_version を更新（dasel v2 互換性のため）
      if grep -q '^[[:space:]]*starter_kit_version[[:space:]]*=' "$config_dest"; then
        # キーが存在する場合: 値を置換
        _tmp_config=$(mktemp)
        if sed 's/^\([[:space:]]*starter_kit_version[[:space:]]*=[[:space:]]*\)"[^"]*"/\1"'"$_canonical_version"'"/' "$config_dest" > "$_tmp_config" && mv "$_tmp_config" "$config_dest"; then
          echo "  Updated: starter_kit_version = $_canonical_version" >&2
          _add_applied "$(jq -n --arg v "$_canonical_version" '{resource_type: "version_update", path: ".aidlc/config.toml", status: "success", detail: ("starter_kit_version updated to " + $v), expected_version: $v}')"
        else
          rm -f "$_tmp_config"
          echo "  Error: starter_kit_version update (sed write failed)" >&2
          _add_applied "$(jq -n --arg v "$_canonical_version" '{resource_type: "version_update", path: ".aidlc/config.toml", status: "error", detail: "sed write failed", expected_version: $v, reason_code: "sed_write_failed"}')"
        fi
      else
        # キーが存在しない場合（v1からの移行等）: ファイル先頭に挿入
        _tmp_config=$(mktemp)
        if { echo "starter_kit_version = \"$_canonical_version\""; cat "$config_dest"; } > "$_tmp_config" && mv "$_tmp_config" "$config_dest"; then
          echo "  Inserted: starter_kit_version = $_canonical_version (key was absent)" >&2
          _add_applied "$(jq -n --arg v "$_canonical_version" '{resource_type: "version_update", path: ".aidlc/config.toml", status: "success", detail: ("starter_kit_version inserted as " + $v), expected_version: $v}')"
        else
          rm -f "$_tmp_config"
          echo "  Error: starter_kit_version insert (write failed)" >&2
          _add_applied "$(jq -n --arg v "$_canonical_version" '{resource_type: "version_update", path: ".aidlc/config.toml", status: "error", detail: "insert write failed", expected_version: $v, reason_code: "insert_write_failed"}')"
        fi
      fi
    fi
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

# Unit 001（v2.5.1）: feedback_mode_migrate に書込失敗があった場合は非0を返し、
# 上位 aidlc-migrate の rollback 経路に書込失敗を伝播する。
if [[ "${FEEDBACK_MODE_MIGRATE_FAILED:-0}" -ne 0 ]]; then
  exit 1
fi
