#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 005: gh_pr_edit_body_with_fallback() の bats テスト
# Plan / Logical Design §「単一 gh shim の構造」を verify する。
# 関連 Issue: #626

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    SHIM_DIR="${REPO_ROOT}/tests/fixtures/gh-pr-edit-fallback"
    PATH="${SHIM_DIR}:${PATH}"
    export PATH

    # operations-release.sh を source して gh_pr_edit_body_with_fallback を取得
    # （末尾の main 呼び出しは BASH_SOURCE ガードで隔離されている）
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"

    # body_file fixture（中身は任意）
    TEST_BODY_FILE="$(mktemp -t aidlc-unit005-body.XXXXXX)"
    printf '## test body\n' > "$TEST_BODY_FILE"
}

teardown() {
    rm -f "$TEST_BODY_FILE"
    unset GH_MOCK_MODE
}

@test "ケース 1: 通常成功 - gh pr edit が exit 0 を返す場合は fallback 経路を経由しない" {
    export GH_MOCK_MODE="pr-edit-success"
    run gh_pr_edit_body_with_fallback "123" "$TEST_BODY_FILE"
    [ "$status" -eq 0 ]
    # fallback シグナルが含まれないこと
    [[ "$output" != *"pr-ready:fallback:rest-patch"* ]]
    # 後方互換: gh CLI の stdout（PR URL）が呼び出し元に透過されること
    [[ "$output" == *"https://github.com/owner/repo/pull/123"* ]]
}

@test "ケース 2: スコープ不足 fallback - read:org エラー → REST PATCH で復旧" {
    export GH_MOCK_MODE="pr-edit-scope-org"
    run gh_pr_edit_body_with_fallback "123" "$TEST_BODY_FILE"
    [ "$status" -eq 0 ]
    # fallback 発動シグナルが stderr に出力されている
    [[ "$output" == *"pr-ready:fallback:rest-patch:123"* ]]
    # 失敗ログキーは出ない
    [[ "$output" != *"pr-ready:fallback:rest-patch:failed"* ]]
}

@test "ケース 3: GraphQL field error fallback - Could not resolve to a User → REST PATCH で復旧" {
    export GH_MOCK_MODE="pr-edit-graphql-error"
    run gh_pr_edit_body_with_fallback "456" "$TEST_BODY_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"pr-ready:fallback:rest-patch:456"* ]]
}

@test "ケース 4: 後方互換 - non-scope error (network error) は fallback 発動せず元 exit code を透過する" {
    export GH_MOCK_MODE="pr-edit-network-error"
    run gh_pr_edit_body_with_fallback "789" "$TEST_BODY_FILE"
    # gh-network-error fixture は exit 1 を返す
    [ "$status" -eq 1 ]
    # 元 stderr が透過される
    [[ "$output" == *"network error: timeout"* ]]
    # fallback 発動シグナルは出力されない
    [[ "$output" != *"pr-ready:fallback:rest-patch"* ]]
}

@test "ケース 5: 後方互換 - fallback 経路の REST PATCH stdout も呼び出し元へ透過される" {
    # gh api PATCH の stdout（JSON レスポンス）が呼び出し元の stdout に流れることを保証する
    export GH_MOCK_MODE="pr-edit-scope-org"
    run gh_pr_edit_body_with_fallback "999" "$TEST_BODY_FILE"
    [ "$status" -eq 0 ]
    # gh-api-success fixture が返す JSON が透過される
    [[ "$output" == *'"number": 123'* ]]
    [[ "$output" == *"pr-ready:fallback:rest-patch:999"* ]]
}
