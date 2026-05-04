#!/usr/bin/env bats
# Unit 001 観点 A: template / example から個人好み 7 キーが除去されていることを検証
#
# 検証方式:
#   - template: project プレースホルダを含む invalid TOML のため、
#               grep/awk ベースで section + leaf 構造を検査
#   - example:  valid TOML のため aidlc_read_toml（dasel v2/v3 互換ライブラリ）で構造検査
#
# 対象ファイル:
#   - skills/aidlc-setup/templates/config.toml.template
#   - skills/aidlc/config/config.toml.example

load helpers/setup

# --- template: 個人好み 7 キーの section + leaf がないこと ---

@test "template: rules.reviewing.mode が config.toml.template から除去されている" {
  run template_has_section_leaf "rules.reviewing" "mode"
  [ "$status" -ne 0 ]
}

@test "template: rules.reviewing.tools が config.toml.template から除去されている" {
  run template_has_section_leaf "rules.reviewing" "tools"
  [ "$status" -ne 0 ]
}

@test "template: rules.automation セクション全体が config.toml.template から除去されている" {
  run template_has_section "rules.automation"
  [ "$status" -ne 0 ]
}

@test "template: rules.git.squash_enabled が config.toml.template から除去されている" {
  run template_has_section_leaf "rules.git" "squash_enabled"
  [ "$status" -ne 0 ]
}

@test "template: rules.git.ai_author が config.toml.template から除去されている" {
  run template_has_section_leaf "rules.git" "ai_author"
  [ "$status" -ne 0 ]
}

@test "template: rules.git.ai_author_auto_detect が config.toml.template から除去されている" {
  run template_has_section_leaf "rules.git" "ai_author_auto_detect"
  [ "$status" -ne 0 ]
}

@test "template: rules.linting セクション全体が config.toml.template から除去されている" {
  run template_has_section "rules.linting"
  [ "$status" -ne 0 ]
}

# --- example: 個人好み 7 キーが TOML 構造として存在しないこと ---

@test "example: rules.reviewing.mode が config.toml.example に存在しない" {
  run example_has_key "rules.reviewing.mode"
  [ "$status" -ne 0 ]
}

@test "example: rules.reviewing.tools が config.toml.example に存在しない" {
  run example_has_key "rules.reviewing.tools"
  [ "$status" -ne 0 ]
}

@test "example: rules.automation.mode が config.toml.example に存在しない" {
  run example_has_key "rules.automation.mode"
  [ "$status" -ne 0 ]
}

@test "example: rules.git.squash_enabled が config.toml.example に存在しない" {
  run example_has_key "rules.git.squash_enabled"
  [ "$status" -ne 0 ]
}

@test "example: rules.git.ai_author が config.toml.example に存在しない" {
  run example_has_key "rules.git.ai_author"
  [ "$status" -ne 0 ]
}

@test "example: rules.git.ai_author_auto_detect が config.toml.example に存在しない" {
  run example_has_key "rules.git.ai_author_auto_detect"
  [ "$status" -ne 0 ]
}

@test "example: rules.linting.enabled が config.toml.example に存在しない" {
  run example_has_key "rules.linting.enabled"
  [ "$status" -ne 0 ]
}

# --- regression: プロジェクト強制カテゴリのキーが template に残存することを確認 ---

@test "regression: rules.git.branch_mode（プロジェクト強制）は template に残存する" {
  run template_has_section_leaf "rules.git" "branch_mode"
  [ "$status" -eq 0 ]
}

@test "regression: rules.git.unit_branch_enabled（プロジェクト強制）は template に残存する" {
  run template_has_section_leaf "rules.git" "unit_branch_enabled"
  [ "$status" -eq 0 ]
}

@test "regression: rules.git.commit_on_unit_complete（プロジェクト強制）は template に残存する" {
  run template_has_section_leaf "rules.git" "commit_on_unit_complete"
  [ "$status" -eq 0 ]
}

@test "regression: rules.feedback.enabled（プロジェクト強制）は template に残存する" {
  run template_has_section_leaf "rules.feedback" "enabled"
  [ "$status" -eq 0 ]
}
