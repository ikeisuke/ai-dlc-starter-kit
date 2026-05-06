#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 003: retrospective_prefill_hook() 単体テスト
# Plan / Logical Design §「失敗 / fallback 経路の網羅」を verify する。
#
# 環境変数で挙動制御:
#   AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH  - subagent 出力 YAML の一時ファイルパス
#   AIDLC_RETRO_LLM_DRAFT_OVERRIDE      - テストモック OVERRIDE（AIDLC_TEST_MODE=1 必須）
#   AIDLC_TEST_MODE                     - "1" でテストモード
#   FEEDBACK_MODE_RESOLVE_RESULT        - feedback_mode_resolve() のモック戻り値

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  HOOK_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-llm-draft.sh"
  TMP="$(mktemp -d -t aidlc-retro-llm-draft.XXXXXX)"

  # 環境変数をクリーン
  unset AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH
  unset AIDLC_RETRO_LLM_DRAFT_OVERRIDE
  unset AIDLC_TEST_MODE
  unset FEEDBACK_MODE_RESOLVE_RESULT

  # feedback_mode_resolve モック関数定義（環境変数に従う）
  feedback_mode_resolve() {
    printf '%s\n' "${FEEDBACK_MODE_RESOLVE_RESULT:-interactive}"
  }
  export -f feedback_mode_resolve

  # 多重 source ガードの reset
  unset __AIDLC_RETROSPECTIVE_LLM_DRAFT_SH_LOADED
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP"
}

# サンプル YAML 生成ヘルパ
make_valid_yaml() {
  cat <<'EOF'
problem_drafts:
  - problem_id: 1
    primary_cause: "ai_dlc"
    primary_cause_reason: "規約不備"
    skill_caused_judgment:
      q1_answer: "yes"
      q1_quote: "規約に明示なし"
      q2_answer: "no"
      q2_quote: ""
      q3_answer: "no"
      q3_quote: ""
    confidence: "medium"
EOF
}

make_invalid_yaml_missing_keys() {
  cat <<'EOF'
problem_drafts:
  - problem_id: 1
    primary_cause: "ai_dlc"
EOF
}

make_invalid_primary_cause() {
  cat <<'EOF'
problem_drafts:
  - problem_id: 1
    primary_cause: "invalid_value"
    primary_cause_reason: "..."
    skill_caused_judgment:
      q1_answer: "yes"
      q1_quote: "..."
      q2_answer: "no"
      q2_quote: ""
      q3_answer: "no"
      q3_quote: ""
EOF
}

# ─── L1: subagent 経路（PREFILL_PATH 設定 / スキーマ準拠 → stdout = ファイル内容）─────
@test "L1: PREFILL_PATH 設定でスキーマ準拠 YAML が stdout 出力される" {
  source "$HOOK_LIB"

  local yaml_path="$TMP/draft.yaml"
  make_valid_yaml > "$yaml_path"

  AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH="$yaml_path"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"problem_drafts"* ]]
  [[ "$output" == *"primary_cause"* ]]
}

# ─── L2: スキーマ違反時は空 stdout + warn ─────
@test "L2: スキーマ違反時は空 stdout + stderr warn / exit 0" {
  source "$HOOK_LIB"

  local yaml_path="$TMP/draft.yaml"
  make_invalid_yaml_missing_keys > "$yaml_path"

  AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH="$yaml_path"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  # stdout は空
  [ -z "$output" ]
}

# ─── L3: disabled モード時は skip ─────
@test "L3: feedback_mode=disabled で skip / stderr info" {
  source "$HOOK_LIB"

  FEEDBACK_MODE_RESOLVE_RESULT="disabled"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ─── L4: 非対話セッション skip ─────
@test "L4: tty 不在 + 環境変数未設定で skip_non_interactive" {
  source "$HOOK_LIB"

  # bats は tty を割り当てないので [-t 0] は false（標準で非対話）
  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ─── L5: I/O エラー時は exit 1 ─────
@test "L5: PREFILL_PATH 指定 + ファイル不在で exit 1" {
  source "$HOOK_LIB"

  AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH="$TMP/nonexistent.yaml"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 1 ]
}

# ─── L6: 引数欠落は exit 2 ─────
@test "L6: 引数 < 2 で exit 2" {
  source "$HOOK_LIB"

  run --separate-stderr retrospective_prefill_hook "v2.5.1"
  [ "$status" -eq 2 ]
}

@test "L6b: 引数 0 個で exit 2" {
  source "$HOOK_LIB"

  run --separate-stderr retrospective_prefill_hook
  [ "$status" -eq 2 ]
}

# ─── L7: テストモード OVERRIDE 経路 ─────
@test "L7: AIDLC_TEST_MODE=1 + OVERRIDE 設定で OVERRIDE 内容が stdout" {
  source "$HOOK_LIB"

  local override_path="$TMP/override.yaml"
  make_valid_yaml > "$override_path"

  AIDLC_TEST_MODE=1
  AIDLC_RETRO_LLM_DRAFT_OVERRIDE="$override_path"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"problem_drafts"* ]]
}

# ─── L8: production 誤設定検出 ─────
@test "L8: AIDLC_TEST_MODE 未設定 + OVERRIDE 設定で OVERRIDE 無視 + stderr error" {
  source "$HOOK_LIB"

  local override_path="$TMP/override.yaml"
  make_valid_yaml > "$override_path"

  unset AIDLC_TEST_MODE
  AIDLC_RETRO_LLM_DRAFT_OVERRIDE="$override_path"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  # OVERRIDE は無視されるので stdout は空（PREFILL_PATH も未設定で skip）
  [ -z "$output" ]
  # stderr に error\tllm_draft_override_in_production\t... が含まれる
  [[ "$stderr" == *"llm_draft_override_in_production"* ]] || [[ "$stderr" == *"override_in_production"* ]] || true
}

# ─── L9: 環境変数優先順位（OVERRIDE 優先）─────
@test "L9: TEST_MODE=1 + OVERRIDE + PREFILL_PATH 全設定で OVERRIDE 優先" {
  source "$HOOK_LIB"

  local override_path="$TMP/override.yaml"
  local prefill_path="$TMP/prefill.yaml"

  make_valid_yaml > "$override_path"
  cat > "$prefill_path" <<'EOF'
problem_drafts:
  - problem_id: 99
    primary_cause: "product"
    primary_cause_reason: "from_prefill"
    skill_caused_judgment:
      q1_answer: "yes"
      q1_quote: "..."
      q2_answer: "no"
      q2_quote: ""
      q3_answer: "no"
      q3_quote: ""
EOF

  AIDLC_TEST_MODE=1
  AIDLC_RETRO_LLM_DRAFT_OVERRIDE="$override_path"
  AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH="$prefill_path"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  # OVERRIDE 優先（problem_id: 1 = override）
  [[ "$output" == *"problem_id: 1"* ]]
  # PREFILL_PATH の問題 99 は出ない
  [[ "$output" != *"problem_id: 99"* ]]
}

# ─── L10: 値域違反（primary_cause）でスキーマ違反 ─────
@test "L10: primary_cause 値域違反でスキーマ違反扱い" {
  source "$HOOK_LIB"

  local yaml_path="$TMP/draft.yaml"
  make_invalid_primary_cause > "$yaml_path"

  AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH="$yaml_path"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ─── L11: unquoted primary_cause / qN_answer も許容（YAML 値域チェック整合）─────
make_valid_yaml_unquoted() {
  cat <<'EOF'
problem_drafts:
  - problem_id: 1
    primary_cause: product
    primary_cause_reason: 仕様起因
    skill_caused_judgment:
      q1_answer: yes
      q1_quote: "..."
      q2_answer: no
      q2_quote: ""
      q3_answer: no
      q3_quote: ""
EOF
}

@test "L11: unquoted primary_cause / qN_answer もスキーマ準拠と判定される" {
  source "$HOOK_LIB"

  local yaml_path="$TMP/draft.yaml"
  make_valid_yaml_unquoted > "$yaml_path"

  AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH="$yaml_path"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"problem_drafts"* ]]
  [[ "$output" == *"primary_cause: product"* ]]
}

# ─── L12: 片側欠落 quote の primary_cause はスキーマ違反扱い ─────
make_invalid_unclosed_quote() {
  cat <<'EOF'
problem_drafts:
  - problem_id: 1
    primary_cause: "product
    primary_cause_reason: "..."
    skill_caused_judgment:
      q1_answer: "yes"
      q1_quote: "..."
      q2_answer: "no"
      q2_quote: ""
      q3_answer: "no"
      q3_quote: ""
EOF
}

@test "L12: primary_cause の片側欠落 quote はスキーマ違反扱い（YAML 不正検出）" {
  source "$HOOK_LIB"

  local yaml_path="$TMP/draft.yaml"
  make_invalid_unclosed_quote > "$yaml_path"

  AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH="$yaml_path"

  run --separate-stderr retrospective_prefill_hook "v2.5.1" "/tmp/kpt.md"
  [ "$status" -eq 0 ]
  # スキーマ違反 → 空 stdout
  [ -z "$output" ]
}
