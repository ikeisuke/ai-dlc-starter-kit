#!/usr/bin/env bash
#
# test_validate_cycle.sh - validate.sh の validate_cycle() ユニットテスト
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# 共通ライブラリから関数を読み込み
source "${SCRIPT_DIR}/../lib/validate.sh"

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

echo ""
echo "-- SemVer形式 --"
for tc in "v1.0.0" "v1.21.1" "v0.0.1" "v10.20.30"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "通常形式: $tc" 0 "$rc"
done

echo ""
echo "-- 名前付きSemVer形式 --"
for tc in "waf/v1.0.0" "my-project/v2.0.0" "a1/v0.0.1"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "名前付き形式: $tc" 0 "$rc"
done

echo ""
echo "-- prerelease付き --"
for tc in "v1.0.0-rc.1" "v1.0.0-beta" "v1.0.0-alpha.2.3"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "prerelease付き: $tc" 0 "$rc"
done

echo ""
echo "-- 名前付き+prerelease --"
for tc in "waf/v1.0.0-beta" "my-project/v2.0.0-rc.1"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "名前付き+prerelease: $tc" 0 "$rc"
done

echo ""
echo "-- カスタム名（新規対応） --"
for tc in "feature-auth" "2026-03" "not-a-version" "bugfix-123" "release-candidate"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "カスタム名: $tc" 0 "$rc"
done

echo ""
echo "-- 名前付きカスタム名 --"
for tc in "team/feature-auth" "ns/2026-03"; do
    validate_cycle "$tc"; rc=$?
    assert_exit_code "名前付きカスタム: $tc" 0 "$rc"
done

echo ""
echo "--- 異常系（拒否） ---"

echo ""
echo "-- 空文字 --"
validate_cycle "" 2>/dev/null && rc=0 || rc=$?
assert_exit_code "空文字" 1 "$rc"

echo ""
echo "-- パストラバーサル --"
for tc in "../v1.0.0" "v1.0.0-.." "name/../v1.0.0"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "パストラバーサル: $tc" 1 "$rc"
done

echo ""
echo "-- 多重スラッシュ --"
for tc in "foo/bar/v1.0.0" "a/b/v1.0.0"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "多重スラッシュ: $tc" 1 "$rc"
done

echo ""
echo "-- 大文字名 --"
for tc in "FOO/v1.0.0" "Waf/v1.0.0"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "大文字名: $tc" 1 "$rc"
done

echo ""
echo "-- スペース含む --"
for tc in "hello world" "v 1.0.0"; do
    validate_cycle "$tc" && rc=0 || rc=$?
    assert_exit_code "スペース含む: $tc" 1 "$rc"
done

echo ""
echo "-- 先頭スラッシュ --"
validate_cycle "/v1.0.0" && rc=0 || rc=$?
assert_exit_code "先頭スラッシュ: /v1.0.0" 1 "$rc"

echo ""
echo "-- 連続スラッシュ --"
validate_cycle "name//v1.0.0" && rc=0 || rc=$?
assert_exit_code "連続スラッシュ: name//v1.0.0" 1 "$rc"

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
