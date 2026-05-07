#!/usr/bin/env bats
# Unit 002 (#637): write-history.sh の --mode 関連テスト

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  WRITE_HISTORY="${REPO_ROOT}/skills/aidlc/scripts/write-history.sh"
  TMP="$(mktemp -d -t aidlc-write-history-modes.XXXXXX)"
  cd "$TMP"
  # 必須ディレクトリ作成（write-history.sh が cycles 配下に書き出すため）
  CYCLE="v2.5.3"
  mkdir -p ".aidlc/cycles/${CYCLE}/history"
  # AIDLC_PROJECT_ROOT を tmp に向けることで bootstrap が tmp 配下を root として認識
  export AIDLC_PROJECT_ROOT="$TMP"
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP"
}

# ─── 共通呼び出しヘルパ ─────────

_call_construction() {
  # $1: mode (base|unit-complete-short-note|operations-round) または "" (default base)
  # 残り: 追加引数
  local mode="$1"; shift
  local mode_args=()
  if [[ -n "$mode" ]]; then
    mode_args=(--mode "$mode")
  fi
  bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase construction \
    --unit 99 \
    --unit-name "Test Unit" \
    --unit-slug test-unit \
    --step "テストステップ" \
    --content "テスト実行内容" \
    "${mode_args[@]}" \
    "$@"
}

# ─── 既存互換テスト ─────────

@test "base 互換: --mode 未指定で従来動作 (created)" {
  run _call_construction ""
  [ "$status" -eq 0 ]
  [[ "$output" == *":created"* ]]
  [ -f ".aidlc/cycles/${CYCLE}/history/construction_unit99.md" ]
}

@test "base 互換: --mode base 明示指定で従来動作と同等" {
  run _call_construction "base"
  [ "$status" -eq 0 ]
  [[ "$output" == *":created"* ]]
  [ -f ".aidlc/cycles/${CYCLE}/history/construction_unit99.md" ]
  # base モードでは追加セクションが含まれない
  ! grep -q '## 補足（short note）' ".aidlc/cycles/${CYCLE}/history/construction_unit99.md"
  ! grep -q '## Round' ".aidlc/cycles/${CYCLE}/history/construction_unit99.md"
}

# ─── unit-complete-short-note ─────────

@test "unit-complete-short-note: 正常系 → ## 補足（short note）セクション追加" {
  run _call_construction "unit-complete-short-note" --short-note "本 Unit 振り返り 3 行"
  [ "$status" -eq 0 ]
  [[ "$output" == *":created"* ]]
  grep -q '## 補足（short note）' ".aidlc/cycles/${CYCLE}/history/construction_unit99.md"
  grep -q '本 Unit 振り返り 3 行' ".aidlc/cycles/${CYCLE}/history/construction_unit99.md"
}

@test "unit-complete-short-note: --short-note 欠落で exit 1 / missing-short-note" {
  run _call_construction "unit-complete-short-note"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-short-note"* ]]
}

# ─── operations-round ─────────

@test "operations-round: 正常系 → ## Round 1: <timestamp> 見出し + テーブル追加" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "Round 1 集計" \
    --content "round 1 結果" \
    --operations-stage pre-merge \
    --mode operations-round \
    --round 1 \
    --findings 5 \
    --critical 0 \
    --high 1 \
    --medium 3 \
    --low 1 \
    --resolved-count 4 \
    --deferred-count 1
  [ "$status" -eq 0 ]
  [[ "$output" == *":created"* ]]
  grep -qE '## Round 1: ' ".aidlc/cycles/${CYCLE}/history/operations.md"
  grep -q '指摘総数 | 5' ".aidlc/cycles/${CYCLE}/history/operations.md"
  grep -q '重要度: critical | 0' ".aidlc/cycles/${CYCLE}/history/operations.md"
  grep -q '修正対応 | 4' ".aidlc/cycles/${CYCLE}/history/operations.md"
  grep -q 'defer 化 | 1' ".aidlc/cycles/${CYCLE}/history/operations.md"
}

@test "operations-round: --round 欠落で exit 1 / missing-round-args" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "Round X" \
    --content "test" \
    --operations-stage pre-merge \
    --mode operations-round \
    --findings 5 --critical 0 --high 1 --medium 3 --low 1 --resolved-count 4 --deferred-count 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-round-args"* ]]
}

@test "operations-round: round が非数値で exit 1 / invalid-numeric-arg" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "Round X" \
    --content "test" \
    --operations-stage pre-merge \
    --mode operations-round \
    --round abc \
    --findings 5 --critical 0 --high 1 --medium 3 --low 1 --resolved-count 4 --deferred-count 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-numeric-arg"* ]]
}

@test "operations-round: findings が負数で exit 1 / invalid-numeric-arg" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "Round X" \
    --content "test" \
    --operations-stage pre-merge \
    --mode operations-round \
    --round 1 \
    --findings -1 --critical 0 --high 1 --medium 3 --low 1 --resolved-count 4 --deferred-count 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-numeric-arg"* ]]
}

# ─── invalid-mode ─────────

@test "invalid-mode: 未知のモード値で exit 1 / invalid-mode" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase construction \
    --unit 99 --unit-name X --unit-slug x \
    --step "test" --content "test" \
    --mode unknown-mode
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-mode"* ]]
}

# ─── post-merge ガード（新モードでも有効） ─────────

@test "post-merge ガード: --mode operations-round + --operations-stage post-merge で exit 3" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "Round 1" \
    --content "test" \
    --operations-stage post-merge \
    --mode operations-round \
    --round 1 --findings 5 --critical 0 --high 1 --medium 3 --low 1 --resolved-count 4 --deferred-count 1
  [ "$status" -eq 3 ]
}

@test "post-merge ガード優先順位: unit-complete-short-note × operations は mode-phase 違反で exit 1 が先に確定" {
  # 実装上 mode×phase 検証が post-merge ガードより前に走るため、本ケースは exit 1 / invalid-mode-phase-combination で確定
  # （Round 2 指摘 #2 反映 / 期待値固定）
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "Test" \
    --content "test" \
    --operations-stage post-merge \
    --mode unit-complete-short-note \
    --short-note "post-merge guard test"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-mode-phase-combination"* ]]
}

# ─── mode × phase 組み合わせ制約（コードレビュー Round 1 指摘 #1 反映） ─────────

@test "mode-phase: --mode operations-round + --phase construction で exit 1 / invalid-mode-phase-combination" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase construction \
    --unit 99 --unit-name X --unit-slug x \
    --step "test" --content "test" \
    --mode operations-round \
    --round 1 --findings 5 --critical 0 --high 1 --medium 3 --low 1 --resolved-count 4 --deferred-count 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-mode-phase-combination"* ]]
}

@test "mode-phase: --mode unit-complete-short-note + --phase operations で exit 1 / invalid-mode-phase-combination" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "test" --content "test" \
    --operations-stage pre-merge \
    --mode unit-complete-short-note \
    --short-note "test note"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-mode-phase-combination"* ]]
}

# ─── round 値域（1-5 の整数のみ） ─────────

@test "round 値域: --round 0 で exit 1 / invalid-numeric-arg" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "Round 0" --content "test" \
    --operations-stage pre-merge \
    --mode operations-round \
    --round 0 --findings 5 --critical 0 --high 1 --medium 3 --low 1 --resolved-count 4 --deferred-count 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-numeric-arg"* ]]
}

@test "round 値域: --round 6 で exit 1 / invalid-numeric-arg" {
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "Round 6" --content "test" \
    --operations-stage pre-merge \
    --mode operations-round \
    --round 6 --findings 5 --critical 0 --high 1 --medium 3 --low 1 --resolved-count 4 --deferred-count 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-numeric-arg"* ]]
}
