#!/usr/bin/env bats
# Unit 004 / Unit 001 / Unit 002: 観点 F - feedback_mode 解決検証
# v2.5.1 / Unit 002: retrospective-generate.sh は互換アダプタ層化され、新仕様では:
#   - ローカル retrospective.md ファイル生成は撤廃（Plan §「互換アダプタ層 保証範囲」）
#   - gh 利用可能時は Issue 起票（出力: retrospective\tcreated\t<URL>）
#   - gh 利用不可時は spool（出力: retrospective\tskip\tspooled）
#   - interactive モードは disabled に縮退（出力: retrospective\tskip\tdisabled）
# テスト環境では gh 利用不可前提のため `spooled` / `disabled` を verify する。
# Plan §「互換アダプタ層 保証範囲」に従い「行構造（exit 0 + retrospective\t...）」を保証する。

load helpers/setup

teardown() { teardown_env; }

@test "F1: defaults.toml の feedback_mode = interactive（v2.5.1 既定） → disabled 縮退 skip" {
  setup_env
  # v2.5.1: interactive は __retro_resolve_target で 'none' に縮退 → result=skipped reason=mode-disabled
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "F2: project の feedback_mode = disabled → スキップ" {
  setup_env
  set_project_feedback_mode "disabled"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "F3: project の feedback_mode = mirror（旧値）→ mirror-only 正規化 → gh 不可で spooled" {
  setup_env
  set_project_feedback_mode "mirror"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	spooled"* ]]
}

@test "F4: project の feedback_mode = on (不正値) → disabled ダウングレード警告 + スキップ（v2.5.1 / Unit 001）" {
  setup_env
  set_project_feedback_mode "on"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn	feedback_mode_unknown	on"* ]]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "F5: project の feedback_mode = silent（旧値）→ interactive 正規化 → disabled 縮退（v2.5.1 / Unit 002）" {
  setup_env
  set_project_feedback_mode "silent"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "F6: project の feedback_mode = local-issue-only（v2.5.1 新値）→ gh 不可で spooled" {
  setup_env
  set_project_feedback_mode "local-issue-only"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	spooled"* ]]
}

@test "F7: project の feedback_mode = local-and-mirror（v2.5.1 新値）→ gh 不可で spooled" {
  setup_env
  set_project_feedback_mode "local-and-mirror"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	spooled"* ]]
}
