#!/usr/bin/env bats
# step-integration.bats - 観点 IM: ## 3.5 Step 5 セクションの存在 + 記述整合性

load helpers/setup.bash

setup() {
  setup_env
}

teardown() {
  teardown_env
}

@test "step-integration: ## 3.5 Step 5 (mirror フロー) セクションが 04-completion.md に存在する" {
  grep -q '#### Step 5: mirror フロー' "${STEP_FILE_PATH}"
}

@test "step-integration: 安定 ID コメントアンカー unit005-mirror-flow が存在する" {
  grep -q 'guidance:id=unit005-mirror-flow' "${STEP_FILE_PATH}"
}

@test "step-integration: retrospective-mirror.sh の detect / send / record 呼び出し記述が存在する" {
  grep -q 'retrospective-mirror.sh detect' "${STEP_FILE_PATH}"
  grep -q 'retrospective-mirror.sh send' "${STEP_FILE_PATH}"
  grep -q 'retrospective-mirror.sh record' "${STEP_FILE_PATH}"
}

@test "step-integration: AskUserQuestion 3 択（送信する / 送信しない / 後で判断）が記述されている" {
  grep -q '送信する' "${STEP_FILE_PATH}"
  grep -q '送信しない' "${STEP_FILE_PATH}"
  grep -q '保留' "${STEP_FILE_PATH}"
}

@test "step-integration: 旧 Step 2〜4 は §1.5 で撤廃され『旧仕様参考』セクションに残置（Unit 002 / v2.5.1）" {
  # Issue #625 fix: 旧 Step 1（cycle-version-check.sh）は撤廃
  ! grep -q 'サイクルバージョンガード' "${STEP_FILE_PATH}"
  # Unit 002 (v2.5.1): §1.5 全面刷新により旧 Step 2-4 は『旧仕様参考（撤廃済 / v2.5.0 実装）』セクションに移動
  grep -q 'guidance:id=unit002-legacy-removed' "${STEP_FILE_PATH}"
  grep -q '旧仕様参考（撤廃済 / v2.5.0 実装）' "${STEP_FILE_PATH}"
  # 新 §1.5 Step 1-5 が SSOT として存在
  grep -q '##### Step 1: feedback_mode 解決' "${STEP_FILE_PATH}"
  grep -q '##### Step 4: Issue 起票' "${STEP_FILE_PATH}"
}
