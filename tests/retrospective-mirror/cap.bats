#!/usr/bin/env bats
# cap.bats - 観点 F (Filter / cap) + DI2〜DI6 (detect 統合)
# Unit 006: サイクル毎上限ガード（feedback_max_per_cycle）

load helpers/setup.bash

setup() {
  setup_env
  set_project_feedback_mode "mirror"
}

teardown() {
  teardown_env
}

# project-local config に feedback_max_per_cycle を追加
_set_max() {
  local max="$1"
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<EOF
[rules.retrospective]
feedback_mode = "mirror"
feedback_max_per_cycle = ${max}
EOF
}

# F6: 上限超過なし（候補 5 件 / max=5）→ 全通過
@test "F6: cap - max=5 で 5 件全通過" {
  _set_max 5
  copy_fixture "cap-exceeded-5items" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]

  candidate_count="$(echo "$output" | grep -c "^mirror"$'\t'"candidate"$'\t' || true)"
  [ "$candidate_count" -eq 5 ]
  [[ "$output" == *"cap-exceeded=0"* ]]
}

# F7: 上限超過（候補 5 件 / max=3）→ 3 件通過 + 2 件 cap-exceeded
@test "F7: cap - max=3 で 3 件通過 + 2 件 cap-exceeded" {
  _set_max 3
  copy_fixture "cap-exceeded-5items" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]

  candidate_count="$(echo "$output" | grep -c "^mirror"$'\t'"candidate"$'\t' || true)"
  [ "$candidate_count" -eq 3 ]

  cap_count="$(echo "$output" | grep -c "^mirror"$'\t'"cap-exceeded"$'\t' || true)"
  [ "$cap_count" -eq 2 ]

  # idx 1, 2, 3 が candidate / idx 4, 5 が cap-exceeded
  [[ "$output" == *"mirror"$'\t'"candidate"$'\t'"1"$'\t'* ]]
  [[ "$output" == *"mirror"$'\t'"candidate"$'\t'"2"$'\t'* ]]
  [[ "$output" == *"mirror"$'\t'"candidate"$'\t'"3"$'\t'* ]]
  [[ "$output" == *"mirror"$'\t'"cap-exceeded"$'\t'"4"$'\t'* ]]
  [[ "$output" == *"mirror"$'\t'"cap-exceeded"$'\t'"5"$'\t'* ]]
}

# F8: dedup → cap の順序保証（dedup-quote-match で 1 件通過 → cap=1 でも超過なし）
@test "F8: dedup → cap 順序 - dedup 後の通過候補が cap 対象" {
  _set_max 1
  copy_fixture "dedup-quote-match" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]

  # dedup で 1 件のみ残る → cap=1 で全通過
  candidate_count="$(echo "$output" | grep -c "^mirror"$'\t'"candidate"$'\t' || true)"
  [ "$candidate_count" -eq 1 ]
  [[ "$output" == *"cap-exceeded=0"* ]]
  [[ "$output" == *"dedup-merged=2"* ]]
}

# DI2: cap-exceeded フィクスチャ全体で TSV 行 + summary 整合（max=3）
@test "DI2: detect 統合 - cap-exceeded フィクスチャで全 TSV 行整合" {
  _set_max 3
  copy_fixture "cap-exceeded-5items" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]

  [[ "$output" == *"total=5"* ]]
  [[ "$output" == *"skill_caused_true=5"* ]]
  [[ "$output" == *"already-processed=0"* ]]
  [[ "$output" == *"dedup-merged=0"* ]]
  [[ "$output" == *"cap-exceeded=2"* ]]
}

# DI3: summary 行に新規拡張フィールド（dedup-merged / cap-exceeded）が存在
@test "DI3: summary 行 - 拡張フィールド dedup-merged + cap-exceeded を含む" {
  copy_fixture "single-skill-caused-empty" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"summary"$'\t'"counts"$'\t'* ]]
  [[ "$output" == *"dedup-merged="* ]]
  [[ "$output" == *"cap-exceeded="* ]]
}

# DI4: feedback_max_per_cycle = 0 で全 candidate cap-exceeded
@test "DI4: cap - max=0 で全 candidate が cap-exceeded" {
  _set_max 0
  copy_fixture "cap-exceeded-5items" "$(test_retrospective_path)"

  run run_mirror detect "$(test_retrospective_path)"
  [ "$status" -eq 0 ]

  candidate_count="$(echo "$output" | grep -c "^mirror"$'\t'"candidate"$'\t' || true)"
  [ "$candidate_count" -eq 0 ]

  cap_count="$(echo "$output" | grep -c "^mirror"$'\t'"cap-exceeded"$'\t' || true)"
  [ "$cap_count" -eq 5 ]
  [[ "$output" == *"cap-exceeded=5"* ]]
}

# DI5: feedback_max_per_cycle 不正値（"abc"）でスキーマ default fallback + warn
@test "DI5: cap - 不正値で schema default 3 にフォールバック + warn ログ" {
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<EOF
[rules.retrospective]
feedback_mode = "mirror"
feedback_max_per_cycle = "abc"
EOF
  copy_fixture "cap-exceeded-5items" "$(test_retrospective_path)"

  # stderr を別ファイルに分けて検証（warn ログを確実にアサート）
  stderr_tmp="${TEST_TMPDIR}/stderr.log"
  run bash -c "'${MIRROR_SCRIPT}' detect '$(test_retrospective_path)' 2>'${stderr_tmp}'"
  [ "$status" -eq 0 ]

  # default 3 にフォールバック → 3 件通過 + 2 件 cap-exceeded
  candidate_count="$(echo "$output" | grep -c "^mirror"$'\t'"candidate"$'\t' || true)"
  [ "$candidate_count" -eq 3 ]
  cap_count="$(echo "$output" | grep -c "^mirror"$'\t'"cap-exceeded"$'\t' || true)"
  [ "$cap_count" -eq 2 ]

  # warn ログが stderr に出力されている（厳密検証）
  grep -q "warn"$'\t'"feedback-max-per-cycle-invalid" "${stderr_tmp}"
}

# DI6: _check_python3 関数 - python3 不在で fatal（exit 2 + nfkc-unavailable）
# 実装本体（retrospective-mirror.sh）から _check_python3 関数定義のみを抽出して
# 一時ファイルに保存し、PATH="" 環境で本物の関数を source 経由で検証する。
@test "DI6: _check_python3 - python3 不在で error 出力 + return 2 (実装本体検証)" {
  # 関数定義抽出（PATH 制限前に awk が利用可能な状態で実施）
  fn_file="${TEST_TMPDIR}/check_python3.sh"
  awk '/^_check_python3\(\) \{/,/^\}/' "${MIRROR_SCRIPT}" >"${fn_file}"
  # 抽出が成功したことを確認
  grep -q "command -v python3" "${fn_file}"

  # PATH="" で実装本体の _check_python3 を呼び出し（python3 検出失敗を強制）
  result_status=0
  result_output="$(PATH="" /bin/bash -c "source '${fn_file}'; _check_python3" 2>&1)" || result_status=$?

  [ "$result_status" -eq 2 ]
  [[ "$result_output" == *"error"$'\t'"nfkc-unavailable"$'\t'"python3-required"* ]]
}
