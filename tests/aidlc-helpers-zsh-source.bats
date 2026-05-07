#!/usr/bin/env bats
# Unit 004 (#659): helper の zsh source 互換性テスト
# 各 helper を bash と zsh の両方で source して動作確認する。
# SCRIPT_DIR を持つ helper（predecessor-issue.sh / retrospective-issue.sh）は
# source 後の SCRIPT_DIR 系変数が空でない有効な絶対パスとして解決されることも検証する。
#
# DR-001: 修正対象は predecessor-issue.sh の 1 ファイルに限定。
# retrospective-issue.sh は同種バグ（${BASH_SOURCE[0]} ベースの SCRIPT_DIR 解決）を
# 持つ可能性があるが本 Unit のスコープ外のため、zsh 経路は OUT_OF_SCOPE で skip する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  HELPER_LIB_DIR="${REPO_ROOT}/skills/aidlc/scripts/lib"

  if command -v zsh >/dev/null 2>&1; then
    AIDLC_ZSH_AVAILABLE=true
  else
    AIDLC_ZSH_AVAILABLE=false
  fi
}

# ─── leaf helper（SCRIPT_DIR 不使用）─────────

@test "zsh-source: aidlc-paths.sh source 動作確認（bash / zsh 両対応）" {
  run bash -c "source '${HELPER_LIB_DIR}/aidlc-paths.sh'"
  [ "$status" -eq 0 ]

  if [ "$AIDLC_ZSH_AVAILABLE" = "true" ]; then
    run zsh -c "source '${HELPER_LIB_DIR}/aidlc-paths.sh'"
    [ "$status" -eq 0 ]
  else
    skip "zsh not available"
  fi
}

@test "zsh-source: aidlc-validate.sh source 動作確認（bash / zsh 両対応）" {
  run bash -c "source '${HELPER_LIB_DIR}/aidlc-validate.sh'"
  [ "$status" -eq 0 ]

  if [ "$AIDLC_ZSH_AVAILABLE" = "true" ]; then
    run zsh -c "source '${HELPER_LIB_DIR}/aidlc-validate.sh'"
    [ "$status" -eq 0 ]
  else
    skip "zsh not available"
  fi
}

@test "zsh-source: aidlc-gh.sh source 動作確認（bash / zsh 両対応）" {
  run bash -c "source '${HELPER_LIB_DIR}/aidlc-gh.sh'"
  [ "$status" -eq 0 ]

  if [ "$AIDLC_ZSH_AVAILABLE" = "true" ]; then
    run zsh -c "source '${HELPER_LIB_DIR}/aidlc-gh.sh'"
    [ "$status" -eq 0 ]
  else
    skip "zsh not available"
  fi
}

@test "zsh-source: aidlc-spool.sh source 動作確認（bash / zsh 両対応）" {
  run bash -c "source '${HELPER_LIB_DIR}/aidlc-spool.sh'"
  [ "$status" -eq 0 ]

  if [ "$AIDLC_ZSH_AVAILABLE" = "true" ]; then
    run zsh -c "source '${HELPER_LIB_DIR}/aidlc-spool.sh'"
    [ "$status" -eq 0 ]
  else
    skip "zsh not available"
  fi
}

# ─── SCRIPT_DIR 使用 helper ─────────

@test "zsh-source: predecessor-issue.sh source 動作確認 + SCRIPT_DIR（bash / zsh 両対応）" {
  # bash 経路: source + __PRED_SCRIPT_DIR が有効な絶対パス
  run bash -c "source '${HELPER_LIB_DIR}/predecessor-issue.sh' && printf '%s' \"\${__PRED_SCRIPT_DIR}\""
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  [ -d "$output" ]
  [ "$output" = "${HELPER_LIB_DIR}" ]

  if [ "$AIDLC_ZSH_AVAILABLE" = "true" ]; then
    # zsh 経路: source + __PRED_SCRIPT_DIR が有効な絶対パス（Unit 004 修正対象）
    run zsh -c "source '${HELPER_LIB_DIR}/predecessor-issue.sh' && printf '%s' \"\${__PRED_SCRIPT_DIR}\""
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -d "$output" ]
    [ "$output" = "${HELPER_LIB_DIR}" ]
  else
    skip "zsh not available"
  fi
}

@test "zsh-source: retrospective-issue.sh source 動作確認 + SCRIPT_DIR（bash 必須、zsh は OUT_OF_SCOPE）" {
  # bash 経路: source + __RETRO_ISSUE_SCRIPT_DIR が有効な絶対パス
  run bash -c "source '${HELPER_LIB_DIR}/retrospective-issue.sh' && printf '%s' \"\${__RETRO_ISSUE_SCRIPT_DIR}\""
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  [ -d "$output" ]
  [ "$output" = "${HELPER_LIB_DIR}" ]

  # zsh 経路: DR-001 不変条件により retrospective-issue.sh への構造変更は禁止のため OUT_OF_SCOPE 扱い
  # （同種バグの可能性が高いため skip 化、修正は next-cycle 候補としてバックログ Issue 起票で対応）
  skip "OUT_OF_SCOPE: see backlog #661"
}
