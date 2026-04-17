#!/usr/bin/env bash
#
# test_pr_ops_merge_skip_checks.sh - pr-ops.sh merge の --skip-checks オプションと
# resolve_check_status() の 5 分類判定ユニットテスト。
#
# Unit 003 で追加した以下の挙動を検証する:
#  - CheckStatus 5 分類（pass / fail / pending / no-checks-configured / checks-query-failed）
#  - --skip-checks の適用マトリクス（no-checks-configured のみバイパス許可）
#  - error:checks-status-unknown 出力時の順序固定契約（error → reason → hint）
#  - pending の exit code 8 対応（stdout 優先、checks-query-failed への誤分類防止）
#
# gh CLI をモック化するため PATH を一時ディレクトリに差し替える。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PR_OPS="${SCRIPT_DIR}/../pr-ops.sh"
TMPDIR_BASE=""
COUNTER_FILE=""
GH_MOCK_DIR=""
GH_STATE_FILE=""

# --- テストヘルパー ---

setup_tmpdir() {
    TMPDIR_BASE=$(mktemp -d)
    COUNTER_FILE="${TMPDIR_BASE}/.test_counters"
    GH_MOCK_DIR="${TMPDIR_BASE}/bin"
    GH_STATE_FILE="${TMPDIR_BASE}/gh_state"
    printf '0\n0\n' > "$COUNTER_FILE"
    mkdir -p "$GH_MOCK_DIR"
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

# gh モックを設定
# $1: checks_mode (pass | fail | pending | no-checks | query-fail)
# $2: merge_result (ok | error)
write_gh_mock() {
    local checks_mode="$1"
    local merge_result="${2:-ok}"
    printf '%s\n%s\n' "$checks_mode" "$merge_result" > "$GH_STATE_FILE"

    cat > "${GH_MOCK_DIR}/gh" <<'GHMOCK'
#!/usr/bin/env bash
# gh CLI モック - 状態ファイルから挙動を決定
state_file="${GH_STATE_FILE}"
checks_mode=$(sed -n '1p' "$state_file")
merge_result=$(sed -n '2p' "$state_file")

case "$1" in
    auth)
        exit 0
        ;;
    pr)
        shift
        case "$1" in
            view)
                # head SHA を返す（race condition 防止用）
                echo 'abc123def456'
                exit 0
                ;;
            checks)
                case "$checks_mode" in
                    pass)
                        echo 'pass'
                        exit 0
                        ;;
                    fail)
                        echo 'fail'
                        exit 1
                        ;;
                    pending)
                        # 公式仕様: pending 時 exit 8
                        echo 'pending'
                        exit 8
                        ;;
                    no-checks)
                        # 必須チェック未設定: stderr + exit 1
                        echo 'no checks reported for the "xxx" branch' >&2
                        exit 1
                        ;;
                    query-fail)
                        # ネットワーク / API エラー等
                        echo 'HTTP 500: server error' >&2
                        exit 1
                        ;;
                esac
                ;;
            merge)
                if [ "$merge_result" = "ok" ]; then
                    exit 0
                else
                    echo 'some merge error' >&2
                    exit 1
                fi
                ;;
        esac
        ;;
esac
exit 1
GHMOCK
    chmod +x "${GH_MOCK_DIR}/gh"
}

# PATH を差し替えて pr-ops.sh merge を実行
# $1: pr_number, $2 以降: 残り引数（--squash / --skip-checks 等）
run_pr_ops_merge() {
    local pr_number="$1"
    shift
    PATH="${GH_MOCK_DIR}:${PATH}" GH_STATE_FILE="${GH_STATE_FILE}" \
        "$PR_OPS" merge "$pr_number" "$@" 2>&1 || true
}

# --- テスト本体 ---

echo "=== pr-ops.sh merge --skip-checks テスト ==="

setup_tmpdir

# ============================================================
# 1. pass + フラグなし → 即時マージ
# ============================================================
echo ""
echo "[Case 1] pass + フラグなし → 即時マージ"
write_gh_mock pass ok
actual=$(run_pr_ops_merge 123 --squash)
assert_eq "pass: stdout" "pr:123:merged:squash" "$actual"

# ============================================================
# 2. pass + --skip-checks → 即時マージ（フラグ無視）
# ============================================================
echo ""
echo "[Case 2] pass + --skip-checks → 即時マージ（フラグ無視）"
write_gh_mock pass ok
actual=$(run_pr_ops_merge 123 --squash --skip-checks)
assert_eq "pass+skip: stdout" "pr:123:merged:squash" "$actual"

# ============================================================
# 3. fail + フラグなし → error:checks-failed
# ============================================================
echo ""
echo "[Case 3] fail + フラグなし → error:checks-failed"
write_gh_mock fail ok
actual=$(run_pr_ops_merge 123 --squash)
assert_eq "fail: stdout" "pr:123:error:checks-failed" "$actual"

# ============================================================
# 4. fail + --skip-checks → error:checks-failed（バイパス禁止、安全性契約）
# ============================================================
echo ""
echo "[Case 4] fail + --skip-checks → error:checks-failed（バイパス禁止）"
write_gh_mock fail ok
actual=$(run_pr_ops_merge 123 --squash --skip-checks)
assert_eq "fail+skip: stdout" "pr:123:error:checks-failed" "$actual"

# ============================================================
# 5. pending + フラグなし → auto-merge-set（exit 8 公式仕様の regression 防止）
# ============================================================
echo ""
echo "[Case 5] pending + フラグなし → auto-merge-set（exit 8 対応）"
write_gh_mock pending ok
actual=$(run_pr_ops_merge 123 --squash)
assert_eq "pending: stdout" "pr:123:auto-merge-set:squash" "$actual"

# ============================================================
# 6. pending + --skip-checks → auto-merge-set（フラグ無視）
# ============================================================
echo ""
echo "[Case 6] pending + --skip-checks → auto-merge-set（フラグ無視）"
write_gh_mock pending ok
actual=$(run_pr_ops_merge 123 --squash --skip-checks)
assert_eq "pending+skip: stdout" "pr:123:auto-merge-set:squash" "$actual"

# ============================================================
# 7. no-checks-configured + フラグなし → error:checks-status-unknown + reason + hint
# ============================================================
echo ""
echo "[Case 7] no-checks-configured + フラグなし → error + reason + hint"
write_gh_mock no-checks ok
actual=$(run_pr_ops_merge 123 --squash)
assert_contains "no-checks: error line" "pr:123:error:checks-status-unknown" "$actual"
assert_contains "no-checks: reason line" "pr:123:reason:no-checks-configured" "$actual"
assert_contains "no-checks: hint line" "pr:123:hint:" "$actual"

# 出力順序契約（error → reason → hint）の検証
expected_order="pr:123:error:checks-status-unknown
pr:123:reason:no-checks-configured"
assert_contains "no-checks: order (error→reason)" "$expected_order" "$actual"

# ============================================================
# 8. no-checks-configured + --skip-checks → 即時マージ（新規挙動）
# ============================================================
echo ""
echo "[Case 8] no-checks-configured + --skip-checks → 即時マージ"
write_gh_mock no-checks ok
actual=$(run_pr_ops_merge 123 --squash --skip-checks)
assert_eq "no-checks+skip: stdout" "pr:123:merged:squash" "$actual"

# ============================================================
# 9. checks-query-failed + フラグなし → error + reason:checks-query-failed + hint
# ============================================================
echo ""
echo "[Case 9] checks-query-failed + フラグなし → error + reason + hint"
write_gh_mock query-fail ok
actual=$(run_pr_ops_merge 123 --squash)
assert_contains "query-fail: error line" "pr:123:error:checks-status-unknown" "$actual"
assert_contains "query-fail: reason line" "pr:123:reason:checks-query-failed" "$actual"
assert_contains "query-fail: hint line" "pr:123:hint:" "$actual"

# ============================================================
# 10. checks-query-failed + --skip-checks → error（バイパス禁止、安全性契約）
# ============================================================
echo ""
echo "[Case 10] checks-query-failed + --skip-checks → error（バイパス禁止）"
write_gh_mock query-fail ok
actual=$(run_pr_ops_merge 123 --squash --skip-checks)
assert_contains "query-fail+skip: error (not merged)" "pr:123:error:checks-status-unknown" "$actual"
assert_contains "query-fail+skip: reason still checks-query-failed" "pr:123:reason:checks-query-failed" "$actual"
# 重要: --skip-checks があっても merged にはならない（安全性契約）
if printf '%s' "$actual" | grep -qF "pr:123:merged:"; then
    echo "  FAIL: query-fail+skip: バイパス禁止違反（merged が出力された）"
    echo "    actual: $actual"
    _inc_fail
else
    echo "  PASS: query-fail+skip: バイパス禁止（merged 無し）"
    _inc_pass
fi

# ============================================================
# 11. merge/rebase サブコマンドでも --skip-checks が透過される
# ============================================================
echo ""
echo "[Case 11] merge メソッドでも --skip-checks が動作"
write_gh_mock no-checks ok
actual=$(run_pr_ops_merge 123 --skip-checks)  # 既定は merge
assert_eq "merge+skip: stdout" "pr:123:merged:merge" "$actual"

write_gh_mock no-checks ok
actual=$(run_pr_ops_merge 123 --rebase --skip-checks)
assert_eq "rebase+skip: stdout" "pr:123:merged:rebase" "$actual"

# ============================================================
# 12. pending が exit code 非依存で判定されるかを個別検証（regression 防止）
# ============================================================
echo ""
echo "[Case 12] pending (exit 8) が checks-query-failed に誤分類されない"
write_gh_mock pending ok
actual=$(run_pr_ops_merge 123 --squash)
# checks-query-failed ではないことを確認
if printf '%s' "$actual" | grep -qF "checks-query-failed"; then
    echo "  FAIL: pending regression: checks-query-failed に誤分類された"
    echo "    actual: $actual"
    _inc_fail
else
    echo "  PASS: pending regression: checks-query-failed 未発生"
    _inc_pass
fi
if printf '%s' "$actual" | grep -qF "auto-merge-set:"; then
    echo "  PASS: pending regression: auto-merge-set 経路到達"
    _inc_pass
else
    echo "  FAIL: pending regression: auto-merge-set 経路未到達"
    echo "    actual: $actual"
    _inc_fail
fi

# --- 結果集計 ---

echo ""
{ read -r pass_count; read -r fail_count; } < "$COUNTER_FILE"
total=$(( pass_count + fail_count ))
echo "=== 結果: PASS=$pass_count / FAIL=$fail_count / TOTAL=$total ==="

if [ "$fail_count" -gt 0 ]; then
    exit 1
fi
exit 0
