#!/usr/bin/env bats
# v2.6.2 Unit 005 Phase 2: bin/migrate-issue-524.sh 本体動作テスト
#
# 計画書: .aidlc/cycles/v2.6.2/plans/unit-005-plan.md
# 設計書: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md
#
# モック: _helpers.bash の gh API モックフレームワーク経由
#
# 設計書ケース表 (4 ケース):
#   1. --dry-run で diff 出力 + バックアップ + gh issue view 1 回 / gh issue edit 0 回
#   2. バックアップが .aidlc/cycles/v2.6.0/operations/issue-524-backup.md に作成される
#   3. --strict scope 不足で exit 2
#   4. unknown option で exit 1

load '_helpers'

setup() {
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    SUBJECT="${REPO_ROOT}/bin/migrate-issue-524.sh"

    gh_project_setup_env
    gh_project_mock_gh
    gh_project_mock_dasel
    gh_project_mock_yq

    # config.toml.json (dasel mock 経由で project_url を返すため)
    cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml" <<TOML
[github_projects]
owner = "@me"
project_number = "123"
project_url = "https://github.com/users/me/projects/123"
TOML
    cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml.json" <<JSON
{"github_projects":{"owner":"@me","project_number":"123","project_url":"https://github.com/users/me/projects/123"}}
JSON

    # 既定 fixture を配置 (subject が gh issue view 524 → issue body 取得)
    gh_project_set_fixture issue-view "${BATS_TEST_DIRNAME}/fixtures/issue-view.json"
    gh_project_set_fixture issue-edit "${BATS_TEST_DIRNAME}/fixtures/issue-edit.json"
}

# ==============================================================================
# Case 1: --dry-run で diff 出力 (gh issue view 1 回 / gh issue edit 0 回)
# ==============================================================================
@test "migrate-issue-524: --dry-run で would-edit ファイル出力 + gh issue edit 0 回 + gh issue view 1 回" {
    run "$SUBJECT" --dry-run --soft
    [ "$status" -eq 0 ]
    [[ "$output" == *"issue-524:would-edit:"* ]]
    [[ "$output" == *"issue-524:backup-saved:"* ]]
    # バックアップファイル実在
    [ -f "$BATS_TEST_TMPDIR/.aidlc/cycles/v2.6.0/operations/issue-524-backup.md" ]
    # would-edit 用 dryrun 出力ファイル実在
    [ -f "$BATS_TEST_TMPDIR/.aidlc/cycles/v2.6.0/operations/issue-524-new-body.dryrun.md" ]
    gh_project_assert_gh_call_count "^issue view " 1
    gh_project_assert_gh_call_count "^issue edit " 0
}

# ==============================================================================
# Case 2: バックアップが期待パスに作成される (内容に元 issue body を含む)
# ==============================================================================
@test "migrate-issue-524: バックアップが .aidlc/cycles/v2.6.0/operations/issue-524-backup.md に作成される" {
    run "$SUBJECT" --dry-run --soft
    [ "$status" -eq 0 ]
    local backup="$BATS_TEST_TMPDIR/.aidlc/cycles/v2.6.0/operations/issue-524-backup.md"
    [ -f "$backup" ]
    # バックアップは fixture (issue-view.json) の内容を保持
    grep -q "Legacy backlog body" "$backup"
}

# ==============================================================================
# Case 3: --strict + scope 不足で exit 2 + scope_missing
# ==============================================================================
@test "migrate-issue-524: --strict scope 不足で exit 2 + scope_missing" {
    # gh auth status から Token scopes 行を消した出力を返すよう wrapper を上書き
    cat > "${MOCK_DIR}/gh" <<'GH_MOCK_NOSCOPE'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${GH_PROJECT_CALL_LOG:-/dev/null}"
if [[ "$1" == "auth" ]] && [[ "$2" == "status" ]]; then
    echo "github.com"
    echo "  ✓ Logged in"
    # Token scopes 行をあえて出さない → 全 scope 不足扱い
    exit 0
fi
echo "unmocked: $*" >&2
exit 99
GH_MOCK_NOSCOPE
    chmod +x "${MOCK_DIR}/gh"
    run "$SUBJECT" --strict
    [ "$status" -eq 2 ]
    [[ "$output" == *"scope_missing"* ]]
}

# ==============================================================================
# Case 4: unknown option で exit 1 + args_invalid
# ==============================================================================
@test "migrate-issue-524: unknown option で exit 1 + args_invalid" {
    run "$SUBJECT" --bogus
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown_option:--bogus"* ]]
}
