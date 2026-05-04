#!/usr/bin/env bats
# Unit 004 / Unit 001: 観点 F - feedback_mode 解決検証（4 階層マージ + 不正値ダウングレード）
# v2.5.1 / Unit 001: 5 値 enum + 旧 3 値（後方互換）対応 / 不正値 fallback を silent → disabled に変更

load helpers/setup

teardown() { teardown_env; }

@test "F1: defaults.toml の feedback_mode = interactive（v2.5.1 既定） → 通常生成" {
  setup_env
  # project / user-global の feedback_mode を未設定で defaults.toml の interactive が反映される
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

@test "F3: project の feedback_mode = mirror（旧値）→ 通常生成（mirror-only として）" {
  setup_env
  set_project_feedback_mode "mirror"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
}

@test "F4: project の feedback_mode = on (不正値) → disabled ダウングレード警告 + スキップ（v2.5.1 / Unit 001）" {
  # v2.5.1 で fallback 値を silent → disabled に変更（保守的フォールバック）。
  # feedback-mode.sh の feedback_mode_normalize() が未知値を disabled に正規化し、
  # その後の retrospective-generate.sh が disabled としてスキップする。
  setup_env
  set_project_feedback_mode "on"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn	feedback_mode_unknown	on"* ]]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "F5: project の feedback_mode = silent（旧値）→ interactive 正規化で通常生成（v2.5.1 / Unit 001）" {
  # 旧値 silent は feedback-mode.sh の normalize で interactive に正規化される。
  # interactive は valid_feedback_modes に含まれ、!= disabled なのでファイル生成される。
  setup_env
  set_project_feedback_mode "silent"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
}

@test "F6: project の feedback_mode = local-issue-only（v2.5.1 新値）→ 通常生成" {
  setup_env
  set_project_feedback_mode "local-issue-only"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
}

@test "F7: project の feedback_mode = local-and-mirror（v2.5.1 新値）→ 通常生成" {
  setup_env
  set_project_feedback_mode "local-and-mirror"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
}
