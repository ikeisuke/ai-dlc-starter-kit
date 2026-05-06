#!/usr/bin/env bats
# operations-release.sh record-release-prep-commit サブコマンドの単体テスト
# 観点:
#   - slot 行なし → recorded（末尾追加）
#   - slot 行あり（空値） → updated（値置換）
#   - slot 行あり（既存値あり） → updated（既存値上書き）
#   - progress.md 不在 → exit 1 + error 出力

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  OPS_REL="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"
  TEMPLATE="${REPO_ROOT}/skills/aidlc/templates/operations_progress_template.md"

  # 一時 git リポジトリを作成（cycle ディレクトリ + progress.md fixture）
  TMP_REPO="$(mktemp -d -t aidlc-record-rpc-test.XXXXXX)"
  cd "$TMP_REPO"
  git init --quiet
  git config user.email "test@example.com"
  git config user.name "Test"
  git config commit.gpgsign false
  CYCLE="v9.9.9"
  mkdir -p ".aidlc/cycles/${CYCLE}/operations"
  echo "init" > README.md
  git add README.md
  git commit --quiet -m "initial"
}

teardown() {
  cd "$BATS_TEST_TMPDIR"
  rm -rf "$TMP_REPO"
}

@test "record-release-prep-commit: slot 行あり (空値) → updated" {
  cp "$TEMPLATE" ".aidlc/cycles/${CYCLE}/operations/progress.md"
  HEAD_SHA_BEFORE=$(git rev-parse HEAD)  # スクリプト実行前の HEAD（記録対象）
  run bash "$OPS_REL" record-release-prep-commit --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"release_prep_commit:updated:"* ]]
  [[ "$output" == *"$HEAD_SHA_BEFORE"* ]]
  # progress.md に slot が反映されていること（記録対象は実行前 HEAD）
  grep -q "<!-- release_prep_commit: $HEAD_SHA_BEFORE -->" ".aidlc/cycles/${CYCLE}/operations/progress.md"
}

@test "record-release-prep-commit: slot 行なし → recorded (末尾追加)" {
  # 旧 template (release_prep_commit slot なし) を再現
  cat > ".aidlc/cycles/${CYCLE}/operations/progress.md" <<'EOF'
# Operations Phase 進捗管理

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=false
completion_gate_ready=false
pr_number=

## 現在のステップ

次回: 1. 変更確認
EOF
  HEAD_SHA_BEFORE=$(git rev-parse HEAD)
  run bash "$OPS_REL" record-release-prep-commit --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"release_prep_commit:recorded:"* ]]
  [[ "$output" == *"$HEAD_SHA_BEFORE"* ]]
  grep -q "<!-- release_prep_commit: $HEAD_SHA_BEFORE -->" ".aidlc/cycles/${CYCLE}/operations/progress.md"
}

@test "record-release-prep-commit: 既存値ありの slot → 新値で上書き (updated)" {
  cat > ".aidlc/cycles/${CYCLE}/operations/progress.md" <<'EOF'
## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=false
completion_gate_ready=false
pr_number=

<!-- release_prep_commit: 0000000000000000000000000000000000000000 -->
EOF
  HEAD_SHA_BEFORE=$(git rev-parse HEAD)
  run bash "$OPS_REL" record-release-prep-commit --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"release_prep_commit:updated:"* ]]
  grep -q "<!-- release_prep_commit: $HEAD_SHA_BEFORE -->" ".aidlc/cycles/${CYCLE}/operations/progress.md"
  # 旧値が残っていないこと
  ! grep -q "0000000000000000000000000000000000000000" ".aidlc/cycles/${CYCLE}/operations/progress.md"
}

@test "record-release-prep-commit: progress.md 不在で exit 1 + progress-not-found エラー" {
  run bash "$OPS_REL" record-release-prep-commit --cycle "$CYCLE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"record-release-prep-commit:progress-not-found"* ]]
}

@test "record-release-prep-commit: --cycle 未指定で exit 1 + cycle-required エラー" {
  run bash "$OPS_REL" record-release-prep-commit
  [ "$status" -eq 1 ]
  [[ "$output" == *"cycle-required"* ]]
}
