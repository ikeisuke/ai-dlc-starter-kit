#!/usr/bin/env bash
#
# test_check_version.sh - check-version.sh のユニットテスト
# vプレフィックス正規化（sanitize_version）を検証
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
    # daselスタブを作成（TOMLからstarter_kit_versionを簡易的に抽出）
    cat > "$STUB_DIR/dasel" << 'STUB'
#!/usr/bin/env bash
# daselスタブ: stdin から starter_kit_version を抽出
input=$(cat)
value=$(echo "$input" | grep 'starter_kit_version' | sed 's/.*= *"\(.*\)".*/\1/')
echo "$value"
STUB
    chmod +x "$STUB_DIR/dasel"
fi

# 共通ヘルパー: テストケースをセットアップして実行
run_version_test() {
    local case_name="$1"
    local version_txt="$2"
    local aidlc_toml="$3"
    local expected="$4"

    local case_dir="$WORK_DIR/$case_name"
    mkdir -p "$case_dir/docs" "$case_dir/prompts/setup/bin"
    cp "${SETUP_BIN}/check-version.sh" "$case_dir/prompts/setup/bin/"

    if [[ "$version_txt" != "__ABSENT__" ]]; then
        echo "$version_txt" > "$case_dir/version.txt"
    fi
    if [[ "$aidlc_toml" != "__ABSENT__" ]]; then
        echo "$aidlc_toml" > "$case_dir/docs/aidlc.toml"
    fi

    cd "$case_dir"
    local output
    output=$(PATH="$STUB_DIR:$PATH" bash prompts/setup/bin/check-version.sh 2>/dev/null || true)
    assert_output "$case_name" "$expected" "$output"
}

echo "=== check-version.sh テスト ==="

echo ""
echo "--- vプレフィックス正規化 ---"
run_version_test "v付きversion.txt同一" "v1.22.0" 'starter_kit_version = "1.22.0"' "version_status:current"
run_version_test "v無しversion.txt同一" "1.22.0" 'starter_kit_version = "1.22.0"' "version_status:current"
run_version_test "v付きversion.txt upgrade" "v1.23.0" 'starter_kit_version = "1.22.0"' "version_status:upgrade_available:1.22.0:1.23.0"
run_version_test "v付きaidlc.toml同一" "1.22.0" 'starter_kit_version = "v1.22.0"' "version_status:current"
run_version_test "両方v付き同一" "v1.22.0" 'starter_kit_version = "v1.22.0"' "version_status:current"

echo ""
echo "--- project_newer ---"
run_version_test "project_newer" "1.20.0" 'starter_kit_version = "1.22.0"' "version_status:project_newer:1.22.0:1.20.0"

echo ""
echo "--- not_found系 ---"
run_version_test "version.txt欠落" "__ABSENT__" 'starter_kit_version = "1.22.0"' "version_status:not_found"
run_version_test "aidlc.toml欠落" "1.22.0" "__ABSENT__" "version_status:not_found"
run_version_test "不正フォーマットversion.txt" "abc" 'starter_kit_version = "1.22.0"' "version_status:not_found"
run_version_test "不正フォーマットaidlc.toml" "1.22.0" 'starter_kit_version = "invalid"' "version_status:not_found"
run_version_test "null値aidlc.toml" "1.22.0" 'starter_kit_version = "null"' "version_status:not_found"
run_version_test "空文字aidlc.toml" "1.22.0" 'starter_kit_version = ""' "version_status:not_found"

echo ""
echo "--- 境界値 ---"
run_version_test "短縮バージョン1.0" "v1.0" 'starter_kit_version = "1.0"' "version_status:current"
run_version_test "単一数字" "v1" 'starter_kit_version = "1"' "version_status:current"

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
