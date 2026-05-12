#!/usr/bin/env bats
# v2.6.2 Unit 004: gh-project-cli.sh ensure-fields の field options 差分同期テスト
#
# 計画書: .aidlc/cycles/v2.6.2/plans/unit-004-plan.md
# 設計書: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_004_gh_project_cli_options_sync_logical_design.md
#
# v2.6.2 Unit 005 Phase 2 末尾: _helpers.bash 経由のモックフレームワークに置換
#   - setup() 内のインライン gh / yq / dasel モック (約 80 行) を撤去
#   - load '_helpers' + gh_project_setup_env + gh_project_mock_gh/dasel/yq に集約
#   - assert 本体の意味は維持 (graphql 呼出回数 / option 引数の検証)
#   - 呼出ログは GH_PROJECT_CALL_LOG (全 gh 呼出 / 1 行 1 呼出 / フル引数)
#   - graphql 呼出回数の検証は `^api graphql ` パターンで filter

load '_helpers'

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  CLI="${REPO_ROOT}/bin/gh-project-cli.sh"

  gh_project_setup_env
  gh_project_mock_gh
  gh_project_mock_dasel
  gh_project_mock_yq

  # spec.yaml と fixture json (yq モック経由で読まれる)
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
    options: [A, B]
cycle_map:
  patterns: []
  fallback: Later
views: []
YAML
  _write_spec_fixture '["A","B"]'

  # .aidlc/config.toml に runtime binding (_read_runtime_binding 経由)
  cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml" <<'TOML'
[github_projects]
owner = "@me"
project_number = "123"
project_url = "https://github.com/users/me/projects/123"
TOML
  cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml.json" <<'JSON'
{"github_projects":{"owner":"@me","project_number":"123","project_url":"https://github.com/users/me/projects/123"}}
JSON

  # AIDLC_GH_PROJECT_SPEC は subject に明示伝達
  export AIDLC_GH_PROJECT_SPEC="$BATS_TEST_TMPDIR/config/github-project-spec.yaml"
  # キャッシュをテスト毎に隔離
  export AIDLC_GH_PROJECT_CACHE_DIR="${BATS_TEST_TMPDIR}/state-cache"
  mkdir -p "$AIDLC_GH_PROJECT_CACHE_DIR"

  # graphql 呼出時に必要な fixture (mutation の戻り値 / 成功シナリオ用)
  gh_project_set_fixture api-graphql "${BATS_TEST_DIRNAME}/fixtures/api-graphql.json"
}

teardown() {
  unset MOCK_API_GRAPHQL_FAIL || true
  unset MOCK_API_GRAPHQL_FAIL_ON_NTH || true
}

# spec.yaml.json の中身を切替えるヘルパー (spec.fields[0].options を任意の JSON 配列文字列で差替え)
_write_spec_fixture() {
  local options_json="$1"
  cat > "$BATS_TEST_TMPDIR/config/github-project-spec.yaml.json" <<EOF
{"version":1,"project":{"title":"TestProject","owner":"@me","visibility":"public"},"fields":[{"name":"Status","data_type":"single_select","options":${options_json}}],"cycle_map":{"patterns":[],"fallback":"Later"},"views":[]}
EOF
}

# existing fields fixture を作成して project-field-list 用 fixture に配置する
_set_existing_fields() {
  local options_json="$1"  # JSON 配列例: '["A","B"]'
  local fixture="${BATS_TEST_TMPDIR}/fields-existing.json"
  printf '{"fields":[{"id":"PVTSSF_TEST","name":"Status","options":%s}]}\n' \
    "$(printf '%s' "$options_json" | jq -c 'map({name:.})')" > "$fixture"
  gh_project_set_fixture project-field-list "$fixture"
}

# graphql 呼出回数 / 引数検証ヘルパー (assert 本体の意味を維持)
_graphql_call_count() {
  local cnt
  cnt="$(grep -c -E '^api graphql ' "$GH_PROJECT_CALL_LOG" 2>/dev/null || true)"
  printf '%s' "${cnt:-0}"
}

# ==============================================================================
# Case 1: no-op (差分なし / spec == existing)
# ==============================================================================
@test "ensure-fields: spec == existing で no-op (options-added 出力なし / strict)" {
  _write_spec_fixture '["A","B"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" != *"options-added"* ]]
  [[ "$output" != *"options-would-add"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}

# ==============================================================================
# Case 2: 1 件追加 (spec ⊋ existing / strict)
# ==============================================================================
@test "ensure-fields: 1 件追加 (strict / spec={A,B} existing={A})" {
  _write_spec_fixture '["A","B"]'
  _set_existing_fields '["A"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" == *"field:Status:options-added:1:names=B"* ]]
  [ "$(_graphql_call_count)" = "1" ]
  gh_project_assert_gh_call_contains "option=B"
}

# ==============================================================================
# Case 3: 複数追加 (spec - existing = 2 / strict)
# ==============================================================================
@test "ensure-fields: 複数追加 (strict / spec={A,B,C} existing={A})" {
  _write_spec_fixture '["A","B","C"]'
  _set_existing_fields '["A"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:Status:options-added:2:names=B,C"* ]]
  [ "$(_graphql_call_count)" = "2" ]
  gh_project_assert_gh_call_contains "option=B"
  gh_project_assert_gh_call_contains "option=C"
}

# ==============================================================================
# Case 4: strict + 既存余分 (fail-fast / spec ⊊ existing)
# ==============================================================================
@test "ensure-fields: strict + 既存余分 fail-fast (exit 3 / API 呼ばれず)" {
  _write_spec_fixture '["A"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 3 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" != *"options-added"* ]]
  [[ "$output" == *"options_extraneous"* ]]
  [[ "$output" == *"names=B"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}

# ==============================================================================
# Case 4-bis: strict + 双方向差分 (fail-fast / 追加 API 呼ばれず)
# ==============================================================================
@test "ensure-fields: strict + 双方向差分 fail-fast (追加 API 呼ばれず exit 3)" {
  _write_spec_fixture '["A","C"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 3 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" != *"options-added"* ]]
  [[ "$output" == *"options_extraneous"* ]]
  [[ "$output" == *"names=B"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}

# ==============================================================================
# Case 5: soft + 既存余分 (warn のみで exit 0)
# ==============================================================================
@test "ensure-fields: soft + 既存余分 (warn 継続 exit 0)" {
  _write_spec_fixture '["A"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields --soft
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" == *"options_extraneous"* ]]
  [[ "$output" == *"names=B"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}

# ==============================================================================
# Case 6: dry-run + 追加方向差分 (options-would-add / API 呼ばれない)
# ==============================================================================
@test "ensure-fields: dry-run + 追加方向差分 (options-would-add / API 呼ばれない)" {
  _write_spec_fixture '["A","B"]'
  _set_existing_fields '["A"]'
  run "$CLI" ensure-fields --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" == *"field:Status:options-would-add:1:names=B"* ]]
  [[ "$output" != *"options-added"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}

# ==============================================================================
# Case 7: dry-run + 既存余分 (warn のみ / exit 0)
# ==============================================================================
@test "ensure-fields: dry-run + 既存余分 (warn のみ exit 0)" {
  _write_spec_fixture '["A"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" == *"options_extraneous"* ]]
  [[ "$output" != *"options-would-add"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}

# ==============================================================================
# Case 8: strict + API 失敗 (即 exit 3 / 部分追加なし)
# ==============================================================================
@test "ensure-fields: strict + API 失敗 (部分追加なしで exit 3)" {
  _write_spec_fixture '["A","B"]'
  _set_existing_fields '["A"]'
  export MOCK_API_GRAPHQL_FAIL=1
  run "$CLI" ensure-fields
  [ "$status" -eq 3 ]
  [[ "$output" == *"gh_api_error"* ]]
  [[ "$output" == *"options_add_failed"* ]]
  [[ "$output" != *"options-added"* ]]
  [ "$(_graphql_call_count)" = "1" ]
}

# ==============================================================================
# Case 9: soft + API 失敗 (warn 継続 / exit 0)
# ==============================================================================
@test "ensure-fields: soft + API 失敗 (warn 継続 exit 0)" {
  _write_spec_fixture '["A","B","C"]'
  _set_existing_fields '["A"]'
  export MOCK_API_GRAPHQL_FAIL=1
  run "$CLI" ensure-fields --soft
  [ "$status" -eq 0 ]
  [[ "$output" == *"gh_api_error"* ]]
  [[ "$output" == *"options_add_failed"* ]]
  [ "$(_graphql_call_count)" = "2" ]
}

# ==============================================================================
# Case 9-bis: strict + 部分成功後失敗 (1 件成功 → 2 件目失敗で exit 3)
# コード R1 指摘 #3 反映: 部分追加の可観測性を回帰させない
# ==============================================================================
@test "ensure-fields: strict + 部分成功後失敗 (options-added:1:names=B 出力 + exit 3)" {
  _write_spec_fixture '["A","B","C"]'
  _set_existing_fields '["A"]'
  # to_add 順 = [B, C]: 1 回目=option=B 成功 / 2 回目=option=C 失敗
  export MOCK_API_GRAPHQL_FAIL_ON_NTH=2
  run "$CLI" ensure-fields
  [ "$status" -eq 3 ]
  [[ "$output" == *"field:Status:options-added:1:names=B"* ]]
  [[ "$output" == *"gh_api_error"* ]]
  [[ "$output" == *"option=C"* ]]
  [ "$(_graphql_call_count)" = "2" ]
}

# ==============================================================================
# Case 10: option 名サニタイズ (制御文字 / カンマ含むと args_invalid + exit 1)
# ==============================================================================
@test "ensure-fields: spec.options 内のカンマ含む option 名で args_invalid (exit 1)" {
  _write_spec_fixture '["A,B","C"]'
  _set_existing_fields '["C"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 1 ]
  [[ "$output" == *"options_name_unsafe_chars"* ]]
  [[ "$output" == *"source=spec"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}

@test "ensure-fields: existing options 内の改行含む option 名で args_invalid (exit 1)" {
  _write_spec_fixture '["A"]'
  _set_existing_fields '["A","Bad\nName"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 1 ]
  [[ "$output" == *"options_name_unsafe_chars"* ]]
  [[ "$output" == *"source=existing"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}

# ==============================================================================
# Case 11: dynamic field のスキップ (差分同期は呼ばれない)
# ==============================================================================
@test "ensure-fields: dynamic field (cycle) の差分同期はスキップ" {
  # spec.fields[0].options を "dynamic" 文字列に
  cat > "$BATS_TEST_TMPDIR/config/github-project-spec.yaml.json" <<'EOF'
{"version":1,"project":{"title":"TestProject","owner":"@me","visibility":"public"},"fields":[{"name":"Cycle","data_type":"single_select","options":"dynamic"}],"cycle_map":{"patterns":[],"fallback":"Later"},"views":[]}
EOF
  # existing: Cycle field が既に存在し options に旧 milestone を持つ
  local fixture="${BATS_TEST_TMPDIR}/fields-existing.json"
  cat > "$fixture" <<'EOF'
{"fields":[{"id":"PVTSSF_CYC","name":"Cycle","options":[{"name":"Later"},{"name":"v1.0.0"}]}]}
EOF
  gh_project_set_fixture project-field-list "$fixture"
  run "$CLI" ensure-fields
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Cycle"* ]]
  [[ "$output" != *"options-added"* ]]
  [[ "$output" != *"options-would-add"* ]]
  [[ "$output" != *"options_extraneous"* ]]
  [ "$(_graphql_call_count)" = "0" ]
}
