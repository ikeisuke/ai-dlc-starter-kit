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

@test "GE4: 不正な feedback_mode (on) → warn\tfeedback_mode_unknown + disabled スキップ（v2.5.1 / Unit 001）" {
  # v2.5.1 で fallback 値を silent → disabled に変更（保守的フォールバック）。
  # feedback-mode.sh の feedback_mode_normalize() が未知値を disabled に正規化し、
  # その後の retrospective-generate.sh が disabled としてスキップする。
  setup_env
  set_project_feedback_mode "on"
  run run_generate v2.5.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn	feedback_mode_unknown	on"* ]]
  [[ "$output" == *"retrospective	skip	disabled"* ]]
}

@test "GE5: 旧版にあった cycle 番号バージョンガードは Issue #625 fix で撤廃された（cycle 番号と starter kit 番号の名前空間混同バグ修正）" {
  setup_env
  # 旧版では cycle が v2.5.0 未満の場合 cycle-too-old skip だったが、撤廃したため通常生成される
  run run_generate v1.14.2
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
  [ -f "${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v1.14.2/operations/retrospective.md" ]
}

@test "GE6: cycle 引数のパストラバーサル防止検証（codex P1 対応 / Issue #625 fix）" {
  setup_env

  # `../` 含むパスは弾く
  run run_generate "../etc"
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid-cycle-format"* ]]

  # `/` 含むパスは弾く
  run run_generate "v2.5.0/foo"
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid-cycle-format"* ]]

  # `..` 単独は弾く（regex には match するが、ディレクトリトラバーサルとして機能するため）
  run run_generate ".."
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid-cycle-format"* ]]

  # `.` 単独も弾く
  run run_generate "."
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid-cycle-format"* ]]

  # 通常の SemVer プレフィックス付きは通る
  run run_generate "v2.5.0-test"
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]

  # visitory 形式 (v1.14.2) も通る
  run run_generate "v1.14.2"
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]

  # 日付サイクル (2024-12) も通る
  run run_generate "2024-12"
  [ "$status" -eq 0 ]
  [[ "$output" == *"retrospective	created	"* ]]
}
