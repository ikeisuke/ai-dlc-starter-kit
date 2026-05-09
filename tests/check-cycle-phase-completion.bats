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
