#!/usr/bin/env bats
# Unit 001: feedback-mode.sh の純粋関数 + wizard 関数の単体テスト
# 04-completion §1.5 経由の統合テストは Unit 002 範囲（本ファイルでは扱わない）

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  FEEDBACK_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/feedback-mode.sh"
  WIZARD_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/feedback-mode-wizard.sh"
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-fmw-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}/project"
  mkdir -p "${AIDLC_PROJECT_ROOT}/.aidlc"
  printf '' >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  git -C "${AIDLC_PROJECT_ROOT}" init --quiet 2>/dev/null || true
  export AIDLC_PLUGIN_ROOT="${REPO_ROOT}/skills/aidlc"
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "$HOME/.aidlc"
}

teardown() {
  cd "$BATS_TMPDIR"
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# ----- is_interactive_env -----

@test "is_interactive_env: 非tty環境では false" {
  run bash -c "source '$FEEDBACK_LIB' && is_interactive_env"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "is_interactive_env: CI=1 環境変数では false（tty があっても）" {
  export CI=1
  run bash -c "source '$FEEDBACK_LIB' && is_interactive_env"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
  unset CI
}

@test "is_interactive_env: AIDLC_NON_INTERACTIVE=1 では false" {
  export AIDLC_NON_INTERACTIVE=1
  run bash -c "source '$FEEDBACK_LIB' && is_interactive_env"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
  unset AIDLC_NON_INTERACTIVE
}

# ----- feedback_mode_normalize -----

@test "normalize: interactive はそのまま" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_normalize interactive"
  [ "$status" -eq 0 ]
  [ "$output" = "interactive" ]
}

@test "normalize: 5 値新値はそのまま" {
  for v in interactive local-issue-only mirror-only local-and-mirror disabled; do
    run bash -c "source '$FEEDBACK_LIB' && feedback_mode_normalize '$v'"
    [ "$status" -eq 0 ]
    [ "$output" = "$v" ]
  done
}

@test "normalize: 旧 silent → interactive" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_normalize silent"
  [ "$status" -eq 0 ]
  [ "$output" = "interactive" ]
}

@test "normalize: 旧 mirror → mirror-only" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_normalize mirror"
  [ "$status" -eq 0 ]
  [ "$output" = "mirror-only" ]
}

@test "normalize: 空文字 → interactive（新規セットアップ既定）" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_normalize ''"
  [ "$status" -eq 0 ]
  [ "$output" = "interactive" ]
}

@test "normalize: 未知値 → disabled + warn（exit 0 / set -e セーフ）" {
  # stdout だけを取得（stderr の warn は除外）
  out="$(bash -c "source '$FEEDBACK_LIB' && feedback_mode_normalize unknown_value 2>/dev/null")"
  [ "$out" = "disabled" ]
  # stderr に warn が出ている
  err="$(bash -c "source '$FEEDBACK_LIB' && feedback_mode_normalize unknown_value 2>&1 >/dev/null")"
  [[ "$err" == *"feedback_mode_unknown"* ]]
}

@test "normalize: 引数なし → exit 2" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_normalize"
  [ "$status" -eq 2 ]
}

# ----- feedback_mode_resolve -----

@test "resolve: interactive × tty=true → disabled（暫定 / 呼出側が wizard 起動）" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_resolve interactive true"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "resolve: interactive × tty=false → disabled" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_resolve interactive false"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "resolve: local-issue-only → local_only" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_resolve local-issue-only true"
  [ "$status" -eq 0 ]
  [[ "$output" == *"local_only"* ]]
}

@test "resolve: mirror-only → mirror_only" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_resolve mirror-only true"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mirror_only"* ]]
}

@test "resolve: local-and-mirror → both" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_resolve local-and-mirror true"
  [ "$status" -eq 0 ]
  [[ "$output" == *"both"* ]]
}

@test "resolve: disabled → disabled" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_resolve disabled true"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "resolve: 未知値 → disabled + warn" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_resolve unknown true"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "resolve: 引数不足 → exit 2" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_resolve interactive"
  [ "$status" -eq 2 ]
}

# ----- feedback_mode_requires_wizard -----

@test "requires_wizard: interactive × tty=true → true" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_requires_wizard interactive true"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "requires_wizard: interactive × tty=false → false" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_requires_wizard interactive false"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "requires_wizard: local-issue-only × tty=true → false（wizard 不要）" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_requires_wizard local-issue-only true"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "requires_wizard: 引数不足 → exit 2" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_requires_wizard interactive"
  [ "$status" -eq 2 ]
}

# ----- feedback_mode_save (write-config.sh ラップ) -----

@test "save: 5 値新値の書込が成功する" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_save mirror-only local"
  [ "$status" -eq 0 ]
  # 個人設定として書き込まれる
  [ -f "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml" ]
  grep -q 'feedback_mode' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
  grep -q 'mirror-only' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
}

@test "save: enum 違反 → exit 2 + 書込まれない" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_save invalid local"
  [ "$status" -eq 2 ]
  ! grep -q 'invalid' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml" 2>/dev/null
}

@test "save: scope=invalid → exit 2" {
  run bash -c "source '$FEEDBACK_LIB' && feedback_mode_save mirror-only bogus_scope"
  [ "$status" -eq 2 ]
}

# ----- feedback_mode_wizard 起動条件（非対話で拒否） -----

@test "wizard: 非対話環境で呼ばれた場合 exit 2" {
  export AIDLC_NON_INTERACTIVE=1
  run bash -c "source '$WIZARD_LIB' && feedback_mode_wizard"
  [ "$status" -eq 2 ]
  unset AIDLC_NON_INTERACTIVE
}

# ----- feedback_mode_wizard 成功経路（AIDLC_FORCE_INTERACTIVE で tty 検査をバイパス） -----

@test "wizard: 入力 1 → interactive 選択で保存 + stdout に interactive を返す" {
  export AIDLC_FORCE_INTERACTIVE=1
  out="$(printf '1\n' | bash -c "source '$WIZARD_LIB' && feedback_mode_wizard 2>/dev/null")"
  [ "$out" = "interactive" ]
  grep -q 'feedback_mode' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
  grep -q 'interactive' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
  unset AIDLC_FORCE_INTERACTIVE
}

@test "wizard: 入力 2 → local-issue-only 保存 + 戻り値" {
  export AIDLC_FORCE_INTERACTIVE=1
  out="$(printf '2\n' | bash -c "source '$WIZARD_LIB' && feedback_mode_wizard 2>/dev/null")"
  [ "$out" = "local-issue-only" ]
  grep -q 'local-issue-only' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
  unset AIDLC_FORCE_INTERACTIVE
}

@test "wizard: 入力 3 → mirror-only 保存 + 戻り値" {
  export AIDLC_FORCE_INTERACTIVE=1
  out="$(printf '3\n' | bash -c "source '$WIZARD_LIB' && feedback_mode_wizard 2>/dev/null")"
  [ "$out" = "mirror-only" ]
  grep -q 'mirror-only' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
  unset AIDLC_FORCE_INTERACTIVE
}

@test "wizard: 入力 4 → local-and-mirror 保存 + 戻り値" {
  export AIDLC_FORCE_INTERACTIVE=1
  out="$(printf '4\n' | bash -c "source '$WIZARD_LIB' && feedback_mode_wizard 2>/dev/null")"
  [ "$out" = "local-and-mirror" ]
  grep -q 'local-and-mirror' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
  unset AIDLC_FORCE_INTERACTIVE
}

@test "wizard: 入力 5 → disabled 保存 + 戻り値" {
  export AIDLC_FORCE_INTERACTIVE=1
  out="$(printf '5\n' | bash -c "source '$WIZARD_LIB' && feedback_mode_wizard 2>/dev/null")"
  [ "$out" = "disabled" ]
  grep -q 'disabled' "${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
  unset AIDLC_FORCE_INTERACTIVE
}

@test "wizard: 不正入力 → 再入力 → 1 で interactive 確定" {
  export AIDLC_FORCE_INTERACTIVE=1
  out="$(printf '99\nfoo\n1\n' | bash -c "source '$WIZARD_LIB' && feedback_mode_wizard 2>/dev/null")"
  [ "$out" = "interactive" ]
  unset AIDLC_FORCE_INTERACTIVE
}

@test "wizard: EOF（中断）→ exit 1" {
  export AIDLC_FORCE_INTERACTIVE=1
  run bash -c "source '$WIZARD_LIB' && feedback_mode_wizard </dev/null"
  [ "$status" -eq 1 ]
  unset AIDLC_FORCE_INTERACTIVE
}
