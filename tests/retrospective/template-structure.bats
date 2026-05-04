#!/usr/bin/env bats
# Unit 004: 観点 T - テンプレート構造検証

load helpers/setup

@test "T1: テンプレートが存在する + 必須セクション 3 件を含む" {
  [ -f "${TEMPLATE_PATH}" ]
  grep -F "## 概要" "${TEMPLATE_PATH}"
  grep -F "## 問題項目" "${TEMPLATE_PATH}"
  grep -F "## 次サイクルへの引き継ぎ事項" "${TEMPLATE_PATH}"
}

@test "T2: テンプレートに skill 起因判定 6 キーが含まれる" {
  grep -F "q1_answer" "${TEMPLATE_PATH}"
  grep -F "q1_quote" "${TEMPLATE_PATH}"
  grep -F "q2_answer" "${TEMPLATE_PATH}"
  grep -F "q2_quote" "${TEMPLATE_PATH}"
  grep -F "q3_answer" "${TEMPLATE_PATH}"
  grep -F "q3_quote" "${TEMPLATE_PATH}"
}

@test "T4: テンプレートに KPT セクション + 主因切り分けマトリクスが含まれる（Unit 007 / #625）" {
  grep -F "## メトリクスサマリ" "${TEMPLATE_PATH}"
  grep -F "## Keep" "${TEMPLATE_PATH}"
  grep -F "## Try" "${TEMPLATE_PATH}"
  grep -F "**主因切り分け**" "${TEMPLATE_PATH}"
  grep -F "プロダクト固有" "${TEMPLATE_PATH}"
  grep -F "AI-DLC Starter Kit 固有" "${TEMPLATE_PATH}"
  grep -F "両方に責任" "${TEMPLATE_PATH}"
  grep -F "## 反映先一覧" "${TEMPLATE_PATH}"
}

@test "T5: predecessor_retrospective.md（分岐 b 用テンプレ）が存在し、KPT + 引き継ぎ事項を含む（Unit 007 / #625）" {
  local predecessor_template="${TEMPLATE_PATH%/*}/predecessor_retrospective.md"
  [ -f "${predecessor_template}" ]
  grep -F "前サイクル" "${predecessor_template}"
  grep -F "## Keep" "${predecessor_template}"
  grep -F "## Try" "${predecessor_template}"
  grep -F "## Problem" "${predecessor_template}"
  grep -F "本サイクルへの引き継ぎ事項" "${predecessor_template}"
  grep -F "{{PREV_CYCLE}}" "${predecessor_template}"
  grep -F "{{CYCLE}}" "${predecessor_template}"
}

@test "T3: テンプレートが markdownlint パスする" {
  if ! command -v markdownlint-cli2 >/dev/null 2>&1 && ! command -v npx >/dev/null 2>&1; then
    skip "markdownlint-cli2 / npx not available"
  fi
  if command -v markdownlint-cli2 >/dev/null 2>&1; then
    run markdownlint-cli2 "${TEMPLATE_PATH}"
  else
    run npx markdownlint-cli2 "${TEMPLATE_PATH}"
  fi
  [ "$status" -eq 0 ]
}
