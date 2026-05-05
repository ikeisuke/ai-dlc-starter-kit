#!/usr/bin/env bats
# Unit 002: retrospective_body_compose() 単体テスト
# Plan §「retrospective_body_compose() 入出力契約」/ Logical Design §「Pure / I/O 二層」を verify する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  RETRO_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-issue.sh"
  TMP="$(mktemp -d -t aidlc-retro-body-compose.XXXXXX)"
}

teardown() {
  rm -rf "$TMP"
}

@test "compose: 空 draft + 空 KPT + 正常 cycle → ヘッダ + 問題なしブロック + メタデータ" {
  printf '' > "$TMP/draft.yml"
  printf '' > "$TMP/kpt.md"
  run bash -c "source '$RETRO_LIB' && retrospective_body_compose '$TMP/draft.yml' '$TMP/kpt.md' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"# Retrospective: v2.5.1"* ]]
  [[ "$output" == *"## 問題項目（Problem）"* ]]
  [[ "$output" == *"### 問題なし"* ]]
  [[ "$output" == *"mirror_state:"* ]]
  [[ "$output" == *"human_reviewed: false"* ]]
}

@test "compose: KPT 本文があれば本文に展開される" {
  printf '## Keep\n\n- ok\n' > "$TMP/kpt.md"
  printf '' > "$TMP/draft.yml"
  run bash -c "source '$RETRO_LIB' && retrospective_body_compose '$TMP/draft.yml' '$TMP/kpt.md' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Keep"* ]]
  [[ "$output" == *"- ok"* ]]
}

@test "compose: draft に problem_drafts があれば Problem セクションを生成" {
  cat > "$TMP/draft.yml" <<'EOF'
problem_drafts:
  - problem_id: "P-001"
    primary_cause: "product"
    primary_cause_reason: "テスト用の理由"
    skill_caused_judgment:
      q1_answer: "no"
      q1_quote: ""
      q2_answer: "no"
      q2_quote: ""
      q3_answer: "no"
      q3_quote: ""
    confidence: "high"
EOF
  printf '' > "$TMP/kpt.md"
  run bash -c "source '$RETRO_LIB' && retrospective_body_compose '$TMP/draft.yml' '$TMP/kpt.md' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### 問題 P-001"* ]]
  [[ "$output" == *"テスト用の理由"* ]]
  [[ "$output" == *"プロダクト固有"* ]]
}

@test "compose: cycle が空文字 → exit 2" {
  printf '' > "$TMP/draft.yml"
  printf '' > "$TMP/kpt.md"
  run bash -c "source '$RETRO_LIB' && retrospective_body_compose '$TMP/draft.yml' '$TMP/kpt.md' ''"
  [ "$status" -eq 2 ]
}

@test "compose: cycle に path traversal → exit 2" {
  printf '' > "$TMP/draft.yml"
  printf '' > "$TMP/kpt.md"
  run bash -c "source '$RETRO_LIB' && retrospective_body_compose '$TMP/draft.yml' '$TMP/kpt.md' '../etc'"
  [ "$status" -eq 2 ]
}

@test "compose: cycle に / 含む → exit 2" {
  printf '' > "$TMP/draft.yml"
  printf '' > "$TMP/kpt.md"
  run bash -c "source '$RETRO_LIB' && retrospective_body_compose '$TMP/draft.yml' '$TMP/kpt.md' 'a/b'"
  [ "$status" -eq 2 ]
}

@test "compose: 引数不足 → exit 2" {
  run bash -c "source '$RETRO_LIB' && retrospective_body_compose '$TMP/draft.yml' '$TMP/kpt.md'"
  [ "$status" -eq 2 ]
}

@test "compose: draft / KPT が存在しないパス → 空扱い + 正常終了" {
  run bash -c "source '$RETRO_LIB' && retrospective_body_compose '/no/such/path' '/no/such/path2' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"# Retrospective: v2.5.1"* ]]
  [[ "$output" == *"### 問題なし"* ]]
}

@test "_pure_compose_body: 文字列入力で純粋関数として動作" {
  run bash -c "source '$RETRO_LIB' && _pure_compose_body '' '' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"# Retrospective: v2.5.1"* ]]
  [[ "$output" == *"### 問題なし"* ]]
}
