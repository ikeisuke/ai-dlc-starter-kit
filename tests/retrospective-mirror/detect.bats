#!/usr/bin/env bats
# detect.bats - 観点 D: candidate 抽出ロジック
#   - feedback_mode 解決による分岐（mirror / silent / disabled / 不正値）
#   - skill_caused 派生計算 + mirror_state.state 状態判定
#   - 後方互換（mirror_state ブロック欠落）

load helpers/setup.bash

setup() {
  setup_env
}

teardown() {
  teardown_env
}

@test "detect: feedback_mode=silent の場合 mirror skip not-mirror-mode を出力" {
  set_project_feedback_mode "silent"
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"skip"$'\t'"not-mirror-mode"* ]]
  [[ "$output" != *"mirror"$'\t'"candidate"* ]]
}

@test "detect: feedback_mode=disabled の場合もスキップする" {
  set_project_feedback_mode "disabled"
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"skip"$'\t'"not-mirror-mode"* ]]
}

@test "detect: feedback_mode=mirror で skill_caused=true × state=Empty を candidate として抽出" {
  set_project_feedback_mode "mirror"
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"candidate"$'\t'"1"* ]]
  [[ "$output" == *"summary"$'\t'"counts"$'\t'"total=1;skill_caused_true=1;already-processed=0"* ]]
}

@test "detect: feedback_mode=mirror で skill_caused=false のみの場合 mirror skip no-skill-caused" {
  set_project_feedback_mode "mirror"
  copy_fixture "no-skill-caused" "$(test_retrospective_path)"
  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"skip"$'\t'"no-skill-caused"* ]]
  [[ "$output" != *"mirror"$'\t'"candidate"* ]]
}

@test "detect: 後方互換 - mirror_state ブロック欠落の旧形式を Empty 扱いで candidate 抽出" {
  set_project_feedback_mode "mirror"
  copy_fixture "legacy-no-mirror-state" "$(test_retrospective_path)"
  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"candidate"$'\t'"1"* ]]
}

@test "detect: mixed-state で processed 項目はスキップし Empty のみ candidate" {
  set_project_feedback_mode "mirror"
  copy_fixture "mixed-state" "$(test_retrospective_path)"
  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  # 問題 1 (sent) / 問題 2 (skipped) / 問題 4 (pending) は candidate にならない
  [[ "$output" != *"mirror"$'\t'"candidate"$'\t'"1"$'\t'* ]]
  [[ "$output" != *"mirror"$'\t'"candidate"$'\t'"2"$'\t'* ]]
  [[ "$output" != *"mirror"$'\t'"candidate"$'\t'"4"$'\t'* ]]
  # 問題 3 (Empty + skill_caused=true) のみ candidate
  [[ "$output" == *"mirror"$'\t'"candidate"$'\t'"3"* ]]
  # already-processed=3（問題 1, 2, 4）
  [[ "$output" == *"already-processed=3"* ]]
}

@test "detect: retrospective.md 不在で fatal exit 2" {
  set_project_feedback_mode "mirror"
  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 2 ]
  [[ "$output" == *"error"$'\t'"retrospective-not-found"* ]]
}
