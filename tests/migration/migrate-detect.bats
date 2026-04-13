#!/usr/bin/env bats

load helpers/setup

setup() {
  setup_v1_environment
}

teardown() {
  teardown_environment
}

@test "detect: symlink_agents detected" {
  result="$(run_detect)"
  assert_json_has_resource_type "${result}" "symlink_agents"
}

@test "detect: symlink_kiro skills detected" {
  result="$(run_detect)"
  count="$(echo "${result}" | jq '[.resources[] | select(.resource_type == "symlink_kiro" and .path == ".kiro/skills/aidlc")] | length')"
  [ "${count}" -gt 0 ]
}

@test "detect: symlink_materialize for kiro agents detected" {
  result="$(run_detect)"
  count="$(echo "${result}" | jq '[.resources[] | select(.resource_type == "symlink_materialize" and .path == ".kiro/agents/aidlc.json")] | length')"
  [ "${count}" -gt 0 ]
}

@test "detect: backlog_dir detected with condition" {
  result="$(run_detect)"
  assert_json_has_resource_type "${result}" "backlog_dir"
  condition="$(echo "${result}" | jq -r '[.resources[] | select(.resource_type == "backlog_dir")][0].condition')"
  [ "${condition}" != "null" ]
}

@test "detect: issue_template detected with hash match" {
  result="$(run_detect)"
  assert_json_has_resource_type "${result}" "issue_template"
  is_owned="$(echo "${result}" | jq -r '[.resources[] | select(.resource_type == "issue_template")][0].ownership_evidence.is_owned')"
  [ "${is_owned}" = "true" ]
}

@test "detect: config_update detected" {
  result="$(run_detect)"
  assert_json_has_resource_type "${result}" "config_update"
}

@test "detect: data_migration detected" {
  result="$(run_detect)"
  assert_json_has_resource_type "${result}" "data_migration"
}

@test "detect: already_v2 when no v1 artifacts" {
  teardown_environment
  setup_v2_environment
  result="$(run_detect)"
  assert_json_field "${result}" ".status" "already_v2"
  assert_json_array_length "${result}" ".resources" "0"
}

@test "detect: manifest JSON schema has required fields" {
  result="$(run_detect)"
  assert_json_has_field "${result}" ".version"
  assert_json_has_field "${result}" ".status"
  assert_json_has_field "${result}" ".detected_at"
  assert_json_has_field "${result}" ".source_version"
  assert_json_has_field "${result}" ".target_version"
  assert_json_has_field "${result}" ".resources"
  assert_json_field "${result}" ".status" "v1_detected"
  assert_json_field "${result}" ".version" "1"
}
