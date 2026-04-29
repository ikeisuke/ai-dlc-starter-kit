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
