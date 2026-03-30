#!/usr/bin/env bash
#
# test_read_starter_kit_version.sh - version.sh の read_starter_kit_version() ユニットテスト
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# 共通ライブラリから関数を読み込み
source "${SCRIPT_DIR}/../lib/version.sh"

# テスト用一時ディレクトリ
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

echo "=== read_starter_kit_version() テスト ==="

echo ""
echo "--- 正常系 ---"

# 正常なconfig.toml
cat > "$TEST_DIR/normal.toml" << 'EOF'
[project]
name = "test-project"
starter_kit_version = "2.0.6"
EOF

rc=0
output=$(read_starter_kit_version "$TEST_DIR/normal.toml") || rc=$?
assert_exit_code "正常なconfig.toml" 0 "$rc"
assert_output "正常なconfig.toml" "2.0.6" "$output"

# prerelease付きバージョン
cat > "$TEST_DIR/prerelease.toml" << 'EOF'
starter_kit_version = "1.0.0-alpha.1"
EOF

rc=0
output=$(read_starter_kit_version "$TEST_DIR/prerelease.toml") || rc=$?
assert_exit_code "prerelease付きバージョン" 0 "$rc"
assert_output "prerelease付きバージョン" "1.0.0-alpha.1" "$output"

# 先頭にスペースがあるキー
cat > "$TEST_DIR/indented.toml" << 'EOF'
  starter_kit_version = "3.0.0"
EOF

rc=0
output=$(read_starter_kit_version "$TEST_DIR/indented.toml") || rc=$?
assert_exit_code "インデント付きキー" 0 "$rc"
assert_output "インデント付きキー" "3.0.0" "$output"

echo ""
echo "--- 異常系（exit 1: バリデーションエラー） ---"

# キー不在
cat > "$TEST_DIR/no_key.toml" << 'EOF'
[project]
name = "test-project"
EOF

rc=0
output=$(read_starter_kit_version "$TEST_DIR/no_key.toml") || rc=$?
assert_exit_code "キー不在" 1 "$rc"

# 複数キー存在
cat > "$TEST_DIR/duplicate.toml" << 'EOF'
starter_kit_version = "1.0.0"
starter_kit_version = "2.0.0"
EOF

rc=0
output=$(read_starter_kit_version "$TEST_DIR/duplicate.toml") || rc=$?
assert_exit_code "複数キー存在" 1 "$rc"

# 値が空
cat > "$TEST_DIR/empty_value.toml" << 'EOF'
starter_kit_version = ""
EOF

rc=0
output=$(read_starter_kit_version "$TEST_DIR/empty_value.toml") || rc=$?
assert_exit_code "値が空" 1 "$rc"

# クォートなし（sedで値抽出できない不正行）
cat > "$TEST_DIR/no_quotes.toml" << 'EOF'
starter_kit_version = 1.2.3
EOF

rc=0
output=$(read_starter_kit_version "$TEST_DIR/no_quotes.toml") || rc=$?
assert_exit_code "クォートなし不正行" 1 "$rc"

echo ""
echo "--- 異常系（exit 2: ファイルエラー） ---"

# ファイル不在
rc=0
output=$(read_starter_kit_version "$TEST_DIR/nonexistent.toml") || rc=$?
assert_exit_code "ファイル不在" 2 "$rc"

# 読み取り権限なし
touch "$TEST_DIR/unreadable.toml"
chmod 000 "$TEST_DIR/unreadable.toml"
rc=0
output=$(read_starter_kit_version "$TEST_DIR/unreadable.toml") || rc=$?
assert_exit_code "読み取り権限なし" 2 "$rc"
chmod 644 "$TEST_DIR/unreadable.toml"

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
