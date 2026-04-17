#!/usr/bin/env bash
#
# test_validate_git_remote_sync.sh - validate-git.sh の run_remote_sync() ユニットテスト
#
# Unit 002 で追加した 2 ビット真理値表分類・異名 upstream 対応・error code 拡張を検証する。
# 一時 bare / working リポジトリを作成し、各種 git 状態を再現してスクリプト出力を確認する。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE_GIT="${SCRIPT_DIR}/../validate-git.sh"
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

assert_not_contains() {
    local test_name="$1"
    local unexpected_substring="$2"
    local actual="$3"
    if printf '%s' "$actual" | grep -qF "$unexpected_substring"; then
        echo "  FAIL: $test_name (unexpected substring '$unexpected_substring' found in actual='$actual')"
        _inc_fail
    else
        echo "  PASS: $test_name"
        _inc_pass
    fi
}

# リモート bare + 初期 main + 指定 cycle ブランチをセットアップし、working repo をクローン
# 使用: setup_repo <prefix> <upstream_branch> [<local_branch>]
# local_branch 省略時は upstream_branch と同名（同名 upstream）
setup_repo() {
    local prefix="$1"
    local upstream_branch="$2"
    local local_branch="${3:-$upstream_branch}"
    local bare="${TMPDIR_BASE}/${prefix}_bare"
    local work="${TMPDIR_BASE}/${prefix}_work"

    git init --bare "$bare" >/dev/null 2>&1
    git init "$work" >/dev/null 2>&1
    (
        cd "$work"
        git config user.name "test"
        git config user.email "test@example.com"
        git config commit.gpgsign false
        git remote add origin "$bare"
        git commit --allow-empty -m "init" >/dev/null 2>&1
        git branch -M main
        git push origin main >/dev/null 2>&1
        git checkout -b "$upstream_branch" >/dev/null 2>&1
        git commit --allow-empty -m "upstream-base" >/dev/null 2>&1
        git push -u origin "$upstream_branch" >/dev/null 2>&1
        if [ "$local_branch" != "$upstream_branch" ]; then
            git checkout -b "$local_branch" >/dev/null 2>&1
            git config "branch.${local_branch}.remote" "origin"
            git config "branch.${local_branch}.merge" "refs/heads/${upstream_branch}"
        fi
    )
    echo "$work"
}

# --- テスト本体 ---

echo "=== validate-git.sh run_remote_sync テスト ==="

setup_tmpdir

echo ""
echo "--- テスト1: status:ok（完全一致） ---"
(
    repo=$(setup_repo "t1" "cycle/t1")
    cd "$repo"
    out=$(bash "$VALIDATE_GIT" remote-sync)
    assert_contains "status:ok" "status:ok" "$out"
    assert_not_contains "warning 出力なし" "status:warning" "$out"
    assert_not_contains "diverged 出力なし" "status:diverged" "$out"
)

echo ""
echo "--- テスト2: status:warning + unpushed_commits（HEAD が upstream を追い越し） ---"
(
    repo=$(setup_repo "t2" "cycle/t2")
    cd "$repo"
    git commit --allow-empty -m "local-ahead-1" >/dev/null 2>&1
    git commit --allow-empty -m "local-ahead-2" >/dev/null 2>&1
    out=$(bash "$VALIDATE_GIT" remote-sync)
    assert_contains "status:warning" "status:warning" "$out"
    assert_contains "unpushed_commits:2" "unpushed_commits:2" "$out"
    assert_not_contains "behind_commits 出力なし" "behind_commits:" "$out"
    assert_not_contains "recommended_command 出力なし" "recommended_command:" "$out"
)

echo ""
echo "--- テスト3: status:warning + behind_commits（upstream が HEAD を追い越し） ---"
(
    repo=$(setup_repo "t3" "cycle/t3")
    cd "$repo"
    # リモートだけ進める
    remote_work="${TMPDIR_BASE}/t3_remote_work"
    git clone "${TMPDIR_BASE}/t3_bare" "$remote_work" >/dev/null 2>&1
    (
        cd "$remote_work"
        git config user.name "test"
        git config user.email "test@example.com"
        git config commit.gpgsign false
        git checkout "cycle/t3" >/dev/null 2>&1
        git commit --allow-empty -m "remote-ahead-1" >/dev/null 2>&1
        git commit --allow-empty -m "remote-ahead-2" >/dev/null 2>&1
        git commit --allow-empty -m "remote-ahead-3" >/dev/null 2>&1
        git push origin "cycle/t3" >/dev/null 2>&1
    )
    out=$(bash "$VALIDATE_GIT" remote-sync)
    assert_contains "status:warning" "status:warning" "$out"
    assert_contains "behind_commits:3" "behind_commits:3" "$out"
    assert_not_contains "unpushed_commits 出力なし" "unpushed_commits:" "$out"
)

echo ""
echo "--- テスト4: status:diverged（双方向に差分、新規分類） ---"
(
    repo=$(setup_repo "t4" "cycle/t4")
    cd "$repo"
    # ローカルを進める
    git commit --allow-empty -m "local-side-1" >/dev/null 2>&1
    git commit --allow-empty -m "local-side-2" >/dev/null 2>&1
    # リモートを別方向に進める
    remote_work="${TMPDIR_BASE}/t4_remote_work"
    git clone "${TMPDIR_BASE}/t4_bare" "$remote_work" >/dev/null 2>&1
    (
        cd "$remote_work"
        git config user.name "test"
        git config user.email "test@example.com"
        git config commit.gpgsign false
        git checkout "cycle/t4" >/dev/null 2>&1
        git commit --allow-empty -m "remote-side-1" >/dev/null 2>&1
        git push origin "cycle/t4" >/dev/null 2>&1
    )
    out=$(bash "$VALIDATE_GIT" remote-sync)
    assert_contains "status:diverged" "status:diverged" "$out"
    assert_contains "diverged_ahead:2" "diverged_ahead:2" "$out"
    assert_contains "diverged_behind:1" "diverged_behind:1" "$out"
    assert_contains "recommended_command 出力" "recommended_command:git push --force-with-lease origin HEAD:cycle/t4" "$out"
)

echo ""
echo "--- テスト5: 異名 upstream の recommended_command 形式（HEAD:<upstream_branch>） ---"
(
    repo=$(setup_repo "t5" "cycle/t5-remote" "cycle/t5-local")
    cd "$repo"
    # diverge を作る
    git commit --allow-empty -m "local-a" >/dev/null 2>&1
    remote_work="${TMPDIR_BASE}/t5_remote_work"
    git clone "${TMPDIR_BASE}/t5_bare" "$remote_work" >/dev/null 2>&1
    (
        cd "$remote_work"
        git config user.name "test"
        git config user.email "test@example.com"
        git config commit.gpgsign false
        git checkout "cycle/t5-remote" >/dev/null 2>&1
        git commit --allow-empty -m "remote-a" >/dev/null 2>&1
        git push origin "cycle/t5-remote" >/dev/null 2>&1
    )
    out=$(bash "$VALIDATE_GIT" remote-sync)
    assert_contains "status:diverged" "status:diverged" "$out"
    # branch: はローカルブランチ名（既存互換）
    assert_contains "branch:ローカル名" "branch:cycle/t5-local" "$out"
    # recommended_command は HEAD:<upstream_branch> 形式
    assert_contains "recommended_command HEAD:upstream_branch" "recommended_command:git push --force-with-lease origin HEAD:cycle/t5-remote" "$out"
)

echo ""
echo "--- テスト6: status:error + no-upstream（branch.*.merge 未設定） ---"
(
    repo=$(setup_repo "t6" "cycle/t6")
    cd "$repo"
    # 追跡設定を削除
    git config --unset "branch.cycle/t6.merge" 2>/dev/null || true
    ec=0
    out=$(bash "$VALIDATE_GIT" remote-sync) || ec=$?
    assert_eq "exit 2" "2" "$ec"
    assert_contains "status:error" "status:error" "$out"
    assert_contains "no-upstream code" "error:no-upstream:" "$out"
    assert_not_contains "upstream-resolve-failed ではない" "upstream-resolve-failed" "$out"
)

echo ""
echo "--- テスト7: status:error + upstream-resolve-failed（branch.*.merge が refs/heads/* 以外） ---"
(
    repo=$(setup_repo "t7" "cycle/t7")
    cd "$repo"
    # 不正形式の merge_ref を書き込む
    git config "branch.cycle/t7.merge" "refs/tags/invalid"
    ec=0
    out=$(bash "$VALIDATE_GIT" remote-sync) || ec=$?
    assert_eq "exit 2" "2" "$ec"
    assert_contains "status:error" "status:error" "$out"
    assert_contains "upstream-resolve-failed code" "error:upstream-resolve-failed:" "$out"
)

echo ""
echo "--- テスト8: status:error + branch-unresolved（detached HEAD） ---"
(
    repo=$(setup_repo "t8" "cycle/t8")
    cd "$repo"
    sha=$(git rev-parse HEAD)
    git checkout --detach "$sha" >/dev/null 2>&1
    ec=0
    out=$(bash "$VALIDATE_GIT" remote-sync) || ec=$?
    assert_eq "exit 2" "2" "$ec"
    assert_contains "status:error" "status:error" "$out"
    assert_contains "branch-unresolved code" "error:branch-unresolved:" "$out"
    assert_contains "branch:unknown" "branch:unknown" "$out"
)

echo ""
echo "--- テスト9: status:error + fetch-failed（リモート到達不能） ---"
(
    repo=$(setup_repo "t9" "cycle/t9")
    cd "$repo"
    # bare を削除して fetch を失敗させる
    \rm -rf "${TMPDIR_BASE}/t9_bare"
    ec=0
    out=$(bash "$VALIDATE_GIT" remote-sync) || ec=$?
    assert_eq "exit 2" "2" "$ec"
    assert_contains "status:error" "status:error" "$out"
    assert_contains "fetch-failed code" "error:fetch-failed:" "$out"
)

echo ""
echo "--- テスト10: run_all の summary 分類（diverged → status:diverged） ---"
(
    repo=$(setup_repo "t10" "cycle/t10")
    cd "$repo"
    git commit --allow-empty -m "local-a" >/dev/null 2>&1
    remote_work="${TMPDIR_BASE}/t10_remote_work"
    git clone "${TMPDIR_BASE}/t10_bare" "$remote_work" >/dev/null 2>&1
    (
        cd "$remote_work"
        git config user.name "test"
        git config user.email "test@example.com"
        git config commit.gpgsign false
        git checkout "cycle/t10" >/dev/null 2>&1
        git commit --allow-empty -m "remote-a" >/dev/null 2>&1
        git push origin "cycle/t10" >/dev/null 2>&1
    )
    out=$(bash "$VALIDATE_GIT" all)
    summary=$(printf '%s\n' "$out" | awk '/^--- summary ---$/{flag=1;next} flag' | head -n1)
    assert_eq "summary=status:diverged" "status:diverged" "$summary"
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
