#!/usr/bin/env bash
#
# test_emit_error.sh - validate.sh の emit_error() ユニットテスト
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# 共通ライブラリから関数を読み込み
source "${SCRIPT_DIR}/../lib/validate.sh"

assert_output() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $test_name"
        ((++PASS))
    else
        echo "  FAIL: $test_name (expected='$expected', actual='$actual')"
        ((++FAIL))
    fi
}

echo "=== emit_error() テスト ==="
echo ""

echo "--- コード+メッセージ ---"

result=$(emit_error "test-code" "test message")
assert_output "基本形式" "error:test-code:test message" "$result"

result=$(emit_error "gh-not-installed" "gh is not installed")
assert_output "ケバブケースコード" "error:gh-not-installed:gh is not installed" "$result"

result=$(emit_error "missing-value" "--option requires a value")
assert_output "オプション系メッセージ" "error:missing-value:--option requires a value" "$result"

echo ""
echo "--- コードのみ（メッセージ省略） ---"

result=$(emit_error "no-message")
assert_output "メッセージ省略" "error:no-message" "$result"

result=$(emit_error "simple-code" "")
assert_output "空文字メッセージ" "error:simple-code" "$result"

echo ""
echo "--- 特殊文字を含むメッセージ ---"

result=$(emit_error "special-chars" "File not found: /path/to/file.txt")
assert_output "パス含むメッセージ" "error:special-chars:File not found: /path/to/file.txt" "$result"

result=$(emit_error "colon-in-msg" "key:value format")
assert_output "コロン含むメッセージ" "error:colon-in-msg:key:value format" "$result"

echo ""
echo "=== 結果: PASS=${PASS}, FAIL=${FAIL} ==="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
