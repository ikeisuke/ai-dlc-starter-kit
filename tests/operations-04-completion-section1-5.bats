#!/usr/bin/env bats
# Unit 002 → Unit 005 (#667): 04-completion.md §1 + retrospective skill §1.5 構造テスト
#
# v2.5.x まで: skills/aidlc/steps/operations/04-completion.md §1.5 に Issue 起票フロー（Step 1-5）が存在
# v2.6.0 以降: 振り返り全量を skills/aidlc-retrospective/steps/retrospective.md に移転
#
# 本テストは Unit 005 移転後の構造（旧ファイルの縮退 + 新ファイルへの構造保持）を verify する。
# Markdown コードブロック内 $() 規約準拠は bin/check-bash-substitution.sh が担保。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  OLD_TARGET="${REPO_ROOT}/skills/aidlc/steps/operations/04-completion.md"
  NEW_TARGET="${REPO_ROOT}/skills/aidlc-retrospective/steps/retrospective.md"
}

@test "section1-5: 新旧両ファイルが存在する" {
  [ -f "$OLD_TARGET" ]
  [ -f "$NEW_TARGET" ]
}

@test "section1-5 (v2.6.0 移転後): retrospective.md §1.5 セクション見出しが存在" {
  grep -q '^## 1.5 Issue 起票フロー' "$NEW_TARGET"
}

@test "section1-5 (v2.6.0 移転後): retrospective.md に 5 つの Step 見出しが順序通り出現する" {
  step1_line="$(grep -n '^### Step 1: feedback_mode の確定' "$NEW_TARGET" | head -1 | cut -d: -f1)"
  step2_line="$(grep -n '^### Step 2: KPT テンプレ展開' "$NEW_TARGET" | head -1 | cut -d: -f1)"
  step3_line="$(grep -n '^### Step 3: 本文構築' "$NEW_TARGET" | head -1 | cut -d: -f1)"
  step4_line="$(grep -n '^### Step 4: Issue 起票' "$NEW_TARGET" | head -1 | cut -d: -f1)"
  step5_line="$(grep -n '^### Step 5: update フック' "$NEW_TARGET" | head -1 | cut -d: -f1)"
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

@test "section1-5 (v2.6.0 移転後): 旧 04-completion.md §1 から実行ロジックは完全削除されている" {
  # 旧ファイルに残ってはならない関数 / 定数
  ! grep -q 'retrospective_issue_create' "$OLD_TARGET"
  ! grep -q 'retrospective_prefill_hook' "$OLD_TARGET"
  ! grep -q 'retrospective_update_hook' "$OLD_TARGET"
  ! grep -q 'AIDLC_RETRO_CURRENT_COUNT' "$OLD_TARGET"
}

@test "section1-5 (v2.6.0 移転後): retrospective.md は Facade 経由（retrospective_api_*）で呼び出している" {
  grep -q 'retrospective_api_resolve_feedback_mode' "$NEW_TARGET"
  grep -q 'retrospective_api_check_cap' "$NEW_TARGET"
  grep -q 'retrospective_api_prefill' "$NEW_TARGET"
  grep -q 'retrospective_api_compose_body' "$NEW_TARGET"
  grep -q 'retrospective_api_create_issue' "$NEW_TARGET"
  grep -q 'retrospective_api_update_issue' "$NEW_TARGET"
  grep -q 'retrospective_api_record_response' "$NEW_TARGET"
}

@test "section1-5 (v2.6.0 移転後): retrospective.md Step 4 で AIDLC_RETRO_CURRENT_COUNT / AIDLC_RETRO_LIMIT を渡している" {
  grep -q 'AIDLC_RETRO_CURRENT_COUNT' "$NEW_TARGET"
  grep -q 'AIDLC_RETRO_LIMIT' "$NEW_TARGET"
}

@test "section1-5 (v2.6.0 移転後): 旧 04-completion.md は /aidlc r 案内のみ残置（破壊的変更明示）" {
  grep -qE '/aidlc[[:space:]]+r|aidlc-retrospective' "$OLD_TARGET"
}

@test "section1-5: §1 改修コードブロックに \$() が含まれない（プロジェクト規約）" {
  # bin/check-bash-substitution.sh と同等のロジックを直接適用
  run bash "${REPO_ROOT}/bin/check-bash-substitution.sh" skills/aidlc/steps/operations/
  [ "$status" -eq 0 ]
}

@test "section1-5 (v2.6.0 移転後): retrospective.md は gh 不可時のスプール案内を含む" {
  grep -q 'retrospective-resend.sh' "$NEW_TARGET"
}
