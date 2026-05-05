#!/usr/bin/env bats
# Unit 004 / Unit 002: 観点 GE - retrospective-generate.sh 互換アダプタ
# v2.5.1 / Unit 002: 互換アダプタ層化（Plan §「互換アダプタ層 保証範囲」）
#   保証: 旧 stdout プレフィックス契約（行構造）+ 引数 `<CYCLE>` 受け入れ + 終了コード（0 / 2）
#   非保証: ローカル retrospective.md 生成（廃止）/ <path> は Issue URL に置換
# テスト環境（gh 不可）では:
#   - 通常 mode (interactive 既定): retrospective\tskip\tdisabled
#   - gh 起票対象 mode (mirror-only / local-issue-only 等): retrospective\tskip\tspooled

load helpers/setup

teardown() { teardown_env; }

@test "GE1: 通常生成（interactive 既定）→ retrospective\tskip\tdisabled（v2.5.1 縮退）" {
  setup_env
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
  # v2.5.1 ではローカルファイル生成は廃止（Plan §「互換アダプタ層 保証範囲」）
  [ ! -f "${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.5.0/operations/retrospective.md" ]
}

@test "GE2: feedback_mode = disabled → retrospective\tskip\tdisabled + ファイル作成なし" {
  setup_env
  set_project_feedback_mode "disabled"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
  [ ! -f "${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.5.0/operations/retrospective.md" ]
}

@test "GE4: 不正な feedback_mode (on) → warn\tfeedback_mode_unknown + disabled スキップ（v2.5.1 / Unit 001）" {
  setup_env
  set_project_feedback_mode "on"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn	feedback_mode_unknown	on"* ]]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "GE5: cycle 番号バージョンガードは Issue #625 fix で撤廃済（任意 cycle で動作）" {
  setup_env
  run run_generate v1.14.2
  [ "$status" -eq 0 ]
  # v2.5.1 では interactive 既定で disabled 縮退するため skip\tdisabled が出力される
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "GE6: cycle 引数のパストラバーサル防止検証（Unit 002 / __retro_validate_cycle）" {
  setup_env

  # v2.5.1 では retrospective_issue_create 内の __retro_validate_cycle で検証
  # ただし interactive 既定 + 不正 cycle: cycle 検証は target=none で skip 経路に乗る前に通らない場合があるため
  # mirror-only に切り替えてから cycle を不正にする
  set_project_feedback_mode "mirror-only"

  # `../` 含むパスは弾く
  run run_generate "../etc"
  [ "$status" -eq 2 ]
  [[ "$output" == *"cycle_invalid"* ]] || [[ "$output" == *"create-fatal"* ]]

  # `/` 含むパスは弾く
  run run_generate "v2.5.0/foo"
  [ "$status" -eq 2 ]

  # `..` 単独は弾く
  run run_generate ".."
  [ "$status" -eq 2 ]

  # `.` 単独も弾く
  run run_generate "."
  [ "$status" -eq 2 ]

  # 通常の SemVer プレフィックス付きは通る（gh 不可なので spooled）
  run run_generate "v2.5.0-test"
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	spooled"* ]]

  # visitory 形式 (v1.14.2) も通る
  run run_generate "v1.14.2"
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	spooled"* ]]

  # 日付サイクル (2024-12) も通る
  run run_generate "2024-12"
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	spooled"* ]]
}
