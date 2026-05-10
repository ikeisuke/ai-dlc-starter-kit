#!/usr/bin/env bats
# bin/lib/gh-scope-check.sh の strict/soft / 引数検証 / JSON エスケープテスト
#
# モック方針:
#   - gh コマンドを mock 関数で差し替え（gh auth status 出力を制御）

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  SCRIPT="${REPO_ROOT}/bin/lib/gh-scope-check.sh"
  cd "$BATS_TEST_TMPDIR"
  # gh モック PATH 用ディレクトリ
  MOCK_DIR="${BATS_TEST_TMPDIR}/mock-bin"
  mkdir -p "$MOCK_DIR"
  export PATH="${MOCK_DIR}:${PATH}"
  # cache を BATS_TEST_TMPDIR に隔離
  export AIDLC_REPO_ROOT="$BATS_TEST_TMPDIR"
  mkdir -p "$BATS_TEST_TMPDIR/.aidlc/cache"
}

teardown() {
  cd "$BATS_TEST_TMPDIR"
}

# gh モック: 与えられた scopes でレスポンス
_mock_gh_with_scopes() {
  local scopes="$1"
  cat > "${MOCK_DIR}/gh" <<MOCK
#!/usr/bin/env bash
if [[ "\$1" == "auth" ]] && [[ "\$2" == "status" ]]; then
  cat <<EOF
github.com
  ✓ Logged in to github.com
  - Token scopes: ${scopes}
EOF
  exit 0
fi
echo "unmocked: \$@" >&2; exit 99
MOCK
  chmod +x "${MOCK_DIR}/gh"
}

@test "gh_scope_check_require: 引数なしで args_invalid (exit 1)" {
  _mock_gh_with_scopes "'project'"
  run "$SCRIPT" --strict
  [ "$status" -eq 1 ]
  [[ "$output" == *"required_scopes_empty"* ]] || [[ "$output" == *"args_invalid"* ]]
}

@test "gh_scope_check_require: 全スコープ充足で exit 0" {
  _mock_gh_with_scopes "'project', 'read:org', 'read:project'"
  run "$SCRIPT" --strict project read:org read:project
  [ "$status" -eq 0 ]
}

@test "gh_scope_check_require: strict モード + スコープ不足で exit 2 + scope_missing JSON" {
  _mock_gh_with_scopes "'project'"
  run "$SCRIPT" --strict project read:org
  [ "$status" -eq 2 ]
  [[ "$output" == *"scope_missing"* ]]
  [[ "$output" == *"read:org"* ]]
}

@test "gh_scope_check_require: soft モード + スコープ不足で exit 0 + warn" {
  _mock_gh_with_scopes "'project'"
  run "$SCRIPT" --soft project read:org
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN"* ]] || [[ "$output" == *"missing"* ]]
}

@test "gh_scope_check_require: soft モード時 cache に scope_missing が記録される" {
  _mock_gh_with_scopes "'project'"
  run "$SCRIPT" --soft project read:org
  [ "$status" -eq 0 ]
  [ -f "${AIDLC_REPO_ROOT}/.aidlc/cache/gh-project-last-run.json" ]
  cat "${AIDLC_REPO_ROOT}/.aidlc/cache/gh-project-last-run.json" | grep -q "scope_missing"
}

@test "gh_scope_check_require: details に JSON 注入文字を含む scope 名でも JSON 破損しない" {
  _mock_gh_with_scopes "'project'"
  run "$SCRIPT" --strict 'malicious"; echo INJECTED'
  [ "$status" -eq 2 ]
  # jq エスケープにより JSON が valid であること（jq -n は pretty-print 出力 /改行を含む）
  [[ "$output" == *'"error_type"'* ]]
  [[ "$output" == *'"scope_missing"'* ]]
  # INJECTED 文字列がコマンド実行されていないこと（stderr に literal で含まれる）
  [[ "$output" == *"INJECTED"* ]]
  # output 自身が valid JSON 部分を含むことを jq でパースして確認
  json_part="$(echo "$output" | sed -n '/^{/,/^}/p')"
  echo "$json_part" | jq -e . >/dev/null
}
