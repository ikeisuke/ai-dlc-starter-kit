#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 003 (#677 / v2.6.2): A+B 連鎖の integration テスト
# §7.7 commit → §7.12 write-history (auto-commit) → §7.12.5 squash-712 → git log 1 commit + history 差分含有
#
# 設計 SoT: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_003_fix_squash712_history_integration_logical_design.md
#
# 検証ケース:
#   (a) normal 経路（A+B）: write-history auto-commit → squash-712 通常経路 → 1 squash commit + history 差分
#   (b) opt-out 経路: write-history --no-commit → squash-712 fail-fast（dirty_history）

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    WRITE_HISTORY="${REPO_ROOT}/skills/aidlc/scripts/write-history.sh"
    OP_RELEASE="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"
    TMP="$(mktemp -d -t aidlc-squash712-integ.XXXXXX)"
    cd "$TMP"
    CYCLE="v2.6.2"

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

    # §7.7 commit 相当: 初期 progress.md（release_prep_commit slot 込み）
    printf '# operations progress\n\n<!-- release_prep_commit: PLACEHOLDER -->\n' \
        > ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git add ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git commit -q -m "chore: [${CYCLE}] §7.7 release prep"

    # release_prep_commit SHA を取得し progress.md を差し替え（実 SHA に置換）
    RELEASE_PREP_SHA="$(git rev-parse HEAD)"
    sed -i.bak "s|PLACEHOLDER|${RELEASE_PREP_SHA}|" ".aidlc/cycles/${CYCLE}/operations/progress.md"
    rm -f ".aidlc/cycles/${CYCLE}/operations/progress.md.bak"
    git add ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git commit -q --amend --no-edit
    RELEASE_PREP_SHA="$(git rev-parse HEAD)"
    # progress.md を SHA で再書き込み（amend 後の SHA が新規 SHA）
    printf '# operations progress\n\n<!-- release_prep_commit: %s -->\n' "$RELEASE_PREP_SHA" \
        > ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git add ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git commit -q -m "chore: [${CYCLE}] anchor release_prep_commit"

    # この時点の HEAD を release_prep_commit anchor とする
    RELEASE_PREP_SHA="$(git rev-parse HEAD)"
    # progress.md を最終 SHA で更新（自己参照になるが integration テスト用途では本 commit を anchor 扱い）
    printf '# operations progress\n\n<!-- release_prep_commit: %s -->\n' "$RELEASE_PREP_SHA" \
        > ".aidlc/cycles/${CYCLE}/operations/progress.md"

    # 修正コミット 1 件追加（§7.12 レビュー反映 commit 相当）
    printf 'review-fix content\n' > "review-fix.txt"
    git add "review-fix.txt" ".aidlc/cycles/${CYCLE}/operations/progress.md"
    git commit -q -m "fix: [${CYCLE}] review round 1 fix"

    export AIDLC_PROJECT_ROOT="$TMP"
}

teardown() {
    cd "$BATS_TMPDIR"
    rm -rf "$TMP"
}

_call_write_history_op_round() {
    bash "$WRITE_HISTORY" \
        --cycle "$CYCLE" \
        --phase operations \
        --step "§7.12 round 1" \
        --content "AI レビュー round 1 完了" \
        --mode operations-round \
        --round 1 \
        --findings 0 \
        --critical 0 --high 0 --medium 0 --low 0 \
        --resolved-count 0 --deferred-count 0 \
        "$@"
}

# ─── (a) normal 経路 ─────────

@test "integration: A+B normal 経路 → 1 squash commit + history/operations.md 差分含有" {
    # §7.12: write-history auto-commit
    run _call_write_history_op_round
    [ "$status" -eq 0 ]
    [[ "$output" == *"history-commit:"* ]]
    [[ "$output" == *":operations-round-round-1"* ]]

    # working tree clean
    run git status --porcelain
    [ -z "$output" ]

    # §7.12.5: squash-712 通常経路
    run bash "$OP_RELEASE" squash-712 --cycle "$CYCLE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"squash:success:"* ]]

    # 観測点 1: git log <RELEASE_PREP_SHA>..HEAD --oneline 行数 = 1
    run git log "${RELEASE_PREP_SHA}..HEAD" --oneline
    local line_count
    line_count=$(printf '%s\n' "$output" | grep -c '.' || true)
    [ "$line_count" -eq 1 ]

    # 観測点 2: HEAD commit に history/operations.md 差分が含まれる
    run git show --stat HEAD
    [[ "$output" == *".aidlc/cycles/${CYCLE}/history/operations.md"* ]]
}

# ─── (b) opt-out 経路 ─────────

@test "integration: --no-commit opt-out 経路 → squash-712 が dirty_history で fail-fast" {
    # §7.12: write-history --no-commit（append のみ、auto-commit skip）
    run _call_write_history_op_round --no-commit
    [ "$status" -eq 0 ]
    [[ "$output" != *"history-commit:"*"operations-round-round-1"* ]]

    # unstaged 差分が残っているはず
    run git status --porcelain -- ".aidlc/cycles/${CYCLE}/history/operations.md"
    [ -n "$output" ]

    # §7.12.5: squash-712 → fail-fast
    run bash "$OP_RELEASE" squash-712 --cycle "$CYCLE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"squash:failed:reason=dirty_history"* ]]
    [[ "$output" == *"squash-712:uncommitted-history"* ]]
}
