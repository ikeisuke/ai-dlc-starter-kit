#!/bin/bash
# ワイルドカードルール検出のテスト
# jq版とpython3版の両方で同一テストケースを検証（バックエンド同値性テスト）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# カラー出力（TTY接続時のみ）
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN=''
  RED=''
  NC=''
fi

run_jq_test() {
  local settings_json="$1"
  local defaults_json="$2"

  echo "$settings_json" | jq --argjson defaults "$defaults_json" '
    .permissions //= {} |
    .permissions.allow //= [] |
    .permissions.allow as $existing |
    ($defaults - $existing) as $new_candidates |
    ($existing | map(select(type == "string" and endswith(":*)")))) as $wildcards |
    [
      $new_candidates[] |
      . as $candidate |
      if ($candidate | type) != "string" then $candidate
      elif ($candidate | test("^[^(]+\\(")) then
        ($candidate | split("(") | .[0]) as $cand_type |
        ($candidate | split("(") | .[1:] | join("(") | rtrimstr(")")) as $cand_path |
        if [
          $wildcards[] |
          select(type == "string" and test("^[^(]+\\(")) |
          (split("(") | .[0]) as $wc_type |
          (split("(") | .[1:] | join("(") | rtrimstr(":*)")) as $wc_prefix |
          select($wc_type == $cand_type and ($cand_path | startswith($wc_prefix)))
        ] | length > 0 then empty
        else $candidate
        end
      else $candidate
      end
    ] as $new |
    ($new_candidates | length) - ($new | length) as $skipped |
    {new_count: ($new | length), skipped_count: $skipped}
  '
}

run_python_test() {
  local settings_json="$1"
  local defaults_json="$2"

  python3 -c "
import json, sys, re

def is_covered_by_wildcard(rule, wildcards):
    if not isinstance(rule, str):
        return False
    m = re.match(r'^([^(]+)\((.+)\)\$', rule)
    if not m:
        return False
    cand_type, cand_path = m.group(1), m.group(2)
    for wc in wildcards:
        wm = re.match(r'^([^(]+)\((.*):\*\)\$', wc)
        if not wm:
            continue
        wc_type, wc_prefix = wm.group(1), wm.group(2)
        if wc_type == cand_type and cand_path.startswith(wc_prefix):
            return True
    return False

settings = json.loads(sys.argv[1])
defaults = json.loads(sys.argv[2])
existing = settings.get('permissions', {}).get('allow', [])
existing_set = set(existing)
new_candidates = [p for p in defaults if p not in existing_set]
wildcards = [r for r in existing if isinstance(r, str) and r.endswith(':*)')]
new_patterns = [p for p in new_candidates if not is_covered_by_wildcard(p, wildcards)]
skipped = len(new_candidates) - len(new_patterns)
print(json.dumps({'new_count': len(new_patterns), 'skipped_count': skipped}))
" "$settings_json" "$defaults_json"
}

assert_result() {
  local test_name="$1"
  local backend="$2"
  local actual="$3"
  local expected_new="$4"
  local expected_skipped="$5"

  local actual_new actual_skipped
  actual_new=$(echo "$actual" | jq -r '.new_count')
  actual_skipped=$(echo "$actual" | jq -r '.skipped_count')

  if [ "$actual_new" = "$expected_new" ] && [ "$actual_skipped" = "$expected_skipped" ]; then
    printf "${GREEN}PASS${NC} [%s] %s: new=%s skipped=%s\n" "$backend" "$test_name" "$actual_new" "$actual_skipped"
    PASS=$((PASS + 1))
  else
    printf "${RED}FAIL${NC} [%s] %s: expected new=%s skipped=%s, got new=%s skipped=%s\n" \
      "$backend" "$test_name" "$expected_new" "$expected_skipped" "$actual_new" "$actual_skipped"
    FAIL=$((FAIL + 1))
  fi
}

run_test() {
  local test_name="$1"
  local settings_json="$2"
  local defaults_json="$3"
  local expected_new="$4"
  local expected_skipped="$5"

  # jq版テスト
  if command -v jq >/dev/null 2>&1; then
    local jq_result
    jq_result=$(run_jq_test "$settings_json" "$defaults_json")
    assert_result "$test_name" "jq" "$jq_result" "$expected_new" "$expected_skipped"
  fi

  # python3版テスト
  if command -v python3 >/dev/null 2>&1; then
    local py_result
    py_result=$(run_python_test "$settings_json" "$defaults_json")
    assert_result "$test_name" "py" "$py_result" "$expected_new" "$expected_skipped"
  fi
}

# ============================================
# テストケース定義
# ============================================

DEFAULTS='["Bash(docs/aidlc/bin/:*)", "Bash(mktemp /tmp/aidlc-:*)", "Skill(reviewing-architecture)", "Skill(reviewing-code)"]'

echo "=== Wildcard Rule Detection Tests ==="
echo ""

# Test 1: 既存に完全一致のルールがある場合（ワイルドカードスキップなし）
run_test "exact match - no wildcard skip" \
  '{"permissions":{"allow":["Bash(docs/aidlc/bin/:*)","Bash(mktemp /tmp/aidlc-:*)"]}}' \
  "$DEFAULTS" \
  2 0

# Test 2: 広いワイルドカードが狭いワイルドカードをカバー
run_test "broader wildcard covers narrower" \
  '{"permissions":{"allow":["Bash(docs/:*)","Bash(mktemp /tmp/:*)"]}}' \
  "$DEFAULTS" \
  2 2

# Test 3: Skill(:*) が全Skillルールをカバー
run_test "Skill(:*) covers all Skills" \
  '{"permissions":{"allow":["Skill(:*)"]}}' \
  "$DEFAULTS" \
  2 2

# Test 4: 異なるType間でワイルドカード判定が適用されないこと
run_test "different type - no cross-type matching" \
  '{"permissions":{"allow":["Skill(docs/aidlc/bin/:*)"]}}' \
  "$DEFAULTS" \
  4 0

# Test 5: 既存ルールが空の場合
run_test "empty existing - all new" \
  '{"permissions":{"allow":[]}}' \
  "$DEFAULTS" \
  4 0

# Test 6: 全ワイルドカードで全ルールカバー
run_test "all covered by wildcards" \
  '{"permissions":{"allow":["Bash(docs/:*)","Bash(mktemp /tmp/:*)","Skill(:*)"]}}' \
  "$DEFAULTS" \
  0 4

# Test 7: 部分的ワイルドカード（Bashのみカバー）
run_test "partial wildcard - Bash only" \
  '{"permissions":{"allow":["Bash(:*)"]}}' \
  "$DEFAULTS" \
  2 2

# Test 8: 不正形式のルールは非包含として扱う
run_test "malformed rules treated as non-covered" \
  '{"permissions":{"allow":["not-a-valid-rule"]}}' \
  "$DEFAULTS" \
  4 0

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
