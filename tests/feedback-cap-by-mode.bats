#!/usr/bin/env bats
# Unit 001: feedback_cap_check 単体テスト
# Intent §「主要設計判断 5」の cap 適用範囲表（合算 / 単独 / 不適用）を verify する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  FEEDBACK_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/feedback-mode.sh"
}

# stdout のみ取得するヘルパー
_cap_stdout() {
  bash -c "source '$FEEDBACK_LIB' && feedback_cap_check '$1' '$2' '$3' 2>/dev/null"
}

@test "cap: local-issue-only / current<limit → over=false / scope=local" {
  out="$(_cap_stdout local-issue-only 1 3)"
  [[ "$out" == *"over=false"* ]]
  [[ "$out" == *"scope=local"* ]]
}

@test "cap: local-issue-only / current==limit → over=true" {
  out="$(_cap_stdout local-issue-only 3 3)"
  [[ "$out" == *"over=true"* ]]
  [[ "$out" == *"scope=local"* ]]
}

@test "cap: mirror-only / current<limit → over=false / scope=mirror" {
  out="$(_cap_stdout mirror-only 0 3)"
  [[ "$out" == *"over=false"* ]]
  [[ "$out" == *"scope=mirror"* ]]
}

@test "cap: mirror-only / current>limit → over=true" {
  out="$(_cap_stdout mirror-only 5 3)"
  [[ "$out" == *"over=true"* ]]
  [[ "$out" == *"scope=mirror"* ]]
}

@test "cap: local-and-mirror → scope=combined（合算）" {
  out="$(_cap_stdout local-and-mirror 2 3)"
  [[ "$out" == *"over=false"* ]]
  [[ "$out" == *"scope=combined"* ]]
}

@test "cap: local-and-mirror / current==limit → over=true / scope=combined" {
  out="$(_cap_stdout local-and-mirror 3 3)"
  [[ "$out" == *"over=true"* ]]
  [[ "$out" == *"scope=combined"* ]]
}

@test "cap: interactive → over=false / scope=none（暫定。呼出側が wizard 起動後に再 check）" {
  out="$(_cap_stdout interactive 99 3)"
  [[ "$out" == *"over=false"* ]]
  [[ "$out" == *"scope=none"* ]]
}

@test "cap: disabled → over=false / scope=none（cap 不適用）" {
  out="$(_cap_stdout disabled 99 3)"
  [[ "$out" == *"over=false"* ]]
  [[ "$out" == *"scope=none"* ]]
}

@test "cap: 未知 mode → over=true / scope=none（保守的に「起票させない」）" {
  out="$(_cap_stdout invalid_mode 0 3)"
  [[ "$out" == *"over=true"* ]]
  [[ "$out" == *"scope=none"* ]]
}

@test "cap: current が整数でない → exit 2" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_cap_check local-issue-only abc 3"
  [ "$status" -eq 2 ]
}

@test "cap: limit が整数でない → exit 2" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_cap_check local-issue-only 0 limit"
  [ "$status" -eq 2 ]
}

@test "cap: 引数不足 → exit 2" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_cap_check local-issue-only 1"
  [ "$status" -eq 2 ]
}

@test "cap: limit=0 / current=0 → over=true（0件で既に上限到達 / current >= limit）" {
  out="$(_cap_stdout mirror-only 0 0)"
  [[ "$out" == *"over=true"* ]]
}

@test "cap: 出力フォーマット（key=value 2 行）" {
  out="$(_cap_stdout mirror-only 1 3)"
  # 2 行であること
  line_count="$(printf '%s' "$out" | grep -c '^')"
  [ "$line_count" -eq 2 ]
}
