#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 003 (#677 / v2.6.2): operations-release.sh squash-712 の history dirty 検出 fail-fast テスト
#
# 設計 SoT: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_003_fix_squash712_history_integration_logical_design.md
#
# 検証ケース:
#   (a) clean → 既存 Step 2 以降へ進む（本テストでは release_prep_commit slot 不在で skip 経路へ）
#   (b) dirty（unstaged）→ exit 1 + squash:failed:reason=dirty_history
#   (c) dirty（staged）→ exit 1 + squash:failed:reason=dirty_history
#   (d) --dry-run + dirty → exit 1 + squash:failed:reason=dirty_history（Round 1 LOW #1 対応 / dry-run でも fail-fast）

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    OP_RELEASE="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"
    TMP="$(mktemp -d -t aidlc-squash712-dirty.XXXXXX)"
    cd "$TMP"
    CYCLE="v2.6.2"

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

# ─── (a) clean ─────────

@test "squash-712: history clean → Step 1 後の Step 2 経路（release_prep_commit_missing で skip）に進む" {
    # release_prep_commit slot が無い progress.md
    printf '# progress\n' > ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git add ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git commit -q -m "progress"

    run bash "$OP_RELEASE" squash-712 --cycle "$CYCLE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"squash:skipped"* ]]
    # dirty 検出は発火しない
    [[ "$output" != *"squash:failed:reason=dirty_history"* ]]
    [[ "$output" != *"squash-712:uncommitted-history"* ]]
}

# ─── (b) dirty（unstaged）─────────

@test "squash-712: history unstaged dirty → exit 1 + squash:failed:reason=dirty_history" {
    printf '# history\n\n' > ".aidlc/cycles/${CYCLE}/history/operations.md"
    git add ".aidlc/cycles/${CYCLE}/history/operations.md"
    git commit -q -m "initial history"
    # 追加変更を unstaged で残す
    printf 'additional unstaged content\n' >> ".aidlc/cycles/${CYCLE}/history/operations.md"

    run bash "$OP_RELEASE" squash-712 --cycle "$CYCLE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash:failed:reason=dirty_history"* ]]
    [[ "$output" == *"squash-712:uncommitted-history"* ]]
    [[ "$output" == *".aidlc/cycles/${CYCLE}/history/operations.md"* ]]
    [[ "$output" == *"recommended_command:git add"* ]]
}

# ─── (c) dirty（staged）─────────

@test "squash-712: history staged dirty → exit 1 + squash:failed:reason=dirty_history" {
    printf '# history\n\n' > ".aidlc/cycles/${CYCLE}/history/operations.md"
    git add ".aidlc/cycles/${CYCLE}/history/operations.md"
    git commit -q -m "initial history"
    # 追加変更を staged 状態で残す
    printf 'additional staged content\n' >> ".aidlc/cycles/${CYCLE}/history/operations.md"
    git add ".aidlc/cycles/${CYCLE}/history/operations.md"

    run bash "$OP_RELEASE" squash-712 --cycle "$CYCLE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash:failed:reason=dirty_history"* ]]
    [[ "$output" == *"squash-712:uncommitted-history"* ]]
}

# ─── (d) --dry-run + dirty ─────────

@test "squash-712: --dry-run + dirty → exit 1 + squash:failed:reason=dirty_history（実行前検証）" {
    printf '# history\n\n' > ".aidlc/cycles/${CYCLE}/history/operations.md"
    git add ".aidlc/cycles/${CYCLE}/history/operations.md"
    git commit -q -m "initial history"
    printf 'additional dirty content\n' >> ".aidlc/cycles/${CYCLE}/history/operations.md"

    run bash "$OP_RELEASE" squash-712 --cycle "$CYCLE" --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash:failed:reason=dirty_history"* ]]
    # dry-run 通常経路には進まない
    [[ "$output" != *"squash:dry-run:target_count="* ]]
}

# ─── (e) --dry-run + clean ─────────

@test "squash-712: --dry-run + clean → dirty 検出スルー、既存 dry-run 経路継続" {
    printf '# progress\n' > ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git add ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git commit -q -m "progress"

    run bash "$OP_RELEASE" squash-712 --cycle "$CYCLE" --dry-run
    [ "$status" -eq 0 ]
    # release_prep_commit slot 不在で skip 経路（dirty 検出は発火しない）
    [[ "$output" == *"squash:skipped"* ]]
    [[ "$output" != *"squash:failed:reason=dirty_history"* ]]
}

# ─── (f) Round 1 MEDIUM #1 部分対応: 新規ガード経路のパストラバーサル拒否 ─────────

@test "squash-712: --cycle にパストラバーサル → exit 1 + squash-712:invalid-cycle" {
    run bash "$OP_RELEASE" squash-712 --cycle "../etc"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash-712:invalid-cycle"* ]]
}

@test "squash-712: --cycle に絶対パス → exit 1 + squash-712:invalid-cycle" {
    run bash "$OP_RELEASE" squash-712 --cycle "/tmp/evil"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash-712:invalid-cycle"* ]]
}
