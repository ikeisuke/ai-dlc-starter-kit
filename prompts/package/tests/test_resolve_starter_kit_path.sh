#!/usr/bin/env bash
#
# test_resolve_starter_kit_path.sh - resolve-starter-kit-path.sh のユニットテスト
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TMPDIR_BASE=""

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

cleanup() {
    if [[ -n "$TMPDIR_BASE" && -d "$TMPDIR_BASE" ]]; then
        \rm -rf "$TMPDIR_BASE"
    fi
}

trap cleanup EXIT

echo "=== resolve-starter-kit-path.sh tests ==="

# --- テスト1: メタ開発モード（prompts/package/bin/ から実行） ---
echo ""
echo "--- メタ開発モード ---"

# 実際のスクリプトがメタ開発モードで動作するか確認
# スクリプトは prompts/package/bin/ にあるので、メタ開発モードになるはず
RESULT=$("$SCRIPT_DIR/../bin/resolve-starter-kit-path.sh")
# prompts/package/bin/../../../ = スターターキットルート
EXPECTED_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
assert_eq "meta-dev mode resolves correctly" "$EXPECTED_ROOT" "$RESULT"

# --- テスト2: 利用プロジェクトモード（docs/aidlc/bin/ を模擬） ---
echo ""
echo "--- 利用プロジェクトモード ---"

TMPDIR_BASE=$(mktemp -d)

# 模擬ディレクトリ構造を作成
mkdir -p "$TMPDIR_BASE/project/docs/aidlc/bin"
\cp "$SCRIPT_DIR/../bin/resolve-starter-kit-path.sh" "$TMPDIR_BASE/project/docs/aidlc/bin/"
chmod +x "$TMPDIR_BASE/project/docs/aidlc/bin/resolve-starter-kit-path.sh"

# 模擬スターターキットルート
mkdir -p "$TMPDIR_BASE/starter-kit"

# テスト2a: AIDLC_STARTER_KIT_PATH 設定済み
AIDLC_STARTER_KIT_PATH="$TMPDIR_BASE/starter-kit" \
    "$TMPDIR_BASE/project/docs/aidlc/bin/resolve-starter-kit-path.sh" > "$TMPDIR_BASE/output.txt" 2>&1 && rc=0 || rc=$?
assert_exit_code "user-project mode with valid env" 0 "$rc"
RESULT=$(cat "$TMPDIR_BASE/output.txt")
EXPECTED="$(cd "$TMPDIR_BASE/starter-kit" && pwd)"
assert_eq "user-project mode resolves to env path" "$EXPECTED" "$RESULT"

# テスト2b: AIDLC_STARTER_KIT_PATH 未設定
unset AIDLC_STARTER_KIT_PATH 2>/dev/null || true
"$TMPDIR_BASE/project/docs/aidlc/bin/resolve-starter-kit-path.sh" > "$TMPDIR_BASE/output.txt" 2>&1 && rc=0 || rc=$?
assert_exit_code "user-project mode without env fails" 1 "$rc"

# テスト2c: AIDLC_STARTER_KIT_PATH が存在しないディレクトリ
AIDLC_STARTER_KIT_PATH="$TMPDIR_BASE/nonexistent" \
    "$TMPDIR_BASE/project/docs/aidlc/bin/resolve-starter-kit-path.sh" > "$TMPDIR_BASE/output.txt" 2>&1 && rc=0 || rc=$?
assert_exit_code "user-project mode with nonexistent dir fails" 1 "$rc"

# テスト2d: AIDLC_STARTER_KIT_PATH が相対パスの場合でも絶対パスを返す
cd "$TMPDIR_BASE"
AIDLC_STARTER_KIT_PATH="starter-kit" \
    "$TMPDIR_BASE/project/docs/aidlc/bin/resolve-starter-kit-path.sh" > "$TMPDIR_BASE/output.txt" 2>&1 && rc=0 || rc=$?
assert_exit_code "user-project mode with relative path succeeds" 0 "$rc"
RESULT=$(cat "$TMPDIR_BASE/output.txt")
# 結果は絶対パスであること（/ で始まる）
if [[ "$RESULT" == /* ]]; then
    echo "  PASS: relative path normalized to absolute"
    ((++PASS))
else
    echo "  FAIL: relative path not normalized (got: $RESULT)"
    ((++FAIL))
fi

# --- テスト3: symlink経由の実行 ---
echo ""
echo "--- symlink解決 ---"

mkdir -p "$TMPDIR_BASE/symlink-test"
ln -s "$SCRIPT_DIR/../bin/resolve-starter-kit-path.sh" "$TMPDIR_BASE/symlink-test/resolve.sh"

# symlink先のスクリプトのSCRIPT_DIRが正しく解決されるか
RESULT=$("$TMPDIR_BASE/symlink-test/resolve.sh") && rc=0 || rc=$?
assert_exit_code "symlink execution succeeds" 0 "$rc"
assert_eq "symlink resolves to real path" "$EXPECTED_ROOT" "$RESULT"

# --- テスト4: 不明なディレクトリからの実行 ---
echo ""
echo "--- 不明ディレクトリ ---"

mkdir -p "$TMPDIR_BASE/unknown/dir"
\cp "$SCRIPT_DIR/../bin/resolve-starter-kit-path.sh" "$TMPDIR_BASE/unknown/dir/"
chmod +x "$TMPDIR_BASE/unknown/dir/resolve-starter-kit-path.sh"
"$TMPDIR_BASE/unknown/dir/resolve-starter-kit-path.sh" > "$TMPDIR_BASE/output.txt" 2>&1 && rc=0 || rc=$?
assert_exit_code "unknown directory fails" 1 "$rc"

cleanup

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
