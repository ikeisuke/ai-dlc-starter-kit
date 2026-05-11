#!/usr/bin/env bats
# v2.6.2 Unit 004: gh-project-cli.sh ensure-fields の field options 差分同期テスト
#
# 計画書: .aidlc/cycles/v2.6.2/plans/unit-004-plan.md
# 設計書: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_004_gh_project_cli_options_sync_logical_design.md
#
# モック方針:
#   - gh モック: auth status / project field-list / api graphql の 3 動作を切替
#   - yq モック: spec.yaml -> json 変換（fixture json で固定値返却）
#   - GraphQL 呼出ログを ${BATS_TEST_TMPDIR}/gh_api_graphql_calls.log に記録（呼出回数・引数アサート用）
#   - 失敗注入: 環境変数 MOCK_GH_API_GRAPHQL_FAIL=1 で gh api graphql を exit 1

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  CLI="${REPO_ROOT}/bin/gh-project-cli.sh"
  cd "$BATS_TEST_TMPDIR"

  # AIDLC ルートとして BATS_TEST_TMPDIR を使う
  export AIDLC_REPO_ROOT="$BATS_TEST_TMPDIR"
  mkdir -p "$BATS_TEST_TMPDIR/.aidlc/cache"
  mkdir -p "$BATS_TEST_TMPDIR/config"

  # spec.yaml と fixture json（yq モック経由で読まれる）
  # デフォルト spec: Status field に options [A, B]
  cat > "$BATS_TEST_TMPDIR/config/github-project-spec.yaml" <<'YAML'
version: 1
project:
  title: TestProject
  owner: "@me"
  visibility: public
fields:
  - name: Status
    data_type: single_select
    options: [A, B]
cycle_map:
  patterns: []
  fallback: Later
views: []
YAML
  _write_spec_fixture '["A","B"]'

  # .aidlc/config.toml に runtime binding を仕込む（_read_runtime_binding 経由で読まれる）
  cat > "$BATS_TEST_TMPDIR/.aidlc/config.toml" <<'TOML'
[github_projects]
owner = "@me"
project_number = "123"
project_url = "https://github.com/users/me/projects/123"
TOML

  # gh / yq モックを配置
  MOCK_DIR="${BATS_TEST_TMPDIR}/mock-bin"
  mkdir -p "$MOCK_DIR"

  # yq モック: <file>.json があればそれを返す
  cat > "${MOCK_DIR}/yq" <<'YQMOCK'
#!/usr/bin/env bash
file="${@: -1}"
if [[ -f "$file.json" ]]; then
  cat "$file.json"
else
  echo "yq mock: fixture not found: $file.json" >&2
  exit 1
fi
YQMOCK
  chmod +x "${MOCK_DIR}/yq"

  # dasel モック: _read_runtime_binding 経由で呼ばれる。
  # 本体 gh-project-cli.sh は `dasel -f <file> <key>` 形式（dasel v2 構文）を使うが、
  # dasel v3 では `-f` フラグが廃止されているため、現環境では壊れる。
  # 本 Unit のスコープ外のため、テスト側で v2 構文を受け付けるモックで吸収する。
  cat > "${MOCK_DIR}/dasel" <<'DASELMOCK'
#!/usr/bin/env bash
# 期待呼出: dasel -f <toml> <key>  または  dasel <key> -f <toml>
file=""
key=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) file="$2"; shift 2 ;;
    -t|-v|-o|--type|--value) shift 2 ;;
    put) shift; while [[ $# -gt 0 ]] && [[ "$1" != -* ]]; do shift; done ;;
    *)  if [[ -z "$key" ]]; then key="$1"; fi; shift ;;
  esac
done
case "$key" in
  github_projects.owner) echo "@me" ;;
  github_projects.project_number) echo "123" ;;
  github_projects.project_url) echo "https://github.com/users/me/projects/123" ;;
  *) echo "" ;;
esac
DASELMOCK
  chmod +x "${MOCK_DIR}/dasel"

  # gh モック: auth status / project field-list / api graphql を切替
  cat > "${MOCK_DIR}/gh" <<'GHMOCK'
#!/usr/bin/env bash
LOG="${GH_API_GRAPHQL_CALLS_LOG:-/dev/null}"
FIELDS_FIXTURE="${GH_FIELDS_FIXTURE:-}"

case "$1" in
  auth)
    if [[ "$2" == "status" ]]; then
      cat <<EOF
github.com
  ✓ Logged in
  - Token scopes: 'project', 'read:org', 'read:project'
EOF
      exit 0
    fi
    ;;
  project)
    if [[ "$2" == "field-list" ]]; then
      if [[ -n "$FIELDS_FIXTURE" ]] && [[ -f "$FIELDS_FIXTURE" ]]; then
        cat "$FIELDS_FIXTURE"
        exit 0
      fi
      echo '{"fields":[]}'
      exit 0
    fi
    ;;
  api)
    if [[ "$2" == "graphql" ]]; then
      # GraphQL mutation の query 文字列には改行が含まれるため、
      # 呼出ログは「1 行 / 1 呼出」に正規化する（option=<name> のみを抽出して記録）。
      # 期待形式: gh api graphql ... -f fieldId=<id> -f option=<name>
      opt_pair=""
      for arg in "$@"; do
        case "$arg" in option=*) opt_pair="$arg" ;; esac
      done
      printf 'CALL graphql %s\n' "$opt_pair" >> "$LOG"
      # MOCK_GH_API_GRAPHQL_FAIL=1: 常時失敗
      # MOCK_GH_API_GRAPHQL_FAIL_ON_NTH=<N>: 累計 N 回目の呼出で失敗（部分成功テスト用）
      call_count=$(wc -l < "$LOG" | tr -d ' ')
      if [[ "${MOCK_GH_API_GRAPHQL_FAIL:-0}" == "1" ]]; then
        echo "mock: graphql failure injected" >&2
        exit 1
      fi
      if [[ -n "${MOCK_GH_API_GRAPHQL_FAIL_ON_NTH:-}" ]] && [[ "$call_count" == "${MOCK_GH_API_GRAPHQL_FAIL_ON_NTH}" ]]; then
        echo "mock: graphql nth-call failure injected (call=$call_count)" >&2
        exit 1
      fi
      echo '{"data":{"updateProjectV2Field":{"projectV2Field":{"id":"PVTSSF_xxx","name":"Status"}}}}'
      exit 0
    fi
    ;;
esac
echo "unmocked gh: $*" >&2
exit 99
GHMOCK
  chmod +x "${MOCK_DIR}/gh"

  export PATH="${MOCK_DIR}:${PATH}"
  export GH_API_GRAPHQL_CALLS_LOG="${BATS_TEST_TMPDIR}/gh_api_graphql_calls.log"
  : > "$GH_API_GRAPHQL_CALLS_LOG"

  # キャッシュをテスト毎に隔離
  export AIDLC_GH_PROJECT_CACHE_DIR="${BATS_TEST_TMPDIR}/state-cache"
  mkdir -p "$AIDLC_GH_PROJECT_CACHE_DIR"
}

teardown() {
  unset MOCK_GH_API_GRAPHQL_FAIL || true
  unset MOCK_GH_API_GRAPHQL_FAIL_ON_NTH || true
  unset GH_FIELDS_FIXTURE || true
}

# spec.yaml.json の中身を切替えるヘルパー（spec.fields[0].options を任意の JSON 配列文字列で差替え）
_write_spec_fixture() {
  local options_json="$1"
  cat > "$BATS_TEST_TMPDIR/config/github-project-spec.yaml.json" <<EOF
{"version":1,"project":{"title":"TestProject","owner":"@me","visibility":"public"},"fields":[{"name":"Status","data_type":"single_select","options":${options_json}}],"cycle_map":{"patterns":[],"fallback":"Later"},"views":[]}
EOF
}

# existing fields fixture を作成して GH_FIELDS_FIXTURE で参照させる
_set_existing_fields() {
  local options_json="$1"  # JSON 配列例: '["A","B"]'
  local fixture="${BATS_TEST_TMPDIR}/fields-existing.json"
  # name 配列から {"name": "..."} の options 配列を組み立てる
  printf '{"fields":[{"id":"PVTSSF_TEST","name":"Status","options":%s}]}\n' \
    "$(printf '%s' "$options_json" | jq -c 'map({name:.})')" > "$fixture"
  export GH_FIELDS_FIXTURE="$fixture"
}

# ==============================================================================
# Case 1: no-op（差分なし / spec == existing）
# ==============================================================================
@test "ensure-fields: spec == existing で no-op（options-added 出力なし / strict）" {
  _write_spec_fixture '["A","B"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" != *"options-added"* ]]
  [[ "$output" != *"options-would-add"* ]]
  # graphql は呼ばれない
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}

# ==============================================================================
# Case 2: 1 件追加（spec ⊋ existing / strict）
# ==============================================================================
@test "ensure-fields: 1 件追加（strict / spec={A,B} existing={A}）" {
  _write_spec_fixture '["A","B"]'
  _set_existing_fields '["A"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" == *"field:Status:options-added:1:names=B"* ]]
  # graphql 1 回
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "1" ]
  grep -q "option=B" "$GH_API_GRAPHQL_CALLS_LOG"
}

# ==============================================================================
# Case 3: 複数追加（spec - existing = 2 / strict）
# ==============================================================================
@test "ensure-fields: 複数追加（strict / spec={A,B,C} existing={A}）" {
  _write_spec_fixture '["A","B","C"]'
  _set_existing_fields '["A"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:Status:options-added:2:names=B,C"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "2" ]
  grep -q "option=B" "$GH_API_GRAPHQL_CALLS_LOG"
  grep -q "option=C" "$GH_API_GRAPHQL_CALLS_LOG"
}

# ==============================================================================
# Case 4: strict + 既存余分（fail-fast / spec ⊊ existing）
# ==============================================================================
@test "ensure-fields: strict + 既存余分 fail-fast（exit 3 / API 呼ばれず）" {
  _write_spec_fixture '["A"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 3 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" != *"options-added"* ]]
  [[ "$output" == *"options_extraneous"* ]]
  [[ "$output" == *"names=B"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}

# ==============================================================================
# Case 4-bis: strict + 双方向差分（fail-fast / 追加 API 呼ばれず）
# ==============================================================================
@test "ensure-fields: strict + 双方向差分 fail-fast（追加 API 呼ばれず exit 3）" {
  _write_spec_fixture '["A","C"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 3 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" != *"options-added"* ]]
  [[ "$output" == *"options_extraneous"* ]]
  [[ "$output" == *"names=B"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}

# ==============================================================================
# Case 5: soft + 既存余分（warn のみで exit 0）
# ==============================================================================
@test "ensure-fields: soft + 既存余分（warn 継続 exit 0）" {
  _write_spec_fixture '["A"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields --soft
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" == *"options_extraneous"* ]]
  [[ "$output" == *"names=B"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}

# ==============================================================================
# Case 6: dry-run + 追加方向差分（options-would-add / API 呼ばれない）
# ==============================================================================
@test "ensure-fields: dry-run + 追加方向差分（options-would-add / API 呼ばれない）" {
  _write_spec_fixture '["A","B"]'
  _set_existing_fields '["A"]'
  run "$CLI" ensure-fields --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" == *"field:Status:options-would-add:1:names=B"* ]]
  [[ "$output" != *"options-added"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}

# ==============================================================================
# Case 7: dry-run + 既存余分（warn のみ / exit 0）
# ==============================================================================
@test "ensure-fields: dry-run + 既存余分（warn のみ exit 0）" {
  _write_spec_fixture '["A"]'
  _set_existing_fields '["A","B"]'
  run "$CLI" ensure-fields --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Status"* ]]
  [[ "$output" == *"options_extraneous"* ]]
  [[ "$output" != *"options-would-add"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}

# ==============================================================================
# Case 8: strict + API 失敗（即 exit 3 / 部分追加なし）
# ==============================================================================
@test "ensure-fields: strict + API 失敗（部分追加なしで exit 3）" {
  _write_spec_fixture '["A","B"]'
  _set_existing_fields '["A"]'
  export MOCK_GH_API_GRAPHQL_FAIL=1
  run "$CLI" ensure-fields
  [ "$status" -eq 3 ]
  [[ "$output" == *"gh_api_error"* ]]
  [[ "$output" == *"options_add_failed"* ]]
  # 1 件目で失敗 → fail-fast、追加成功 0 件のため options-added 出力なし
  [[ "$output" != *"options-added"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "1" ]
}

# ==============================================================================
# Case 9: soft + API 失敗（warn 継続 / exit 0）
# ==============================================================================
@test "ensure-fields: soft + API 失敗（warn 継続 exit 0）" {
  _write_spec_fixture '["A","B","C"]'
  _set_existing_fields '["A"]'
  export MOCK_GH_API_GRAPHQL_FAIL=1
  run "$CLI" ensure-fields --soft
  [ "$status" -eq 0 ]
  [[ "$output" == *"gh_api_error"* ]]
  [[ "$output" == *"options_add_failed"* ]]
  # 2 件すべて失敗 → graphql は 2 回呼ばれ、すべて warn 継続
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "2" ]
}

# ==============================================================================
# Case 9-bis: strict + 部分成功後失敗（1 件成功 → 2 件目失敗で exit 3）
# コード R1 指摘 #3 反映: 部分追加の可観測性を回帰させない
# ==============================================================================
@test "ensure-fields: strict + 部分成功後失敗（options-added:1:names=B 出力 + exit 3）" {
  _write_spec_fixture '["A","B","C"]'
  _set_existing_fields '["A"]'
  # 1 回目: project field-list（spec 取得後の存在確認に該当しない経路）/ 実際は graphql 呼出が API 失敗対象
  # _sync_field_options 内のループは to_add 順（spec - existing = [B, C]）
  # 累計 graphql call: 1 回目=option=B → 成功 / 2 回目=option=C → 失敗
  export MOCK_GH_API_GRAPHQL_FAIL_ON_NTH=2
  run "$CLI" ensure-fields
  [ "$status" -eq 3 ]
  # B は追加成功 → stdout に options-added:1:names=B
  [[ "$output" == *"field:Status:options-added:1:names=B"* ]]
  # C 失敗 → stderr に gh_api_error JSON
  [[ "$output" == *"gh_api_error"* ]]
  [[ "$output" == *"option=C"* ]]
  # graphql は 2 回呼ばれた（B 成功 + C 失敗）
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "2" ]
}

# ==============================================================================
# Case 10: option 名サニタイズ（制御文字 / カンマ含むと args_invalid + exit 1）
# コード R1 指摘 #1 反映: stdout ログ注入対策
# ==============================================================================
@test "ensure-fields: spec.options 内のカンマ含む option 名で args_invalid (exit 1)" {
  # spec.options に "A,B"（カンマ含む）を入れる
  _write_spec_fixture '["A,B","C"]'
  _set_existing_fields '["C"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 1 ]
  [[ "$output" == *"options_name_unsafe_chars"* ]]
  [[ "$output" == *"source=spec"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}

@test "ensure-fields: existing options 内の改行含む option 名で args_invalid (exit 1)" {
  _write_spec_fixture '["A"]'
  _set_existing_fields '["A","Bad\nName"]'
  run "$CLI" ensure-fields
  [ "$status" -eq 1 ]
  [[ "$output" == *"options_name_unsafe_chars"* ]]
  [[ "$output" == *"source=existing"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}

# ==============================================================================
# Case 11: dynamic field のスキップ（差分同期は呼ばれない）
# ==============================================================================
@test "ensure-fields: dynamic field（cycle）の差分同期はスキップ" {
  # spec.fields[0].options を "dynamic" 文字列に
  cat > "$BATS_TEST_TMPDIR/config/github-project-spec.yaml.json" <<'EOF'
{"version":1,"project":{"title":"TestProject","owner":"@me","visibility":"public"},"fields":[{"name":"Cycle","data_type":"single_select","options":"dynamic"}],"cycle_map":{"patterns":[],"fallback":"Later"},"views":[]}
EOF
  # existing: Cycle field が既に存在し options に旧 milestone を持つ
  local fixture="${BATS_TEST_TMPDIR}/fields-existing.json"
  cat > "$fixture" <<'EOF'
{"fields":[{"id":"PVTSSF_CYC","name":"Cycle","options":[{"name":"Later"},{"name":"v1.0.0"}]}]}
EOF
  export GH_FIELDS_FIXTURE="$fixture"
  run "$CLI" ensure-fields
  [ "$status" -eq 0 ]
  [[ "$output" == *"field:exists:Cycle"* ]]
  # dynamic はスキップ → options-added / options-would-add / extraneous いずれも出力なし
  [[ "$output" != *"options-added"* ]]
  [[ "$output" != *"options-would-add"* ]]
  [[ "$output" != *"options_extraneous"* ]]
  [ "$(wc -l < "$GH_API_GRAPHQL_CALLS_LOG" | tr -d ' ')" = "0" ]
}
