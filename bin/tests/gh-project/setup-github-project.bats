#!/usr/bin/env bats
# v2.6.2 Unit 005 Phase 2: bin/setup-github-project.sh 本体動作テスト
#
# 計画書: .aidlc/cycles/v2.6.2/plans/unit-005-plan.md
# 設計書: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md
#
# モック: _helpers.bash 経由 / 4 スクリプト中、最も複雑な orchestrator (5 subcommand 順次呼出)
#
# 設計書ケース表 (4 ケース):
#   1. --dry-run で 5 subcommand 順次実行 + setup-github-project: completed
#   2. --strict 透過 (write API 呼出あり)
#   3. 途中失敗 fail-fast (ensure-fields で失敗注入)
#   4. audit ステップで --dry-run が除去される

load '_helpers'

setup() {
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    SUBJECT="${REPO_ROOT}/bin/setup-github-project.sh"

    gh_project_setup_env
    gh_project_mock_gh
    gh_project_mock_dasel
    gh_project_mock_yq

    mkdir -p "$BATS_TEST_TMPDIR/config"
    cat > "$BATS_TEST_TMPDIR/config/github-project-spec.yaml" <<'YAML'
version: 1
project:
  title: TestProject
  owner: "@me"
  visibility: public
fields:
  - name: Status
    data_type: single_select
    options: [Todo, "In Progress", Done]
cycle_map:
  patterns: []
  fallback: Later
views:
  - name: All Issues
    layout: table_layout
    apply_strategy: cli
YAML
    cat > "$BATS_TEST_TMPDIR/config/github-project-spec.yaml.json" <<'JSON'
{"version":1,"project":{"title":"TestProject","owner":"@me","visibility":"public"},"fields":[{"name":"Status","data_type":"single_select","options":["Todo","In Progress","Done"]}],"cycle_map":{"patterns":[],"fallback":"Later"},"views":[{"name":"All Issues","layout":"table_layout","apply_strategy":"cli"}]}
JSON

    cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml" <<TOML
[github_projects]
owner = "@me"
project_number = "123"
project_url = "https://github.com/users/me/projects/123"
TOML
    cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml.json" <<JSON
{"github_projects":{"owner":"@me","project_number":"123","project_url":"https://github.com/users/me/projects/123"}}
JSON

    export AIDLC_GH_PROJECT_SPEC="$BATS_TEST_TMPDIR/config/github-project-spec.yaml"
    export AIDLC_GH_PROJECT_CACHE_DIR="${BATS_TEST_TMPDIR}/state-cache"
    mkdir -p "$AIDLC_GH_PROJECT_CACHE_DIR"

    # 既定 fixtures (dry-run no-op に必要なもの)
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    gh_project_set_fixture project-field-list "${BATS_TEST_DIRNAME}/fixtures/project-field-list.json"
    gh_project_set_fixture project-view-list "${BATS_TEST_DIRNAME}/fixtures/project-view-list.json"
    gh_project_set_fixture project-item-list "${BATS_TEST_DIRNAME}/fixtures/project-item-list.json"
    gh_project_set_fixture issue-view "${BATS_TEST_DIRNAME}/fixtures/issue-view.json"
    gh_project_set_fixture issue-list "${BATS_TEST_DIRNAME}/fixtures/issue-list.json"
    gh_project_set_fixture project-create "${BATS_TEST_DIRNAME}/fixtures/project-create.json"
    gh_project_set_fixture project-edit "${BATS_TEST_DIRNAME}/fixtures/project-edit.json"
    gh_project_set_fixture issue-edit "${BATS_TEST_DIRNAME}/fixtures/issue-edit.json"
    gh_project_set_fixture project-item-add "${BATS_TEST_DIRNAME}/fixtures/project-item-add.json"
    gh_project_set_fixture project-item-edit "${BATS_TEST_DIRNAME}/fixtures/project-item-edit.json"
    gh_project_set_fixture project-view-create "${BATS_TEST_DIRNAME}/fixtures/project-view-create.json"
    gh_project_set_fixture api-graphql "${BATS_TEST_DIRNAME}/fixtures/api-graphql.json"
}

# ==============================================================================
# Case 1: --dry-run で 5 subcommand 順次実行 + completed
# ==============================================================================
@test "setup-github-project: --dry-run で 5 subcommand 順次実行 + setup-github-project: completed" {
    run "$SUBJECT" --dry-run --soft
    [ "$status" -eq 0 ]
    # 5 セクションヘッダ
    [[ "$output" == *"== ensure-project =="* ]]
    [[ "$output" == *"== ensure-fields =="* ]]
    [[ "$output" == *"== ensure-views =="* ]]
    [[ "$output" == *"== sync-items =="* ]]
    [[ "$output" == *"== audit (spec-conformance) =="* ]]
    [[ "$output" == *"setup-github-project: completed"* ]]
    # dry-run なので write 系 API は呼ばれない
    gh_project_assert_gh_call_count "^project create " 0
    gh_project_assert_gh_call_count "^project item-add " 0
    gh_project_assert_gh_call_count "^api graphql " 0
}

# ==============================================================================
# Case 2: --strict 透過 (新規 project 作成 + write API 呼出を伴うシナリオ)
# ==============================================================================
@test "setup-github-project: --strict で write API 透過 (新規 view 作成)" {
    # view 未作成のシナリオを再現 (project-view-list を空に上書き)
    cat > "${GH_PROJECT_FIXTURE_DIR}/project-view-list.json" <<'JSON'
{"views":[]}
JSON
    # dry-run なしで実行 → ensure-views で project view-create が呼ばれる
    run "$SUBJECT" --strict
    [ "$status" -eq 0 ]
    [[ "$output" == *"setup-github-project: completed"* ]]
    # view-create が 1 回呼ばれる (spec.views = [All Issues] 1 件)
    gh_project_assert_gh_call_count "^project view-create " 1
}

# ==============================================================================
# Case 3: 途中失敗 (ensure-fields の field-list 失敗注入) で fail-fast
# ==============================================================================
@test "setup-github-project: ensure-fields 失敗注入で fail-fast (set -e で非 0 / 後続セクション未出力)" {
    # ensure-fields で gh project field-list が失敗するように注入
    gh_project_inject_failure "project field-list"
    run "$SUBJECT" --strict
    [ "$status" -ne 0 ]
    [[ "$output" == *"== ensure-project =="* ]]
    [[ "$output" == *"== ensure-fields =="* ]]
    # ensure-views 以降は出力されない (fail-fast)
    [[ "$output" != *"== ensure-views =="* ]]
    [[ "$output" != *"== sync-items =="* ]]
    [[ "$output" != *"setup-github-project: completed"* ]]
}

# ==============================================================================
# Case 4: audit ステップで --dry-run が除去される
# ==============================================================================
@test "setup-github-project: audit ステップで --dry-run が除去され audit-github-project.sh が成功する" {
    # R1 #1 反映: 単に「gh ログに --dry-run がない」ことだけ見ると false-positive
    # を許す。`${_OPTS[@]/--dry-run/}` の空要素残存 bug 未修正時は audit が
    # unknown_option:_ で exit 1 となり stdout に audit-summary 行も
    # `audit:spec-conformance:` 行も出ない。本テストはこの 2 行の存在を
    # 必須アサーションとして「audit-github-project.sh が完走した」ことを直接検証する。
    run "$SUBJECT" --dry-run --soft
    [ "$status" -eq 0 ]
    [[ "$output" == *"== audit (spec-conformance) =="* ]]
    [[ "$output" == *"audit:spec-conformance:"* ]]
    [[ "$output" == *"audit-summary:"* ]]
    [[ "$output" == *"setup-github-project: completed"* ]]
    # 補助確認: 全 gh 呼出ログから --dry-run を含む行が存在しない
    if grep -q -- "--dry-run" "$GH_PROJECT_CALL_LOG"; then
        echo "unexpected --dry-run in gh call log:" >&2
        cat "$GH_PROJECT_CALL_LOG" >&2
        return 1
    fi
}
