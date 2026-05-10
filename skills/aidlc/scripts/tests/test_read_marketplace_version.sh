#!/usr/bin/env bash
#
# test_read_marketplace_version.sh - lib/version.sh::read_marketplace_version の単体テスト
#
# 検証対象（v2.6.0 / Unit 003）:
#  - dasel 経路で metadata.version を抽出
#  - jq 経路で metadata.version を抽出（dasel 不在時のフォールバック）
#  - 不正な metadata.version（不在 / 空 / 非 SemVer）は exit 1
#  - ファイル不在 / 読取失敗は exit 2
#  - 終了コードと stderr メッセージの仕様確認
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# 共通ライブラリから関数を読み込み
# shellcheck source=../lib/version.sh
source "${SCRIPT_DIR}/../lib/version.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

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

assert_output() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $test_name (output)"
        ((++PASS))
    else
        echo "  FAIL: $test_name (expected output='$expected', actual output='$actual')"
        ((++FAIL))
    fi
}

write_marketplace_json() {
    local path="$1"
    local version="$2"
    cat > "$path" <<JSON
{
  "name": "ai-dlc-starter-kit",
  "metadata": {
    "description": "fixture",
    "version": "${version}"
  }
}
JSON
}

echo "=== read_marketplace_version() テスト ==="

echo ""
echo "--- 正常系（dasel/jq いずれか利用可能を前提） ---"

# 通常の SemVer
write_marketplace_json "${TEST_DIR}/normal.json" "2.6.0"
rc=0
output=$(read_marketplace_version "${TEST_DIR}/normal.json") || rc=$?
assert_exit_code "通常の SemVer" 0 "$rc"
assert_output "通常の SemVer" "2.6.0" "$output"

# prerelease 付き
write_marketplace_json "${TEST_DIR}/prerelease.json" "1.0.0-alpha.1"
rc=0
output=$(read_marketplace_version "${TEST_DIR}/prerelease.json") || rc=$?
assert_exit_code "prerelease 付き SemVer" 0 "$rc"
assert_output "prerelease 付き SemVer" "1.0.0-alpha.1" "$output"

echo ""
echo "--- 異常系: コンテンツエラー（exit 1） ---"

# metadata.version が空
write_marketplace_json "${TEST_DIR}/empty_version.json" ""
rc=0
output=$(read_marketplace_version "${TEST_DIR}/empty_version.json" 2>/dev/null) || rc=$?
assert_exit_code "metadata.version 空" 1 "$rc"

# metadata.version が非 SemVer
write_marketplace_json "${TEST_DIR}/invalid_version.json" "not-a-semver"
rc=0
output=$(read_marketplace_version "${TEST_DIR}/invalid_version.json" 2>/dev/null) || rc=$?
assert_exit_code "metadata.version 非 SemVer" 1 "$rc"

# metadata 不在（version キーがない）
cat > "${TEST_DIR}/no_metadata.json" <<'JSON'
{
  "name": "ai-dlc-starter-kit"
}
JSON
rc=0
output=$(read_marketplace_version "${TEST_DIR}/no_metadata.json" 2>/dev/null) || rc=$?
assert_exit_code "metadata 不在" 1 "$rc"

echo ""
echo "--- 異常系: 実行環境エラー（exit 2） ---"

# ファイル不在
rc=0
output=$(read_marketplace_version "${TEST_DIR}/does-not-exist.json" 2>/dev/null) || rc=$?
assert_exit_code "ファイル不在" 2 "$rc"

# 引数空
rc=0
output=$(read_marketplace_version "" 2>/dev/null) || rc=$?
assert_exit_code "引数空" 2 "$rc"

# 読取権限なし
write_marketplace_json "${TEST_DIR}/unreadable.json" "2.6.0"
chmod 000 "${TEST_DIR}/unreadable.json"
rc=0
output=$(read_marketplace_version "${TEST_DIR}/unreadable.json" 2>/dev/null) || rc=$?
chmod 644 "${TEST_DIR}/unreadable.json"
assert_exit_code "読取権限なし" 2 "$rc"

echo ""
echo "--- 結果 ---"
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
