#!/usr/bin/env bats
# Unit 003 / v2.6.6 / #652:
#   - L1 extractors (decisions / review_summary / history) 単体テスト
#   - L2 renderer 単体テスト
#   - L3 公開 API retrospective_api_extract_facts 統合テスト
#   - 後方互換: §1.1.5 互換 markdown 表の列・行構造一致 (固定 fixture との diff 0)
#   - cycle 不在時 fatal (exit 2)
#   - jsonl 関連は tests/retrospective-fact-extract-jsonl.bats を参照

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  API="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-api.sh"
  LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-fact-extract.sh"
  FIXTURE_DIR="${REPO_ROOT}/tests/fixtures/retrospective-fact-extract"
  FIXTURE_CYCLE_DIR="${FIXTURE_DIR}/cycles/v_test"
  EXPECTED_MD="${FIXTURE_DIR}/expected_v_test.md"
}

load_lib_fresh() {
  unset RETROSPECTIVE_FACT_EXTRACT_SOURCED
  # shellcheck disable=SC1090
  source "$LIB"
}

load_api_fresh() {
  unset RETROSPECTIVE_API_SOURCED RETROSPECTIVE_FACT_EXTRACT_SOURCED
  # shellcheck disable=SC1090
  source "$API"
}

# ─── L1 extractors: decisions ────────────────────────────────────────

@test "L1-DEC-1: decisions extractor が DR 件数 3 を返す (fixture)" {
  load_lib_fresh
  run _retrospective_fact_extract_decisions "$FIXTURE_CYCLE_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^decisions\|dr_count\|3\|inception/decisions\.md$'
}

@test "L1-DEC-2: decisions extractor が dr_titles を 3 件結合する" {
  load_lib_fresh
  run _retrospective_fact_extract_decisions "$FIXTURE_CYCLE_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^decisions\|dr_titles\|.*フィクスチャ用テスト DR その 1.*フィクスチャ用テスト DR その 2.*フィクスチャ用テスト DR その 3.*\|inception/decisions\.md$'
}

@test "L1-DEC-3: decisions extractor が source 不在時に warn + '-（source 不在）' 行を出力" {
  load_lib_fresh
  run _retrospective_fact_extract_decisions "/tmp/aidlc-nonexistent-cycle-$$"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^decisions\|dr_count\|-（source 不在）\|inception/decisions\.md$'
}

# ─── L1 extractors: review_summary ───────────────────────────────────

@test "L1-REV-1: review_summary extractor が round 3 / 指摘 3 / defer 2 を集計" {
  load_lib_fresh
  run _retrospective_fact_extract_review_summary "$FIXTURE_CYCLE_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^review_summary\|review_round_total\|3\|'
  echo "$output" | grep -qE '^review_summary\|review_finding_total\|3\|'
  echo "$output" | grep -qE '^review_summary\|defer_count\|2\|'
}

@test "L1-REV-2: review_summary extractor が dir 不在時に warn + 3 行の '-（source 不在）' を出力" {
  load_lib_fresh
  run _retrospective_fact_extract_review_summary "/tmp/aidlc-nonexistent-cycle-$$"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | grep -cE '\|-（source 不在）\|')" -eq 3 ]
}

# ─── L1 extractors: history ──────────────────────────────────────────

@test "L1-HIS-1: history extractor がタイムスタンプ昇順 + 4 イベント結合" {
  load_lib_fresh
  run _retrospective_fact_extract_history "$FIXTURE_CYCLE_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^history\|history_event\|.*2026-05-19T08:00:00.*Intent 確定.*2026-05-19T11:00:00.*コード生成完了.*\|history/\*\.md$'
}

@test "L1-HIS-2: history extractor max_events=2 で 2 件に打切る" {
  load_lib_fresh
  run _retrospective_fact_extract_history "$FIXTURE_CYCLE_DIR" 2
  [ "$status" -eq 0 ]
  # ; 区切りでイベント数を数える: 2 件なら 1 つの ;
  local sep_count
  sep_count=$(echo "$output" | grep -oE '; ' | wc -l | tr -d ' ')
  [ "$sep_count" -eq 1 ]
}

@test "L1-HIS-3: history extractor が dir 不在時に warn + '-（source 不在）' 1 行" {
  load_lib_fresh
  run _retrospective_fact_extract_history "/tmp/aidlc-nonexistent-cycle-$$"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^history\|history_event\|-（source 不在）\|'
}

# ─── L2 renderer ─────────────────────────────────────────────────────

@test "L2-REND-1: renderer がヘッダ + 区切り行を出力" {
  load_lib_fresh
  run bash -c "printf 'decisions|dr_count|3|inception/decisions.md\n' | (source '$LIB' && _retrospective_fact_extract_render_markdown)"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF '| 項目 | 値 | 出典 |'
  echo "$output" | grep -qF '|------|-----|------|'
}

@test "L2-REND-2: renderer が dr_titles / dr_root_cause_class を出力しない (内部集計のみ)" {
  load_lib_fresh
  run bash -c "printf 'decisions|dr_count|3|inception/decisions.md\ndecisions|dr_titles|t1; t2|inception/decisions.md\ndecisions|dr_root_cause_class|product=1;starter=2;both=0|inception/decisions.md\n' | (source '$LIB' && _retrospective_fact_extract_render_markdown)"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF 'DR 件数'
  ! echo "$output" | grep -qF 'dr_titles'
  ! echo "$output" | grep -qF 'dr_root_cause_class'
}

@test "L2-REND-3: renderer が jsonl_event を opt-in (入力なしなら出力なし)" {
  load_lib_fresh
  run bash -c "printf 'decisions|dr_count|3|inception/decisions.md\n' | (source '$LIB' && _retrospective_fact_extract_render_markdown)"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qF '時系列イベント（jsonl）'
}

@test "L2-REND-4: renderer が jsonl_event を入力ありで出力する" {
  load_lib_fresh
  run bash -c "printf 'decisions|dr_count|3|inception/decisions.md\njsonl|jsonl_event|2026 - evt|sample.jsonl\n' | (source '$LIB' && _retrospective_fact_extract_render_markdown)"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF '時系列イベント（jsonl）'
  echo "$output" | grep -qF 'sample.jsonl'
}

# ─── L3 公開 API: 引数バリデーション ─────────────────────────────────

@test "L3-API-1: cycle_id 空時に exit 2" {
  load_api_fresh
  run retrospective_api_extract_facts ""
  [ "$status" -eq 2 ]
  echo "$output" | grep -qF 'cycle_id 必須引数が空です'
}

@test "L3-API-2: cycle_id 形式不正 (空白含む) で exit 2" {
  load_api_fresh
  run retrospective_api_extract_facts "v 1.0"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qF 'cycle_id 形式不正'
}

@test "L3-API-3: cycle_dir 不在で exit 2" {
  load_api_fresh
  run retrospective_api_extract_facts "v0.0.0-bats-nonexistent"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qF 'cycle ディレクトリ不在'
}

# ─── L3 公開 API: smoke test (実 cycle) ──────────────────────────────

@test "L3-API-4: 実 cycle v2.6.6 で smoke test (markdown 表ヘッダ + DR 件数行)" {
  load_api_fresh
  run retrospective_api_extract_facts v2.6.6
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF '| 項目 | 値 | 出典 |'
  echo "$output" | grep -qF 'DR 件数'
}

# ─── §1.1.5 互換: 固定 fixture との diff 0 ───────────────────────────

@test "COMPAT-1: fixture cycle に対する extractor + renderer 出力が期待 markdown と diff 0" {
  load_lib_fresh
  local actual
  actual=$(
    {
      _retrospective_fact_extract_decisions "$FIXTURE_CYCLE_DIR"
      _retrospective_fact_extract_review_summary "$FIXTURE_CYCLE_DIR"
      _retrospective_fact_extract_history "$FIXTURE_CYCLE_DIR"
    } | _retrospective_fact_extract_render_markdown
  )
  local expected
  expected=$(cat "$EXPECTED_MD")
  if [[ "$actual" != "$expected" ]]; then
    diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual")
    return 1
  fi
}
