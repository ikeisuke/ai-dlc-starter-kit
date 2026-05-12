#!/usr/bin/env bats
# bin/tests/gh-project/_helpers_self_test.bats
#
# Phase 1 完了マーカー: _helpers.bash のヘルパー API 自体の最小動作確認
#   - 環境セットアップ (gh_project_setup_env)
#   - gh mock factory + fixture dispatch
#   - 未モック API exit 99 検出
#   - per-api 失敗注入 + 失敗注入解除
#   - 呼出ログアサート
#
# 本ファイルは Phase 1 完了マーカーであり、4 スクリプト本体の動作テストは
# 別 bats (setup-github-project.bats / migrate-issue-524.bats /
# probe-github-project.bats / audit-github-project.bats) で実施する。

load '_helpers'

setup() {
    gh_project_setup_env
    gh_project_mock_gh
    gh_project_mock_dasel
    gh_project_mock_yq
}

@test "_helpers: gh_project_setup_env が必要な環境変数を export する" {
    [ -n "$AIDLC_REPO_ROOT" ]
    [ -n "$MOCK_DIR" ]
    [ -n "$GH_PROJECT_FIXTURE_DIR" ]
    [ -n "$GH_PROJECT_CALL_LOG" ]
    [ -d "$AIDLC_REPO_ROOT/.aidlc/cache" ]
    [ -d "$AIDLC_REPO_ROOT/config" ]
    [ -d "$MOCK_DIR" ]
    [ -d "$GH_PROJECT_FIXTURE_DIR" ]
    [ -f "$GH_PROJECT_CALL_LOG" ]
    # PATH 先頭が MOCK_DIR
    [[ "$PATH" == "$MOCK_DIR"* ]]
}

@test "_helpers: gh mock が gh auth status に固定応答する" {
    run gh auth status
    [ "$status" -eq 0 ]
    [[ "$output" == *"Logged in"* ]]
}

@test "_helpers: gh mock が fixture 配置済み API を dispatch する" {
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    run gh project list --owner @me --format json
    [ "$status" -eq 0 ]
    [[ "$output" == *"TestProject"* ]]
}

@test "_helpers: 未モック API は exit 99 で fail する" {
    run gh project bogus-subcommand
    [ "$status" -eq 99 ]
    [[ "$output" == *"unmocked"* ]]
}

@test "_helpers: fixture 不在の API は exit 98 で fail する" {
    # fixture 未配置の API を呼ぶ
    run gh issue view 524 --json body
    [ "$status" -eq 98 ]
    [[ "$output" == *"fixture not found"* ]]
}

@test "_helpers: per-api 失敗注入 (gh_project_inject_failure project list) で MOCK_PROJECT_LIST_FAIL が立つ" {
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    gh_project_inject_failure "project list"
    [ "$MOCK_PROJECT_LIST_FAIL" = "1" ]
    run gh project list --owner @me --format json
    [ "$status" -eq 1 ]
    [[ "$output" == *"project_list injected failure"* ]]
}

@test "_helpers: per-api 失敗注入は他 API に波及しない" {
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    gh_project_set_fixture project-field-list "${BATS_TEST_DIRNAME}/fixtures/project-field-list.json"
    gh_project_inject_failure "project list"
    # project list は fail
    run gh project list --owner @me --format json
    [ "$status" -eq 1 ]
    # project field-list は成功
    run gh project field-list --owner @me 123 --format json
    [ "$status" -eq 0 ]
    [[ "$output" == *"Status"* ]]
}

@test "_helpers: グローバル失敗 (MOCK_GH_FAIL=1) は全 API に波及する" {
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    export MOCK_GH_FAIL=1
    run gh project list --owner @me --format json
    [ "$status" -eq 1 ]
    [[ "$output" == *"global injected failure"* ]]
}

@test "_helpers: 呼出ログに引数が追記される" {
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    gh project list --owner @me --format json >/dev/null
    gh project list --owner @me --format json >/dev/null
    gh_project_assert_gh_call_count "project list" 2
    gh_project_assert_gh_call_contains "project list.*--owner.*@me"
}

@test "_helpers: gh_project_assert_gh_call_count の不一致時は non-zero return" {
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    gh project list --owner @me --format json >/dev/null
    run gh_project_assert_gh_call_count "project list" 2
    [ "$status" -ne 0 ]
}

@test "_helpers: gh_project_set_fixture は src 不在時に non-zero return" {
    run gh_project_set_fixture project-list "/nonexistent/path/missing.json"
    [ "$status" -ne 0 ]
    [[ "$output" == *"source not found"* ]]
}

# v2.6.2 Unit 005 統合レビュー R4 #1 反映: gh_project_assert_gh_call_count_fixed のコントラクト確認
# - grep -Fx で行全体一致 (部分一致 false-positive を排除)
# - 部分一致 needle に対しては false-negative (count=0) になることを明示
@test "_helpers: gh_project_assert_gh_call_count_fixed は行全体一致 (auth status は count=1)" {
    # gh auth status を 1 回呼ぶ (固定応答 stub / 呼出ログに 'auth status' 1 行が追記される)
    gh auth status >/dev/null
    gh_project_assert_gh_call_count_fixed "auth status" 1
}

@test "_helpers: gh_project_assert_gh_call_count_fixed は部分一致では false-negative" {
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    gh project list --owner @me --format json >/dev/null
    # ログ行は "project list --owner @me --format json" であり "project list" は部分一致
    # grep -Fx (行全体一致) では count=0 となるため、本ヘルパーは完全一致 needle 用途専用
    run gh_project_assert_gh_call_count_fixed "project list" 1
    [ "$status" -ne 0 ]
}
