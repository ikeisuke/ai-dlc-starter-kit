#!/usr/bin/env bats
# Unit 004: 観点 V - cycle-version-check helper

load helpers/setup

@test "V1: v2.5.0 → exit 0" {
  run run_cycle_check v2.5.0
  [ "$status" -eq 0 ]
}

@test "V2: v2.5.1 → exit 0" {
  run run_cycle_check v2.5.1
  [ "$status" -eq 0 ]
}

@test "V3: v2.6.0 → exit 0" {
  run run_cycle_check v2.6.0
  [ "$status" -eq 0 ]
}

@test "V4: v3.0.0 → exit 0" {
  run run_cycle_check v3.0.0
  [ "$status" -eq 0 ]
}

@test "V5: v2.4.3 → exit 1" {
  run run_cycle_check v2.4.3
  [ "$status" -eq 1 ]
}

@test "V6: v2.4.0 → exit 1" {
  run run_cycle_check v2.4.0
  [ "$status" -eq 1 ]
}

@test "V7: v1.0.0 → exit 1" {
  run run_cycle_check v1.0.0
  [ "$status" -eq 1 ]
}

@test "V8: 2.5.0 (v 抜き) → exit 2 + invalid-format" {
  run run_cycle_check 2.5.0
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid-format:2.5.0"* ]]
}

@test "V9: v2.5 (パッチなし) → exit 2 + invalid-format" {
  run run_cycle_check v2.5
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid-format:v2.5"* ]]
}

@test "V10: vX.Y.Z (非数字) → exit 2 + invalid-format" {
  run run_cycle_check vX.Y.Z
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid-format:vX.Y.Z"* ]]
}

@test "V11: 空文字 → exit 2 + missing-argument" {
  run run_cycle_check ""
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-argument"* ]]
}
