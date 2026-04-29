#!/usr/bin/env bats
# Unit 003: 観点 A - detect サブコマンド
# A1: 全 7 キー検出 / A2: 部分 3 キー検出 / A3: 0 件検出 / A4: user_global_conflict 列の true/false

load helpers/setup

teardown() { teardown_env; }

@test "A1: project に全 7 キー存在 + user-global 空 → detected 7 件 + summary total 7 + conflict 全て false" {
  setup_env "p-all7-keys" "u-empty"
  run run_detect
  [ "$status" -eq 0 ]
  # 各キー検出（conflict false）
  echo "$output" | grep -F -- $'detected\trules.reviewing.mode\trequired\tfalse'
  echo "$output" | grep -F -- $'detected\trules.reviewing.tools\t[\'claude\']\tfalse'
  echo "$output" | grep -F -- $'detected\trules.automation.mode\tfull_auto\tfalse'
  echo "$output" | grep -F -- $'detected\trules.git.squash_enabled\ttrue\tfalse'
  echo "$output" | grep -F -- $'detected\trules.git.ai_author_auto_detect\tfalse\tfalse'
  echo "$output" | grep -F -- $'detected\trules.linting.enabled\ttrue\tfalse'
  echo "$output" | grep -F -- $'summary\ttotal\t7'
}

@test "A2: project に 3 キー存在 + user-global 空 → detected 3 件 + summary total 3" {
  setup_env "p-mixed-3keys" "u-empty"
  run run_detect
  [ "$status" -eq 0 ]
  echo "$output" | grep -F -- $'detected\trules.reviewing.mode\trequired\tfalse'
  echo "$output" | grep -F -- $'detected\trules.git.squash_enabled\ttrue\tfalse'
  echo "$output" | grep -F -- $'detected\trules.linting.enabled\ttrue\tfalse'
  echo "$output" | grep -F -- $'summary\ttotal\t3'
  # 残り 4 キーは含まれない
  ! echo "$output" | grep -F -- 'detected\trules.reviewing.tools'
  ! echo "$output" | grep -F -- 'detected\trules.automation.mode'
  ! echo "$output" | grep -F -- 'detected\trules.git.ai_author'
}

@test "A3: project に個人好みキーなし + user-global 空 → detected 0 件 + summary total 0 + exit 0" {
  setup_env "p-no-keys" "u-empty"
  run run_detect
  [ "$status" -eq 0 ]
  echo "$output" | grep -F -- $'summary\ttotal\t0'
  # 1 行も detected が出ない
  ! echo "$output" | grep -F -- $'detected\t'
}

@test "A4: project に 7 キー + user-global に rules.reviewing.mode 既存 → conflict=true は当該キーのみ" {
  setup_env "p-all7-keys" "u-with-key"
  run run_detect
  [ "$status" -eq 0 ]
  # 既存キーは conflict=true
  echo "$output" | grep -F -- $'detected\trules.reviewing.mode\trequired\ttrue'
  # その他は conflict=false
  echo "$output" | grep -F -- $'detected\trules.git.squash_enabled\ttrue\tfalse'
  echo "$output" | grep -F -- $'detected\trules.linting.enabled\ttrue\tfalse'
  echo "$output" | grep -F -- $'summary\ttotal\t7'
}
