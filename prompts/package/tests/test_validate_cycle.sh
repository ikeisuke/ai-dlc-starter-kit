#!/usr/bin/env bash
#
# test_validate_cycle.sh - write-history.sh の validate_cycle() ユニットテスト
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# write-history.sh から validate_cycle 関数を抽出
eval "$(sed -n '/^validate_cycle()/,/^}/p' "$SCRIPT_DIR/../bin/write-history.sh")"

assert_exit_code() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" -eq "$actual" ]]; then
        echo "  PASS: $test_name"
        ((++PASS))
    else
        echo "  FAIL: $test_name (expected exit=$expected, actual exit=$actual)"
        ((++FAIL))
    fi
}

echo "=== validate_cycle() テスト ==="

echo ""
echo "--- 正常系（受け入れ） ---"

for tc in "v1.0.0" "v1.21.1" "v0.0.1" "v10.20.30"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "通常形式: $tc" 0 "$rc"
done

for tc in "waf/v1.0.0" "my-project/v2.0.0" "a1/v0.0.1"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "名前付き形式: $tc" 0 "$rc"
done

for tc in "v1.0.0-rc.1" "v1.0.0-beta" "v1.0.0-alpha.2.3"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "prerelease付き: $tc" 0 "$rc"
done

for tc in "waf/v1.0.0-beta" "my-project/v2.0.0-rc.1"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "名前付き+prerelease: $tc" 0 "$rc"
done

echo ""
echo "--- 異常系（拒否） ---"

validate_cycle "" 2>/dev/null && rc=0 || rc=$?
assert_exit_code "空文字" 1 "$rc"

for tc in "../v1.0.0" "v1.0.0-.." "name/../v1.0.0"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "パストラバーサル: $tc" 1 "$rc"
done

for tc in "foo/bar/v1.0.0" "a/b/v1.0.0"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "多重スラッシュ: $tc" 1 "$rc"
done

for tc in "FOO/v1.0.0" "Waf/v1.0.0"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "大文字名: $tc" 1 "$rc"
done

for tc in "hello world" "v 1.0.0"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "スペース含む: $tc" 1 "$rc"
done

validate_cycle "/v1.0.0" && rc=0 || rc=$?
assert_exit_code "先頭スラッシュ: /v1.0.0" 1 "$rc"

for tc in "name/v1.2" "v1" "v1.0" "name/v1"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "不完全バージョン: $tc" 1 "$rc"
done

validate_cycle "name//v1.0.0" && rc=0 || rc=$?
assert_exit_code "連続スラッシュ: name//v1.0.0" 1 "$rc"

validate_cycle "not-a-version" && rc=0 || rc=$?
assert_exit_code "バージョンなし: not-a-version" 1 "$rc"

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
