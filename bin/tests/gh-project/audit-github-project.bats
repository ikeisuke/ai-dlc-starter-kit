#!/usr/bin/env bats
# v2.6.2 Unit 005 Phase 2: bin/audit-github-project.sh 本体動作テスト
#
# 計画書: .aidlc/cycles/v2.6.2/plans/unit-005-plan.md
# 設計書: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md
#
# モック: _helpers.bash 経由
#
# 設計書ケース表 (6 ケース / R1 #3 反映で --check all 追加):
#   1. --check workflow-item-closed + within_sla            -> sla:within_sla / exit 0
#   2. --check workflow-item-closed + sla_exceeded (strict) -> sla:sla_exceeded / exit 7
#   3. --check workflow-item-closed + unknown               -> sla:unknown / exit 0 (warn)
#   4. probe-evidence 不在                                   -> evidence_missing JSON / exit 5
#   5. --check spec-conformance + drift                     -> drift 出力 / exit 7 (strict)
#   6. --check all (workflow + spec) 集約                   -> overall_exit = max(rc) / strict=7 / soft=0

load '_helpers'

setup() {
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    SUBJECT="${REPO_ROOT}/bin/audit-github-project.sh"

    gh_project_setup_env
    gh_project_mock_gh
    gh_project_mock_dasel
    gh_project_mock_yq

    # spec.yaml (yq mock 経由 / fields = Status のみ。drift 検出は project-field-list 側で制御)
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
views: []
YAML
    cat > "$BATS_TEST_TMPDIR/config/github-project-spec.yaml.json" <<'JSON'
{"version":1,"project":{"title":"TestProject","owner":"@me","visibility":"public"},"fields":[{"name":"Status","data_type":"single_select","options":["Todo","In Progress","Done"]}],"cycle_map":{"patterns":[],"fallback":"Later"},"views":[]}
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

    # AIDLC_GH_PROJECT_SPEC を subject に伝えるため export
    export AIDLC_GH_PROJECT_SPEC="$BATS_TEST_TMPDIR/config/github-project-spec.yaml"

    # キャッシュをテスト毎に隔離
    export AIDLC_GH_PROJECT_CACHE_DIR="${BATS_TEST_TMPDIR}/state-cache"
    mkdir -p "$AIDLC_GH_PROJECT_CACHE_DIR"

    # 既定 fixtures
    gh_project_set_fixture project-field-list "${BATS_TEST_DIRNAME}/fixtures/project-field-list.json"
    # item-list は Status="Done" / id=PVTI_TEST_999 のアイテムを持つ (audit_workflow_item_closed 用)
    cat > "${GH_PROJECT_FIXTURE_DIR}/project-item-list.json" <<'JSON'
{"items":[{"id":"PVTI_TEST_999","content":{"url":"https://github.com/x/y/issues/9999"},"status":"Done"}]}
JSON
}

# probe-evidence-within.json を __NOW_ISO__ 置換してキャッシュへ配置
_install_probe_evidence_within() {
    local src="${BATS_TEST_DIRNAME}/fixtures/probe-evidence-within.json"
    local dst="$BATS_TEST_TMPDIR/.aidlc/cache/audit/probe-evidence.json"
    mkdir -p "$(dirname "$dst")"
    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    sed "s/__NOW_ISO__/${now}/" "$src" > "$dst"
}

_install_probe_evidence_exceeded() {
    mkdir -p "$BATS_TEST_TMPDIR/.aidlc/cache/audit"
    cp "${BATS_TEST_DIRNAME}/fixtures/probe-evidence-exceeded.json" \
        "$BATS_TEST_TMPDIR/.aidlc/cache/audit/probe-evidence.json"
}

_install_probe_evidence_unknown() {
    mkdir -p "$BATS_TEST_TMPDIR/.aidlc/cache/audit"
    cp "${BATS_TEST_DIRNAME}/fixtures/probe-evidence-unknown.json" \
        "$BATS_TEST_TMPDIR/.aidlc/cache/audit/probe-evidence.json"
}

# ==============================================================================
# Case 1: workflow-item-closed + within_sla -> pass / exit 0
# ==============================================================================
@test "audit-github-project: --check workflow-item-closed + within_sla で pass / exit 0" {
    _install_probe_evidence_within
    run "$SUBJECT" --check workflow-item-closed --soft
    [ "$status" -eq 0 ]
    [[ "$output" == *"audit:workflow-item-closed:pass"* ]]
    [[ "$output" == *"audit-summary:"* ]]
    # audit-summary.json に sla:within_sla を含む
    local summary="$BATS_TEST_TMPDIR/.aidlc/cache/audit/audit-summary.json"
    [ -f "$summary" ]
    local sla
    sla="$(jq -r '.workflow_item_closed.sla' "$summary")"
    [ "$sla" = "within_sla" ]
}

# ==============================================================================
# Case 2: workflow-item-closed + sla_exceeded (strict) -> warn / exit 7
# ==============================================================================
@test "audit-github-project: --check workflow-item-closed + sla_exceeded で warn (strict / exit 7)" {
    _install_probe_evidence_exceeded
    run "$SUBJECT" --check workflow-item-closed --strict
    [ "$status" -eq 7 ]
    [[ "$output" == *"audit:workflow-item-closed:warn"* ]]
    local summary="$BATS_TEST_TMPDIR/.aidlc/cache/audit/audit-summary.json"
    [ -f "$summary" ]
    local sla
    sla="$(jq -r '.workflow_item_closed.sla' "$summary")"
    [ "$sla" = "sla_exceeded" ]
}

# ==============================================================================
# Case 3: workflow-item-closed + unknown -> warn / exit 0 (Status=Done で warn 降格 / soft)
# ==============================================================================
@test "audit-github-project: --check workflow-item-closed + unknown で warn (soft / exit 0)" {
    _install_probe_evidence_unknown
    run "$SUBJECT" --check workflow-item-closed --soft
    [ "$status" -eq 0 ]
    [[ "$output" == *"audit:workflow-item-closed:warn"* ]]
    local summary="$BATS_TEST_TMPDIR/.aidlc/cache/audit/audit-summary.json"
    local sla
    sla="$(jq -r '.workflow_item_closed.sla' "$summary")"
    [ "$sla" = "unknown" ]
}

# ==============================================================================
# Case 4: probe-evidence 不在 -> evidence_missing / exit 5
# ==============================================================================
@test "audit-github-project: probe-evidence 不在で evidence_missing + exit 5 (strict)" {
    # probe-evidence.json をあえて作らない / soft mode は overall_exit を 0 に丸めるため strict で検証
    run "$SUBJECT" --check workflow-item-closed --strict
    [ "$status" -eq 5 ]
    # stdout は audit:workflow-item-closed:fail:exit=5 行 + summary 行
    [[ "$output" == *"audit:workflow-item-closed:fail:exit=5"* ]]
    # 詳細 (probe_evidence_missing) は audit-summary.json の details に保存される
    local summary="$BATS_TEST_TMPDIR/.aidlc/cache/audit/audit-summary.json"
    [ -f "$summary" ]
    local details
    details="$(jq -r '.workflow_item_closed.details' "$summary")"
    [ "$details" = "probe_evidence_missing" ]
}

# ==============================================================================
# Case 5: --check spec-conformance + drift (strict) -> drift / exit 7
# ==============================================================================
@test "audit-github-project: --check spec-conformance + drift で exit 7 (strict)" {
    # project-field-list を Status を持たない fixture に差し替え (Cycle のみ → Status field_missing drift)
    cat > "${GH_PROJECT_FIXTURE_DIR}/project-field-list.json" <<'JSON'
{"fields":[{"id":"PVTF_CYC","name":"Cycle","type":"ProjectV2SingleSelectField","options":[]}]}
JSON
    run "$SUBJECT" --check spec-conformance --strict
    [ "$status" -eq 7 ]
    [[ "$output" == *"audit:spec-conformance:drift:exit=7"* ]]
    local summary="$BATS_TEST_TMPDIR/.aidlc/cache/audit/audit-summary.json"
    local field_missing
    field_missing="$(jq -r '.spec_conformance.drifts[0].name' "$summary")"
    [ "$field_missing" = "Status" ]
}

# ==============================================================================
# Case 6: --check all 集約 (workflow + spec / strict)
# ==============================================================================
@test "audit-github-project: --check all 集約で 2 系統の結果行 + audit-summary 行を出力 (strict)" {
    _install_probe_evidence_within
    # spec drift も発生させる
    cat > "${GH_PROJECT_FIXTURE_DIR}/project-field-list.json" <<'JSON'
{"fields":[{"id":"PVTF_CYC","name":"Cycle","type":"ProjectV2SingleSelectField","options":[]}]}
JSON
    run "$SUBJECT" --check all --strict
    [ "$status" -eq 7 ]
    # workflow-item-closed は within_sla (closed_at=now で status=Done) だが、
    # project-item-list fixture を上書きしていないので Status=Done が解決される
    [[ "$output" == *"audit:workflow-item-closed:"* ]]
    [[ "$output" == *"audit:spec-conformance:drift:exit=7"* ]]
    [[ "$output" == *"audit-summary:"* ]]
}
