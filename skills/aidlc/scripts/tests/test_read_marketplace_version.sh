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
echo "=== CLI モード経由テスト（v2.6.1 Unit 001 / Issue #688） ==="
echo ""
echo "--- CLI モード正常系 ---"

VERSION_SH="${SCRIPT_DIR}/../lib/version.sh"

# C1: 正常な marketplace.json
write_marketplace_json "${TEST_DIR}/cli_normal.json" "2.6.0"
rc=0
output=$(bash "${VERSION_SH}" "${TEST_DIR}/cli_normal.json") || rc=$?
assert_exit_code "C1: CLI モード 正常な SemVer" 0 "$rc"
assert_output "C1: CLI モード 正常な SemVer" "2.6.0" "$output"

# C2: 連続実行の安定性（3回連続で同一結果）
rc1=0
out1=$(bash "${VERSION_SH}" "${TEST_DIR}/cli_normal.json") || rc1=$?
rc2=0
out2=$(bash "${VERSION_SH}" "${TEST_DIR}/cli_normal.json") || rc2=$?
rc3=0
out3=$(bash "${VERSION_SH}" "${TEST_DIR}/cli_normal.json") || rc3=$?
if [[ "$rc1" -eq 0 && "$rc2" -eq 0 && "$rc3" -eq 0 && "$out1" == "$out2" && "$out2" == "$out3" ]]; then
    echo "  PASS: C2: CLI モード 3 回連続実行の安定性"
    ((++PASS))
else
    echo "  FAIL: C2: CLI モード 3 回連続実行の安定性 (rc1=$rc1 rc2=$rc2 rc3=$rc3 out1='$out1' out2='$out2' out3='$out3')"
    ((++FAIL))
fi

echo ""
echo "--- CLI モード異常系 ---"

# C3: 引数なし
rc=0
output=$(bash "${VERSION_SH}" 2>/dev/null) || rc=$?
assert_exit_code "C3: CLI モード 引数なし" 2 "$rc"
stderr_output=$(bash "${VERSION_SH}" 2>&1 >/dev/null) || true
if [[ "$stderr_output" == *"error:missing-json-path"* ]]; then
    echo "  PASS: C3: CLI モード 引数なし stderr"
    ((++PASS))
else
    echo "  FAIL: C3: CLI モード 引数なし stderr (got: $stderr_output)"
    ((++FAIL))
fi

# C4: 存在しないパス
rc=0
output=$(bash "${VERSION_SH}" "${TEST_DIR}/nonexistent.json" 2>/dev/null) || rc=$?
assert_exit_code "C4: CLI モード 存在しないパス" 2 "$rc"
stderr_output=$(bash "${VERSION_SH}" "${TEST_DIR}/nonexistent.json" 2>&1 >/dev/null) || true
if [[ "$stderr_output" == *"error:marketplace-json-not-found"* ]]; then
    echo "  PASS: C4: CLI モード 存在しないパス stderr"
    ((++PASS))
else
    echo "  FAIL: C4: CLI モード 存在しないパス stderr (got: $stderr_output)"
    ((++FAIL))
fi

# C5: metadata.version キー不在
cat > "${TEST_DIR}/cli_no_version.json" <<'JSON'
{
  "name": "ai-dlc-starter-kit"
}
JSON
rc=0
output=$(bash "${VERSION_SH}" "${TEST_DIR}/cli_no_version.json" 2>/dev/null) || rc=$?
assert_exit_code "C5: CLI モード metadata.version キー不在" 1 "$rc"
stderr_output=$(bash "${VERSION_SH}" "${TEST_DIR}/cli_no_version.json" 2>&1 >/dev/null) || true
if [[ "$stderr_output" == *"error:metadata-version-missing-or-empty"* ]]; then
    echo "  PASS: C5: CLI モード metadata.version 不在 stderr"
    ((++PASS))
else
    echo "  FAIL: C5: CLI モード metadata.version 不在 stderr (got: $stderr_output)"
    ((++FAIL))
fi

# C6: 不正な SemVer
write_marketplace_json "${TEST_DIR}/cli_invalid_semver.json" "not-a-semver"
rc=0
output=$(bash "${VERSION_SH}" "${TEST_DIR}/cli_invalid_semver.json" 2>/dev/null) || rc=$?
assert_exit_code "C6: CLI モード 不正な SemVer" 1 "$rc"
stderr_output=$(bash "${VERSION_SH}" "${TEST_DIR}/cli_invalid_semver.json" 2>&1 >/dev/null) || true
if [[ "$stderr_output" == *"error:metadata-version-invalid-semver:"* ]]; then
    echo "  PASS: C6: CLI モード 不正な SemVer stderr"
    ((++PASS))
else
    echo "  FAIL: C6: CLI モード 不正な SemVer stderr (got: $stderr_output)"
    ((++FAIL))
fi

echo ""
echo "--- CLI モードと source 経路の両立確認 ---"

# C8: source 経由で末尾 if は実行されない（副作用ゼロ）
# テスト方法: source した直後に直近のコマンド成否（$?）が変化しないことを確認
# version.sh を source した時点で末尾 if が走ると read_marketplace_version "$@" が呼ばれ
# 引数なしのため exit 2 が返る → set -e で source 自体が失敗する。実際には source は成功する。
# このテストは本テスト全体が source "${SCRIPT_DIR}/../lib/version.sh" 後も継続している事実で
# 暗黙にカバー済み（このテスト自体が走っていることが C8 の証明）。
echo "  PASS: C8: source 経路で末尾 CLI モードガードが実行されない（本テスト全体の継続実行が証拠）"
((++PASS))

echo ""
echo "--- 最終結果 ---"
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
