#!/usr/bin/env bats
# migrate-v3-config.sh のテスト（v2 config → v3 config 変換 / plan・apply）
# 変換規則の正本: docs/v3/migration.md §3.1 / 変換先 schema: docs/v3/data-model.md §11

load helpers/setup

teardown() {
  teardown_environment
}

# --- plan: 世代差 fixtures ---

@test "v3-config: plan keeps explicit v2 values (full generation)" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config --plan
  [ "$status" -eq 0 ]
  [[ "$output" == *"keep:rules.depth_level.level=standard"* ]]
  [[ "$output" == *"keep:rules.automation.mode=semi_auto"* ]]
  [[ "$output" == *"keep:rules.reviewing.mode=required"* ]]
  [[ "$output" == *'keep:rules.reviewing.tools=["codex"]'* ]]
  [[ "$output" == *"keep:rules.reviewing.exclude_patterns=[]"* ]]
  [[ "$output" == *"keep:rules.release.changelog=true"* ]]
  [[ "$output" == *"keep:rules.release.version_tag=false"* ]]
  [[ "$output" == *"default:rules.release.required_ci_zero_fallback=false"* ]]
  [[ "$output" == *"status:planned"* ]]
}

@test "v3-config: plan does not modify source config" {
  setup_v2v3_environment gen-2.5.5-full
  before="$(cat "${TEST_TMPDIR}/.aidlc/config.toml")"
  run run_v3_config --plan
  [ "$status" -eq 0 ]
  after="$(cat "${TEST_TMPDIR}/.aidlc/config.toml")"
  [ "$before" = "$after" ]
}

@test "v3-config: dropped keys are warned not errored (incompat #3)" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config --plan
  [ "$status" -eq 0 ]
  [[ "$output" == *"drop:starter_kit_version"* ]]
  [[ "$output" == *"drop:rules.git.merge_method"* ]]
  [[ "$output" == *"drop:rules.github.milestone_enabled"* ]]
  [[ "$output" == *"drop:rules.retrospective.feedback_mode"* ]]
}

@test "v3-config: minimal generation falls back to v3 defaults" {
  setup_v2v3_environment gen-early-minimal
  run run_v3_config --plan
  [ "$status" -eq 0 ]
  [[ "$output" == *"default:rules.depth_level.level=standard"* ]]
  [[ "$output" == *"default:rules.automation.mode=manual"* ]]
  [[ "$output" == *"keep:rules.reviewing.mode=recommend"* ]]
  [[ "$output" == *'default:rules.reviewing.tools=["codex"]'* ]]
  [[ "$output" == *"default:rules.reviewing.exclude_patterns=[]"* ]]
  [[ "$output" == *"default:rules.release.changelog=false"* ]]
  [[ "$output" == *"default:rules.release.version_tag=false"* ]]
}

@test "v3-config: invalid enum and multiline array fall back with warn" {
  setup_v2v3_environment gen-unknown-keys
  run run_v3_config --plan
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn:invalid-value:rules.depth_level.level:fallback=standard"* ]]
  [[ "$output" == *"default:rules.depth_level.level=standard"* ]]
  [[ "$output" == *"warn:invalid-value:rules.reviewing.tools"* ]]
  [[ "$output" == *'default:rules.reviewing.tools=["codex"]'* ]]
}

@test "v3-config: unknown and custom keys warned not errored" {
  setup_v2v3_environment gen-unknown-keys
  run run_v3_config --plan
  [ "$status" -eq 0 ]
  [[ "$output" == *"drop:rules.custom.my_special_flag"* ]]
  [[ "$output" == *"drop:future.section.key"* ]]
}

@test "v3-config: v3-new key in v2 config is not carried over" {
  setup_v2v3_environment gen-unknown-keys
  run run_v3_config --plan
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn:not-carried-over:rules.release.required_ci_zero_fallback"* ]]
  [[ "$output" == *"default:rules.release.required_ci_zero_fallback=false"* ]]
}

# --- apply ---

@test "v3-config: apply writes v3 config with 8 keys only" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config --apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"status:applied"* ]]
  config="$(cat "${TEST_TMPDIR}/.aidlc/config.toml")"
  [[ "$config" == *'level = "standard"'* ]]
  [[ "$config" == *'mode = "semi_auto"'* ]]
  [[ "$config" == *'mode = "required"'* ]]
  [[ "$config" == *'tools = ["codex"]'* ]]
  [[ "$config" == *"exclude_patterns = []"* ]]
  [[ "$config" == *"changelog = true"* ]]
  [[ "$config" == *"version_tag = false"* ]]
  [[ "$config" == *"required_ci_zero_fallback = false"* ]]
  # 旧キーが消えている（v3 は 8 キー終端集合のみ）
  [[ "$config" != *"starter_kit_version"* ]]
  [[ "$config" != *"milestone_enabled"* ]]
  [[ "$config" != *"feedback_mode"* ]]
}

@test "v3-config: apply is idempotent (re-run on generated v3 config)" {
  setup_v2v3_environment gen-2.5.5-full
  export AIDLC_MIGRATE_NOW="2026-01-01T00:00:00Z"
  run run_v3_config --apply
  [ "$status" -eq 0 ]
  first="$(cat "${TEST_TMPDIR}/.aidlc/config.toml")"
  run run_v3_config --apply
  [ "$status" -eq 0 ]
  second="$(cat "${TEST_TMPDIR}/.aidlc/config.toml")"
  [ "$first" = "$second" ]
}

@test "v3-config: source/target override (repo-relative) keeps source untouched" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config --apply \
    --source ".aidlc/config.toml" \
    --target "v3-config.toml"
  [ "$status" -eq 0 ]
  [ -f "${TEST_TMPDIR}/v3-config.toml" ]
  # source は v2 のまま
  config="$(cat "${TEST_TMPDIR}/.aidlc/config.toml")"
  [[ "$config" == *"starter_kit_version"* ]]
}

# --- エラー系 ---

@test "v3-config: error when source missing" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config --plan --source "no-such-config.toml"
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:source-not-found"* ]]
}

@test "v3-config: absolute path rejected (path-guard)" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config --plan --source "${TEST_TMPDIR}/.aidlc/config.toml"
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:path-rejected:source"* ]]
}

@test "v3-config: parent traversal rejected (path-guard)" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config --apply --target "../escape.toml"
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:path-rejected:target"* ]]
  [ ! -f "${TEST_TMPDIR}/../escape.toml" ]
}

@test "v3-config: target directory rejected" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config --apply --target ".aidlc"
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:target-is-directory"* ]]
}

@test "v3-config: error on missing mode argument" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_config
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage:"* ]]
}
