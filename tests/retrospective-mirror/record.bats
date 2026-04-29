#!/usr/bin/env bats
# record.bats - 観点 R: skipped/pending 記録 + 不正値ガード

load helpers/setup.bash

setup() {
  setup_env
  set_project_feedback_mode "mirror"
}

teardown() {
  teardown_env
}

@test "record: skipped で mirror_state.state を skipped に書き換え" {
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  run run_mirror record "$(test_retrospective_path)" 1 skipped
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"recorded"$'\t'"1"$'\t'"skipped"* ]]
  grep -q 'state: "skipped"' "$(test_retrospective_path)"
  grep -q 'issue_url: ""' "$(test_retrospective_path)"
}

@test "record: pending で mirror_state.state を pending に書き換え" {
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  run run_mirror record "$(test_retrospective_path)" 1 pending
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"recorded"$'\t'"1"$'\t'"pending"* ]]
  grep -q 'state: "pending"' "$(test_retrospective_path)"
}

@test "record: 不正な decision で fatal exit 2" {
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  run run_mirror record "$(test_retrospective_path)" 1 invalid-value
  [ "$status" -eq 2 ]
  [[ "$output" == *"error"$'\t'"invalid-decision"$'\t'"invalid-value"* ]]
}

@test "record: 後方互換 - mirror_state 欠落の旧形式に新規ブロック追加" {
  copy_fixture "legacy-no-mirror-state" "$(test_retrospective_path)"
  run run_mirror record "$(test_retrospective_path)" 1 pending
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"recorded"$'\t'"1"$'\t'"pending"* ]]
  grep -q 'mirror_state:' "$(test_retrospective_path)"
  grep -q 'state: "pending"' "$(test_retrospective_path)"
}

@test "record: multi-problem の先頭 idx=1 を skipped に書き換えできる（中間以前の問題更新）" {
  copy_fixture "mixed-state" "$(test_retrospective_path)"
  # mixed-state では問題 1 は state=sent。その状態を skipped に書き換える（処理済みでも record で上書きされる仕様確認用）
  run run_mirror record "$(test_retrospective_path)" 1 skipped
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"recorded"$'\t'"1"$'\t'"skipped"* ]]
  # 問題 1 の mirror_state.state が "skipped" になっていることを確認
  awk '/^### 問題 1:/,/^### 問題 2:/' "$(test_retrospective_path)" | grep -q 'state: "skipped"'
}

@test "record: multi-problem の中間 idx=3 を pending に書き換えできる（後続問題が存在する場合）" {
  copy_fixture "mixed-state" "$(test_retrospective_path)"
  run run_mirror record "$(test_retrospective_path)" 3 pending
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"recorded"$'\t'"3"$'\t'"pending"* ]]
  # 問題 3 の mirror_state.state が "pending" になっていることを確認
  awk '/^### 問題 3:/,/^### 問題 4:/' "$(test_retrospective_path)" | grep -q 'state: "pending"'
  # 問題 1 / 2 / 4 の mirror_state は変更されない
  awk '/^### 問題 1:/,/^### 問題 2:/' "$(test_retrospective_path)" | grep -q 'state: "sent"'
  awk '/^### 問題 2:/,/^### 問題 3:/' "$(test_retrospective_path)" | grep -q 'state: "skipped"'
  awk '/^### 問題 4:/,/^## 次サイクル/' "$(test_retrospective_path)" | grep -q 'state: "pending"'
}
