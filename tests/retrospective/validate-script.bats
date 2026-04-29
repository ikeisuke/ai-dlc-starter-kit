#!/usr/bin/env bats
# Unit 004: 観点 EX/VA/AP/RB - retrospective-validate.sh（3 段責務）

load helpers/setup

teardown() { teardown_env; }

# ─── 観点 EX（extract）─────────

@test "EX1: multiple-problems fixture → 3 問題 × 6 キー = 18 行 extracted + summary 1 行" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture multiple-problems "$target"
  run run_validate extract "$target"
  [ "$status" -eq 0 ]
  local extracted_count
  extracted_count=$(echo "$output" | grep -c "^extracted	" || true)
  [ "$extracted_count" -eq 18 ]
  [[ "$output" == *"summary	extracted_keys	total=18"* ]]
}

# ─── 観点 VA（validate）─────────

@test "VA1: single-problem-no-cause (全 no) → downgrade 0 件 / skill_caused_true=0" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture single-problem-no-cause "$target"
  run run_validate validate "$target"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "^downgrade	"
  [[ "$output" == *"summary	counts	total=1;downgraded=0;skill_caused_true=0"* ]]
}

@test "VA2: single-problem-yes-empty-quote → downgrade 1 件 (q1_quote:empty)" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture single-problem-yes-empty-quote "$target"
  run run_validate validate "$target"
  [ "$status" -eq 0 ]
  [[ "$output" == *"downgrade	1	q1_quote:empty"* ]]
  [[ "$output" == *"summary	counts	total=1;downgraded=1;skill_caused_true=0"* ]]
}

@test "VA3: single-problem-yes-short-quote (5 文字) → downgrade 1 件 (length-below-10)" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture single-problem-yes-short-quote "$target"
  run run_validate validate "$target"
  [ "$status" -eq 0 ]
  [[ "$output" == *"downgrade	1	q1_quote:length-below-10"* ]]
}

@test "VA4: single-problem-yes-forbidden-word (該当 単独) → downgrade 1 件 (length-below-10 のみ / 短いため先に検出)" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture single-problem-yes-forbidden-word "$target"
  run run_validate validate "$target"
  [ "$status" -eq 0 ]
  # 「該当」は 2 文字なので length-below-10 で先にマッチする（実装上の挙動）
  [[ "$output" == *"downgrade	1	q1_quote:length-below-10"* ]]
}

@test "VA5: single-problem-yes-valid-quote → downgrade 0 件 / skill_caused_true=1" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture single-problem-yes-valid-quote "$target"
  run run_validate validate "$target"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "^downgrade	"
  [[ "$output" == *"summary	counts	total=1;downgraded=0;skill_caused_true=1"* ]]
}

# ─── 観点 AP（apply）─────────

@test "AP1: --apply で違反項目の q1_answer が yes → no に書き換え + sha 変化" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture single-problem-yes-empty-quote "$target"
  local before
  before=$(snapshot_sha "$target")

  run run_validate validate "$target" --apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"applied	1	q1_answer"* ]]

  # ファイルが変化している
  local after
  after=$(snapshot_sha "$target")
  [ "$before" != "$after" ]
  # q1_answer が "no" に書き換えられている
  grep -F 'q1_answer: "no"' "$target"
}

@test "AP2: validate (--apply なし / デフォルト) で sha 変化なし" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture single-problem-yes-empty-quote "$target"
  local before
  before=$(snapshot_sha "$target")

  run run_validate validate "$target"
  [ "$status" -eq 0 ]

  run assert_unchanged "$target" "$before"
  [ "$status" -eq 0 ]
}

# ─── 観点 RB（rollback）─────────

@test "RB1: --apply 中に書き込み失敗（read-only ファイル）→ rollback で sha 一致 + error\tapply-failed\trollback-completed" {
  setup_env
  local target
  target="$(test_retrospective_path)"
  copy_fixture single-problem-yes-empty-quote "$target"
  local before
  before=$(snapshot_sha "$target")

  # ディレクトリを read-only にして mv を失敗させる
  chmod 555 "$(dirname "$target")"
  chmod 444 "$target"

  run bash "${VALIDATE_SCRIPT}" validate "$target" --apply
  local rc=$status

  # 後始末
  chmod 755 "$(dirname "$target")"
  chmod 644 "$target"

  # 失敗時 exit 2
  [ "$rc" -eq 2 ]
  [[ "$output" == *"apply-failed	rollback-completed"* ]] || [[ "$output" == *"backup-failed"* ]] || [[ "$output" == *"backup-mktemp-failed"* ]]

  # ファイルがロールバック済み（sha 一致）
  run assert_unchanged "$target" "$before"
  [ "$status" -eq 0 ]
}
