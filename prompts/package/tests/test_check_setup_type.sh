#!/usr/bin/env bash
#
# test_check_setup_type.sh - check-setup-type.sh のユニットテスト
# not_foundフォールバック改善を検証
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_BIN="${SCRIPT_DIR}/../../../prompts/setup/bin"
PASS=0
FAIL=0

assert_output() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" = "$actual" ]]; then
        echo "  PASS: $test_name"
        ((++PASS))
    else
        echo "  FAIL: $test_name (expected='$expected', actual='$actual')"
        ((++FAIL))
    fi
}

WORK_DIR=$(mktemp -d)
trap '\rm -rf "$WORK_DIR"' EXIT

# daselスタブ: 実際のdaselが無い環境でもテスト可能にする
STUB_DIR="$WORK_DIR/__stub__"
mkdir -p "$STUB_DIR"
if ! command -v dasel >/dev/null 2>&1; then
    cat > "$STUB_DIR/dasel" << 'STUB'
#!/usr/bin/env bash
input=$(cat)
value=$(echo "$input" | grep 'starter_kit_version' | sed 's/.*= *"\(.*\)".*/\1/')
echo "$value"
STUB
    chmod +x "$STUB_DIR/dasel"
fi

# 共通ヘルパー: テストケースをセットアップして実行
run_setup_type_test() {
    local case_name="$1"
    local version_txt="$2"
    local aidlc_toml="$3"
    local project_toml="$4"
    local expected="$5"

    local case_dir="$WORK_DIR/$case_name"
    mkdir -p "$case_dir/docs" "$case_dir/prompts/setup/bin"
    cp "${SETUP_BIN}/check-setup-type.sh" "$case_dir/prompts/setup/bin/"
    cp "${SETUP_BIN}/check-version.sh" "$case_dir/prompts/setup/bin/"

    if [[ "$version_txt" != "__ABSENT__" ]]; then
        echo "$version_txt" > "$case_dir/version.txt"
    fi
    if [[ "$aidlc_toml" != "__ABSENT__" ]]; then
        echo "$aidlc_toml" > "$case_dir/docs/aidlc.toml"
    fi
    if [[ "$project_toml" = "__PRESENT__" ]]; then
        mkdir -p "$case_dir/docs/aidlc"
        touch "$case_dir/docs/aidlc/project.toml"
    fi

    cd "$case_dir"
    local output
    output=$(PATH="$STUB_DIR:$PATH" bash prompts/setup/bin/check-setup-type.sh 2>/dev/null || true)
    assert_output "$case_name" "$expected" "$output"
}

echo "=== check-setup-type.sh テスト ==="

echo ""
echo "--- 正常系 ---"
run_setup_type_test "バージョン一致→cycle_start" "1.22.0" 'starter_kit_version = "1.22.0"' "__ABSENT__" "setup_type:cycle_start"
run_setup_type_test "v付きversion.txt→cycle_start" "v1.22.0" 'starter_kit_version = "1.22.0"' "__ABSENT__" "setup_type:cycle_start"

echo ""
echo "--- フォールバック改善 ---"
run_setup_type_test "aidlc.toml+version.txt欠落→upgrade" "__ABSENT__" 'starter_kit_version = "1.22.0"' "__ABSENT__" "setup_type:upgrade:unknown:unknown"
run_setup_type_test "aidlc.toml+null値→upgrade" "1.22.0" 'starter_kit_version = "null"' "__ABSENT__" "setup_type:upgrade:unknown:unknown"
run_setup_type_test "aidlc.toml+空文字値→upgrade" "1.22.0" 'starter_kit_version = ""' "__ABSENT__" "setup_type:upgrade:unknown:unknown"

echo ""
echo "--- aidlc.toml非存在 ---"
run_setup_type_test "aidlc.toml非存在→initial" "1.22.0" "__ABSENT__" "__ABSENT__" "setup_type:initial"

echo ""
echo "--- migration ---"
run_setup_type_test "project.tomlのみ→migration" "__ABSENT__" "__ABSENT__" "__PRESENT__" "setup_type:migration"

echo ""
echo "--- upgrade_available ---"
run_setup_type_test "アップグレード可能" "1.23.0" 'starter_kit_version = "1.22.0"' "__ABSENT__" "setup_type:upgrade:1.22.0:1.23.0"

echo ""
echo "--- warning_newer ---"
run_setup_type_test "プロジェクトが新しい" "1.20.0" 'starter_kit_version = "1.22.0"' "__ABSENT__" "setup_type:warning_newer:1.22.0:1.20.0"

echo ""
echo "--- 未知ステータス（wildcard→unknown） ---"
# check-version.shをスタブ化して未知ステータスを返すケース
UNKNOWN_CASE_DIR="$WORK_DIR/unknown_status"
mkdir -p "$UNKNOWN_CASE_DIR/docs" "$UNKNOWN_CASE_DIR/prompts/setup/bin"
cp "${SETUP_BIN}/check-setup-type.sh" "$UNKNOWN_CASE_DIR/prompts/setup/bin/"
cat > "$UNKNOWN_CASE_DIR/prompts/setup/bin/check-version.sh" << 'VSTUB'
#!/usr/bin/env bash
echo "version_status:weird_state"
VSTUB
chmod +x "$UNKNOWN_CASE_DIR/prompts/setup/bin/check-version.sh"
echo 'starter_kit_version = "1.22.0"' > "$UNKNOWN_CASE_DIR/docs/aidlc.toml"
cd "$UNKNOWN_CASE_DIR"
OUTPUT=$(PATH="$STUB_DIR:$PATH" bash prompts/setup/bin/check-setup-type.sh 2>/dev/null || true)
assert_output "未知ステータス→unknown" "setup_type:" "$OUTPUT"

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
