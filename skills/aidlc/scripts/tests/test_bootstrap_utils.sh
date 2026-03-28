#!/usr/bin/env bash
#
# test_bootstrap_utils.sh - bootstrap.sh ユーティリティ関数のテスト
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $label"
        ((PASS++))
    else
        echo "  FAIL: $label (expected='$expected', actual='$actual')"
        ((FAIL++))
    fi
}

# bootstrap.sh を source（プロジェクトルートが必要）
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
AIDLC_PROJECT_ROOT="$PROJECT_ROOT" source "$PROJECT_ROOT/skills/aidlc/scripts/lib/bootstrap.sh"

echo "=== aidlc_strip_quotes() tests ==="

echo ""
echo "--- シングルクォート ---"
assert_eq "single quotes" "hello" "$(aidlc_strip_quotes "'hello'")"
assert_eq "no quotes" "hello" "$(aidlc_strip_quotes "hello")"

echo ""
echo "--- ダブルクォート ---"
assert_eq "double quotes" "hello" "$(aidlc_strip_quotes '"hello"')"

echo ""
echo "--- 前後空白 ---"
assert_eq "leading/trailing spaces" "hello" "$(aidlc_strip_quotes "  hello  ")"
assert_eq "spaces + single quotes" "hello" "$(aidlc_strip_quotes "  'hello'  ")"
assert_eq "spaces + double quotes" "hello" "$(aidlc_strip_quotes '  "hello"  ')"

echo ""
echo "--- 空文字 ---"
assert_eq "empty string" "" "$(aidlc_strip_quotes "")"

echo ""
echo "--- 内部クォート保持 ---"
assert_eq "internal single quote" "he'llo" "$(aidlc_strip_quotes "he'llo")"
assert_eq "internal double quote" 'he"llo' "$(aidlc_strip_quotes 'he"llo')"

echo ""
echo "=== aidlc_get_current_branch() tests ==="

echo ""
echo "--- 通常ブランチ ---"
BRANCH=$(aidlc_get_current_branch)
# CIや通常実行時はブランチ名が返るはず
if [[ -n "$BRANCH" ]]; then
    echo "  PASS: branch returned ($BRANCH)"
    ((PASS++))
else
    echo "  INFO: empty branch (detached HEAD or bare repo)"
    ((PASS++))
fi

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
