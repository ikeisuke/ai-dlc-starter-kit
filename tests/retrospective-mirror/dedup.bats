#!/usr/bin/env bats
# dedup.bats - 観点 F (Filter / dedup) + DI1 (detect 統合)
# Unit 006: 重複検出（Pass A: 引用箇所完全一致 / Pass B: タイトル類似度）

load helpers/setup.bash

setup() {
  setup_env
  set_project_feedback_mode "mirror"
}

teardown() {
  teardown_env
}

# subshell 内で関数を呼ぶヘルパー（set -e の漏れと dispatcher 起動を回避）
_call_fn() {
  local fn="$1"
  shift
  AIDLC_PLUGIN_ROOT="${REPO_ROOT}/skills/aidlc" \
    bash -c "source '${MIRROR_SCRIPT}' 2>/dev/null; ${fn} \"\$@\"" -- "$@"
}

# F1: 引用箇所完全一致（同一文字列）→ 1 件のみ通過
@test "F1: dedup Pass A - 引用箇所完全一致で 1 件通過 + 2 件 dedup-merged" {
  copy_fixture "dedup-quote-match" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]

  [[ "$output" == *"mirror"$'\t'"candidate"$'\t'"1"$'\t'* ]]
  [[ "$output" == *"mirror"$'\t'"dedup-merged"$'\t'"2"$'\t'"1"* ]]
  [[ "$output" == *"mirror"$'\t'"dedup-merged"$'\t'"3"$'\t'"1"* ]]
  [[ "$output" == *"dedup-merged=2"* ]]
}

# F2: 前後空白違い（問題 2）が問題 1 に統合（fixture dedup-quote-match に内包）
@test "F2: dedup Pass A - 前後空白違いの引用箇所が正規化で同一視" {
  copy_fixture "dedup-quote-match" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"dedup-merged"$'\t'"2"$'\t'"1"* ]]
}

# F3: 連続空白違い（問題 3）が問題 1 に統合
@test "F3: dedup Pass A - 連続空白違いの引用箇所が正規化で同一視" {
  copy_fixture "dedup-quote-match" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"dedup-merged"$'\t'"3"$'\t'"1"* ]]
}

# F4: _jaccard_bigram_milli - 完全一致タイトルで 1000 を返す（境界 700 直後の代表ケース）
@test "F4: _jaccard_bigram_milli - 完全一致は 1000" {
  result="$(_call_fn _jaccard_bigram_milli 'abcdefghij' 'abcdefghij')"
  [ "$result" = "1000" ]
}

# F4b: _jaccard_bigram_milli - 部分一致で 0..1000 範囲の整数を返す
@test "F4b: _jaccard_bigram_milli - 部分一致は範囲内整数" {
  result="$(_call_fn _jaccard_bigram_milli 'abcdef' 'abczzz')"
  # bigrams('abcdef') = {ab,bc,cd,de,ef} (5 個)
  # bigrams('abczzz') = {ab,bc,cz,zz} (4 個 / zz 重複は 1 個)
  # union = 7, intersection = {ab,bc} = 2
  # 2 * 1000 / 7 = 285（切り捨て）
  [ "$result" -ge 280 ] && [ "$result" -le 290 ]
}

# F5: _jaccard_bigram_milli - 完全異タイトルで 0 を返す（閾値 700 大きく下回る）
@test "F5: _jaccard_bigram_milli - 完全異字は 0" {
  result="$(_call_fn _jaccard_bigram_milli 'aaaaaa' 'zzzzzz')"
  [ "$result" = "0" ]
}

# F5b: _edit_distance_ratio_pct - 完全一致は 0%
@test "F5b: _edit_distance_ratio_pct - 完全一致は 0" {
  result="$(_call_fn _edit_distance_ratio_pct 'hello' 'hello')"
  [ "$result" = "0" ]
}

# F5c: _edit_distance_ratio_pct - 完全異字で 100% 以下
@test "F5c: _edit_distance_ratio_pct - 完全異字は 100" {
  result="$(_call_fn _edit_distance_ratio_pct 'aaa' 'zzz')"
  [ "$result" = "100" ]
}

# DI1: dedup フィクスチャの detect 統合（summary 詳細検証）
@test "DI1: detect 統合 - dedup フィクスチャで passing/dedup-merged/summary 整合" {
  copy_fixture "dedup-quote-match" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]

  candidate_count="$(echo "$output" | grep -c "^mirror"$'\t'"candidate"$'\t' || true)"
  [ "$candidate_count" -eq 1 ]

  merged_count="$(echo "$output" | grep -c "^mirror"$'\t'"dedup-merged"$'\t' || true)"
  [ "$merged_count" -eq 2 ]

  [[ "$output" == *"total=3"* ]]
  [[ "$output" == *"skill_caused_true=3"* ]]
  [[ "$output" == *"dedup-merged=2"* ]]
  [[ "$output" == *"cap-exceeded=0"* ]]
}
