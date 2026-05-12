#!/usr/bin/env bats
# v2.6.2 Unit 005 Phase 2: bin/probe-github-project.sh 本体動作テスト
#
# 計画書: .aidlc/cycles/v2.6.2/plans/unit-005-plan.md
# 設計書: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md
#
# モック: _helpers.bash 経由
#
# 設計書ケース表 (4 ケース):
#   1. --probe workflow-item-closed --dry-run で structure-only evidence JSON (cleanup_status: null)
#   2. apply 経路で issue create → item-add → issue close → cleanup (gh issue delete) が呼ばれる
#      cleanup_status: "succeeded" / cleanup は gh_project_repo_delete_issue 経由
#   3. --probe 値欠落で exit 1 + missing_value_for_option:--probe
#   4. --strict scope 不足で exit 2 + scope_missing

load '_helpers'

setup() {
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    SUBJECT="${REPO_ROOT}/bin/probe-github-project.sh"

    gh_project_setup_env
    gh_project_mock_gh
    gh_project_mock_dasel
    gh_project_mock_yq

    cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml" <<TOML
[github_projects]
owner = "@me"
project_number = "123"
project_url = "https://github.com/users/me/projects/123"
TOML
    cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml.json" <<JSON
{"github_projects":{"owner":"@me","project_number":"123","project_url":"https://github.com/users/me/projects/123"}}
JSON

    gh_project_set_fixture issue-create "${BATS_TEST_DIRNAME}/fixtures/issue-create.json"
    gh_project_set_fixture project-item-add "${BATS_TEST_DIRNAME}/fixtures/project-item-add.json"
    gh_project_set_fixture issue-close "${BATS_TEST_DIRNAME}/fixtures/issue-close.json"
    gh_project_set_fixture issue-delete "${BATS_TEST_DIRNAME}/fixtures/issue-delete.json"
}

# ==============================================================================
# Case 1: --dry-run で structure-only evidence JSON (cleanup_status: null / 副作用なし)
# ==============================================================================
@test "probe-github-project: --probe workflow-item-closed --dry-run で structure-only evidence" {
    run "$SUBJECT" --probe workflow-item-closed --dry-run --soft
    [ "$status" -eq 0 ]
    [[ "$output" == *"probe:workflow-item-closed:would-run:"* ]]
    [[ "$output" == *"evidence:"* ]]
    # evidence JSON を読んで cleanup_status: null を確認
    local evidence="$BATS_TEST_TMPDIR/.aidlc/cache/audit/probe-evidence.json"
    [ -f "$evidence" ]
    local cleanup
    cleanup="$(jq -r '.cleanup_status' "$evidence")"
    [ "$cleanup" = "null" ]
    local dry
    dry="$(jq -r '.dry_run' "$evidence")"
    [ "$dry" = "true" ]
    # write 系 API は呼ばれない
    gh_project_assert_gh_call_count "^issue create " 0
    gh_project_assert_gh_call_count "^project item-add " 0
    gh_project_assert_gh_call_count "^issue close " 0
    gh_project_assert_gh_call_count "^issue delete " 0
}

# ==============================================================================
# Case 2: apply 経路で sandbox 操作 + cleanup (gh issue delete 1 回)
# ==============================================================================
@test "probe-github-project: apply 経路で cleanup (gh issue delete) 1 回 + cleanup_status: succeeded" {
    run "$SUBJECT" --probe workflow-item-closed --soft
    [ "$status" -eq 0 ]
    [[ "$output" == *"probe:workflow-item-closed:completed:9999"* ]]
    [[ "$output" == *"evidence:"* ]]
    # 各 write API の呼出回数
    gh_project_assert_gh_call_count "^issue create " 1
    gh_project_assert_gh_call_count "^project item-add " 1
    gh_project_assert_gh_call_count "^issue close " 1
    gh_project_assert_gh_call_count "^issue delete " 1
    # cleanup は gh issue delete 経由 (R1 指摘 #2 反映: gh project item-delete ではない)
    gh_project_assert_gh_call_count "^project item-delete " 0
    # evidence JSON の cleanup_status: succeeded
    local evidence="$BATS_TEST_TMPDIR/.aidlc/cache/audit/probe-evidence.json"
    [ -f "$evidence" ]
    local cleanup
    cleanup="$(jq -r '.cleanup_status' "$evidence")"
    [ "$cleanup" = "succeeded" ]
}

# ==============================================================================
# Case 3: --probe 値欠落で exit 1 + missing_value_for_option
# ==============================================================================
@test "probe-github-project: --probe 値欠落で exit 1 + missing_value_for_option" {
    run "$SUBJECT" --probe
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing_value_for_option:--probe"* ]]
}

# ==============================================================================
# Case 4: --strict scope 不足で exit 2 + scope_missing
# ==============================================================================
@test "probe-github-project: --strict scope 不足で exit 2 + scope_missing" {
    cat > "${MOCK_DIR}/gh" <<'GH_MOCK_NOSCOPE'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${GH_PROJECT_CALL_LOG:-/dev/null}"
if [[ "$1" == "auth" ]] && [[ "$2" == "status" ]]; then
    echo "github.com"
    echo "  ✓ Logged in"
    exit 0
fi
echo "unmocked: $*" >&2
exit 99
GH_MOCK_NOSCOPE
    chmod +x "${MOCK_DIR}/gh"
    run "$SUBJECT" --probe workflow-item-closed --strict
    [ "$status" -eq 2 ]
    [[ "$output" == *"scope_missing"* ]]
}
