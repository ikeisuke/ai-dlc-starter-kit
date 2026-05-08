#!/usr/bin/env bash
#
# test_pr_ops_auto_merge_error_classification.sh - pr-ops.sh merge の
# set-auto-merge 失敗時 auto_error 分類分岐（line 444 周辺）の文言バリアント
# テスト。Unit 001 (#665) で追加した以下の挙動を検証する:
#  - 半角スペース型 "auto merge is not allowed" -> auto-merge-not-enabled
#  - GraphQL 型 "enablePullRequestAutoMerge" -> auto-merge-not-enabled
#  - 後方互換: ハイフン型 "auto-merge is not allowed" -> auto-merge-not-enabled
#  - 誤分類なし: "permission denied" -> permission-denied
#
# 既存 test_pr_ops_merge_skip_checks.sh の gh モック方式（PATH 差し替え + GH_STATE_FILE）
# を踏襲する。
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
        echo "  FAIL: $test_name (should not contain '$unexpected_substring')"
        echo "    actual: $actual"
        _inc_fail
    else
        echo "  PASS: $test_name"
        _inc_pass
    fi
}

# gh モックを設定
# $1: auto_merge_stderr_fixture（auto-merge 失敗時に stderr に出力する文字列）
write_gh_mock() {
    local auto_merge_stderr="$1"
    printf '%s\n' "$auto_merge_stderr" > "$GH_STATE_FILE"

    cat > "${GH_MOCK_DIR}/gh" <<'GHMOCK'
#!/usr/bin/env bash
# gh CLI モック - state ファイルから auto-merge 失敗 stderr を決定
state_file="${GH_STATE_FILE}"
auto_merge_stderr=$(cat "$state_file")

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
                # CI pending を返し set-auto-merge 経路に進ませる
                echo 'pending'
                exit 8
                ;;
            merge)
                # --auto 付き呼び出しは fixture stderr で失敗
                # --auto 無し呼び出し（merge-now）は ok
                while [ $# -gt 0 ]; do
                    if [ "$1" = "--auto" ]; then
                        printf '%s\n' "$auto_merge_stderr" >&2
                        exit 1
                    fi
                    shift
                done
                exit 0
                ;;
        esac
        ;;
esac
exit 1
GHMOCK
    chmod +x "${GH_MOCK_DIR}/gh"
}

# PATH を差し替えて pr-ops.sh merge を実行
run_pr_ops_merge() {
    local pr_number="$1"
    shift
    PATH="${GH_MOCK_DIR}:${PATH}" GH_STATE_FILE="${GH_STATE_FILE}" \
        "$PR_OPS" merge "$pr_number" "$@" 2>&1 || true
}

# --- テスト本体 ---

echo "=== pr-ops.sh merge auto-merge エラー分類テスト (Unit 001 / #665) ==="

setup_tmpdir

# ============================================================
# Case (a): 半角スペース型 "auto merge is not allowed" (#665 観測形式)
# ============================================================
echo ""
echo "[Case (a)] space-form: 'auto merge is not allowed' -> auto-merge-not-enabled"
write_gh_mock 'GraphQL: Auto merge is not allowed for this repository (enablePullRequestAutoMerge)'
actual=$(run_pr_ops_merge 123 --squash)
assert_contains "(a) space-form: classification" "pr:123:error:auto-merge-not-enabled" "$actual"
assert_not_contains "(a) space-form: not unknown" "pr:123:error:unknown" "$actual"

# ============================================================
# Case (b): GraphQL 型 "enablePullRequestAutoMerge" のみ
# ============================================================
echo ""
echo "[Case (b)] graphql-mutation: 'enablePullRequestAutoMerge' -> auto-merge-not-enabled"
write_gh_mock 'GraphQL error: field enablePullRequestAutoMerge does not exist'
actual=$(run_pr_ops_merge 123 --squash)
assert_contains "(b) graphql-mutation: classification" "pr:123:error:auto-merge-not-enabled" "$actual"
assert_not_contains "(b) graphql-mutation: not unknown" "pr:123:error:unknown" "$actual"

# ============================================================
# Case (c): 既存ハイフン型 "auto-merge is not allowed" (後方互換)
# ============================================================
echo ""
echo "[Case (c)] hyphen-form-bc: 'auto-merge is not allowed' -> auto-merge-not-enabled (後方互換)"
write_gh_mock 'auto-merge is not allowed for this repository'
actual=$(run_pr_ops_merge 123 --squash)
assert_contains "(c) hyphen-form-bc: classification" "pr:123:error:auto-merge-not-enabled" "$actual"

# ============================================================
# Case (d): 純粋な permission 系エラー (誤分類なし)
#
# 注: 「auto-merge」キーワードと「permission」キーワードを両方含む混在文言は
# 既存 cmd_merge の if-elif 順序により auto-merge-not-enabled 側が先に評価される
# （grep 順序固定の既存仕様）。本テストでは auto-merge を含まない純粋な permission
# エラーで permission-denied 側に正しく振り分けられることのみを検証し、
# 混在文言の優先度仕様は本 Unit のスコープ外とする。
# ============================================================
echo ""
echo "[Case (d)] permission-denied: pure 'forbidden' -> permission-denied (誤分類なし)"
write_gh_mock 'HTTP 403: forbidden - insufficient privileges'
actual=$(run_pr_ops_merge 123 --squash)
assert_contains "(d) permission-denied: classification" "pr:123:error:permission-denied" "$actual"
assert_not_contains "(d) permission-denied: not auto-merge-not-enabled" "pr:123:error:auto-merge-not-enabled" "$actual"

# --- 結果集計 ---

echo ""
{ read -r pass_count; read -r fail_count; } < "$COUNTER_FILE"
total=$(( pass_count + fail_count ))
echo "=== 結果: PASS=$pass_count / FAIL=$fail_count / TOTAL=$total ==="

if [ "$fail_count" -gt 0 ]; then
    exit 1
fi
exit 0
