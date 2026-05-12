#!/usr/bin/env bash
#
# migrate-cleanup.sh - manifest宣言済みリソースの削除
#
# 使用方法:
#   ./migrate-cleanup.sh --manifest <path>
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

# Unit 002 (Issue #680): manifest 由来パスのトラバーサル検証ライブラリ
# shellcheck source=lib/path-guard.sh
source "${SCRIPT_DIR}/lib/path-guard.sh"
_aidlc_migrate_path_guard_init
_init_rc=$?
if [[ $_init_rc -ne 0 ]]; then
  exit "$_init_rc"
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

# Unit 002 (Issue #680): 旧 _validate_path 関数は lib/path-guard.sh の _aidlc_migrate_validate_path に統合
# 旧仕様（continue でスキップ）は fail-closed 強化（即 exit 1）に変更。挙動変更は意図通り

# symlink実体化（action=materialize）
resource_count=$(jq '.resources | length' "$MANIFEST")
for i in $(seq 0 $((resource_count - 1))); do
  action=$(jq -r ".resources[$i].action" "$MANIFEST")
  [[ "$action" != "materialize" ]] && continue

  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  path=$(jq -r ".resources[$i].path" "$MANIFEST")

  # Unit 002 (Issue #680): trav 検証（materialize）
  _aidlc_migrate_validate_path "$path" "path" "migrate-cleanup"
  _vrc=$?
  if [[ $_vrc -ne 0 ]]; then exit "$_vrc"; fi

  if [[ -L "$path" ]]; then
    # symlinkの実体を取得してコピーで差し替え
    # readlinkの結果は相対パスの場合があるため、symlinkのディレクトリを基準に解決する
    link_target=$(readlink "$path" 2>/dev/null || true)
    link_dir=$(dirname "$path")
    if [[ "$link_target" == /* ]]; then
      resolved_path="$link_target"
    else
      resolved_path="${link_dir}/${link_target}"
    fi
    if [[ -f "$resolved_path" ]]; then
      tmp=$(mktemp)
      cp "$resolved_path" "$tmp"
      rm -f "$path"
      mv "$tmp" "$path"
      echo "  Materialized: $path (was symlink to $link_target)" >&2
      _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
        '{resource_type: $rt, path: $p, status: "success", detail: "symlink replaced with file"}')"
    else
      echo "  WARN: symlink target not found: $link_target (removing broken symlink)" >&2
      rm -f "$path"
      _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
        '{resource_type: $rt, path: $p, status: "success", detail: "removed broken symlink"}')"
    fi
  else
    echo "  Skipped (not a symlink): $path" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "skipped", detail: "not a symlink"}')"
  fi
done

# 削除対象リソースを処理（action=delete のもののみ）
for i in $(seq 0 $((resource_count - 1))); do
  action=$(jq -r ".resources[$i].action" "$MANIFEST")
  [[ "$action" != "delete" ]] && continue

  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  path=$(jq -r ".resources[$i].path" "$MANIFEST")

  # Unit 002 (Issue #680): trav 検証（delete）
  # 旧仕様の「末尾スラッシュでディレクトリ判定」は維持するため、検証用の path から末尾スラッシュは除去せず渡す
  # _aidlc_migrate_validate_path は末尾スラッシュをそのまま扱える（末尾スラッシュは parent_traversal にも当たらない）
  _aidlc_migrate_validate_path "$path" "path" "migrate-cleanup"
  _vrc=$?
  if [[ $_vrc -ne 0 ]]; then exit "$_vrc"; fi

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

    # 親ディレクトリが空になった場合は再帰的に削除（プロジェクトルートまで）
    parent_dir=$(dirname "$path")
    while [[ -d "$parent_dir" ]] && [[ "$parent_dir" != "." ]] && [[ -z "$(ls -A "$parent_dir" 2>/dev/null)" ]]; do
      rmdir "$parent_dir" 2>/dev/null || break
      echo "  Removed empty directory: $parent_dir" >&2
      parent_dir=$(dirname "$parent_dir")
    done
  else
    echo "  Skipped (not found): $path" >&2
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "skipped", detail: "file not found"}')"
  fi
done

# journal JSON 出力
jq -n --arg phase "cleanup" --argjson applied "$APPLIED" \
  '{phase: $phase, applied: $applied}'
