#!/usr/bin/env bats
# bin/lib/gh-project-spec.sh の load / validate / resolve_cycle テスト
#
# モック方針:
#   - yq が無い環境用に専用 mock yq を PATH に置く
#   - 実 spec.yaml は fixture を使う

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  SCRIPT="${REPO_ROOT}/bin/lib/gh-project-spec.sh"
  cd "$BATS_TEST_TMPDIR"
  MOCK_DIR="${BATS_TEST_TMPDIR}/mock-bin"
  mkdir -p "$MOCK_DIR"
  # yq モック: yaml -> json (jq -R -s で擬装は難しいので、固定 fixture json を返す)
  cat > "${MOCK_DIR}/yq" <<'MOCK'
#!/usr/bin/env bash
# 簡易モック: 実装は jq を使った fixture 返却
# 引数が "-o=json" / "eval" / "." / file の形式を想定
file="${@: -1}"
if [[ -f "$file.json" ]]; then
  cat "$file.json"
elif [[ -f "$file" ]]; then
  # yq 本物が PATH にある場合は本物を呼ぶ
  REAL_YQ="$(command -v -p /usr/bin:/usr/local/bin:/opt/homebrew/bin yq 2>/dev/null || true)"
  if [[ -n "$REAL_YQ" ]] && [[ "$REAL_YQ" != "$(realpath "$0")" ]]; then
    "$REAL_YQ" "$@"
  else
    # fallback: minimal valid spec JSON
    echo '{"version":1,"project":{"title":"X","owner":"@me","visibility":"public"},"fields":[{"name":"Status","data_type":"single_select"}],"cycle_map":{"patterns":[],"fallback":"Later"},"views":[]}'
  fi
else
  echo "yq mock: file not found: $file" >&2
  exit 1
fi
MOCK
  chmod +x "${MOCK_DIR}/yq"
  export PATH="${MOCK_DIR}:${PATH}"
}

teardown() {
  cd "$BATS_TEST_TMPDIR"
}

@test "spec_load: ファイル不在で spec_invalid (exit 4)" {
  run "$SCRIPT" load /nonexistent/path/spec.yaml
  [ "$status" -eq 4 ]
  [[ "$output" == *"file_not_found"* ]] || [[ "$output" == *"spec_invalid"* ]]
}

@test "spec_load: 引数 path 欠落で args_invalid (exit 1)" {
  run "$SCRIPT" load
  [ "$status" -eq 1 ]
  [[ "$output" == *"args_invalid"* ]]
}

@test "spec_load: fixture json を介して valid spec を読み込める" {
  # fixture: spec.yaml に対応する spec.yaml.json を用意
  cat > "${BATS_TEST_TMPDIR}/spec.yaml.json" <<'EOF'
{"version":1,"project":{"title":"X","owner":"@me","visibility":"public"},"fields":[{"name":"Status","data_type":"single_select"}],"cycle_map":{"patterns":[],"fallback":"Later"},"views":[]}
EOF
  touch "${BATS_TEST_TMPDIR}/spec.yaml"
  run "$SCRIPT" load "${BATS_TEST_TMPDIR}/spec.yaml"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.project.title=="X"' >/dev/null
}

@test "spec_validate: project.title 欠落で spec_invalid (exit 4)" {
  spec='{"version":1,"project":{"owner":"@me","visibility":"public"},"fields":[{"name":"Status"}],"cycle_map":{"fallback":"Later"}}'
  run "$SCRIPT" validate "$spec"
  [ "$status" -eq 4 ]
  [[ "$output" == *"project_title_missing"* ]]
}

@test "spec_validate: visibility 不正で spec_invalid (exit 4)" {
  spec='{"version":1,"project":{"title":"X","owner":"@me","visibility":"hidden"},"fields":[{"name":"Status"}],"cycle_map":{"fallback":"Later"}}'
  run "$SCRIPT" validate "$spec"
  [ "$status" -eq 4 ]
  [[ "$output" == *"project_visibility_invalid"* ]]
}

@test "spec_validate: cycle_map.fallback 欠落で spec_invalid" {
  spec='{"version":1,"project":{"title":"X","owner":"@me","visibility":"public"},"fields":[{"name":"Status"}],"cycle_map":{}}'
  run "$SCRIPT" validate "$spec"
  [ "$status" -eq 4 ]
  [[ "$output" == *"cycle_map_fallback_missing"* ]]
}

@test "spec_validate: 正常 spec で exit 0" {
  spec='{"version":1,"project":{"title":"X","owner":"@me","visibility":"public"},"fields":[{"name":"Status"}],"cycle_map":{"fallback":"Later"},"views":[]}'
  run "$SCRIPT" validate "$spec"
  [ "$status" -eq 0 ]
}

@test "spec_resolve_cycle: パターンマッチ時に <milestone-title> を展開" {
  # bash → bash の escape を避けるため、`.` の代わりに `[.]` 文字クラスを使用
  spec='{"cycle_map":{"patterns":[{"milestone_pattern":"^v[0-9]+[.][0-9]+[.][0-9]+$","cycle_label":"<milestone-title>"}],"fallback":"Later"}}'
  run "$SCRIPT" resolve-cycle "$spec" "v2.6.0"
  [ "$status" -eq 0 ]
  [ "$output" = "v2.6.0" ]
}

@test "spec_resolve_cycle: マッチしない場合は fallback を返す" {
  spec='{"cycle_map":{"patterns":[{"milestone_pattern":"^v[0-9]+[.][0-9]+[.][0-9]+$","cycle_label":"<milestone-title>"}],"fallback":"Later"}}'
  run "$SCRIPT" resolve-cycle "$spec" "next-release"
  [ "$status" -eq 0 ]
  [ "$output" = "Later" ]
}

@test "spec_resolve_cycle: milestone 空で fallback を返す" {
  spec='{"cycle_map":{"patterns":[],"fallback":"Later"}}'
  run "$SCRIPT" resolve-cycle "$spec" ""
  [ "$status" -eq 0 ]
  [ "$output" = "Later" ]
}
