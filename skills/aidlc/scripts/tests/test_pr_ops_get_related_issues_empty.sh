#!/usr/bin/env bash
#
# test_pr_ops_get_related_issues_empty.sh - pr-ops.sh get-related-issues の
# 空配列展開 set -u 安全化 regression テスト（Unit 001 / Issue #588）。
#
# 検証対象: cmd_get_related_issues の closes_list / relates_list の
# 空・非空 4 形態（2x2）と各形態での出力期待値。
#
# bug 修正前は formA/B/C すべてで `unbound variable` で失敗していた。
# 修正後は 4 形態すべてで exit 0 で完走する必要がある。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PR_OPS="${SCRIPT_DIR}/../pr-ops.sh"
TMPDIR_BASE=""
COUNTER_FILE=""

# --- テストヘルパー ---

setup_tmpdir() {
    TMPDIR_BASE=$(mktemp -d)
    COUNTER_FILE="${TMPDIR_BASE}/.test_counters"
    printf '0\n0\n' > "$COUNTER_FILE"
    # AIDLC_PROJECT_ROOT を上書きして bootstrap.sh の git rev-parse 依存を回避
    export AIDLC_PROJECT_ROOT="$TMPDIR_BASE"
    mkdir -p "${TMPDIR_BASE}/.aidlc/cycles/v0.0.0/story-artifacts/units"
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

assert_exit() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $test_name (exit=$actual)"
        _inc_pass
    else
        echo "  FAIL: $test_name (expected exit=$expected, actual=$actual)"
        _inc_fail
    fi
}

# Unit 定義 fixture を書き出す
# $1: スラッグ（ファイル名用）, $2: 関連Issue セクション本文（複数行可）
write_unit_fixture() {
    local slug="$1"
    local issues_body="$2"
    local file="${TMPDIR_BASE}/.aidlc/cycles/v0.0.0/story-artifacts/units/${slug}.md"
    cat > "$file" <<UNITFILE
# Unit: ${slug}

## 概要

テスト用 Unit fixture

## 関連Issue

${issues_body}

## 実装状態

- 状態: 未着手
UNITFILE
}

# 既存 fixture をクリア
clear_fixtures() {
    \rm -f "${TMPDIR_BASE}/.aidlc/cycles/v0.0.0/story-artifacts/units/"*.md
}

# pr-ops.sh get-related-issues 実行
# 出力: stdout、exit code は別途
run_get_related_issues() {
    "$PR_OPS" get-related-issues v0.0.0 2>&1
}

# --- テスト本体 ---

echo "=== pr-ops.sh get-related-issues 空配列展開テスト ==="

setup_tmpdir

# ============================================================
# ケース1（形態 A: 両配列空）: Unit 定義に関連 Issue 0 件
# 修正前は closes_list[@]: unbound variable で fail。
# 修正後は exit 0 で issues:none / closes:none / relates:none を出力。
# ============================================================
echo ""
echo "[Case 1] 形態 A: 関連 Issue 0 件"
clear_fixtures
write_unit_fixture "001-empty" "（関連 Issue なし）"
actual_ec=0
actual=$(run_get_related_issues) || actual_ec=$?
assert_exit "case1: exit code" "0" "$actual_ec"
expected="issues:none
closes:none
relates:none"
assert_eq "case1: stdout" "$expected" "$actual"

# ============================================================
# ケース2（形態 B: closes のみ非空）: closes 1 件のみ
# 修正前は relates_list[@]: unbound variable で fail。
# 修正後は exit 0、issues/closes に #123、relates:none。
# ============================================================
echo ""
echo "[Case 2] 形態 B: closes 1 件のみ"
clear_fixtures
write_unit_fixture "002-closes" "- #123"
actual_ec=0
actual=$(run_get_related_issues) || actual_ec=$?
assert_exit "case2: exit code" "0" "$actual_ec"
expected="issues:#123
closes:#123
relates:none"
assert_eq "case2: stdout" "$expected" "$actual"

# ============================================================
# ケース3（形態 C: relates のみ非空）: relates 1 件のみ
# 修正前は closes_list[@]: unbound variable で fail。
# 修正後は exit 0、issues/relates に #456、closes:none。
# ============================================================
echo ""
echo "[Case 3] 形態 C: relates 1 件のみ"
clear_fixtures
write_unit_fixture "003-relates" "- #456（部分対応）"
actual_ec=0
actual=$(run_get_related_issues) || actual_ec=$?
assert_exit "case3: exit code" "0" "$actual_ec"
expected="issues:#456
closes:none
relates:#456"
assert_eq "case3: stdout" "$expected" "$actual"

# ============================================================
# ケース4（形態 D: 両配列非空）: 複数 Unit / 複数 Issue 混在
# 修正前後ともに exit 0（既存唯一の安全形態）。
# 重複除去・ソート確認も含む。
# ============================================================
echo ""
echo "[Case 4] 形態 D: 複数 Unit / 複数 Issue 混在（重複・ソート検証）"
clear_fixtures
write_unit_fixture "004-multi-a" "- #100
- #200
- #300（部分対応）"
write_unit_fixture "005-multi-b" "- #100
- #400（部分対応）"
actual_ec=0
actual=$(run_get_related_issues) || actual_ec=$?
assert_exit "case4: exit code" "0" "$actual_ec"
# sort -u は ASCII ソート: #100, #200, #300, #400
expected="issues:#100,#200,#300,#400
closes:#100,#200
relates:#300,#400"
assert_eq "case4: stdout" "$expected" "$actual"

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
