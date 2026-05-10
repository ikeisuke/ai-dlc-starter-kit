#!/usr/bin/env bash
#
# test_update_version_no_toml_write.sh - bin/update-version.sh の
# marketplace.json SoT 化（v2.6.0 / Unit 003 / Issue #617）の regression テスト。
#
# 検証対象（v2.6.0 仕様）:
#  - 出力フォーマット: marketplace_version_* / marketplace_version: の出力
#  - .claude-plugin/marketplace.json の metadata.version 更新
#  - .aidlc/config.toml.starter_kit_version は更新されない（互換維持）
#  - エラーチェック（marketplace-json-not-found / invalid-version-format）
#  - dry-run 動作（実書き込みなし）
#  - 末尾改行保持
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_VERSION_SRC="${SCRIPT_DIR}/../update-version.sh"
LIB_SRC="${SCRIPT_DIR}/../../skills/aidlc/scripts/lib/version.sh"
TMPDIR_BASE=""
COUNTER_FILE=""

# --- テストヘルパー ---

setup_tmpdir() {
    TMPDIR_BASE=$(mktemp -d)
    COUNTER_FILE="${TMPDIR_BASE}/.test_counters"
    printf '0\n0\n' > "$COUNTER_FILE"
}

cleanup_tmpdir() {
    if [ -n "$TMPDIR_BASE" ] && [ -d "$TMPDIR_BASE" ]; then
        \rm -rf "$TMPDIR_BASE"
    fi
}
trap cleanup_tmpdir EXIT

_inc_pass() {
    local pass fail
    { read -r pass; read -r fail; } < "$COUNTER_FILE"
    printf '%d\n%d\n' "$(( pass + 1 ))" "$fail" > "$COUNTER_FILE"
}

_inc_fail() {
    local pass fail
    { read -r pass; read -r fail; } < "$COUNTER_FILE"
    printf '%d\n%d\n' "$pass" "$(( fail + 1 ))" > "$COUNTER_FILE"
}

assert_eq() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $test_name"
        _inc_pass
    else
        echo "  FAIL: $test_name"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        _inc_fail
    fi
}

assert_contains() {
    local test_name="$1"
    local expected_substring="$2"
    local actual="$3"
    if printf '%s' "$actual" | grep -qF "$expected_substring"; then
        echo "  PASS: $test_name"
        _inc_pass
    else
        echo "  FAIL: $test_name (expected to contain '$expected_substring')"
        echo "    actual: $actual"
        _inc_fail
    fi
}

assert_not_contains() {
    local test_name="$1"
    local unexpected_substring="$2"
    local actual="$3"
    if printf '%s' "$actual" | grep -qF "$unexpected_substring"; then
        echo "  FAIL: $test_name (expected NOT to contain '$unexpected_substring')"
        echo "    actual: $actual"
        _inc_fail
    else
        echo "  PASS: $test_name"
        _inc_pass
    fi
}

# fixture をセットアップ
# $1: ワークスペース dir, $2: marketplace.json metadata.version の初期値,
# $3: config.toml starter_kit_version の初期値
setup_fixture() {
    local workspace="$1"
    local existing_marketplace_version="$2"
    local existing_toml_version="$3"

    mkdir -p "${workspace}/bin" \
             "${workspace}/skills/aidlc/scripts/lib" \
             "${workspace}/.claude-plugin" \
             "${workspace}/.aidlc"

    \cp "$UPDATE_VERSION_SRC" "${workspace}/bin/update-version.sh"
    chmod +x "${workspace}/bin/update-version.sh"
    \cp "$LIB_SRC" "${workspace}/skills/aidlc/scripts/lib/version.sh"

    cat > "${workspace}/.claude-plugin/marketplace.json" <<JSON
{
  "name": "fixture-plugin",
  "metadata": {
    "description": "fixture",
    "version": "${existing_marketplace_version}"
  }
}
JSON

    printf 'starter_kit_version = "%s"\n' "$existing_toml_version" > "${workspace}/.aidlc/config.toml"
}

run_update_version() {
    local workspace="$1"
    shift
    (cd "$workspace" && bash bin/update-version.sh "$@" 2>&1)
}

read_marketplace_version_test() {
    local workspace="$1"
    jq -r '.metadata.version' "${workspace}/.claude-plugin/marketplace.json"
}

# --- テスト本体 ---

echo "=== bin/update-version.sh marketplace.json SoT 化テスト（v2.6.0） ==="

setup_tmpdir

# ============================================================
# ケース1: dry-run 出力 + 書き込みなし
# ============================================================
echo ""
echo "[Case 1] dry-run 出力に marketplace_version_current/new が含まれ、書き込みは行われない"
ws1="${TMPDIR_BASE}/case1"
mkdir -p "$ws1"
setup_fixture "$ws1" "2.5.0" "2.5.0"

actual_ec=0
actual=$(run_update_version "$ws1" --version 9.9.9 --dry-run) || actual_ec=$?
assert_eq "case1: 終了コード 0" 0 "$actual_ec"
assert_contains "case1: version_update:dry-run 含む" "version_update:dry-run" "$actual"
assert_contains "case1: marketplace_version_current 含む" "marketplace_version_current:2.5.0" "$actual"
assert_contains "case1: marketplace_version_new 含む" "marketplace_version_new:9.9.9" "$actual"
assert_not_contains "case1: 旧キー version_txt_current が含まれない" "version_txt_current" "$actual"
assert_not_contains "case1: 旧キー skill_aidlc_version_current が含まれない" "skill_aidlc_version_current" "$actual"

# 実書き込みされていない
mp_after=$(read_marketplace_version_test "$ws1")
assert_eq "case1: marketplace.json は変更されない" "2.5.0" "$mp_after"

# ============================================================
# ケース2: 通常実行 + 末尾改行保持
# ============================================================
echo ""
echo "[Case 2] 通常実行で marketplace.json が更新され、config.toml は変更されない"
ws2="${TMPDIR_BASE}/case2"
mkdir -p "$ws2"
setup_fixture "$ws2" "2.5.0" "2.4.0"

actual_ec=0
actual=$(run_update_version "$ws2" --version 9.9.9) || actual_ec=$?
assert_eq "case2: 終了コード 0" 0 "$actual_ec"
assert_contains "case2: version_update:success 含む" "version_update:success" "$actual"
assert_contains "case2: marketplace_version 含む" "marketplace_version:9.9.9" "$actual"

mp_after=$(read_marketplace_version_test "$ws2")
assert_eq "case2: marketplace.json metadata.version 更新" "9.9.9" "$mp_after"

# config.toml は不変
toml_value=$(grep -E '^[[:space:]]*starter_kit_version[[:space:]]*=' "${ws2}/.aidlc/config.toml" | head -1)
assert_contains "case2: config.toml starter_kit_version は不変" "2.4.0" "$toml_value"

# 末尾改行を確認
last_byte=$(tail -c 1 "${ws2}/.claude-plugin/marketplace.json")
assert_eq "case2: marketplace.json は末尾改行で終わる" "" "$last_byte"

# ============================================================
# ケース3: v プレフィックス除去
# ============================================================
echo ""
echo "[Case 3] v プレフィックス付きバージョンが正規化される"
ws3="${TMPDIR_BASE}/case3"
mkdir -p "$ws3"
setup_fixture "$ws3" "2.5.0" "2.5.0"

actual_ec=0
actual=$(run_update_version "$ws3" --version v3.1.4) || actual_ec=$?
assert_eq "case3: 終了コード 0" 0 "$actual_ec"
assert_contains "case3: marketplace_version 含む（v 除去）" "marketplace_version:3.1.4" "$actual"

mp_after=$(read_marketplace_version_test "$ws3")
assert_eq "case3: marketplace.json metadata.version 更新（3.1.4）" "3.1.4" "$mp_after"

# ============================================================
# ケース4: 不正バージョンフォーマット
# ============================================================
echo ""
echo "[Case 4] SemVer 不正バージョンは error:invalid-version-format"
ws4="${TMPDIR_BASE}/case4"
mkdir -p "$ws4"
setup_fixture "$ws4" "2.5.0" "2.5.0"

actual_ec=0
actual=$(run_update_version "$ws4" --version not-a-semver) || actual_ec=$?
assert_eq "case4: 終了コード 1" 1 "$actual_ec"
assert_contains "case4: error:invalid-version-format" "error:invalid-version-format" "$actual"

# ============================================================
# ケース5: marketplace.json 不在
# ============================================================
echo ""
echo "[Case 5] marketplace.json 不在は error:marketplace-json-not-found"
ws5="${TMPDIR_BASE}/case5"
mkdir -p "$ws5"
setup_fixture "$ws5" "2.5.0" "2.5.0"
\rm -f "${ws5}/.claude-plugin/marketplace.json"

actual_ec=0
actual=$(run_update_version "$ws5" --version 9.9.9) || actual_ec=$?
assert_eq "case5: 終了コード 1" 1 "$actual_ec"
assert_contains "case5: error:marketplace-json-not-found" "error:marketplace-json-not-found" "$actual"

# ============================================================
# ケース6: --version 値未指定
# ============================================================
echo ""
echo "[Case 6] --version 値未指定は error:missing-version-value"
ws6="${TMPDIR_BASE}/case6"
mkdir -p "$ws6"
setup_fixture "$ws6" "2.5.0" "2.5.0"

actual_ec=0
actual=$(run_update_version "$ws6" --version) || actual_ec=$?
assert_eq "case6: 終了コード 1" 1 "$actual_ec"
assert_contains "case6: error:missing-version-value" "error:missing-version-value" "$actual"

# ============================================================
# ケース7: --version 完全省略
# ============================================================
echo ""
echo "[Case 7] --version 省略は error:missing-version"
ws7="${TMPDIR_BASE}/case7"
mkdir -p "$ws7"
setup_fixture "$ws7" "2.5.0" "2.5.0"

actual_ec=0
actual=$(run_update_version "$ws7" --dry-run) || actual_ec=$?
assert_eq "case7: 終了コード 1" 1 "$actual_ec"
assert_contains "case7: error:missing-version" "error:missing-version" "$actual"

# ============================================================
# ケース8: 不正な metadata.version 値（空文字）
# ============================================================
echo ""
echo "[Case 8] marketplace.json metadata.version が空は error:invalid-marketplace-json-format"
ws8="${TMPDIR_BASE}/case8"
mkdir -p "$ws8"
setup_fixture "$ws8" "" "2.5.0"

actual_ec=0
actual=$(run_update_version "$ws8" --version 9.9.9) || actual_ec=$?
assert_eq "case8: 終了コード 1" 1 "$actual_ec"
assert_contains "case8: error:invalid-marketplace-json-format" "error:invalid-marketplace-json-format" "$actual"

# ============================================================
# 結果集計
# ============================================================
echo ""
echo "=== テスト結果 ==="
{ read -r pass; read -r fail; } < "$COUNTER_FILE"
echo "PASS: $pass"
echo "FAIL: $fail"

if [ "$fail" -gt 0 ]; then
    exit 1
fi
exit 0
