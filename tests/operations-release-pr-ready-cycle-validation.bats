#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 002 (#708 / v2.6.4): operations-release.sh cmd_pr_ready への --cycle バリデーション導入テスト
#
# 設計 SoT: .aidlc/cycles/v2.6.4/design-artifacts/logical-designs/unit_002_operations_release_validate_cycle_extend_logical_design.md
#
# 検証ケース:
#   1. 正常 cycle                       → validate_cycle 通過、dry-run で stop しない
#   2. パストラバーサル(..)             → exit 1 + error<TAB>pr-ready:invalid-cycle<TAB><value>
#   3. 先頭スラッシュ                   → exit 1 + invalid-cycle
#   4. 空白を含む                       → exit 1 + invalid-cycle
#   5. 制御文字(tab)を含む              → exit 1 + invalid-cycle
#   6. 形式不一致(大文字)               → exit 1 + invalid-cycle
#   7. --cycle 未指定 + cycle/v2.6.4 ブランチ → validate_cycle 通過（解決結果が v2.6.4）
#   8. --cycle 未指定 + feature/x ブランチ    → exit 1 + invalid-cycle（解決結果が空文字 → 拒否）
#   9. --cycle 空値                     → exit 1 + missing-value:--cycle（既存経路、invalid-cycle ではない）
#
# 統合観点: cmd_pr_ready 入口で validate_cycle が呼ばれ、cycle が下流の
# pr-ops.sh get-related-issues に渡る前に fail-fast することを検証する。
# --dry-run + --pr <number> 指定で gh / pr-ops.sh 等の副作用を回避する。

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    OP_RELEASE="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"
    TMP="$(mktemp -d -t aidlc-pr-ready-cycle-validation.XXXXXX)"
    cd "$TMP"
    CYCLE="v2.6.4"

    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    # デフォルトブランチを cycle/v2.6.4 にして、未指定ケースで resolve_cycle_from_branch が
    # v2.6.4 を返すようにする（テスト #7 で使用）。
    git checkout -q -b "cycle/${CYCLE}" 2>/dev/null || git checkout -q "cycle/${CYCLE}"

    mkdir -p ".aidlc/cycles/${CYCLE}/story-artifacts/units"
    cat > ".aidlc/config.toml" <<EOF
[project]
name = "test-project"
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

@test "pr-ready: 正常 cycle --dry-run → validate_cycle 通過、dry-run で副作用なく終了" {
    run bash "$OP_RELEASE" pr-ready --cycle "$CYCLE" --pr 999 --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"invalid-cycle"* ]]
}

# ─── 2. パストラバーサル（.. を含む）─────────

@test "pr-ready: --cycle にパストラバーサル(..) → exit 1 + pr-ready:invalid-cycle" {
    run bash "$OP_RELEASE" pr-ready --cycle "../etc" --pr 999 --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"pr-ready:invalid-cycle"* ]]
    [[ "$output" == *"../etc"* ]]
}

# ─── 3. 先頭スラッシュ（絶対パス）─────────

@test "pr-ready: --cycle に先頭スラッシュ → exit 1 + pr-ready:invalid-cycle" {
    run bash "$OP_RELEASE" pr-ready --cycle "/abs/path" --pr 999 --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"pr-ready:invalid-cycle"* ]]
    [[ "$output" == *"/abs/path"* ]]
}

# ─── 4. 空白を含む ─────────

@test "pr-ready: --cycle に空白を含む → exit 1 + pr-ready:invalid-cycle" {
    run bash "$OP_RELEASE" pr-ready --cycle "v2.6 4" --pr 999 --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"pr-ready:invalid-cycle"* ]]
}

# ─── 5. 制御文字（tab）を含む ─────────

@test "pr-ready: --cycle に制御文字(tab)を含む → exit 1 + pr-ready:invalid-cycle" {
    run bash "$OP_RELEASE" pr-ready --cycle $'v2.6\t4' --pr 999 --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"pr-ready:invalid-cycle"* ]]
}

# ─── 6. 形式不一致（大文字）─────────

@test "pr-ready: --cycle が形式不一致(大文字) → exit 1 + pr-ready:invalid-cycle" {
    run bash "$OP_RELEASE" pr-ready --cycle "V2.6.4" --pr 999 --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"pr-ready:invalid-cycle"* ]]
    [[ "$output" == *"V2.6.4"* ]]
}

# ─── 7. --cycle 未指定 + cycle/v2.6.4 ブランチ（resolve_cycle_from_branch 経由で通過）─────────

@test "pr-ready: --cycle 未指定 + cycle/v2.6.4 ブランチ → resolve_cycle_from_branch で v2.6.4 解決 → validate_cycle 通過" {
    # setup で既に cycle/v2.6.4 ブランチに切り替え済み
    run bash "$OP_RELEASE" pr-ready --pr 999 --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"invalid-cycle"* ]]
}

# ─── 8. --cycle 未指定 + feature/x ブランチ（解決結果が空文字 → invalid-cycle）─────────

@test "pr-ready: --cycle 未指定 + feature/x ブランチ → 解決結果が空文字 → pr-ready:invalid-cycle" {
    git checkout -q -b "feature/x"
    run bash "$OP_RELEASE" pr-ready --pr 999 --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"pr-ready:invalid-cycle"* ]]
}

# ─── 9. --cycle 空値（既存経路、invalid-cycle ではない）─────────

@test "pr-ready: --cycle '' → exit 1 + missing-value:--cycle（既存経路、invalid-cycle ではない）" {
    run bash "$OP_RELEASE" pr-ready --cycle "" --pr 999 --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"pr-ready:error:missing-value:--cycle"* ]]
    [[ "$output" != *"invalid-cycle"* ]]
}
