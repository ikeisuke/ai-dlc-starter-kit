#!/usr/bin/env bash
#
# test_root_commit_helpers.sh - is_root_commit/safe_log_range/rebase_base_args のユニットテスト
#
# 一時的なgitリポジトリを作成してルートコミット関連の関数をテストする。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TMPDIR_BASE=""

# squash-unit.sh から関数定義を抽出
eval "$(sed -n '/^is_root_commit()/,/^}/p' "$SCRIPT_DIR/../bin/squash-unit.sh")"
eval "$(sed -n '/^safe_log_range()/,/^}/p' "$SCRIPT_DIR/../bin/squash-unit.sh")"
eval "$(sed -n '/^rebase_base_args()/,/^}/p' "$SCRIPT_DIR/../bin/squash-unit.sh")"

assert_eq() {
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

setup_test_repo() {
    TMPDIR_BASE=$(mktemp -d)
    cd "$TMPDIR_BASE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
}

cleanup_test_repo() {
    if [[ -n "$TMPDIR_BASE" && -d "$TMPDIR_BASE" ]]; then
        \rm -rf "$TMPDIR_BASE"
    fi
}

trap cleanup_test_repo EXIT

echo "=== is_root_commit() tests ==="

setup_test_repo

# ルートコミット作成
echo "file1" > file1.txt
git add file1.txt
git commit -q -m "root commit"
ROOT_HASH=$(git rev-parse HEAD)

# ルートコミット判定
is_root_commit "$ROOT_HASH" && rc=0 || rc=$?
assert_exit_code "root commit detected" 0 "$rc"

# 2つ目のコミット
echo "file2" > file2.txt
git add file2.txt
git commit -q -m "second commit"
SECOND_HASH=$(git rev-parse HEAD)

# 非ルートコミット判定
is_root_commit "$SECOND_HASH" && rc=0 || rc=$?
assert_exit_code "non-root commit detected" 1 "$rc"

# shortハッシュでも動作
SHORT_ROOT=$(git rev-parse --short "$ROOT_HASH")
is_root_commit "$SHORT_ROOT" && rc=0 || rc=$?
assert_exit_code "root commit with short hash" 0 "$rc"

cleanup_test_repo

echo ""
echo "=== safe_log_range() tests ==="

setup_test_repo

# ルートコミット
echo "file1" > file1.txt
git add file1.txt
git commit -q -m "root commit"
ROOT_HASH=$(git rev-parse HEAD)

# 2つ目のコミット
echo "file2" > file2.txt
git add file2.txt
git commit -q -m "second commit"
SECOND_HASH=$(git rev-parse HEAD)

# 3つ目のコミット
echo "file3" > file3.txt
git add file3.txt
git commit -q -m "third commit"
THIRD_HASH=$(git rev-parse HEAD)

# ルートコミットが先頭の場合: last のみを返す
result=$(safe_log_range "$ROOT_HASH" "$THIRD_HASH")
assert_eq "root commit range returns last only" "$THIRD_HASH" "$result"

# 非ルートコミットが先頭の場合: first^..last を返す
result=$(safe_log_range "$SECOND_HASH" "$THIRD_HASH")
expected="${SECOND_HASH}^..${THIRD_HASH}"
assert_eq "non-root range returns first^..last" "$expected" "$result"

cleanup_test_repo

echo ""
echo "=== rebase_base_args() tests ==="

setup_test_repo

# ルートコミット
echo "file1" > file1.txt
git add file1.txt
git commit -q -m "root commit"
ROOT_HASH=$(git rev-parse HEAD)

# 2つ目のコミット
echo "file2" > file2.txt
git add file2.txt
git commit -q -m "second commit"
SECOND_HASH=$(git rev-parse HEAD)

# ルートコミット時: --root を返す
result=$(rebase_base_args "$ROOT_HASH")
assert_eq "root commit returns --root" "--root" "$result"

# 非ルートコミット時: first^ を返す
result=$(rebase_base_args "$SECOND_HASH")
expected=$(git rev-parse "${SECOND_HASH}^")
assert_eq "non-root returns parent hash" "$expected" "$result"

cleanup_test_repo

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
