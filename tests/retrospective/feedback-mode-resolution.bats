#!/usr/bin/env bats
# Unit 004: 観点 F - feedback_mode 解決検証（4 階層マージ + 不正値ダウングレード）

load helpers/setup

teardown() { teardown_env; }

@test "F1: defaults.toml の feedback_mode = silent → 通常生成" {
  setup_env
  # project / user-global の feedback_mode を未設定で defaults.toml が反映される
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
}

@test "F2: project の feedback_mode = disabled → スキップ" {
  setup_env
  set_project_feedback_mode "disabled"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "F3: project の feedback_mode = mirror → 通常生成（mirror として）" {
  setup_env
  set_project_feedback_mode "mirror"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
}

@test "F4: project の feedback_mode = on (不正値) → silent ダウングレード警告 + 通常生成" {
  setup_env
  set_project_feedback_mode "on"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn	feedback-mode-invalid	on:downgrade-to-silent"* ]]
  [[ "$output" == *"retrospective	created	"* ]]
}
