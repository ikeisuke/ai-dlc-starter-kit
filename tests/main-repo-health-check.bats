#!/usr/bin/env bats

# tests/main-repo-health-check.bats
#
# Unit 002: メインリポジトリ Health Check helper の自動テスト
# 4 シナリオ: 健全 / unmerged paths / MERGE_HEAD / コンフリクトマーカー残骸

setup() {
    export FIXTURE_REPO="${BATS_TEST_TMPDIR}/fake-main-repo"
    # 既定ブランチを main に明示（環境依存を排除、git ≥ 2.28 必要）
    git init -b main "$FIXTURE_REPO" >/dev/null
    cd "$FIXTURE_REPO"
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "initial" > README.md
    git add README.md
    git commit -m "initial" >/dev/null

    # helper の絶対パスを記録（bats の作業ディレクトリ依存を回避）
    export HELPER="${BATS_TEST_DIRNAME}/../skills/aidlc/scripts/main-repo-health-check.sh"
}

teardown() {
    cd "$BATS_TEST_TMPDIR"
    if [[ -n "${FIXTURE_REPO:-}" && -d "${FIXTURE_REPO}" ]]; then
        rm -rf "${FIXTURE_REPO}"
    fi
}

@test "healthy: clean repo returns exit 0 + status:ok" {
    cd "$FIXTURE_REPO"
    run bash "$HELPER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "status:ok" ]]
    [[ "$output" =~ "health-check:unmerged-paths:ok" ]]
    [[ "$output" =~ "health-check:merge-in-progress:ok" ]]
    [[ "$output" =~ "health-check:conflict-marker:ok" ]]
}

@test "warning: unmerged paths detected returns exit 0 + status:warning" {
    cd "$FIXTURE_REPO"

    # 2 ブランチを作成し意図的にコンフリクトを発生させる
    git checkout -b branch-a >/dev/null 2>&1
    echo "from a" > conflict.txt
    git add conflict.txt
    git commit -m "branch-a change" >/dev/null

    git checkout -b branch-b main >/dev/null 2>&1
    echo "from b" > conflict.txt
    git add conflict.txt
    git commit -m "branch-b change" >/dev/null

    # コンフリクトで失敗、unmerged 状態が残る（|| true で git merge の exit 1 を吸収）
    git merge branch-a >/dev/null 2>&1 || true

    run bash "$HELPER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "status:warning" ]]
    [[ "$output" =~ "health-check:unmerged-paths:warning" ]]
}

@test "warning: MERGE_HEAD exists returns exit 0 + status:warning" {
    cd "$FIXTURE_REPO"

    # MERGE_HEAD ファイルを直接作成（マージ進行中状態の擬似再現）
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir)
    echo "0000000000000000000000000000000000000000" > "${git_common_dir}/MERGE_HEAD"

    run bash "$HELPER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "status:warning" ]]
    [[ "$output" =~ "health-check:merge-in-progress:warning" ]]
    [[ "$output" =~ "MERGE_HEAD" ]]

    rm -f "${git_common_dir}/MERGE_HEAD"
}

@test "warning: conflict marker残骸 (v2.5.3 reproduction) returns exit 0 + status:warning" {
    cd "$FIXTURE_REPO"

    # v2.5.3 で実害発生したパターンを fixture で再現:
    # コンフリクトマーカー 6 件含む tracked ファイルを commit
    cat > review-flow-mock.md <<'EOF'
some content

<<<<<<< Updated upstream
local change
=======
upstream change
>>>>>>> Stashed changes

other content

<<<<<<< Updated upstream
another local
=======
another upstream
>>>>>>> Stashed changes
EOF
    git add review-flow-mock.md
    git commit -m "fixture: stash pop conflict marker remains" >/dev/null

    run bash "$HELPER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "status:warning" ]]
    [[ "$output" =~ "health-check:conflict-marker:warning" ]]
    # 1 件以上のマーカー検出（6 件のはず: <<<<<<< x2 + ======= x2 + >>>>>>> x2）
    [[ "$output" =~ count=[1-9] ]]
}

@test "system error: invalid git context returns exit 2 + status:error" {
    # git リポジトリ外で実行
    cd "$BATS_TEST_TMPDIR"
    mkdir non-git-dir
    cd non-git-dir
    run bash "$HELPER"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "status:error" ]]
    [[ "$output" =~ "error:git-path-resolve-failed" ]]
}
