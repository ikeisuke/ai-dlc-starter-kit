#!/usr/bin/env bats
# Unit 002 / v2.6.6 / #704:
#   retrospective_api_evaluate_selfreview_verdict 純粋判定関数の単体テスト。
#   SC-05 (§1.2.5 セルフレビュー判定 + 差し戻し + capped) 対応。
#
# 判定優先順位 (ドメインモデル §SelfReviewSessionAggregate 不変条件 + 論理設計 §判定論理 と一致):
#   1. いずれかが undecidable -> undecidable
#   2. 3 観点すべて false      -> pass
#   3. rebuttal_count >= 3     -> capped
#   4. それ以外                 -> rebuttal

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  API="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-api.sh"
  export AIDLC_BASE="${REPO_ROOT}/skills/aidlc"
}

load_api_fresh() {
  unset RETROSPECTIVE_API_SOURCED
  # shellcheck disable=SC1090
  source "$API"
}

@test "EV1: 全観点 no / 差し戻し 0 -> pass" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict false false false 0
  [ "$status" -eq 0 ]
  [ "$output" = "pass" ]
}

@test "EV2: 観点 A だけ yes / 差し戻し 0 -> rebuttal" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict true false false 0
  [ "$status" -eq 0 ]
  [ "$output" = "rebuttal" ]
}

@test "EV3: 観点 A だけ yes / 差し戻し 2 -> rebuttal (上限到達前)" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict true false false 2
  [ "$status" -eq 0 ]
  [ "$output" = "rebuttal" ]
}

@test "EV4: 観点 A だけ yes / 差し戻し 3 -> capped (上限到達)" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict true false false 3
  [ "$status" -eq 0 ]
  [ "$output" = "capped" ]
}

@test "EV5: 全観点 yes / 差し戻し 3 -> capped" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict true true true 3
  [ "$status" -eq 0 ]
  [ "$output" = "capped" ]
}

@test "EV6: 観点 A undecidable -> undecidable (最優先)" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict undecidable false false 0
  [ "$status" -eq 0 ]
  [ "$output" = "undecidable" ]
}

@test "EV7: 観点 B undecidable -> undecidable (4 回目で undecidable 発生でも undecidable)" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict false undecidable false 3
  [ "$status" -eq 0 ]
  [ "$output" = "undecidable" ]
}

@test "EV8: 観点 C undecidable -> undecidable" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict false false undecidable 1
  [ "$status" -eq 0 ]
  [ "$output" = "undecidable" ]
}

@test "EV9: 日本語入力正規化: 該当する / 該当しない を受理" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict 該当する 該当しない 該当しない 1
  [ "$status" -eq 0 ]
  [ "$output" = "rebuttal" ]
}

@test "EV10: 入力値不正 (1 / 0 等) は warn + undecidable へフォールバック" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict 1 0 0 0
  [ "$status" -eq 0 ]
  # bats `run` は stderr を $output に統合するため部分一致で検証
  [[ "$output" == *"undecidable"* ]]
  [[ "$output" == *"引数不正"* ]]
}

@test "EV11: rebuttal_count 不正 (abc) は warn + 0 にフォールバックして判定" {
  load_api_fresh
  run retrospective_api_evaluate_selfreview_verdict false false false abc
  [ "$status" -eq 0 ]
  [[ "$output" == *"pass"* ]]
  [[ "$output" == *"rebuttal_count 不正"* ]]
}
