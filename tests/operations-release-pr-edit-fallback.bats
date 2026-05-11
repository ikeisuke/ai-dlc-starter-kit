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

    # gh shim 呼び出しログ（v2.6.2 Unit 001 / Issue #678）
    GH_MOCK_CALL_LOG="$(mktemp -t aidlc-unit001-ghcalls.XXXXXX)"
    export GH_MOCK_CALL_LOG
    : > "$GH_MOCK_CALL_LOG"
}

teardown() {
    rm -f "$TEST_BODY_FILE"
    rm -f "$GH_MOCK_CALL_LOG"
    unset GH_MOCK_MODE
    unset GH_MOCK_CALL_LOG
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

# --- v2.6.2 Unit 001 / Issue #678: 二重防御テスト ---
# gh_pr_edit_body_with_fallback() の冒頭で _pr_ready_validate_body_file() を呼び出し、
# 0 バイト / 不在 / 非 regular file 時に gh CLI / REST PATCH を発火させずに fail-fast することを検証する。

@test "ケース 6: 二重防御 - 0 バイト body file は fallback 経路でも fail-fast し gh を呼ばない" {
    export GH_MOCK_MODE="pr-edit-success"
    local empty_file
    empty_file="$(mktemp -t aidlc-unit001-empty.XXXXXX)"
    : > "$empty_file"  # 0 バイト確定

    run gh_pr_edit_body_with_fallback "123" "$empty_file"
    rm -f "$empty_file"

    [ "$status" -eq 1 ]
    # 機械可読エラー（tab 区切り 3 フィールド）
    [[ "$output" == *"error"*"pr-ready:body-file-empty"* ]]
    # 人間可読の案内
    [[ "$output" == *"本文が空です"* ]]
    # gh shim は一度も呼ばれていないこと（API 未送信）
    [ ! -s "$GH_MOCK_CALL_LOG" ]
}

@test "ケース 7: 二重防御 - 不在 body file は fallback 経路でも fail-fast し gh を呼ばない" {
    export GH_MOCK_MODE="pr-edit-success"
    local missing_path="/tmp/aidlc-unit001-nonexistent-${RANDOM}-${RANDOM}.txt"
    # 念のため不在を保証
    rm -f "$missing_path"

    run gh_pr_edit_body_with_fallback "456" "$missing_path"

    [ "$status" -eq 1 ]
    [[ "$output" == *"error"*"pr-ready:body-file-missing"* ]]
    [[ "$output" == *"$missing_path"* ]]
    # gh shim は一度も呼ばれていないこと
    [ ! -s "$GH_MOCK_CALL_LOG" ]
}

@test "ケース 8: 二重防御 - ディレクトリパス（非 regular file）は missing 扱いで fail-fast" {
    export GH_MOCK_MODE="pr-edit-success"
    local dir_path
    dir_path="$(mktemp -d -t aidlc-unit001-dir.XXXXXX)"

    run gh_pr_edit_body_with_fallback "789" "$dir_path"
    rmdir "$dir_path"

    [ "$status" -eq 1 ]
    # 非 regular file は missing コードに統合（domain model §state=Missing 定義）
    [[ "$output" == *"error"*"pr-ready:body-file-missing"* ]]
    [ ! -s "$GH_MOCK_CALL_LOG" ]
}
