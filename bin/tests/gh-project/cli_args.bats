#!/usr/bin/env bats
# bin/gh-project-cli.sh / audit-github-project.sh / probe-github-project.sh の
# 引数パース / 値欠落検証 / audit --dry-run 拒否 / unknown option エラー

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  CLI="${REPO_ROOT}/bin/gh-project-cli.sh"
  AUDIT="${REPO_ROOT}/bin/audit-github-project.sh"
  PROBE="${REPO_ROOT}/bin/probe-github-project.sh"
  cd "$BATS_TEST_TMPDIR"
  MOCK_DIR="${BATS_TEST_TMPDIR}/mock-bin"
  mkdir -p "$MOCK_DIR"
  # スコープチェックを通すための gh モック（必要なら呼ばれる）
  cat > "${MOCK_DIR}/gh" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "auth" ]] && [[ "$2" == "status" ]]; then
  cat <<EOF
github.com
  ✓ Logged in
  - Token scopes: 'project', 'read:org', 'read:project'
EOF
  exit 0
fi
echo "unmocked: $@" >&2
exit 99
MOCK
  chmod +x "${MOCK_DIR}/gh"
  export PATH="${MOCK_DIR}:${PATH}"
  export AIDLC_REPO_ROOT="$BATS_TEST_TMPDIR"
  mkdir -p "$BATS_TEST_TMPDIR/.aidlc/cache"
}

teardown() {
  cd "$BATS_TEST_TMPDIR"
}

@test "gh-project-cli.sh: unknown subcommand で args_invalid (exit 1)" {
  run "$CLI" bogus-sub
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown_subcommand"* ]] || [[ "$output" == *"args_invalid"* ]]
}

@test "gh-project-cli.sh: ヘルプ表示で exit 0" {
  run "$CLI" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"ensure-project"* ]]
  [[ "$output" == *"audit"* ]]
}

@test "gh-project-cli.sh ensure-project: unknown option で args_invalid (exit 1)" {
  run "$CLI" ensure-project --bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown_option"* ]] || [[ "$output" == *"args_invalid"* ]]
}

@test "gh-project-cli.sh ensure-project: --spec の値欠落で args_invalid (exit 1)" {
  run "$CLI" ensure-project --spec
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing_value_for_option"* ]]
}

@test "gh-project-cli.sh ensure-project: --spec の値が --strict のような他オプションで欠落判定" {
  run "$CLI" ensure-project --spec --strict
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing_value_for_option"* ]]
}

@test "gh-project-cli.sh audit: --dry-run 指定で exit 1 + audit_dry_run_not_supported" {
  run "$CLI" audit --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" == *"audit_dry_run_not_supported"* ]]
}

@test "audit-github-project.sh: --dry-run 指定で exit 1 + audit_dry_run_not_supported" {
  run "$AUDIT" --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" == *"audit_dry_run_not_supported"* ]]
}

@test "audit-github-project.sh: --check の値欠落で args_invalid (exit 1)" {
  run "$AUDIT" --check
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing_value_for_option"* ]]
}

@test "audit-github-project.sh: --check の不正値で args_invalid (exit 1)" {
  run "$AUDIT" --check bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"check_unknown"* ]]
}

@test "probe-github-project.sh: --probe 値欠落で args_invalid (exit 1)" {
  run "$PROBE" --probe
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing_value_for_option"* ]]
}

@test "probe-github-project.sh: --probe なしで args_invalid (exit 1)" {
  run "$PROBE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"probe_kind_missing"* ]]
}

@test "probe-github-project.sh: 未知 probe で args_invalid (exit 1)" {
  run "$PROBE" --probe bogus-probe
  [ "$status" -eq 1 ]
  [[ "$output" == *"probe_kind_unsupported"* ]]
}
