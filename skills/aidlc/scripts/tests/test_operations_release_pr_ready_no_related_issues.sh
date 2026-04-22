#!/usr/bin/env bash
#
# test_operations_release_pr_ready_no_related_issues.sh -
# operations-release.sh pr-ready の関連 Issue 0 件サイクル regression テスト
# （Unit 001 / Issue #588）。
#
# 検証対象: get-related-issues -> ready -> gh pr edit のフローが
# 関連 Issue 0 件サイクルでも exit 0 で完走し、PR Ready 化と本文更新の
# 両経路が呼び出されること。
#
# bug 修正前は pr-ops.sh get-related-issues 段階で
# closes_list[@]: unbound variable で停止していた。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPERATIONS_RELEASE="${SCRIPT_DIR}/../operations-release.sh"
TMPDIR_BASE=""
COUNTER_FILE=""
GH_MOCK_DIR=""
GH_CALL_LOG=""

# --- テストヘルパー ---

setup_tmpdir() {
    TMPDIR_BASE=$(mktemp -d)
    COUNTER_FILE="${TMPDIR_BASE}/.test_counters"
    GH_MOCK_DIR="${TMPDIR_BASE}/bin"
    GH_CALL_LOG="${TMPDIR_BASE}/gh_calls.log"
    printf '0\n0\n' > "$COUNTER_FILE"
    : > "$GH_CALL_LOG"
    mkdir -p "$GH_MOCK_DIR"
    # AIDLC_PROJECT_ROOT を上書きして bootstrap.sh の git rev-parse 依存を回避
    export AIDLC_PROJECT_ROOT="$TMPDIR_BASE"
    mkdir -p "${TMPDIR_BASE}/.aidlc/cycles/v0.0.0/story-artifacts/units"
    # 関連 Issue 0 件の Unit fixture を作成
    cat > "${TMPDIR_BASE}/.aidlc/cycles/v0.0.0/story-artifacts/units/001-no-issue.md" <<'UNITFILE'
# Unit: no-issue

## 概要

関連 Issue 0 件サイクルテスト用 Unit fixture

## 関連Issue

（関連 Issue なし）

## 実装状態

- 状態: 未着手
UNITFILE
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
        echo "  FAIL: $test_name (should NOT contain '$unexpected_substring')"
        echo "    actual: $actual"
        _inc_fail
    else
        echo "  PASS: $test_name"
        _inc_pass
    fi
}

# gh モックを設置（呼び出し履歴を GH_CALL_LOG に追記）
write_gh_mock() {
    cat > "${GH_MOCK_DIR}/gh" <<'GHMOCK'
#!/usr/bin/env bash
# gh CLI モック - 呼び出し引数を GH_CALL_LOG に追記する
log_file="${GH_CALL_LOG}"
printf '%s\n' "gh $*" >> "$log_file"

case "$1" in
    auth)
        # auth status は常に成功
        exit 0
        ;;
    pr)
        shift
        case "$1" in
            ready)
                # pr ready <number>
                exit 0
                ;;
            edit)
                # pr edit <number> --body-file <path>
                exit 0
                ;;
            list)
                # pr list は使われない経路のため空配列を返す
                echo ''
                exit 0
                ;;
            view)
                echo 'abc123'
                exit 0
                ;;
        esac
        ;;
esac
exit 0
GHMOCK
    chmod +x "${GH_MOCK_DIR}/gh"
}

# operations-release.sh pr-ready を実行
# $1 以降: 引数（--cycle / --pr / --body-file 等）
run_pr_ready() {
    PATH="${GH_MOCK_DIR}:${PATH}" GH_CALL_LOG="${GH_CALL_LOG}" \
        "$OPERATIONS_RELEASE" pr-ready "$@" 2>&1 || echo "EXIT_CODE:$?"
}

# --- テスト本体 ---

echo "=== operations-release.sh pr-ready 関連 Issue 0 件 regression テスト ==="

setup_tmpdir
write_gh_mock

# ============================================================
# Case 1: 関連 Issue 0 件サイクル + --pr 明示 + --body-file 指定
# 期待: exit 0、stdout に pr:<number>:ready、gh pr ready / gh pr edit 各 1 回呼ばれる
# ============================================================
echo ""
echo "[Case 1] 関連 Issue 0 件 + --pr 明示 + --body-file 指定"

# 一時 PR 本文ファイル作成
body_file="${TMPDIR_BASE}/pr-body.md"
echo "# テスト用 PR 本文" > "$body_file"

actual=$(run_pr_ready --cycle v0.0.0 --pr 999 --body-file "$body_file")

# assertion 1: exit 0 で完走
assert_not_contains "case1: exit 0 完走" "EXIT_CODE:" "$actual"

# assertion 2: pr:999:ready が出力される
assert_contains "case1: pr ready 出力" "pr:999:ready" "$actual"

# assertion 3: unbound variable エラーが出ていない（修正前の bug 検知）
assert_not_contains "case1: unbound variable 不在" "unbound variable" "$actual"

# assertion 4: get-related-issues の出力（issues:none）が含まれる
assert_contains "case1: get-related-issues 完走" "issues:none" "$actual"

# assertion 5: gh スタブの呼び出し履歴に pr ready 999 が記録されている（厳密に 1 回）
gh_calls=$(cat "$GH_CALL_LOG")
ready_count=$(grep -cF "gh pr ready 999" "$GH_CALL_LOG" || true)
assert_eq "case1: gh pr ready 呼び出し回数（厳密 1 回）" "1" "$ready_count"

# assertion 6: gh スタブの呼び出し履歴に pr edit 999 --body-file が記録されている（厳密に 1 回）
edit_count=$(grep -cF "gh pr edit 999 --body-file ${body_file}" "$GH_CALL_LOG" || true)
assert_eq "case1: gh pr edit 呼び出し回数（厳密 1 回）" "1" "$edit_count"

# assertion 7: 呼び出し順序検証 - pr ready が pr edit より先に呼ばれている
ready_line=$(grep -nF "gh pr ready 999" "$GH_CALL_LOG" | head -1 | cut -d: -f1)
edit_line=$(grep -nF "gh pr edit 999" "$GH_CALL_LOG" | head -1 | cut -d: -f1)
if [ -n "$ready_line" ] && [ -n "$edit_line" ] && [ "$ready_line" -lt "$edit_line" ]; then
    echo "  PASS: case1: 呼び出し順序（pr ready -> pr edit）"
    _inc_pass
else
    echo "  FAIL: case1: 呼び出し順序（ready_line=$ready_line, edit_line=$edit_line）"
    _inc_fail
fi

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
