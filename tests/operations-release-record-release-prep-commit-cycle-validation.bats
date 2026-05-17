#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 002 (#708 / v2.6.4): operations-release.sh cmd_record_release_prep_commit への --cycle バリデーション導入テスト
#
# 設計 SoT: .aidlc/cycles/v2.6.4/design-artifacts/logical-designs/unit_002_operations_release_validate_cycle_extend_logical_design.md
#
# 検証ケース:
#   1. 正常 cycle           → 検証通過後、release_prep_commit:recorded:<sha> 経路に進む（回帰なし）
#   2. パストラバーサル(..) → exit 1 + error<TAB>record-release-prep-commit:invalid-cycle<TAB><value>
#   3. 先頭スラッシュ       → exit 1 + invalid-cycle
#   4. 空白を含む           → exit 1 + invalid-cycle
#   5. 制御文字(tab)を含む  → exit 1 + invalid-cycle
#   6. 形式不一致(大文字)   → exit 1 + invalid-cycle
#   7. --cycle 未指定       → exit 1 + cycle-required（既存経路、invalid-cycle ではない）
#   8. --cycle 空値         → exit 1 + missing-value:--cycle（既存経路、invalid-cycle ではない）
#
# 統合観点: cmd_record_release_prep_commit 入口で validate_cycle が呼ばれ、
# 正しいエラーフォーマットで停止することを検証する。validate_cycle 単体の網羅テストは
# skills/aidlc/scripts/tests/test_validate_cycle.sh に存在する。

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    OP_RELEASE="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"
    TMP="$(mktemp -d -t aidlc-rrpc-cycle-validation.XXXXXX)"
    cd "$TMP"
    CYCLE="v2.6.4"

    # git リポジトリ初期化（cmd_record_release_prep_commit 内で git rev-parse HEAD を使用）
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    git checkout -q -b main 2>/dev/null || true

    mkdir -p ".aidlc/cycles/${CYCLE}/operations"
    cat > ".aidlc/config.toml" <<EOF
[project]
name = "test-project"

[rules.git]
squash_enabled = true
EOF
    # 正常 cycle ケースで使用する progress.md フィクスチャ（release_prep_commit slot なし）
    printf '# progress\n' > ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git add .aidlc/config.toml ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git commit -q -m "init"

    export AIDLC_PROJECT_ROOT="$TMP"
}

teardown() {
    cd "$BATS_TMPDIR"
    rm -rf "$TMP"
}

# ─── 1. 正常 cycle（回帰なし）─────────

@test "record-release-prep-commit: 正常 cycle → validate_cycle 通過後、release_prep_commit:recorded:<sha> 経路に進む（回帰なし）" {
    run bash "$OP_RELEASE" record-release-prep-commit --cycle "$CYCLE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"release_prep_commit:"* ]]
    # invalid-cycle 検証で停止していない
    [[ "$output" != *"invalid-cycle"* ]]
}

# ─── 2. パストラバーサル（.. を含む）─────────

@test "record-release-prep-commit: --cycle にパストラバーサル(..) → exit 1 + record-release-prep-commit:invalid-cycle" {
    run bash "$OP_RELEASE" record-release-prep-commit --cycle "../etc"
    [ "$status" -eq 1 ]
    [[ "$output" == *"record-release-prep-commit:invalid-cycle"* ]]
    [[ "$output" == *"../etc"* ]]
}

# ─── 3. 先頭スラッシュ（絶対パス）─────────

@test "record-release-prep-commit: --cycle に先頭スラッシュ → exit 1 + record-release-prep-commit:invalid-cycle" {
    run bash "$OP_RELEASE" record-release-prep-commit --cycle "/abs/path"
    [ "$status" -eq 1 ]
    [[ "$output" == *"record-release-prep-commit:invalid-cycle"* ]]
    [[ "$output" == *"/abs/path"* ]]
}

# ─── 4. 空白を含む ─────────

@test "record-release-prep-commit: --cycle に空白を含む → exit 1 + record-release-prep-commit:invalid-cycle" {
    run bash "$OP_RELEASE" record-release-prep-commit --cycle "v2.6 4"
    [ "$status" -eq 1 ]
    [[ "$output" == *"record-release-prep-commit:invalid-cycle"* ]]
}

# ─── 5. 制御文字（tab）を含む ─────────

@test "record-release-prep-commit: --cycle に制御文字(tab)を含む → exit 1 + record-release-prep-commit:invalid-cycle" {
    run bash "$OP_RELEASE" record-release-prep-commit --cycle $'v2.6\t4'
    [ "$status" -eq 1 ]
    [[ "$output" == *"record-release-prep-commit:invalid-cycle"* ]]
}

# ─── 6. 形式不一致（大文字）─────────

@test "record-release-prep-commit: --cycle が形式不一致(大文字) → exit 1 + record-release-prep-commit:invalid-cycle" {
    run bash "$OP_RELEASE" record-release-prep-commit --cycle "V2.6.4"
    [ "$status" -eq 1 ]
    [[ "$output" == *"record-release-prep-commit:invalid-cycle"* ]]
    [[ "$output" == *"V2.6.4"* ]]
}

# ─── 7. --cycle 未指定（既存経路、invalid-cycle ではない）─────────

@test "record-release-prep-commit: --cycle 未指定 → exit 1 + cycle-required（既存経路、invalid-cycle ではない）" {
    run bash "$OP_RELEASE" record-release-prep-commit
    [ "$status" -eq 1 ]
    [[ "$output" == *"record-release-prep-commit:error:cycle-required"* ]]
    [[ "$output" != *"invalid-cycle"* ]]
}

# ─── 8. --cycle 空値（既存経路、invalid-cycle ではない）─────────

@test "record-release-prep-commit: --cycle '' → exit 1 + missing-value:--cycle（既存経路、invalid-cycle ではない）" {
    run bash "$OP_RELEASE" record-release-prep-commit --cycle ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"record-release-prep-commit:error:missing-value:--cycle"* ]]
    [[ "$output" != *"invalid-cycle"* ]]
}
