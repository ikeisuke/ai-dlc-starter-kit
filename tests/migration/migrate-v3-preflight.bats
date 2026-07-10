#!/usr/bin/env bats
# migrate-v3-preflight.sh のテスト（v2→v3 migration 前提検証）

load helpers/setup

teardown() {
  teardown_environment
}

@test "v3-preflight: ok on clean v2 environment" {
  setup_v2v3_environment
  run run_v3_preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"status:ok"* ]]
}

@test "v3-preflight: one-way migration warning always emitted" {
  setup_v2v3_environment
  run run_v3_preflight
  [[ "$output" == *"warn:one-way-migration"* ]]
}

@test "v3-preflight: error when state.json already exists (already v3)" {
  setup_v2v3_environment
  echo '{}' > "${TEST_TMPDIR}/.aidlc/state.json"
  run run_v3_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:already-v3"* ]]
}

@test "v3-preflight: error when config.toml missing" {
  setup_v2v3_environment
  rm "${TEST_TMPDIR}/.aidlc/config.toml"
  run run_v3_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:config-not-found"* ]]
}

@test "v3-preflight: error on dirty worktree" {
  setup_v2v3_environment
  echo "x" > "${TEST_TMPDIR}/untracked.txt"
  run run_v3_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:dirty-worktree"* ]]
}

@test "v3-preflight: error when state-init.sh cannot be resolved" {
  setup_v2v3_environment
  export AIDLC_STATE_INIT_SCRIPT="${TEST_TMPDIR}/missing/state-init.sh"
  run run_v3_preflight
  [ "$status" -eq 2 ]
  [[ "$output" == *"error:state-init-not-found"* ]]
}

@test "v3-preflight: error when state-validate.sh missing next to state-init.sh" {
  setup_v2v3_environment
  mkdir -p "${TEST_TMPDIR}/fake-scripts"
  cat > "${TEST_TMPDIR}/fake-scripts/state-init.sh" << 'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "${TEST_TMPDIR}/fake-scripts/state-init.sh"
  export AIDLC_STATE_INIT_SCRIPT="${TEST_TMPDIR}/fake-scripts/state-init.sh"
  run run_v3_preflight
  [ "$status" -eq 2 ]
  [[ "$output" == *"error:state-validate-not-found"* ]]
}

@test "v3-preflight: error when v1 markers present (v1→v2 first)" {
  setup_v2v3_environment
  mkdir -p "${TEST_TMPDIR}/docs"
  touch "${TEST_TMPDIR}/docs/aidlc.toml"
  git -C "${TEST_TMPDIR}" -c user.email=test@example.com -c user.name=test \
    -c commit.gpgsign=false add -A
  git -C "${TEST_TMPDIR}" -c user.email=test@example.com -c user.name=test \
    -c commit.gpgsign=false commit --quiet -m "add v1 marker"
  run run_v3_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:v1-markers-present"* ]]
}
