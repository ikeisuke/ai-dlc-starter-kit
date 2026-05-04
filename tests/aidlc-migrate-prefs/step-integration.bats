#!/usr/bin/env bats
# Unit 003: 観点 S - step-integration (6 ケース)
# S1: ## 4 セクション存在 + 1 回のみ
# S2: 位置 (## 3b. < ## 4. < ## 5.)
# S3: 4 択 (移動/残す/全件移動/全件残す) の文字列含有
# S4: 対話遷移規則 (yes-to-all / no-to-all / bulk_action) の文字列含有
# S5: 安定 ID コメントアンカーが ## 4 直前行に 1 回のみ
# S6: Unit 002 安定 ID への参照 + 単一ソース原則の言及

load helpers/setup

readonly ANCHOR_4='## 4. 個人好みキー移動提案'

@test "S1: ## 4. 個人好みキー移動提案 セクションが 1 回のみ存在" {
  run assert_step_section_count '^## 4\. 個人好みキー移動提案' 1
  [ "$status" -eq 0 ]
}

@test "S2: ## 4. が ## 3b. と ## 5. の間に配置される" {
  # ## 3b. は数字 + b パターン、ヘルパは数字想定なので個別検査
  local line_3b line_4 line_5
  line_3b="$(grep -n -- '^## 3b\.' "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  line_4="$(grep -n -- '^## 4\.' "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  line_5="$(grep -n -- '^## 5\.' "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  [ -n "${line_3b}" ]
  [ -n "${line_4}" ]
  [ -n "${line_5}" ]
  [ "${line_3b}" -lt "${line_4}" ]
  [ "${line_4}" -lt "${line_5}" ]
}

@test "S3: ## 4 本文に 4 択 (移動/残す/全件移動/全件残す) の文字列が全て含まれる" {
  run assert_step_body_contains "${ANCHOR_4}" '移動 (user-global へ)'
  [ "$status" -eq 0 ]
  run assert_step_body_contains "${ANCHOR_4}" 'そのまま残す'
  [ "$status" -eq 0 ]
  run assert_step_body_contains "${ANCHOR_4}" '全件移動 (yes-to-all)'
  [ "$status" -eq 0 ]
  run assert_step_body_contains "${ANCHOR_4}" '全件残す (no-to-all)'
  [ "$status" -eq 0 ]
}

@test "S4: ## 4 本文に 対話遷移規則 (yes-to-all / no-to-all / bulk_action) の指示が含まれる" {
  run assert_step_body_contains "${ANCHOR_4}" 'yes-to-all'
  [ "$status" -eq 0 ]
  run assert_step_body_contains "${ANCHOR_4}" 'no-to-all'
  [ "$status" -eq 0 ]
  run assert_step_body_contains "${ANCHOR_4}" 'bulk_action'
  [ "$status" -eq 0 ]
}

@test "S5: stable_id HTML コメントアンカー guidance:id=unit003-migrate-prefs-relocation が ## 4 直前行に配置 + 1 回のみ" {
  local line_comment line_4
  line_comment="$(grep -n -F -- '<!-- guidance:id=unit003-migrate-prefs-relocation -->' "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  line_4="$(grep -n -- '^## 4\. 個人好みキー移動提案' "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  [ -n "${line_comment}" ]
  [ -n "${line_4}" ]
  [ "$((line_comment + 1))" -eq "${line_4}" ]
  # 1 回のみ
  local count
  count="$(grep -c -F -- '<!-- guidance:id=unit003-migrate-prefs-relocation -->' "${STEP_FILE_PATH}")"
  [ "${count}" -eq 1 ]
}

@test "S6: ## 4 本文に Unit 002 安定 ID unit002-user-global への参照 + 単一ソース原則の言及" {
  run assert_step_body_contains "${ANCHOR_4}" 'unit002-user-global'
  [ "$status" -eq 0 ]
  run assert_step_body_contains "${ANCHOR_4}" '単一ソース原則'
  [ "$status" -eq 0 ]
}

# ─── 回帰: 既存セクション破壊検出 ─────────

@test "R1: 既存 ## 5. ロールバック手順 セクションが残存する (旧 ## 4 から繰り下げ)" {
  run grep -- '^## 5\. ロールバック手順' "${STEP_FILE_PATH}"
  [ "$status" -eq 0 ]
}

@test "R2: 既存 ## 6. 次のステップへ セクションが残存する (旧 ## 5 から繰り下げ)" {
  run grep -- '^## 6\. 次のステップへ' "${STEP_FILE_PATH}"
  [ "$status" -eq 0 ]
}
