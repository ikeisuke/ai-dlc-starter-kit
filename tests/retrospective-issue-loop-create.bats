#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 004 (v2.6.6): §1.5 Step 4 Try ループ起票 + テンプレ改修 構造ガードテスト
#
# 4A の主な改修は AI エージェント実行手順 (steps/retrospective.md §1.5 Step 4) と
# テンプレ (templates/retrospective_template.md) であり、shell 内部実装の追加はない。
# 本テストはテンプレ整合性 / ステップ記述構造の不変条件を保護する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TEMPLATE_FILE="${REPO_ROOT}/skills/aidlc/templates/retrospective_template.md"
  STEPS_FILE="${REPO_ROOT}/skills/aidlc-retrospective/steps/retrospective.md"
}

# ─── T-LOOP-1: テンプレに try_loop_block マーカーが存在する ─────
@test "T-LOOP-1: retrospective_template.md に <!-- BEGIN: try_loop_block --> マーカーが存在し対の END もある" {
  grep -F '<!-- BEGIN: try_loop_block -->' "$TEMPLATE_FILE"
  grep -F '<!-- END: try_loop_block -->' "$TEMPLATE_FILE"
}

# ─── T-LOOP-2: テンプレに aggregate_block マーカーが存在する ─────
@test "T-LOOP-2: retrospective_template.md に <!-- BEGIN: aggregate_block --> マーカーが存在し対の END もある" {
  grep -F '<!-- BEGIN: aggregate_block -->' "$TEMPLATE_FILE"
  grep -F '<!-- END: aggregate_block -->' "$TEMPLATE_FILE"
}

# ─── T-LOOP-3: try_loop_block 内に 5 必須見出しがすべて存在する ─────
@test "T-LOOP-3: try_loop_block 内に 5 必須見出し (背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連) が揃う" {
  # try_loop_block の範囲を sed で切り出して内部の見出しを確認
  local block
  block=$(sed -n '/<!-- BEGIN: try_loop_block -->/,/<!-- END: try_loop_block -->/p' "$TEMPLATE_FILE")
  printf '%s\n' "$block" | grep -F '#### 背景'
  printf '%s\n' "$block" | grep -F '#### 主因切り分け'
  printf '%s\n' "$block" | grep -F '#### 構造課題昇格根拠'
  printf '%s\n' "$block" | grep -F '#### 想定対策'
  printf '%s\n' "$block" | grep -F '#### 関連'
}

# ─── T-LOOP-4: try_loop_block 内に Try N: 形式のタイトル雛形がある ─────
@test "T-LOOP-4: try_loop_block 内に '### Try 1:' タイトル雛形が含まれる" {
  local block
  block=$(sed -n '/<!-- BEGIN: try_loop_block -->/,/<!-- END: try_loop_block -->/p' "$TEMPLATE_FILE")
  printf '%s\n' "$block" | grep -E '^### Try [0-9]+:'
}

# ─── T-LOOP-5: aggregate_block 内に既存表構造（| 優先度 | 施策 | 反映先 |）が維持される ─────
@test "T-LOOP-5: aggregate_block 内に v2.6.5 互換の Try 表構造 (| 優先度 | 施策 | 反映先 |) が保持される" {
  local block
  block=$(sed -n '/<!-- BEGIN: aggregate_block -->/,/<!-- END: aggregate_block -->/p' "$TEMPLATE_FILE")
  printf '%s\n' "$block" | grep -F '| 優先度 | 施策 | 反映先 |'
}

# ─── T-LOOP-6: §1.5 Step 4 が aggregate_issue_enabled で分岐する記述を持つ ─────
@test "T-LOOP-6: steps/retrospective.md §1.5 Step 4 に aggregate_issue_enabled 分岐記述がある" {
  grep -F 'Step 4-A: TryLoopCreationStrategy' "$STEPS_FILE"
  grep -F 'Step 4-B: AggregatedCreationStrategy' "$STEPS_FILE"
  grep -F 'retrospective_api_aggregate_enabled' "$STEPS_FILE"
}

# ─── T-LOOP-7: Step 4-A 内に 5 必須見出しの SectionComposer 手順が記述される ─────
@test "T-LOOP-7: Step 4-A SectionComposer 手順に 5 必須見出し (背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連) が記述される" {
  # Step 4-A セクション部分のみを抽出
  local section
  section=$(sed -n '/#### Step 4-A: TryLoopCreationStrategy/,/#### Step 4-B:/p' "$STEPS_FILE")
  printf '%s\n' "$section" | grep -F '## 背景'
  printf '%s\n' "$section" | grep -F '## 主因切り分け'
  printf '%s\n' "$section" | grep -F '## 構造課題昇格根拠'
  printf '%s\n' "$section" | grep -F '## 想定対策'
  printf '%s\n' "$section" | grep -F '## 関連'
}

# ─── T-LOOP-8: Step 4-A 内に validateSectionsNonEmpty 手順がある ─────
@test "T-LOOP-8: Step 4-A 内に validateSectionsNonEmpty + selfreview-incomplete ラベル付与の skip 経路がある" {
  local section
  section=$(sed -n '/#### Step 4-A: TryLoopCreationStrategy/,/#### Step 4-B:/p' "$STEPS_FILE")
  printf '%s\n' "$section" | grep -F 'validateSectionsNonEmpty'
  printf '%s\n' "$section" | grep -F 'selfreview-incomplete'
}

# ─── T-LOOP-9: 制御フロー仕様表（cap / dialog / section_invalid）が存在する ─────
@test "T-LOOP-9: Step 4-A 内に制御フロー仕様表 (cap 到達 / dialog token 失敗 / section_invalid) が存在する" {
  local section
  section=$(sed -n '/#### Step 4-A: TryLoopCreationStrategy/,/#### Step 4-B:/p' "$STEPS_FILE")
  printf '%s\n' "$section" | grep -F '中断要因'
  printf '%s\n' "$section" | grep -F 'cap 到達'
  printf '%s\n' "$section" | grep -F 'dialog token 失敗'
  printf '%s\n' "$section" | grep -F 'section_invalid'
}

# ─── T-LOOP-10: §1.5 前置きに T ループ起票が implemented として記載される ─────
@test "T-LOOP-10: §1.5 前置きで 'T ループ起票' が Unit 004 で実装完了として記載される" {
  # 旧版の「未実装」「実装予定」表現が残っていないこと
  ! grep -F 'v2.6.6 時点では `false` 設定時の本体動作は未実装' "$STEPS_FILE"
  # 新版の「実装完了」相当の記述が含まれること
  grep -F 'T ループ起票' "$STEPS_FILE"
  grep -F 'Unit 004' "$STEPS_FILE"
}

# ─── T-LOOP-11: §1.6 predecessor 経路一覧に新動作経路 5a/5b が追記されている ─────
@test "T-LOOP-11: §1.6 predecessor 経路一覧に経路 5a t_issue_milestone_scope / 経路 5b t_issue_label_fallback が記載される" {
  grep -F 't_issue_milestone_scope' "$STEPS_FILE"
  grep -F 't_issue_label_fallback' "$STEPS_FILE"
}

# ─── T-LOOP-12: タイトル形式 Retrospective: {cycle} prefix が記述される ─────
@test "T-LOOP-12: Step 4-A タイトル生成ロジックに Retrospective prefix + cycle placeholder + Try summary が記述される" {
  grep -F '[Retrospective: {cycle}]' "$STEPS_FILE"
}

# ─── T-LOOP-13: ループ完了後の出力フォーマット (created / skipped 詳細) が記述される ─────
@test "T-LOOP-13: Step 4-A ループ完了後の出力に created / skipped(cap_reached) / skipped(dialog_required) / skipped(section_invalid) が記載" {
  local section
  section=$(sed -n '/#### Step 4-A: TryLoopCreationStrategy/,/#### Step 4-B:/p' "$STEPS_FILE")
  printf '%s\n' "$section" | grep -F 'created='
  printf '%s\n' "$section" | grep -F 'skipped(cap_reached)'
  printf '%s\n' "$section" | grep -F 'skipped(dialog_required)'
  printf '%s\n' "$section" | grep -F 'skipped(section_invalid)'
}
