#!/usr/bin/env bats
# Unit 003: 観点 D - --dry-run グローバルオプション (3 ケース)
# D1: dry-run move 出力と実 move 出力（dry-run: プレフィックス除去後）が完全一致
# D2: dry-run move で project ファイル変更なし
# D3: dry-run move で user-global ファイル変更なし

load helpers/setup

teardown() { teardown_env; }

@test "D1: dry-run move の出力（dry-run: 除去後）が実 move の出力と完全一致する" {
  # 環境 1: dry-run 実行
  setup_env "p-all7-keys" "u-empty"
  run run_move "rules.reviewing.mode" --dry-run
  [ "$status" -eq 0 ]
  local dry_output_normalized
  dry_output_normalized="$(printf '%s' "$output" | sed 's/^dry-run://')"
  teardown_env

  # 環境 2: 実 move 実行
  setup_env "p-all7-keys" "u-empty"
  run run_move "rules.reviewing.mode"
  [ "$status" -eq 0 ]
  local real_output="$output"

  # 完全一致
  [ "$dry_output_normalized" = "$real_output" ]
}

@test "D2: dry-run move 実行で project ファイルが変更されない (sha256 一致)" {
  setup_env "p-all7-keys" "u-empty"
  local project_before
  project_before=$(snapshot_sha "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml")

  run run_move "rules.reviewing.mode" --dry-run
  [ "$status" -eq 0 ]

  run assert_unchanged "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" "$project_before"
  [ "$status" -eq 0 ]
}

@test "D3: dry-run move 実行で user-global ファイルが変更されない (sha256 一致)" {
  setup_env "p-all7-keys" "u-empty"
  local ug_before
  ug_before=$(snapshot_sha "${AIDLC_USER_GLOBAL_PATH}")

  run run_move "rules.reviewing.mode" --dry-run
  [ "$status" -eq 0 ]

  run assert_unchanged "${AIDLC_USER_GLOBAL_PATH}" "$ug_before"
  [ "$status" -eq 0 ]
}
