#!/usr/bin/env bats
# Unit 005 (#667): retrospective-api.sh Facade 層の公開関数群を検証する。
# - 公開関数の存在
# - 各関数が内部 lib に委譲されること
# - 出力タイプ（A/B）規約

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  API="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-api.sh"
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-retro-api-XXXXXX)"
}

teardown() {
  cd "$BATS_TMPDIR"
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

load_api_fresh() {
  unset RETROSPECTIVE_API_SOURCED
  # shellcheck disable=SC1090
  source "$API"
}

@test "Facade: 全公開関数が定義されている（タイプ A 2 件 + タイプ B 8 件）" {
  load_api_fresh
  for fn in \
    retrospective_api_resolve_feedback_mode \
    retrospective_api_requires_wizard \
    retrospective_api_run_wizard \
    retrospective_api_check_cap \
    retrospective_api_compose_body \
    retrospective_api_is_interactive_env \
    retrospective_api_prefill \
    retrospective_api_update_issue \
    retrospective_api_record_response \
    retrospective_api_create_issue ; do
    declare -F "$fn" >/dev/null
    [ "$?" -eq 0 ] || { echo "missing: $fn" >&2 ; return 1 ; }
  done
}

@test "resolve_feedback_mode: 5 値正規系の透過" {
  load_api_fresh
  for v in interactive local-issue-only mirror-only local-and-mirror disabled ; do
    run retrospective_api_resolve_feedback_mode "$v"
    [ "$status" -eq 0 ]
    [[ "$output" == "$v" ]]
  done
}

@test "resolve_feedback_mode: 旧値互換入力の正規化（silent → interactive / mirror → mirror-only）" {
  load_api_fresh
  run retrospective_api_resolve_feedback_mode "silent"
  [ "$status" -eq 0 ]
  [[ "$output" == "interactive" ]]

  run retrospective_api_resolve_feedback_mode "mirror"
  [ "$status" -eq 0 ]
  [[ "$output" == "mirror-only" ]]
}

@test "resolve_feedback_mode: 空文字 → interactive fallback" {
  load_api_fresh
  run retrospective_api_resolve_feedback_mode ""
  [ "$status" -eq 0 ]
  [[ "$output" == "interactive" ]]
}

@test "resolve_feedback_mode: 未知値 → disabled（warn 通知付き）" {
  load_api_fresh
  run retrospective_api_resolve_feedback_mode "unknown-value"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}

@test "requires_wizard: interactive × tty=true → true（Facade 経由）" {
  load_api_fresh
  run retrospective_api_requires_wizard "interactive" "true"
  [ "$status" -eq 0 ]
  [[ "$output" == "true" ]]
}

@test "requires_wizard: interactive × tty=false → false" {
  load_api_fresh
  run retrospective_api_requires_wizard "interactive" "false"
  [ "$status" -eq 0 ]
  [[ "$output" == "false" ]]
}

@test "requires_wizard: 5 値正規系の非 interactive → false（wizard 不要）" {
  load_api_fresh
  for v in local-issue-only mirror-only local-and-mirror disabled ; do
    run retrospective_api_requires_wizard "$v" "true"
    [ "$status" -eq 0 ]
    [[ "$output" == "false" ]] || { echo "v=$v output=$output" >&2 ; return 1 ; }
  done
}

@test "is_interactive_env: tty 判定が委譲される（true / false どちらかを返す）" {
  load_api_fresh
  run retrospective_api_is_interactive_env
  [ "$status" -eq 0 ]
  [[ "$output" == "true" || "$output" == "false" ]]
}

@test "Facade: 多重 source ガード（2 回目の source は no-op）" {
  load_api_fresh
  # 2 回目の source（RETROSPECTIVE_API_SOURCED は既に 1）
  run bash -c "source '$API' ; source '$API' ; declare -F retrospective_api_requires_wizard >/dev/null && echo loaded"
  [ "$status" -eq 0 ]
  [[ "$output" == *"loaded"* ]]
}
