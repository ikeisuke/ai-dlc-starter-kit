#!/usr/bin/env bats
# Unit 003: 観点 E - 冪等性 (2 ケース)
# E1: 移動済みキーが再 detect で検出されない
# E2: 部分移動後に残ったキーのみ検出される

load helpers/setup

teardown() { teardown_env; }

@test "E1: rules.reviewing.mode を move 後、再 detect で検出されない" {
  setup_env "p-all7-keys" "u-empty"
  # 1 回目 move
  run run_move "rules.reviewing.mode"
  [ "$status" -eq 0 ]
  # 2 回目 detect
  run run_detect
  [ "$status" -eq 0 ]
  # rules.reviewing.mode は detected に出ない
  ! echo "$output" | grep -F -- $'detected\trules.reviewing.mode'
  # summary は 6 件（7 - 1）
  echo "$output" | grep -F -- $'summary\ttotal\t6'
}

@test "E2: 3 キー部分移動後、残り 4 キーのみ検出される" {
  setup_env "p-all7-keys" "u-empty"
  run run_move "rules.reviewing.mode"; [ "$status" -eq 0 ]
  run run_move "rules.linting.enabled"; [ "$status" -eq 0 ]
  run run_move "rules.git.squash_enabled"; [ "$status" -eq 0 ]
  # 残り 4 キーのみ detect
  run run_detect
  [ "$status" -eq 0 ]
  echo "$output" | grep -F -- $'summary\ttotal\t4'
  ! echo "$output" | grep -F -- $'detected\trules.reviewing.mode'
  ! echo "$output" | grep -F -- $'detected\trules.linting.enabled'
  ! echo "$output" | grep -F -- $'detected\trules.git.squash_enabled'
  echo "$output" | grep -F -- $'detected\trules.reviewing.tools'
  echo "$output" | grep -F -- $'detected\trules.automation.mode'
  echo "$output" | grep -F -- $'detected\trules.git.ai_author'
  echo "$output" | grep -F -- $'detected\trules.git.ai_author_auto_detect'
}
