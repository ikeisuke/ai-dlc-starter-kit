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
AIDLC_PLUGIN_ROOT="${AIDLC_PLUGIN_ROOT:-${AIDLC_PROJECT_ROOT}/skills/aidlc}"
# AIDLC_PLUGIN_ROOT の妥当性検証: templates/ ディレクトリの存在を確認
if [ ! -d "${AIDLC_PLUGIN_ROOT}/templates" ]; then
  echo "error:invalid-plugin-root:${AIDLC_PLUGIN_ROOT} (templates/ not found)" >&2; exit 2
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

# symlink実体化（action=materialize）
resource_count=$(jq '.resources | length' "$MANIFEST")
for i in $(seq 0 $((resource_count - 1))); do
  action=$(jq -r ".resources[$i].action" "$MANIFEST")
  [[ "$action" != "materialize" ]] && continue

  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  path=$(jq -r ".resources[$i].path" "$MANIFEST")

  if ! _validate_path "$path"; then
    _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
      '{resource_type: $rt, path: $p, status: "error", detail: "path validation failed"}')"
    continue
  fi

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
      # ターゲットが見つからない場合、v2テンプレートからコピー
      template_path="${AIDLC_PLUGIN_ROOT}/templates/${path}"
      if [[ -f "$template_path" ]]; then
        rm -f "$path"
        mkdir -p "$(dirname "$path")"
        cp "$template_path" "$path"
        echo "  Materialized: $path (from v2 template, symlink target not found: $link_target)" >&2
        _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
          '{resource_type: $rt, path: $p, status: "success", detail: "symlink replaced with v2 template"}')"
      else
        echo "  WARN: symlink target not found: $link_target (removing broken symlink)" >&2
        rm -f "$path"
        _add_applied "$(jq -n --arg rt "$resource_type" --arg p "$path" \
          '{resource_type: $rt, path: $p, status: "success", detail: "removed broken symlink"}')"
      fi
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
