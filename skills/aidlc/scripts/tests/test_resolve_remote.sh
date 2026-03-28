#!/usr/bin/env bash
#
# test_resolve_remote.sh - post-merge-cleanup.sh の resolve_remote() / find_remote_by_branch() ユニットテスト
#
# テスト用の一時gitリポジトリを作成し、マルチリモート環境をシミュレートする
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR_BASE=""
COUNTER_FILE=""

# --- テストヘルパー ---

setup_tmpdir() {
    TMPDIR_BASE=$(mktemp -d)
    COUNTER_FILE="${TMPDIR_BASE}/.test_counters"
    printf '0\n0\n' > "$COUNTER_FILE"
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
        echo "  FAIL: $test_name (expected='$expected', actual='$actual')"
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
        echo "  FAIL: $test_name (expected to contain '$expected_substring', actual='$actual')"
        _inc_fail
    fi
}

# 一時的な bare リポジトリを作成し、指定ブランチを持たせる
create_bare_repo() {
    local path="$1"
    local branch_name="${2:-}"
    git init --bare "$path" >/dev/null 2>&1
    if [ -n "$branch_name" ]; then
        local work_tmp="${path}_work"
        git clone "$path" "$work_tmp" >/dev/null 2>&1
        (
            cd "$work_tmp"
            git config user.name "test"
            git config user.email "test@example.com"
            git commit --allow-empty -m "init" >/dev/null 2>&1
            git checkout -b "$branch_name" >/dev/null 2>&1
            git push origin "$branch_name" >/dev/null 2>&1
        )
        \rm -rf "$work_tmp"
    fi
}

# テスト用ワーキングリポジトリを作成
create_work_repo() {
    local path="$1"
    git init "$path" >/dev/null 2>&1
    (
        cd "$path"
        git config user.name "test"
        git config user.email "test@example.com"
        git commit --allow-empty -m "init" >/dev/null 2>&1
    )
}

# 対象スクリプトから関数を読み込む
source_functions() {
    local script="${SCRIPT_DIR}/../bin/post-merge-cleanup.sh"
    eval "$(sed -n '/^# --- グローバル変数 ---/,/^main() {/{ /^main() {/d; p; }' "$script")"
}

# --- テスト ---

echo "=== resolve_remote() / find_remote_by_branch() テスト ==="

setup_tmpdir
source_functions

echo ""
echo "--- テスト1: シングルリモート + ブランチあり（回帰テスト） ---"
(
    repo="${TMPDIR_BASE}/test1_work"
    bare="${TMPDIR_BASE}/test1_bare"
    create_bare_repo "$bare" "cycle/v1.0.0"
    create_work_repo "$repo"
    cd "$repo"
    git remote add origin "$bare"
    git fetch origin >/dev/null 2>&1
    git checkout -b "cycle/v1.0.0" "origin/cycle/v1.0.0" >/dev/null 2>&1

    BRANCH_NAME="cycle/v1.0.0"
    WT_REMOTE=""
    resolve_remote "cycle/v1.0.0" "test" "test-err" >/dev/null 2>&1
    assert_eq "git configで解決" "origin" "$WT_REMOTE"
)

echo ""
echo "--- テスト2: シングルリモート + ブランチなし（refs/remotesで発見） ---"
(
    repo="${TMPDIR_BASE}/test2_work"
    bare="${TMPDIR_BASE}/test2_bare"
    create_bare_repo "$bare" "cycle/v1.0.0"
    create_work_repo "$repo"
    cd "$repo"
    git remote add origin "$bare"
    git fetch origin >/dev/null 2>&1

    BRANCH_NAME="cycle/v1.0.0"
    WT_REMOTE=""
    resolve_remote "" "test" "test-err" >/dev/null 2>&1
    assert_eq "refs/remotesで解決" "origin" "$WT_REMOTE"
)

echo ""
echo "--- テスト3: マルチリモート + ブランチなし + refs/remotes にあり（origin優先） ---"
(
    repo="${TMPDIR_BASE}/test3_work"
    bare_origin="${TMPDIR_BASE}/test3_origin"
    bare_upstream="${TMPDIR_BASE}/test3_upstream"
    create_bare_repo "$bare_origin" "cycle/v1.0.0"
    create_bare_repo "$bare_upstream" "cycle/v1.0.0"
    create_work_repo "$repo"
    cd "$repo"
    git remote add origin "$bare_origin"
    git remote add upstream "$bare_upstream"
    git fetch --all >/dev/null 2>&1

    BRANCH_NAME="cycle/v1.0.0"
    WT_REMOTE=""
    resolve_remote "" "test" "test-err" >/dev/null 2>&1
    assert_eq "origin優先タイブレーク" "origin" "$WT_REMOTE"
)

echo ""
echo "--- テスト4: マルチリモート + ブランチなし + refs/remotes にあり（origin含まず） ---"
(
    repo="${TMPDIR_BASE}/test4_work"
    bare_upstream="${TMPDIR_BASE}/test4_upstream"
    bare_fork="${TMPDIR_BASE}/test4_fork"
    create_bare_repo "$bare_upstream" "cycle/v1.0.0"
    create_bare_repo "$bare_fork" "cycle/v1.0.0"
    create_work_repo "$repo"
    cd "$repo"
    git remote add upstream "$bare_upstream"
    git remote add fork "$bare_fork"
    git fetch --all >/dev/null 2>&1

    BRANCH_NAME="cycle/v1.0.0"
    WT_REMOTE=""
    resolve_remote "" "test" "test-err" >/dev/null 2>&1
    if [ "$WT_REMOTE" = "upstream" ] || [ "$WT_REMOTE" = "fork" ]; then
        echo "  PASS: origin含まず、最初の候補を選択 (selected: $WT_REMOTE)"
        _inc_pass
    else
        echo "  FAIL: origin含まず、候補選択失敗 (WT_REMOTE='$WT_REMOTE')"
        _inc_fail
    fi
)

echo ""
echo "--- テスト5: マルチリモート + ブランチなし + どこにもなし（フォールバック + 警告） ---"
(
    repo="${TMPDIR_BASE}/test5_work"
    bare_origin="${TMPDIR_BASE}/test5_origin"
    bare_upstream="${TMPDIR_BASE}/test5_upstream"
    create_bare_repo "$bare_origin"
    create_bare_repo "$bare_upstream"
    create_work_repo "$repo"
    cd "$repo"
    git remote add origin "$bare_origin"
    git remote add upstream "$bare_upstream"
    git fetch --all >/dev/null 2>&1

    BRANCH_NAME="cycle/v99.99.99"
    WT_REMOTE=""
    # stdout をファイルにリダイレクトし、WT_REMOTE が現在のシェルに残るようにする
    output_file="${TMPDIR_BASE}/test5_output.txt"
    resolve_remote "" "test" "test-err" > "$output_file" 2>&1
    output=$(cat "$output_file")
    assert_eq "originフォールバック" "origin" "$WT_REMOTE"
    assert_contains "警告出力あり" "警告:" "$output"
)

echo ""
echo "--- テスト6: find_remote_by_branch() 単体テスト ---"
(
    repo="${TMPDIR_BASE}/test6_work"
    bare="${TMPDIR_BASE}/test6_bare"
    create_bare_repo "$bare" "cycle/v2.0.0"
    create_work_repo "$repo"
    cd "$repo"
    git remote add origin "$bare"
    git fetch origin >/dev/null 2>&1

    result=$(find_remote_by_branch "cycle/v2.0.0")
    assert_eq "find_remote_by_branch成功" "origin" "$result"

    result=$(find_remote_by_branch "cycle/v99.99.99")
    assert_eq "find_remote_by_branch該当なし" "" "$result"
)

echo ""
echo "--- テスト7: _select_remote_candidate() 単体テスト ---"
(
    result=$(printf 'upstream\norigin\nfork\n' | _select_remote_candidate)
    assert_eq "origin優先" "origin" "$result"

    result=$(printf 'upstream\nfork\n' | _select_remote_candidate)
    assert_eq "origin含まず→最初" "upstream" "$result"

    result=$(printf '' | _select_remote_candidate)
    assert_eq "空入力→空出力" "" "$result"
)

echo ""
echo "--- テスト8: branch_name引数がBRANCH_NAMEより優先される ---"
(
    repo="${TMPDIR_BASE}/test8_work"
    bare_origin="${TMPDIR_BASE}/test8_origin"
    create_bare_repo "$bare_origin" "cycle/v1.0.0"
    create_work_repo "$repo"
    cd "$repo"
    git remote add origin "$bare_origin"
    git fetch origin >/dev/null 2>&1
    git checkout -b "cycle/v1.0.0" "origin/cycle/v1.0.0" >/dev/null 2>&1

    # BRANCH_NAMEは別の値を設定（存在しないブランチ）
    BRANCH_NAME="cycle/v99.99.99"
    WT_REMOTE=""
    # branch_name引数で正しいブランチを指定 → git configで解決されるはず
    resolve_remote "cycle/v1.0.0" "test" "test-err" >/dev/null 2>&1
    assert_eq "branch_name引数優先" "origin" "$WT_REMOTE"
)

echo ""
echo "--- テスト9: git configが無効なリモートを返す場合のフォールバック ---"
(
    repo="${TMPDIR_BASE}/test9_work"
    bare="${TMPDIR_BASE}/test9_bare"
    create_bare_repo "$bare" "cycle/v1.0.0"
    create_work_repo "$repo"
    cd "$repo"
    git remote add origin "$bare"
    git fetch origin >/dev/null 2>&1
    git checkout -b "cycle/v1.0.0" "origin/cycle/v1.0.0" >/dev/null 2>&1
    # 追跡設定を存在しないリモートに書き換え
    git config "branch.cycle/v1.0.0.remote" "nonexistent_remote"

    BRANCH_NAME="cycle/v1.0.0"
    WT_REMOTE=""
    resolve_remote "cycle/v1.0.0" "test" "test-err" >/dev/null 2>&1
    # git config失敗 → find_remote_by_branch で refs/remotes から origin を発見
    assert_eq "無効remote時のフォールバック" "origin" "$WT_REMOTE"
)

echo ""
# カウンタ読み取り
{
    read -r PASS
    read -r FAIL
} < "$COUNTER_FILE"
echo "=== 結果: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
