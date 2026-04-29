#!/usr/bin/env bats
# Unit 004: 観点 GE - retrospective-generate.sh

load helpers/setup

teardown() { teardown_env; }

@test "GE1: 通常生成 → retrospective\tcreated\t<path> + ファイル作成 + 「問題なし」自動補完" {
  setup_env
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
  local expected_path="${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.5.0/operations/retrospective.md"
  [ -f "$expected_path" ]
  # テンプレートには `### 問題 1: {{タイトル}}` が含まれるため、ガード条件
  # `! grep -q "^### 問題 "` が false となり、補完は実行されない（現テンプレート）。
  # ただし「補完が実行されたケース」を区別するため、コメント外の見出し行を厳密に検出する。
  # コメント外の `^### 問題なし$` 行が存在しないことを確認（補完未実行）。
  ! grep -E "^### 問題なし\$" "$expected_path"
  # コメント内の説明文字列は残っている（テンプレート由来）
  grep -F "### 問題なし" "$expected_path"
}

@test "GE1b: テンプレートに「問題」見出しが無い場合の補完経路（コメント外に追記）" {
  setup_env
  # テンプレート差し替え用一時ディレクトリ + AIDLC_PLUGIN_ROOT 切り替え
  local tmp_plugin="${TEST_TMPDIR}/plugin"
  mkdir -p "${tmp_plugin}/templates" "${tmp_plugin}/config" "${tmp_plugin}/scripts/lib"
  # テンプレートを最小化（「問題」見出しを含まない）
  cat >"${tmp_plugin}/templates/retrospective_template.md" <<'EOF'
# Retrospective: {{CYCLE}}

## 概要

(本文)
EOF
  # 必要 lib / config を実体からコピー
  cp "${REPO_ROOT}/skills/aidlc/scripts/lib/bootstrap.sh" "${tmp_plugin}/scripts/lib/"
  cp "${REPO_ROOT}/skills/aidlc/scripts/lib/cycle-version-check.sh" "${tmp_plugin}/scripts/lib/"
  cp "${REPO_ROOT}/skills/aidlc/config/retrospective-schema.yml" "${tmp_plugin}/config/"
  cp "${REPO_ROOT}/skills/aidlc/config/defaults.toml" "${tmp_plugin}/config/"
  cp "${REPO_ROOT}/skills/aidlc/scripts/read-config.sh" "${tmp_plugin}/scripts/"

  AIDLC_PLUGIN_ROOT="${tmp_plugin}" run bash "${REPO_ROOT}/skills/aidlc/scripts/retrospective-generate.sh" v2.5.0
  [ "$status" -eq 0 ]
  local expected_path="${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.5.0/operations/retrospective.md"
  [ -f "$expected_path" ]
  # コメント外の `### 問題なし` 行が補完されている
  grep -E "^### 問題なし\$" "$expected_path"
}

@test "GE2: feedback_mode = disabled → retrospective\tskip\tdisabled + ファイル作成なし" {
  setup_env
  set_project_feedback_mode "disabled"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
  [ ! -f "${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.5.0/operations/retrospective.md" ]
}

@test "GE3: 既存ファイル → retrospective\tskip\talready-exists + ファイル変更なし" {
  setup_env
  local target="${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.5.0/operations/retrospective.md"
  mkdir -p "$(dirname "$target")"
  echo "preexisting" >"$target"
  local before
  before=$(snapshot_sha "$target")

  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	already-exists"* ]]

  run assert_unchanged "$target" "$before"
  [ "$status" -eq 0 ]
}

@test "GE4: 不正な feedback_mode (on) → warn\tfeedback-mode-invalid + 通常生成" {
  setup_env
  set_project_feedback_mode "on"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn	feedback-mode-invalid	on:downgrade-to-silent"* ]]
  [[ "$output" == *"retrospective	created	"* ]]
}

@test "GE5: cycle が v2.4.3 → exit 0 + retrospective\tskip\tcycle-too-old + ファイル作成なし" {
  setup_env
  run run_generate v2.4.3
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	skip	cycle-too-old"* ]]
  [ ! -f "${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.4.3/operations/retrospective.md" ]
}

@test "GE6: cycle がフォーマット違反 → exit 2 + invalid-format" {
  setup_env
  run run_generate "2.5.0"
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid-format:2.5.0"* ]]
}
