#!/usr/bin/env bats
# Unit 003: retrospective-verify.sh CLI テスト
# Plan / Logical Design §「retrospective-verify.sh」を verify する。
#
# gh コマンドはモック shim で挙動制御:
#   GH_MOCK_API_MILESTONES=<json>     - gh api milestones の出力
#   GH_MOCK_LIST_RESULT=<json>        - gh issue list の出力 JSON
#   GH_MOCK_API_FAIL=1                - gh api を失敗させる
#   GH_MOCK_LIST_FAIL=1               - gh issue list を失敗させる

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  VERIFY_CLI="${REPO_ROOT}/skills/aidlc/scripts/retrospective-verify.sh"
  TMP="$(mktemp -d -t aidlc-retro-verify.XXXXXX)"
  SHIM_DIR="$TMP/shim"
  mkdir -p "$SHIM_DIR"

  # gh shim
  cat > "$SHIM_DIR/gh" <<'SHIM'
#!/usr/bin/env bash
case "$1" in
  api)
    if [[ "${GH_MOCK_API_FAIL:-}" == "1" ]]; then
      echo "mock api failed" >&2
      exit 1
    fi
    # milestones?state=all → milestone 検証用 / milestones?state=open → cycle 自動解決用
    # GH_MOCK_API_MILESTONES の互換解釈:
    #   "0" → 空配列 [] / "1" → cycle 名で 1 件入った配列 / それ以外 → そのまま JSON として透過
    if [[ "$2" == *"milestones"* ]]; then
      case "${GH_MOCK_API_MILESTONES:-0}" in
        0) printf '%s\n' "[]" ;;
        1) printf '[{"title": "%s", "number": 1, "created_at": "2026-05-05T00:00:00Z"}]\n' "${GH_MOCK_CYCLE:-v2.5.1}" ;;
        *) printf '%s\n' "${GH_MOCK_API_MILESTONES}" ;;
      esac
      exit 0
    fi
    exit 0
    ;;
  issue)
    if [[ "$2" == "list" ]]; then
      if [[ "${GH_MOCK_LIST_FAIL:-}" == "1" ]]; then
        echo "mock list failed" >&2
        exit 1
      fi
      printf '%s\n' "${GH_MOCK_LIST_RESULT:-[]}"
      exit 0
    fi
    ;;
esac
exit 0
SHIM
  chmod +x "$SHIM_DIR/gh"
  PATH="$SHIM_DIR:$PATH"
  export PATH
}

teardown() {
  rm -rf "$TMP"
}

# ─── サンプル Issue body（末尾 ```yaml フェンスあり / human_reviewed: true）─────
make_verified_body() {
  cat <<'EOF'
# Retrospective: v2.5.1

## メタデータ

```yaml
skill_caused_judgment:
  q1_answer: "yes"
mirror_state:
  state: "created"
human_reviewed: true
```
EOF
}

make_unverified_body() {
  cat <<'EOF'
# Retrospective: v2.5.1

## メタデータ

```yaml
skill_caused_judgment:
  q1_answer: "yes"
mirror_state:
  state: "created"
human_reviewed: false
```
EOF
}

make_body_no_yaml() {
  printf '# Retrospective v2.5.0 (legacy)\n\nKPT only, no YAML block\n'
}

make_body_no_human_reviewed_key() {
  cat <<'EOF'
# Retrospective: v2.5.1

## メタデータ

```yaml
skill_caused_judgment:
  q1_answer: "yes"
mirror_state:
  state: "created"
```
EOF
}

# 本文上部に misleading な human_reviewed: true 行があるが末尾 YAML フェンスは false のケース
make_body_misleading_marker() {
  cat <<'EOF'
# Retrospective: v2.5.1

human_reviewed: true (この記述は説明文 / 検証対象外であるべき)

## メタデータ

```yaml
skill_caused_judgment:
  q1_answer: "yes"
mirror_state:
  state: "created"
human_reviewed: false
```
EOF
}

# JSON エンコード（jq -Rs）して issue list 形式にする
make_issue_list_json() {
  # $1=number, $2=title, $3=body
  printf '%s' "$3" | jq -Rs --arg n "$1" --arg t "$2" '{number: ($n|tonumber), title: $t, body: .}'
}

# ─── V1: 全件 verified で exit 0 ─────
@test "V1: 全件 human_reviewed: true で exit 0" {
  GH_MOCK_API_MILESTONES="1"
  local body
  body=$(make_verified_body)
  local item1
  item1=$(make_issue_list_json 100 "Retrospective: v2.5.1" "$body")
  GH_MOCK_LIST_RESULT="[$item1]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run "$VERIFY_CLI" --cycle "v2.5.1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"verified"* ]]
}

# ─── V2: 1 件 unverified で exit 1 ─────
@test "V2: 1 件 human_reviewed: false で exit 1" {
  GH_MOCK_API_MILESTONES="1"
  local body
  body=$(make_unverified_body)
  local item1
  item1=$(make_issue_list_json 101 "Retrospective: v2.5.1" "$body")
  GH_MOCK_LIST_RESULT="[$item1]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run "$VERIFY_CLI" --cycle "v2.5.1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unverified"* ]]
}

# ─── V3: YAML ブロックなし → skipped / exit 0（--strict なし）─────
@test "V3: 旧仕様 Issue（YAML ブロックなし）で skipped / exit 0" {
  GH_MOCK_API_MILESTONES="1"
  local body
  body=$(make_body_no_yaml)
  local item1
  item1=$(make_issue_list_json 102 "Retrospective: v2.5.0 (legacy)" "$body")
  GH_MOCK_LIST_RESULT="[$item1]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run "$VERIFY_CLI" --cycle "v2.5.1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped"* ]]
}

# ─── V4: --strict 時の skipped で exit 1 ─────
@test "V4: --strict + skipped 1 件で exit 1" {
  GH_MOCK_API_MILESTONES="1"
  local body
  body=$(make_body_no_yaml)
  local item1
  item1=$(make_issue_list_json 102 "Retrospective: v2.5.0 (legacy)" "$body")
  GH_MOCK_LIST_RESULT="[$item1]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run "$VERIFY_CLI" --cycle "v2.5.1" --strict
  [ "$status" -eq 1 ]
}

# ─── V5: --dry-run 動作 ─────
@test "V5: --dry-run で stdout レポートが出る / 副作用なし" {
  GH_MOCK_API_MILESTONES="1"
  local body
  body=$(make_verified_body)
  local item1
  item1=$(make_issue_list_json 100 "Retrospective: v2.5.1" "$body")
  GH_MOCK_LIST_RESULT="[$item1]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run "$VERIFY_CLI" --cycle "v2.5.1" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"summary"* ]]
}

# ─── V6: gh 不可で exit 1 ─────
@test "V6: gh api 失敗で exit 1" {
  GH_MOCK_API_FAIL=1
  export GH_MOCK_API_FAIL

  run "$VERIFY_CLI" --cycle "v2.5.1"
  [ "$status" -eq 1 ]
}

# ─── V7: Milestone 不在で exit 1 ─────
@test "V7: Milestone 数 0 で exit 1" {
  GH_MOCK_API_MILESTONES="0"
  export GH_MOCK_API_MILESTONES

  run "$VERIFY_CLI" --cycle "v9.9.9"
  [ "$status" -eq 1 ]
}

# ─── V8a: --cycle 未指定 / 最新 open Milestone あり / 該当 Issue 0 件 → exit 0 ─────
@test "V8a: --cycle 未指定 + 最新 open Milestone あり / Issue 0 件で exit 0" {
  GH_MOCK_API_MILESTONES='[{"title": "v2.5.1", "number": 1, "created_at": "2026-05-05T00:00:00Z"}]'
  GH_MOCK_LIST_RESULT="[]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run "$VERIFY_CLI"
  [ "$status" -eq 0 ]
  [[ "$output" == *"summary"* ]]
}

# ─── V8b: --cycle 未指定 / 最新 open Milestone なし → cycle 未解決で exit 1 ─────
@test "V8b: --cycle 未指定 + 最新 Milestone なしで cycle 未解決 / exit 1" {
  GH_MOCK_API_MILESTONES='[]'
  export GH_MOCK_API_MILESTONES

  run "$VERIFY_CLI"
  [ "$status" -eq 1 ]
}

# ─── V9 / V10 はカスタム環境構築が必要で V8 と一部重複するため V11/V12/V13 へ ─────

# ─── V11: --help は exit 0 ─────
@test "V11: --help でusage 表示 / exit 0" {
  run "$VERIFY_CLI" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"USAGE"* ]] || [[ "$output" == *"OPTIONS"* ]]
}

# ─── V12: YAML 存在 + human_reviewed キー欠落で unverified ─────
@test "V12: YAML ブロックあり + human_reviewed キー欠落で unverified / exit 1" {
  GH_MOCK_API_MILESTONES="1"
  local body
  body=$(make_body_no_human_reviewed_key)
  local item1
  item1=$(make_issue_list_json 103 "Retrospective: v2.5.1" "$body")
  GH_MOCK_LIST_RESULT="[$item1]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run "$VERIFY_CLI" --cycle "v2.5.1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unverified"* ]]
}

# ─── V14: 不正なオプションで exit 2 ─────
@test "V14: 未知のオプションで exit 2" {
  run "$VERIFY_CLI" --invalid-option
  [ "$status" -eq 2 ]
}

# ─── V15: --cycle なしで値必須エラー / exit 2 ─────
@test "V15: --cycle に値なしで exit 2" {
  run "$VERIFY_CLI" --cycle
  [ "$status" -eq 2 ]
}

# ─── V16: YAML パース失敗時は warn + unverified（yq ある時のみ） ─────
make_body_with_broken_yaml() {
  cat <<'EOF'
# Retrospective: v2.5.1

## メタデータ

```yaml
skill_caused_judgment:
  q1_answer: "yes"
mirror_state:
  state: "created
human_reviewed: false
```
EOF
}

@test "V16: 末尾 YAML パース失敗時は warn + unverified（yq 利用可能時）" {
  if ! command -v yq >/dev/null 2>&1; then
    skip "yq 不在"
  fi

  GH_MOCK_API_MILESTONES="1"
  local body
  body=$(make_body_with_broken_yaml)
  local item1
  item1=$(make_issue_list_json 200 "Retrospective: v2.5.1" "$body")
  GH_MOCK_LIST_RESULT="[$item1]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run --separate-stderr "$VERIFY_CLI" --cycle "v2.5.1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unverified"* ]]
  [[ "$stderr" == *"verify_yaml_parse_failed"* ]]
}

# ─── V17: 本文上部に misleading な human_reviewed: true があるが末尾 YAML が false → unverified ─────
@test "V17: 本文上部のダミー human_reviewed 行は無視され末尾 YAML フェンス内のみ有効" {
  GH_MOCK_API_MILESTONES="1"
  local body
  body=$(make_body_misleading_marker)
  local item1
  item1=$(make_issue_list_json 300 "Retrospective: v2.5.1" "$body")
  GH_MOCK_LIST_RESULT="[$item1]"
  export GH_MOCK_API_MILESTONES GH_MOCK_LIST_RESULT

  run "$VERIFY_CLI" --cycle "v2.5.1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unverified"* ]]
}
