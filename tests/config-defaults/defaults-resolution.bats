#!/usr/bin/env bats
# Unit 001 観点 B1 + B2: 4 階層マージの優先度規則と既定値同等性 NFR を検証
#
# - B1: project に 7 キー無し → defaults 値が返る（既定値同等性 NFR）
#       期待値はハードコード定数（b1_expected_for 関数）と一致することを検証し、
#       defaults.toml 値が将来意図せず変わった場合にテストが落ちる構造にする
# - B2: project に 7 キー有り → project 値が defaults を上書き（後方互換 NFR）

load helpers/setup

teardown() {
  teardown_environment
}

# --- B1: defaults 値が返る（7 キー × 各テスト） ---

@test "B1: rules.reviewing.mode が project に無い時 defaults 値（recommend）が返る" {
  setup_b1_environment
  run run_read_config_single "rules.reviewing.mode"
  [ "$status" -eq 0 ]
  [ "$output" = "recommend" ]
}

@test "B1: rules.reviewing.tools が project に無い時 defaults 値（['codex']）が返る" {
  setup_b1_environment
  run run_read_config_single "rules.reviewing.tools"
  [ "$status" -eq 0 ]
  [ "$output" = "['codex']" ]
}

@test "B1: rules.automation.mode が project に無い時 defaults 値（manual）が返る" {
  setup_b1_environment
  run run_read_config_single "rules.automation.mode"
  [ "$status" -eq 0 ]
  [ "$output" = "manual" ]
}

@test "B1: rules.git.squash_enabled が project に無い時 defaults 値（false）が返る" {
  setup_b1_environment
  run run_read_config_single "rules.git.squash_enabled"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "B1: rules.git.ai_author が project に無い時 defaults 値（空文字列）が返る" {
  setup_b1_environment
  run run_read_config_single "rules.git.ai_author"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "B1: rules.git.ai_author_auto_detect が project に無い時 defaults 値（true）が返る" {
  setup_b1_environment
  run run_read_config_single "rules.git.ai_author_auto_detect"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "B1: rules.linting.enabled が project に無い時 defaults 値（false）が返る" {
  setup_b1_environment
  run run_read_config_single "rules.linting.enabled"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

# --- B2: project 値が defaults を上書きする（後方互換 NFR） ---

@test "B2: rules.reviewing.mode が project にある時 project 値（required）が返る" {
  setup_b2_environment
  run run_read_config_single "rules.reviewing.mode"
  [ "$status" -eq 0 ]
  [ "$output" = "required" ]
}

@test "B2: rules.reviewing.tools が project にある時 project 値（['claude']）が返る" {
  setup_b2_environment
  run run_read_config_single "rules.reviewing.tools"
  [ "$status" -eq 0 ]
  [ "$output" = "['claude']" ]
}

@test "B2: rules.automation.mode が project にある時 project 値（semi_auto）が返る" {
  setup_b2_environment
  run run_read_config_single "rules.automation.mode"
  [ "$status" -eq 0 ]
  [ "$output" = "semi_auto" ]
}

@test "B2: rules.git.squash_enabled が project にある時 project 値（true）が返る" {
  setup_b2_environment
  run run_read_config_single "rules.git.squash_enabled"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "B2: rules.git.ai_author が project にある時 project 値（TestAuthor ...）が返る" {
  setup_b2_environment
  run run_read_config_single "rules.git.ai_author"
  [ "$status" -eq 0 ]
  [ "$output" = "TestAuthor <test@example.com>" ]
}

@test "B2: rules.git.ai_author_auto_detect が project にある時 project 値（false）が返る" {
  setup_b2_environment
  run run_read_config_single "rules.git.ai_author_auto_detect"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "B2: rules.linting.enabled が project にある時 project 値（true）が返る" {
  setup_b2_environment
  run run_read_config_single "rules.linting.enabled"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

# --- バッチモード（--keys）でも同じ優先度規則が機能することを確認 ---

@test "B1 batch: --keys モードで 7 キー全てが defaults 値を返す" {
  setup_b1_environment
  run run_read_config_batch "${UNIT_001_KEYS[@]}"
  [ "$status" -eq 0 ]
  for key in "${UNIT_001_KEYS[@]}"; do
    expected=$(b1_expected_for "$key")
    grep -Fxq "${key}:${expected}" <<< "$output"
  done
}

@test "B2 batch: --keys モードで 7 キー全てが project 値を返す" {
  setup_b2_environment
  run run_read_config_batch "${UNIT_001_KEYS[@]}"
  [ "$status" -eq 0 ]
  for key in "${UNIT_001_KEYS[@]}"; do
    expected=$(b2_expected_for "$key")
    grep -Fxq "${key}:${expected}" <<< "$output"
  done
}
