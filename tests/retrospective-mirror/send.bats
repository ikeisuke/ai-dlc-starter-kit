#!/usr/bin/env bats
# send.bats - 観点 S: gh issue create + mirror_state 書き込み

load helpers/setup.bash

setup() {
  setup_env
  set_project_feedback_mode "mirror"
}

teardown() {
  teardown_env
}

# ヘルパー: detect → candidate 抽出 → draft path 取得
_first_draft_path() {
  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  echo "$output" | awk -F'\t' '$1 == "mirror" && $2 == "candidate" { print $5; exit }'
}

@test "send: gh 成功時 mirror sent + Issue URL を retrospective.md に書き込み" {
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  mock_gh "success" "700"
  draft_path="$(_first_draft_path)"
  [ -n "$draft_path" ]

  run run_mirror send "$(test_retrospective_path)" 1 "テストタイトル" "$draft_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"sent"$'\t'"1"$'\t'"https://github.com/ikeisuke/ai-dlc-starter-kit/issues/700"* ]]

  # retrospective.md に書き込み確認
  grep -q 'state: "sent"' "$(test_retrospective_path)"
  grep -q 'issue_url: "https://github.com/ikeisuke/ai-dlc-starter-kit/issues/700"' "$(test_retrospective_path)"
}

@test "send: gh auth 失敗時 recoverable failure (exit 0 + send-failed)" {
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  mock_gh "auth-fail"
  draft_path="$(_first_draft_path)"

  run run_mirror send "$(test_retrospective_path)" 1 "Title" "$draft_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"send-failed"$'\t'"1"$'\t'"gh-not-authenticated"* ]]

  # retrospective.md は変更されない（state="" のまま）
  grep -q 'state: ""' "$(test_retrospective_path)"
}

@test "send: gh rate-limit 時 recoverable failure" {
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  mock_gh "rate-limit"
  draft_path="$(_first_draft_path)"

  run run_mirror send "$(test_retrospective_path)" 1 "Title" "$draft_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"send-failed"$'\t'"1"$'\t'"gh-rate-limit"* ]]
}

@test "send: gh ネットワークエラー時 recoverable failure" {
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"
  mock_gh "network-error"
  draft_path="$(_first_draft_path)"

  run run_mirror send "$(test_retrospective_path)" 1 "Title" "$draft_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"send-failed"$'\t'"1"$'\t'"gh-network-error"* ]]
}

@test "send: 後方互換 - mirror_state 欠落の旧形式に新規ブロック追加" {
  copy_fixture "legacy-no-mirror-state" "$(test_retrospective_path)"
  mock_gh "success" "701"
  draft_path="$(_first_draft_path)"

  run run_mirror send "$(test_retrospective_path)" 1 "Title" "$draft_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"sent"* ]]

  # 新規 mirror_state ブロックが追加された
  grep -q 'mirror_state:' "$(test_retrospective_path)"
  grep -q 'state: "sent"' "$(test_retrospective_path)"
  grep -q 'issue_url: "https://github.com/ikeisuke/ai-dlc-starter-kit/issues/701"' "$(test_retrospective_path)"
}

@test "send: multi-problem 中間 idx=3 への書き換えが成功する（非末尾問題更新）" {
  copy_fixture "mixed-state" "$(test_retrospective_path)"
  mock_gh "success" "703"
  # 任意の draft（mock 用テキスト）
  draft_path="${TEST_TMPDIR}/draft-3.md"
  echo "test draft body" > "$draft_path"

  run run_mirror send "$(test_retrospective_path)" 3 "Title for idx=3" "$draft_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror"$'\t'"sent"$'\t'"3"$'\t'"https://github.com/ikeisuke/ai-dlc-starter-kit/issues/703"* ]]

  # 問題 3 の mirror_state.state が "sent" + URL が書き込まれている
  awk '/^### 問題 3:/,/^### 問題 4:/' "$(test_retrospective_path)" | grep -q 'state: "sent"'
  awk '/^### 問題 3:/,/^### 問題 4:/' "$(test_retrospective_path)" | grep -q 'issue_url: "https://github.com/ikeisuke/ai-dlc-starter-kit/issues/703"'
  # 問題 1 / 2 / 4 の mirror_state は不変
  awk '/^### 問題 1:/,/^### 問題 2:/' "$(test_retrospective_path)" | grep -q 'issue_url: "https://github.com/ikeisuke/ai-dlc-starter-kit/issues/999"'
}
