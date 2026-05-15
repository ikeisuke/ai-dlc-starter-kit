#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 002 (#701 / v2.6.3): operations-release.sh cmd_squash_712 への --cycle バリデーション導入テスト
#
# 設計 SoT: .aidlc/cycles/v2.6.3/design-artifacts/logical-designs/unit_002_operations_release_cycle_validation_logical_design.md
#
# 検証ケース:
#   1. 正常 cycle          → 検証通過後、既存挙動（release_prep_commit slot 不在で squash:skipped）に進む（回帰なし）
#   2. パストラバーサル(..)→ exit 1 + error<TAB>squash-712:invalid-cycle<TAB><value>
#   3. 先頭スラッシュ      → exit 1 + invalid-cycle
#   4. 空白を含む          → exit 1 + invalid-cycle
#   5. 制御文字(tab)を含む → exit 1 + invalid-cycle
#   6. 形式不一致(大文字)  → exit 1 + invalid-cycle
#
# ケース 2〜5 は計画 Phase 1 で列挙された不正パターン（.. / 先頭スラッシュ / 空白 / 制御文字）を網羅。
# validate_cycle 単体の網羅テストは skills/aidlc/scripts/tests/test_validate_cycle.sh に存在するため、
# 本テストは「cmd_squash_712 入口で検証が呼ばれ exit 1 + 正しいエラーフォーマットで停止する」統合観点に絞る。

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    OP_RELEASE="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"
    TMP="$(mktemp -d -t aidlc-squash712-cycle-validation.XXXXXX)"
    cd "$TMP"
    CYCLE="v2.6.3"

    # git リポジトリ初期化
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    git checkout -q -b main 2>/dev/null || true

    mkdir -p ".aidlc/cycles/${CYCLE}/history"
    mkdir -p ".aidlc/cycles/${CYCLE}/operations"
    cat > ".aidlc/config.toml" <<EOF
[project]
name = "test-project"

[rules.git]
squash_enabled = true
EOF
    git add .aidlc/config.toml
    git commit -q -m "init"

    export AIDLC_PROJECT_ROOT="$TMP"
}

teardown() {
    cd "$BATS_TMPDIR"
    rm -rf "$TMP"
}

# ─── 1. 正常 cycle（回帰なし）─────────

@test "squash-712: 正常 cycle → validate_cycle 通過後、既存の squash:skipped 経路に進む（回帰なし）" {
    # release_prep_commit slot が無い progress.md（既存 dirty-history bats と同じフィクスチャ構成）
    printf '# progress\n' > ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git add ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git commit -q -m "progress"

    run bash "$OP_RELEASE" squash-712 --cycle "$CYCLE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"squash:skipped"* ]]
    # invalid-cycle 検証で停止していない
    [[ "$output" != *"invalid-cycle"* ]]
}

# ─── 2. パストラバーサル（.. を含む）─────────

@test "squash-712: --cycle にパストラバーサル(..) → exit 1 + squash-712:invalid-cycle" {
    run bash "$OP_RELEASE" squash-712 --cycle "../etc"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash-712:invalid-cycle"* ]]
    [[ "$output" == *"../etc"* ]]
}

# ─── 3. 先頭スラッシュ（絶対パス）─────────

@test "squash-712: --cycle に先頭スラッシュ → exit 1 + squash-712:invalid-cycle" {
    run bash "$OP_RELEASE" squash-712 --cycle "/abs/path"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash-712:invalid-cycle"* ]]
    [[ "$output" == *"/abs/path"* ]]
}

# ─── 4. 空白を含む ─────────

@test "squash-712: --cycle に空白を含む → exit 1 + squash-712:invalid-cycle" {
    run bash "$OP_RELEASE" squash-712 --cycle "v2.6 3"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash-712:invalid-cycle"* ]]
}

# ─── 5. 制御文字（tab）を含む ─────────

@test "squash-712: --cycle に制御文字(tab)を含む → exit 1 + squash-712:invalid-cycle" {
    run bash "$OP_RELEASE" squash-712 --cycle $'v2.6\t3'
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash-712:invalid-cycle"* ]]
}

# ─── 6. 形式不一致（大文字）─────────

@test "squash-712: --cycle が形式不一致(大文字) → exit 1 + squash-712:invalid-cycle" {
    run bash "$OP_RELEASE" squash-712 --cycle "V2.6.3"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash-712:invalid-cycle"* ]]
    [[ "$output" == *"V2.6.3"* ]]
}
