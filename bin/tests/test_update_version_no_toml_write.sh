#!/usr/bin/env bash
#
# test_update_version_no_toml_write.sh - bin/update-version.sh の
# starter_kit_version 上書き廃止の regression テスト（Unit 002 / Issue #596）。
#
# 検証対象:
#  - 出力フォーマット変更: aidlc_toml_* 行の削除（dry-run / success）
#  - .aidlc/config.toml 書き込み廃止（starter_kit_version が保持される）
#  - 既存エラーチェック維持（config-toml-not-found / invalid-config-toml-format）
#  - メタ開発シナリオ（starter_kit_version != version.txt が許容される）
#  - ロールバック整合性（mv 失敗時に version.txt / skills/*/version.txt が元値復元）
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

# サイクル fixture をセットアップ（標準状態: 両 skill ファイル存在）
# $1: ワークスペース dir, $2: 既存 version.txt の値, $3: 既存 starter_kit_version の値
setup_fixture() {
    local workspace="$1"
    local existing_version="$2"
    local existing_toml_version="$3"

    mkdir -p "${workspace}/bin" "${workspace}/skills/aidlc" "${workspace}/skills/aidlc-setup" \
             "${workspace}/skills/aidlc/scripts/lib" "${workspace}/.aidlc"

    # update-version.sh と lib/version.sh を配置
    \cp "$UPDATE_VERSION_SRC" "${workspace}/bin/update-version.sh"
    chmod +x "${workspace}/bin/update-version.sh"
    \cp "$LIB_SRC" "${workspace}/skills/aidlc/scripts/lib/version.sh"

    # version 関連 fixture
    printf '%s\n' "$existing_version" > "${workspace}/version.txt"
    printf 'starter_kit_version = "%s"\n' "$existing_toml_version" > "${workspace}/.aidlc/config.toml"
    printf '%s\n' "$existing_version" > "${workspace}/skills/aidlc/version.txt"
    printf '%s\n' "$existing_version" > "${workspace}/skills/aidlc-setup/version.txt"
}

# 絶対パスで実行するためのヘルパー（workspace を cwd にする）
run_update_version() {
    local workspace="$1"
    shift
    (cd "$workspace" && bash bin/update-version.sh "$@" 2>&1)
}

# --- テスト本体 ---

echo "=== bin/update-version.sh starter_kit_version 上書き廃止テスト ==="

setup_tmpdir

# ============================================================
# ケース1: dry-run 出力に aidlc_toml_* 行が含まれない
# ============================================================
echo ""
echo "[Case 1] dry-run 出力に aidlc_toml_* 行が含まれない"
ws1="${TMPDIR_BASE}/case1"
mkdir -p "$ws1"
setup_fixture "$ws1" "2.3.6" "2.3.6"
actual_ec=0
actual=$(run_update_version "$ws1" --version v9.9.9 --dry-run) || actual_ec=$?
assert_eq "case1: exit code" "0" "$actual_ec"
aidlc_toml_count=$(printf '%s\n' "$actual" | grep -cE '^aidlc_toml_' || true)
assert_eq "case1: aidlc_toml_* 行数" "0" "$aidlc_toml_count"
assert_contains "case1: version_update:dry-run 含む" "version_update:dry-run" "$actual"
assert_contains "case1: version_txt_new 含む" "version_txt_new:9.9.9" "$actual"

# ============================================================
# ケース2: 成功出力に aidlc_toml: 行が含まれず、.aidlc/config.toml が無変更
# ============================================================
echo ""
echo "[Case 2] 成功出力に aidlc_toml: 行が含まれず .aidlc/config.toml 無変更"
ws2="${TMPDIR_BASE}/case2"
mkdir -p "$ws2"
setup_fixture "$ws2" "2.3.6" "2.3.6"
actual_ec=0
actual=$(run_update_version "$ws2" --version v9.9.9) || actual_ec=$?
assert_eq "case2: exit code" "0" "$actual_ec"
aidlc_toml_count=$(printf '%s\n' "$actual" | grep -cE '^aidlc_toml:' || true)
assert_eq "case2: aidlc_toml: 行数" "0" "$aidlc_toml_count"
assert_contains "case2: version_update:success 含む" "version_update:success" "$actual"
# version.txt が 9.9.9 に更新されている
version_txt_after=$(cat "${ws2}/version.txt")
assert_eq "case2: version.txt 更新" "9.9.9" "$version_txt_after"
# .aidlc/config.toml.starter_kit_version が 2.3.6 のまま
toml_after=$(cat "${ws2}/.aidlc/config.toml")
assert_eq "case2: .aidlc/config.toml 保持" 'starter_kit_version = "2.3.6"' "$toml_after"

# ============================================================
# ケース3: .aidlc/config.toml 不在時のエラーチェック維持
# ============================================================
echo ""
echo "[Case 3] .aidlc/config.toml 不在時のエラー維持"
ws3="${TMPDIR_BASE}/case3"
mkdir -p "$ws3"
setup_fixture "$ws3" "2.3.6" "2.3.6"
\rm -f "${ws3}/.aidlc/config.toml"
actual_ec=0
actual=$(run_update_version "$ws3" --version v9.9.9 --dry-run) || actual_ec=$?
assert_eq "case3: exit code (error)" "1" "$actual_ec"
assert_contains "case3: error:config-toml-not-found 含む" "error:config-toml-not-found" "$actual"

# ============================================================
# ケース4: メタ開発シナリオ（starter_kit_version != version.txt 許容）
# ============================================================
echo ""
echo "[Case 4] メタ開発シナリオ（version.txt=2.4.0, starter_kit_version=2.3.6）"
ws4="${TMPDIR_BASE}/case4"
mkdir -p "$ws4"
setup_fixture "$ws4" "2.4.0" "2.3.6"
actual_ec=0
actual=$(run_update_version "$ws4" --version v2.5.0) || actual_ec=$?
assert_eq "case4: exit code" "0" "$actual_ec"
# version.txt が 2.5.0 に更新
version_txt_after=$(cat "${ws4}/version.txt")
assert_eq "case4: version.txt 更新" "2.5.0" "$version_txt_after"
# starter_kit_version が 2.3.6 のまま保持（メタ開発時の独立性が担保される）
toml_after=$(cat "${ws4}/.aidlc/config.toml")
assert_eq "case4: starter_kit_version 保持" 'starter_kit_version = "2.3.6"' "$toml_after"

# ============================================================
# ケース5a: 読み取り検証エラー維持（starter_kit_version キー欠落）
# ============================================================
echo ""
echo "[Case 5a] invalid-config-toml-format (starter_kit_version キー欠落)"
ws5a="${TMPDIR_BASE}/case5a"
mkdir -p "$ws5a"
setup_fixture "$ws5a" "2.3.6" "2.3.6"
# starter_kit_version を削除して別キーに置換
printf 'some_other_key = "value"\n' > "${ws5a}/.aidlc/config.toml"
actual_ec=0
actual=$(run_update_version "$ws5a" --version v9.9.9 --dry-run) || actual_ec=$?
assert_eq "case5a: exit code (error)" "1" "$actual_ec"
assert_contains "case5a: error:invalid-config-toml-format 含む" "error:invalid-config-toml-format" "$actual"

# ============================================================
# ケース5b: 読み取り検証エラー維持（unreadable: chmod 000 で読み取り権限なし）
# read_starter_kit_version の rc=2 経路で error:config-toml-read-failed を返すこと検証。
# 注: root 権限で動作する CI 環境では chmod 000 でも読めるため skip する。
# ============================================================
echo ""
echo "[Case 5b] config-toml-read-failed (unreadable: chmod 000)"
if [ "$(id -u)" = "0" ]; then
    echo "  SKIP: case5b: root 権限環境では chmod 000 が無効化されるため skip"
else
    ws5b="${TMPDIR_BASE}/case5b"
    mkdir -p "$ws5b"
    setup_fixture "$ws5b" "2.3.6" "2.3.6"
    chmod 000 "${ws5b}/.aidlc/config.toml"
    actual_ec=0
    actual=$(run_update_version "$ws5b" --version v9.9.9 --dry-run) || actual_ec=$?
    # 読み取り権限を戻す（cleanup_tmpdir の rm -rf を確実にするため）
    chmod 644 "${ws5b}/.aidlc/config.toml"
    assert_eq "case5b: exit code (error)" "1" "$actual_ec"
    assert_contains "case5b: error:config-toml-read-failed 含む" "error:config-toml-read-failed" "$actual"
fi

# ============================================================
# ケース5c: 読み取り検証エラー維持（starter_kit_version キー重複）
# read_starter_kit_version の rc=1 経路（match_count != 1）の検証
# ============================================================
echo ""
echo "[Case 5c] invalid-config-toml-format (starter_kit_version キー重複)"
ws5c="${TMPDIR_BASE}/case5c"
mkdir -p "$ws5c"
setup_fixture "$ws5c" "2.3.6" "2.3.6"
printf 'starter_kit_version = "2.3.6"\nstarter_kit_version = "2.4.0"\n' > "${ws5c}/.aidlc/config.toml"
actual_ec=0
actual=$(run_update_version "$ws5c" --version v9.9.9 --dry-run) || actual_ec=$?
assert_eq "case5c: exit code (error)" "1" "$actual_ec"
assert_contains "case5c: error:invalid-config-toml-format 含む" "error:invalid-config-toml-format" "$actual"

# ============================================================
# ケース6a: ロールバック整合性（2段階目 mv 失敗）
# mv 順序: version.txt → skills/aidlc/version.txt → skills/aidlc-setup/version.txt
# 2 段階目（skills/aidlc/version.txt の mv）を失敗させ、
# version.txt が元値に復元されることを検証
# ============================================================
echo ""
echo "[Case 6a] ロールバック整合性（2段階目 mv 失敗: skills/aidlc/version.txt）"
ws6a="${TMPDIR_BASE}/case6a"
mkdir -p "$ws6a"
setup_fixture "$ws6a" "2.3.6" "2.3.6"

# 偽 mv スクリプトを配置（skills/aidlc/version.txt への mv で失敗、他は実 mv に委譲）
mkdir -p "${ws6a}/bin_stub"
cat > "${ws6a}/bin_stub/mv" <<'MVSTUB'
#!/usr/bin/env bash
# 偽 mv: 第2引数が skills/aidlc/version.txt のときのみ失敗
if [[ "${2:-}" == "skills/aidlc/version.txt" ]]; then
    echo "mv: mock failure: $2" >&2
    exit 1
fi
# 実 mv に委譲（mock の PATH を除外するため原始パスを使用）
exec /bin/mv "$@"
MVSTUB
chmod +x "${ws6a}/bin_stub/mv"

actual_ec=0
actual=$(cd "$ws6a" && PATH="${ws6a}/bin_stub:$PATH" bash bin/update-version.sh --version v9.9.9 2>&1) || actual_ec=$?
assert_eq "case6a: exit code (error)" "1" "$actual_ec"
assert_contains "case6a: error:skill-aidlc-version-write-failed 含む" "error:skill-aidlc-version-write-failed" "$actual"
# version.txt が 2.3.6 に復元（ロールバック成功）
version_txt_after=$(cat "${ws6a}/version.txt")
assert_eq "case6a: version.txt ロールバック" "2.3.6" "$version_txt_after"
# skills/aidlc/version.txt が 2.3.6 のまま（mv 失敗により未更新）
skill_aidlc_after=$(cat "${ws6a}/skills/aidlc/version.txt")
assert_eq "case6a: skills/aidlc/version.txt 未変更" "2.3.6" "$skill_aidlc_after"
# .aidlc/config.toml が無変更
toml_after=$(cat "${ws6a}/.aidlc/config.toml")
assert_eq "case6a: .aidlc/config.toml 無変更" 'starter_kit_version = "2.3.6"' "$toml_after"

# ============================================================
# ケース6b: ロールバック整合性（3段階目 mv 失敗）
# 3 段階目（skills/aidlc-setup/version.txt の mv）を失敗させ、
# version.txt と skills/aidlc/version.txt の両方が元値に復元されることを検証
# （複数ファイル更新済みからのロールバック経路の本質検証）
# ============================================================
echo ""
echo "[Case 6b] ロールバック整合性（3段階目 mv 失敗: skills/aidlc-setup/version.txt）"
ws6b="${TMPDIR_BASE}/case6b"
mkdir -p "$ws6b"
setup_fixture "$ws6b" "2.3.6" "2.3.6"

mkdir -p "${ws6b}/bin_stub"
cat > "${ws6b}/bin_stub/mv" <<'MVSTUB'
#!/usr/bin/env bash
# 偽 mv: 第2引数が skills/aidlc-setup/version.txt のときのみ失敗
if [[ "${2:-}" == "skills/aidlc-setup/version.txt" ]]; then
    echo "mv: mock failure: $2" >&2
    exit 1
fi
exec /bin/mv "$@"
MVSTUB
chmod +x "${ws6b}/bin_stub/mv"

actual_ec=0
actual=$(cd "$ws6b" && PATH="${ws6b}/bin_stub:$PATH" bash bin/update-version.sh --version v9.9.9 2>&1) || actual_ec=$?
assert_eq "case6b: exit code (error)" "1" "$actual_ec"
assert_contains "case6b: error:skill-setup-version-write-failed 含む" "error:skill-setup-version-write-failed" "$actual"
# version.txt が 2.3.6 に復元
version_txt_after=$(cat "${ws6b}/version.txt")
assert_eq "case6b: version.txt ロールバック" "2.3.6" "$version_txt_after"
# skills/aidlc/version.txt も 2.3.6 に復元（複数ファイル復元の本質検証）
skill_aidlc_after=$(cat "${ws6b}/skills/aidlc/version.txt")
assert_eq "case6b: skills/aidlc/version.txt ロールバック" "2.3.6" "$skill_aidlc_after"
# skills/aidlc-setup/version.txt は未変更
skill_setup_after=$(cat "${ws6b}/skills/aidlc-setup/version.txt")
assert_eq "case6b: skills/aidlc-setup/version.txt 未変更" "2.3.6" "$skill_setup_after"
# .aidlc/config.toml も無変更
toml_after=$(cat "${ws6b}/.aidlc/config.toml")
assert_eq "case6b: .aidlc/config.toml 無変更" 'starter_kit_version = "2.3.6"' "$toml_after"

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
