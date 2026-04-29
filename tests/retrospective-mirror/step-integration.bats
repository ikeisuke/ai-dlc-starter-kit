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

@test "step-integration: 既存 Step 1〜4 (Unit 004) が保持されている" {
  grep -q '#### Step 1: サイクルバージョンガード' "${STEP_FILE_PATH}"
  grep -q '#### Step 2: retrospective-generate.sh 呼び出し' "${STEP_FILE_PATH}"
  grep -q '#### Step 3: 出力プレフィックス分岐' "${STEP_FILE_PATH}"
  grep -q '#### Step 4: retrospective-validate.sh 呼び出し' "${STEP_FILE_PATH}"
}
