#!/usr/bin/env bats
# Acceptance tests for bin/check-cycle-phase-completion.sh
# Unit 001 / Issue #672 / v2.5.6

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    CLI="${REPO_ROOT}/bin/check-cycle-phase-completion.sh"
    export AIDLC_CYCLES_BASE="${REPO_ROOT}/tests/fixtures/cycle-phase-completion"
}

# (a) all 3 phases complete
@test "completion: 3 Phase 全完了で exit 0" {
    run "${CLI}" completion --pr-number 668
    [ "$status" -eq 0 ]
    [[ "$output" == *"inception:complete"* ]]
    [[ "$output" == *"construction:complete"* ]]
    [[ "$output" == *"operations:complete"* ]]
}

# (b) Inception incomplete
@test "Inception 未完: ステップ未着手で exit 1" {
    run "${CLI}" inception-incomplete --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" == *"inception:incomplete:reason=step_incomplete"* ]]
    [[ "$output" == *"status=未着手"* ]]
}

# (c) Construction incomplete
@test "Construction 未完: Unit 未着手で exit 1" {
    run "${CLI}" construction-incomplete --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" == *"construction:incomplete:reason=unit_status_pending"* ]]
    [[ "$output" == *"status=未着手"* ]]
}

# (d) Operations slot unmet
@test "Operations スロット未充足: release_gate_ready=false で exit 1" {
    run "${CLI}" operations-slot-unmet --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" == *"operations:incomplete:reason=fixed_slot_unmet"* ]]
    [[ "$output" == *"slot=release_gate_ready"* ]]
    [[ "$output" == *"actual=false"* ]]
}

# (e) pr_number mismatch
@test "pr_number 不一致: --pr-number 999 で exit 1" {
    run "${CLI}" operations-pr-mismatch --pr-number 999
    [ "$status" -eq 1 ]
    [[ "$output" == *"operations:incomplete:reason=pr_number_mismatch"* ]]
    [[ "$output" == *"expected=999"* ]]
    [[ "$output" == *"actual=668"* ]]
}

# (f) invalid cycle
@test "invalid cycle: validate_cycle で reject される値で exit 2" {
    run "${CLI}" "UPPER_CASE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"error:invalid-cycle:UPPER_CASE"* ]]
}

# (g) --pr-number 未指定 + pr_number 行欠損
@test "--pr-number 未指定 + pr_number 行欠損: fixed_slot_missing で exit 1" {
    run "${CLI}" operations-pr-missing
    [ "$status" -eq 1 ]
    [[ "$output" == *"operations:incomplete:reason=fixed_slot_missing"* ]]
    [[ "$output" == *"slot=pr_number"* ]]
}

# (h) cycle/ prefix
@test "cycle/ prefix 拒否: cycle/v2.5.6 で exit 2" {
    run "${CLI}" "cycle/v2.5.6"
    [ "$status" -eq 2 ]
    [[ "$output" == *"error:cycle-prefix-not-allowed:cycle/v2.5.6"* ]]
    [[ "$output" == *"strip-cycle-prefix-before-passing"* ]]
}

# (i) Unit 定義 0 件
@test "Unit 定義 0 件: no_units_defined で exit 1" {
    run "${CLI}" construction-no-units --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" == *"construction:incomplete:reason=no_units_defined"* ]]
}

# (j) ステップ7 状態が「PR準備完了」の正常系
@test "step7 PR準備完了: 完了として通り exit 0" {
    run "${CLI}" operations-step7-pr-ready --pr-number 668
    [ "$status" -eq 0 ]
    [[ "$output" == *"operations:complete"* ]]
}

# (k) grammar v1 詳細仕様 fixture（カンマ併記/コメント/重複/未知キー混在）
@test "grammar v1 詳細: カンマ併記 + コメント + 重複(first-win) + 未知キー無視で exit 0" {
    run "${CLI}" operations-grammar-v1-detail --pr-number 668
    [ "$status" -eq 0 ]
    [[ "$output" == *"operations:complete"* ]]
}

# (l) grammar v1 マーカー不在: fixed_slot_missing
@test "grammar v1 マーカー不在: fixed_slot_missing で exit 1（コードレビュー Round 1 中指摘 #2 対応）" {
    run "${CLI}" operations-grammar-marker-missing --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" == *"operations:incomplete:reason=fixed_slot_missing"* ]]
    [[ "$output" == *"slot=release_gate_ready"* ]]
}

# (m) Inception 構造的不正: セクション欠落（codex review Round 1 P1 対応）
@test "Inception 構造的不正: ## ステップ一覧 セクション欠落で structurally_invalid:missing_section" {
    run "${CLI}" inception-malformed-no-section --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" == *"inception:incomplete:reason=structurally_invalid"* ]]
    [[ "$output" == *"detail=missing_section"* ]]
}

# (n) Inception 構造的不正: データ行 0 件（codex review Round 1 P1 対応）
@test "Inception 構造的不正: セクション内データ行 0 件で structurally_invalid:no_data_rows" {
    run "${CLI}" inception-malformed-no-rows --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" == *"inception:incomplete:reason=structurally_invalid"* ]]
    [[ "$output" == *"detail=no_data_rows"* ]]
}

# fail-fast 否定アサーション（コードレビュー Round 1 低指摘 #3 対応）
@test "fail-fast: Inception 未完時に Construction/Operations の complete メッセージが混入しない" {
    run "${CLI}" inception-incomplete --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" != *"construction:complete"* ]]
    [[ "$output" != *"operations:complete"* ]]
}

@test "fail-fast: Construction 未完時に Operations の complete メッセージが混入しない" {
    run "${CLI}" construction-incomplete --pr-number 668
    [ "$status" -eq 1 ]
    [[ "$output" != *"operations:complete"* ]]
}

# --- v3-flat structure (Issue #747 / v3.0.0-beta.2 Work Item 002) ---
# v3 tests always set AIDLC_STATE_FILE explicitly so the repository's real
# .aidlc/state.json is never read (test isolation).

# (q) v3 complete
@test "v3-flat complete: 全 work item done/withdrawn + release 記録で exit 0" {
    export AIDLC_STATE_FILE="${AIDLC_CYCLES_BASE}/v3-complete/state.json"
    run "${CLI}" v3-complete --pr-number 755
    [ "$status" -eq 0 ]
    [[ "$output" == *"v3:complete"* ]]
}

# (r) v3 incomplete: work item in_progress
@test "v3-flat 未完: in_progress の work item で exit 1 + 理由出力" {
    export AIDLC_STATE_FILE="${AIDLC_CYCLES_BASE}/v3-item-pending/state.json"
    run "${CLI}" v3-item-pending
    [ "$status" -eq 1 ]
    [[ "$output" == *"v3:incomplete:reason=item_status_pending:item=002-bar:status=in_progress"* ]]
}

# (s) v3 incomplete: release.md missing
@test "v3-flat release.md 欠落: release_md_missing で exit 1" {
    export AIDLC_STATE_FILE="${AIDLC_CYCLES_BASE}/v3-release-md-missing/state.json"
    run "${CLI}" v3-release-md-missing
    [ "$status" -eq 1 ]
    [[ "$output" == *"v3:incomplete:reason=release_md_missing"* ]]
}

# (t) v3 incomplete: pr_number not recorded (null)
@test "v3-flat pr_number 未記録: null で exit 1" {
    export AIDLC_STATE_FILE="${AIDLC_CYCLES_BASE}/v3-pr-not-recorded/state.json"
    run "${CLI}" v3-pr-not-recorded
    [ "$status" -eq 1 ]
    [[ "$output" == *"v3:incomplete:reason=pr_number_not_recorded:actual=null"* ]]
}

# (u) v3 incomplete: --pr-number mismatch
@test "v3-flat pr_number 不一致: --pr-number 999 で exit 1" {
    export AIDLC_STATE_FILE="${AIDLC_CYCLES_BASE}/v3-complete/state.json"
    run "${CLI}" v3-complete --pr-number 999
    [ "$status" -eq 1 ]
    [[ "$output" == *"v3:incomplete:reason=pr_number_mismatch:expected=999:actual=755"* ]]
}

# (v) v3 incomplete: current_cycle mismatch
@test "v3-flat current_cycle 不一致: state.json が別サイクルを指す場合 exit 1" {
    export AIDLC_STATE_FILE="${AIDLC_CYCLES_BASE}/v3-cycle-mismatch/state.json"
    run "${CLI}" v3-cycle-mismatch
    [ "$status" -eq 1 ]
    [[ "$output" == *"v3:incomplete:reason=current_cycle_mismatch:expected=v3-cycle-mismatch:actual=v3-other"* ]]
}

# (w) v3 incomplete: state.json missing
@test "v3-flat state.json 不在: state_json_missing で exit 1" {
    export AIDLC_STATE_FILE="${AIDLC_CYCLES_BASE}/v3-complete/does-not-exist.json"
    run "${CLI}" v3-complete
    [ "$status" -eq 1 ]
    [[ "$output" == *"v3:incomplete:reason=state_json_missing"* ]]
}

# (x) ambiguous structure: both v3 (work-items/) and v2 (inception/) signals
@test "曖昧構造: work-items/ と inception/ 両在で exit 2" {
    export AIDLC_STATE_FILE="${AIDLC_CYCLES_BASE}/v3-complete/state.json"
    run "${CLI}" v3-ambiguous
    [ "$status" -eq 2 ]
    [[ "$output" == *"error:ambiguous-cycle-structure"* ]]
}
