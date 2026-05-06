#!/usr/bin/env bats
# Unit 001: feedback_mode マイグレーション写像表の単体テスト
# migrate-feedback-mode.sh の decide ロジックを検証する。
# 実書込みは migrate-apply-config.sh が manifest 経由で行う（本テストは decide 層に限定）。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  MIGRATE_FB="${REPO_ROOT}/skills/aidlc-migrate/scripts/migrate-feedback-mode.sh"
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-fmm-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}/project"
  mkdir -p "${AIDLC_PROJECT_ROOT}/.aidlc"
  printf '' >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  git -C "${AIDLC_PROJECT_ROOT}" init --quiet 2>/dev/null || true
  export AIDLC_PLUGIN_ROOT="${REPO_ROOT}/skills/aidlc"
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "$HOME/.aidlc"
  # AIDLC_NON_INTERACTIVE をデフォルトでセット（テスト環境は非対話）
  export AIDLC_NON_INTERACTIVE=1
}

teardown() {
  unset AIDLC_NON_INTERACTIVE
  cd "$BATS_TMPDIR"
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

set_project_feedback_mode() {
  local mode="$1"
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<EOF
[rules.retrospective]
feedback_mode = "${mode}"
EOF
}

create_manifest() {
  local manifest="${TEST_TMPDIR}/manifest.json"
  printf '{"resources": []}\n' >"$manifest"
  printf '%s' "$manifest"
}

@test "migrate: silent → 非対話で disabled fallback（consent=non_interactive_fallback）" {
  set_project_feedback_mode "silent"
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"from": "silent"'* ]]
  [[ "$output" == *'"to": "disabled"'* ]]
  [[ "$output" == *'"consent_outcome": "non_interactive_fallback"'* ]]
}

@test "migrate: 未設定（key 不在）→ 非対話で disabled fallback" {
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest"
  [ "$status" -eq 0 ]
  # raw が空文字 → fallback=disabled
  [[ "$output" == *'"to": "disabled"'* ]]
  [[ "$output" == *'"consent_outcome": "non_interactive_fallback"'* ]]
}

@test "migrate: mirror → mirror-only（同意不要）" {
  set_project_feedback_mode "mirror"
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"from": "mirror"'* ]]
  [[ "$output" == *'"to": "mirror-only"'* ]]
  [[ "$output" == *'"consent_outcome": "not_required"'* ]]
}

@test "migrate: disabled → disabled（同意不要 / skipped）" {
  set_project_feedback_mode "disabled"
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"from": "disabled"'* ]]
  [[ "$output" == *'"to": "disabled"'* ]]
  [[ "$output" == *'"status": "skipped"'* ]]
}

@test "migrate: interactive（既マイグレーション済み）→ skipped" {
  set_project_feedback_mode "interactive"
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"to": "interactive"'* ]]
  [[ "$output" == *'"status": "skipped"'* ]]
}

@test "migrate: local-issue-only（既マイグレーション済み）→ skipped" {
  set_project_feedback_mode "local-issue-only"
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"to": "local-issue-only"'* ]]
  [[ "$output" == *'"status": "skipped"'* ]]
}

@test "migrate: 未知値 → 保守的に disabled" {
  set_project_feedback_mode "garbage_value"
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"to": "disabled"'* ]]
}

@test "migrate: --non-interactive 強制で silent → disabled fallback（既に AIDLC_NON_INTERACTIVE 効いていないケース確認）" {
  set_project_feedback_mode "silent"
  manifest="$(create_manifest)"
  unset AIDLC_NON_INTERACTIVE
  run bash "$MIGRATE_FB" --manifest "$manifest" --non-interactive
  [ "$status" -eq 0 ]
  [[ "$output" == *'"to": "disabled"'* ]]
  [[ "$output" == *'"consent_outcome": "non_interactive_fallback"'* ]]
  export AIDLC_NON_INTERACTIVE=1
}

@test "migrate: --dry-run では manifest を更新しない" {
  set_project_feedback_mode "mirror"
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest" --dry-run
  [ "$status" -eq 0 ]
  # manifest の resources は空のまま
  resources_count="$(jq '.resources | length' "$manifest")"
  [ "$resources_count" = "0" ]
}

@test "migrate: --manifest なし → exit 2" {
  run bash "$MIGRATE_FB"
  [ "$status" -eq 2 ]
}

@test "migrate: 不明オプション → exit 2" {
  run bash "$MIGRATE_FB" --bogus
  [ "$status" -eq 2 ]
}

@test "migrate: silent → interactive 同意 accepted（AIDLC_FORCE_INTERACTIVE で tty 検査バイパス + y 入力）" {
  set_project_feedback_mode "silent"
  manifest="$(create_manifest)"
  unset AIDLC_NON_INTERACTIVE
  export AIDLC_FORCE_INTERACTIVE=1
  out="$(printf 'y\n' | bash "$MIGRATE_FB" --manifest "$manifest" 2>/dev/null)"
  [[ "$out" == *'"to": "interactive"'* ]]
  [[ "$out" == *'"consent_outcome": "accepted"'* ]]
  unset AIDLC_FORCE_INTERACTIVE
  export AIDLC_NON_INTERACTIVE=1
}

@test "migrate: silent → 同意 rejected（n 入力 → disabled fallback）" {
  set_project_feedback_mode "silent"
  manifest="$(create_manifest)"
  unset AIDLC_NON_INTERACTIVE
  export AIDLC_FORCE_INTERACTIVE=1
  out="$(printf 'n\n' | bash "$MIGRATE_FB" --manifest "$manifest" 2>/dev/null)"
  [[ "$out" == *'"to": "disabled"'* ]]
  [[ "$out" == *'"consent_outcome": "rejected"'* ]]
  unset AIDLC_FORCE_INTERACTIVE
  export AIDLC_NON_INTERACTIVE=1
}

@test "migrate: mirror（同意不要）で manifest が更新される" {
  set_project_feedback_mode "mirror"
  manifest="$(create_manifest)"
  run bash "$MIGRATE_FB" --manifest "$manifest"
  [ "$status" -eq 0 ]
  resources_count="$(jq '.resources | length' "$manifest")"
  [ "$resources_count" = "1" ]
  to_value="$(jq -r '.resources[0].to' "$manifest")"
  [ "$to_value" = "mirror-only" ]
  resource_type="$(jq -r '.resources[0].resource_type' "$manifest")"
  [ "$resource_type" = "feedback_mode_migrate" ]
}
