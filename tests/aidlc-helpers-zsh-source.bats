#!/usr/bin/env bats
# Unit 004 (#659) / Unit 002 (#661): helper の zsh source 互換性テスト
# 各 helper を bash と zsh の両方で source して動作確認する。
# SCRIPT_DIR を持つ helper（predecessor-issue.sh / retrospective-issue.sh）は
# source 後の SCRIPT_DIR 系変数が空でない有効な絶対パスとして解決されることも検証する。
#
# v2.5.4 Unit 004 (#659) で predecessor-issue.sh の zsh 対応を実装、
# v2.5.5 Unit 002 (#661) で retrospective-issue.sh も同パターンで対応済み。
# 両 helper とも bash / zsh 両経路で SCRIPT_DIR 解決と動作を検証する。

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

@test "zsh-source: retrospective-issue.sh source 動作確認 + SCRIPT_DIR（bash / zsh 両対応）" {
  # bash 経路: 独立契約 C1〜C4（status 0 / SCRIPT_DIR 非空 / 実在ディレクトリ / HELPER_LIB_DIR 一致）
  run bash -c "source '${HELPER_LIB_DIR}/retrospective-issue.sh' && printf '%s' \"\${__RETRO_ISSUE_SCRIPT_DIR}\""
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  [ -d "$output" ]
  [ "$output" = "${HELPER_LIB_DIR}" ]

  if [ "$AIDLC_ZSH_AVAILABLE" = "true" ]; then
    # zsh 経路: 同じく独立契約 C1〜C4（v2.5.5 Unit 002 修正対象）
    run zsh -c "source '${HELPER_LIB_DIR}/retrospective-issue.sh' && printf '%s' \"\${__RETRO_ISSUE_SCRIPT_DIR}\""
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -d "$output" ]
    [ "$output" = "${HELPER_LIB_DIR}" ]
  else
    skip "zsh not available"
  fi
}
