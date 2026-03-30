#!/usr/bin/env bash
#
# migrate-verify.sh - 移行後検証
#
# 使用方法:
#   ./migrate-verify.sh --manifest <path>
#
# 出力:
#   stdout: verify result JSON（overall: "ok" / "fail"）
#   stderr: 検証処理の診断メッセージ
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

CHECKS="[]"
has_fail=false

_add_check() {
  CHECKS=$(echo "$CHECKS" | jq --argjson c "$1" '. + [$c]')
}

echo "Verifying migration results..." >&2

# 1. config_update 検証: docs/aidlc → skills/aidlc に置換されているか
config_ok=true
config_detail=""
resource_count=$(jq '.resources | length' "$MANIFEST")
for i in $(seq 0 $((resource_count - 1))); do
  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  [[ "$resource_type" != "config_update" ]] && continue
  path=$(jq -r ".resources[$i].path" "$MANIFEST")
  if [[ -f "$path" ]]; then
    if grep -q 'docs/aidlc' "$path" 2>/dev/null; then
      config_ok=false
      config_detail="docs/aidlc references still present"
      echo "  FAIL: $path still contains docs/aidlc references" >&2
    elif ! grep -q 'skills/aidlc' "$path" 2>/dev/null; then
      config_ok=false
      config_detail="skills/aidlc not found after migration"
      echo "  FAIL: $path does not contain expected skills/aidlc references" >&2
    fi
  fi
done

if [[ "$config_ok" == "true" ]]; then
  _add_check "$(jq -n '{name: "config_paths", status: "ok", detail: "Config paths correctly updated to skills/aidlc"}')"
  echo "  OK: config_paths" >&2
else
  _add_check "$(jq -n --arg d "$config_detail" '{name: "config_paths", status: "fail", detail: $d}')"
  has_fail=true
fi

# 2. 削除対象の検証: action=delete のリソースが存在しないか
delete_ok=true
delete_detail=""
for i in $(seq 0 $((resource_count - 1))); do
  action=$(jq -r ".resources[$i].action" "$MANIFEST")
  [[ "$action" != "delete" ]] && continue
  path=$(jq -r ".resources[$i].path" "$MANIFEST")

  if [[ "$path" == */ ]]; then
    if [[ -d "$path" ]]; then
      delete_ok=false
      delete_detail="${delete_detail}${path} still exists; "
      echo "  FAIL: $path still exists" >&2
    fi
  else
    if [[ -f "$path" ]] || [[ -L "$path" ]]; then
      delete_ok=false
      delete_detail="${delete_detail}${path} still exists; "
      echo "  FAIL: $path still exists" >&2
    fi
  fi
done

if [[ "$delete_ok" == "true" ]]; then
  _add_check "$(jq -n '{name: "v1_artifacts_removed", status: "ok", detail: "All v1 artifacts removed"}')"
  echo "  OK: v1_artifacts_removed" >&2
else
  _add_check "$(jq -n --arg d "$delete_detail" '{name: "v1_artifacts_removed", status: "fail", detail: $d}')"
  has_fail=true
fi

# 3. データ移行の検証: data_migration 対象が正しく置換されているか
data_ok=true
data_detail=""
for i in $(seq 0 $((resource_count - 1))); do
  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")
  [[ "$resource_type" != "data_migration" ]] && continue
  path=$(jq -r ".resources[$i].path" "$MANIFEST")
  if [[ -f "$path" ]]; then
    if grep -q 'docs/aidlc' "$path" 2>/dev/null; then
      data_ok=false
      data_detail="docs/aidlc references still present in $path"
      echo "  FAIL: $path still contains docs/aidlc references" >&2
    elif ! grep -q '{{aidlc_dir}}' "$path" 2>/dev/null; then
      data_ok=false
      data_detail="{{aidlc_dir}} not found in $path after migration"
      echo "  FAIL: $path does not contain expected {{aidlc_dir}} references" >&2
    fi
  fi
done

if [[ "$data_ok" == "true" ]]; then
  _add_check "$(jq -n '{name: "data_migrated", status: "ok", detail: "All data files migrated"}')"
  echo "  OK: data_migrated" >&2
else
  _add_check "$(jq -n --arg d "$data_detail" '{name: "data_migrated", status: "fail", detail: $d}')"
  has_fail=true
fi

# overall 判定
if [[ "$has_fail" == "true" ]]; then
  overall="fail"
  echo "Verification FAILED." >&2
else
  overall="ok"
  echo "Verification passed." >&2
fi

jq -n --argjson checks "$CHECKS" --arg overall "$overall" \
  '{checks: $checks, overall: $overall}'
