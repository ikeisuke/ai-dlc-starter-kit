#!/usr/bin/env bats
# Unit 003: 観点 C - keep サブコマンド (2 ケース)
# C1: 非破壊性（project / user-global の sha256 一致）
# C2: ログ出力（keep\t<key>）

load helpers/setup

teardown() { teardown_env; }

@test "C1: keep rules.reviewing.mode → project / user-global いずれも変更なし (sha256 一致)" {
  setup_env "p-all7-keys" "u-with-key"
  local project_before
  project_before=$(snapshot_sha "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml")
  local ug_before
  ug_before=$(snapshot_sha "${AIDLC_USER_GLOBAL_PATH}")

  run run_keep "rules.reviewing.mode"
  [ "$status" -eq 0 ]

  run assert_unchanged "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" "$project_before"
  [ "$status" -eq 0 ]
  run assert_unchanged "${AIDLC_USER_GLOBAL_PATH}" "$ug_before"
  [ "$status" -eq 0 ]
}

@test "C2: keep rules.linting.enabled → stdout に keep ログが出力される" {
  setup_env "p-all7-keys" "u-empty"
  run run_keep "rules.linting.enabled"
  [ "$status" -eq 0 ]
  echo "$output" | grep -F -- $'keep\trules.linting.enabled'
}
