#!/usr/bin/env bash
#
# test_operations_release_merge_pr_empty_args.sh - operations-release.sh merge-pr の
# 追加引数なし呼び出し regression テスト。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPERATIONS_RELEASE="${SCRIPT_DIR}/../operations-release.sh"
TMPDIR_BASE=""
COUNTER_FILE=""

# --- テストヘルパー ---

setup_tmpdir() {
    TMPDIR_BASE=$(mktemp -d)
    COUNTER_FILE="${TMPDIR_BASE}/.test_counters"
    printf '0\n0\n' > "$COUNTER_FILE"
    cp "$OPERATIONS_RELEASE" "${TMPDIR_BASE}/operations-release.sh"
    chmod +x "${TMPDIR_BASE}/operations-release.sh"

    cat > "${TMPDIR_BASE}/pr-ops.sh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

printf 'argc:%d\n' "$#"
i=1
for arg in "$@"; do
    printf 'arg%d:%s\n' "$i" "$arg"
    i=$(( i + 1 ))
done
STUB
    chmod +x "${TMPDIR_BASE}/pr-ops.sh"
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

run_merge_pr() {
    "${TMPDIR_BASE}/operations-release.sh" merge-pr "$@" 2>&1
}

# --- テスト本体 ---

echo "=== operations-release.sh merge-pr 追加引数なしテスト ==="

setup_tmpdir

echo ""
echo "[Case 1] squash + 追加引数なし"
actual=$(run_merge_pr --pr 123 --method squash)
expected="argc:3
arg1:merge
arg2:123
arg3:--squash"
assert_eq "squash: pr-ops 引数" "$expected" "$actual"

echo ""
echo "[Case 2] merge + 追加引数なし"
actual=$(run_merge_pr --pr 123 --method merge)
expected="argc:2
arg1:merge
arg2:123"
assert_eq "merge: pr-ops 引数" "$expected" "$actual"

echo ""
echo "[Case 3] rebase + 追加引数なし"
actual=$(run_merge_pr --pr 123 --method rebase)
expected="argc:3
arg1:merge
arg2:123
arg3:--rebase"
assert_eq "rebase: pr-ops 引数" "$expected" "$actual"

echo ""
echo "[Case 4] squash + --skip-checks"
actual=$(run_merge_pr --pr 123 --method squash --skip-checks)
expected="argc:4
arg1:merge
arg2:123
arg3:--squash
arg4:--skip-checks"
assert_eq "squash+skip: pr-ops 引数" "$expected" "$actual"

# --- 結果集計 ---

echo ""
{ read -r pass_count; read -r fail_count; } < "$COUNTER_FILE"
total=$(( pass_count + fail_count ))
echo "=== 結果: PASS=$pass_count / FAIL=$fail_count / TOTAL=$total ==="

if [ "$fail_count" -gt 0 ]; then
    exit 1
fi
exit 0
