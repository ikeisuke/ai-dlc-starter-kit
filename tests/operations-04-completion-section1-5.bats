#!/usr/bin/env bats
# Unit 002: 04-completion.md §1.5 構造テスト
# §1.5 が新フロー（Step 1-5）に置換され、旧フローは「撤廃済」セクションに残置されていることを verify する。
# Markdown コードブロック内 $() 規約準拠は bin/check-bash-substitution.sh が担保。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TARGET="${REPO_ROOT}/skills/aidlc/steps/operations/04-completion.md"
}

@test "section1-5: ファイルが存在する" {
  [ -f "$TARGET" ]
}

@test "section1-5: §1.5 セクション見出しが存在" {
  grep -q '^#### 1.5 Issue 起票フロー' "$TARGET"
}

@test "section1-5: 5 つの Step 見出しが順序通り出現する" {
  step1_line="$(grep -n '^##### Step 1: feedback_mode 解決' "$TARGET" | head -1 | cut -d: -f1)"
  step2_line="$(grep -n '^##### Step 2: cap 判定' "$TARGET" | head -1 | cut -d: -f1)"
  step3_line="$(grep -n '^##### Step 3: 本文構築' "$TARGET" | head -1 | cut -d: -f1)"
  step4_line="$(grep -n '^##### Step 4: Issue 起票' "$TARGET" | head -1 | cut -d: -f1)"
  step5_line="$(grep -n '^##### Step 5: Unit 003 update フック' "$TARGET" | head -1 | cut -d: -f1)"
  [ -n "$step1_line" ]
  [ -n "$step2_line" ]
  [ -n "$step3_line" ]
  [ -n "$step4_line" ]
  [ -n "$step5_line" ]
  [ "$step1_line" -lt "$step2_line" ]
  [ "$step2_line" -lt "$step3_line" ]
  [ "$step3_line" -lt "$step4_line" ]
  [ "$step4_line" -lt "$step5_line" ]
}

@test "section1-5: 旧フローは「撤廃済」セクションに残置" {
  grep -q '撤廃' "$TARGET"
  grep -q 'guidance:id=unit002-legacy-removed' "$TARGET"
}

@test "section1-5: feedback-mode.sh / retrospective-issue.sh の source 指示が含まれる" {
  grep -q 'source skills/aidlc/scripts/lib/feedback-mode.sh' "$TARGET"
  grep -q 'source skills/aidlc/scripts/lib/retrospective-issue.sh' "$TARGET"
}

@test "section1-5: Step 4 で AIDLC_RETRO_CURRENT_COUNT / AIDLC_RETRO_LIMIT を渡している" {
  grep -q 'AIDLC_RETRO_CURRENT_COUNT' "$TARGET"
  grep -q 'AIDLC_RETRO_LIMIT' "$TARGET"
}

@test "section1-5: Unit 003 prefill / update フックの呼出が含まれる" {
  grep -q 'retrospective_prefill_hook' "$TARGET"
  grep -q 'retrospective_update_hook' "$TARGET"
}

@test "section1-5: Step 4 で retrospective_issue_create を呼び出す" {
  grep -q 'retrospective_issue_create' "$TARGET"
}

@test "section1-5: §1.5 改修コードブロックに \$() が含まれない（プロジェクト規約）" {
  # bin/check-bash-substitution.sh と同等のロジックを直接適用
  run bash "${REPO_ROOT}/bin/check-bash-substitution.sh" skills/aidlc/steps/operations/
  [ "$status" -eq 0 ]
}

@test "section1-5: gh が利用不可時のスプール案内を含む" {
  grep -q 'retrospective-resend.sh' "$TARGET"
}
