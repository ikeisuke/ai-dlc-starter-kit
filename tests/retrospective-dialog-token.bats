#!/usr/bin/env bats
# Unit 001 (#647): 対話確認トークン関連関数の単体テスト
# - retrospective_dialog_token_record_response（発行）
# - retrospective_dialog_token_verify（検証）
# - retrospective_issue_create 内の verify ガード組み込み

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  RETRO_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-issue.sh"
  TMP="$(mktemp -d -t aidlc-retro-token.XXXXXX)"
  export TMPDIR="$TMP"
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP"
}

# ─── record_response 単体 ─────────

@test "record_response: approved 応答で成功 (exit 0)" {
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'approved'"
  [ "$status" -eq 0 ]
  [ -f "$TMP/aidlc-retro-confirmed-v2.5.3.flag" ]
  # 行 1=タイムスタンプ、行 2=approved
  line2=$(sed -n '2p' "$TMP/aidlc-retro-confirmed-v2.5.3.flag")
  [ "$line2" = "approved" ]
}

@test "record_response: denied 応答で成功 (exit 0)" {
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'denied'"
  [ "$status" -eq 0 ]
  line2=$(sed -n '2p' "$TMP/aidlc-retro-confirmed-v2.5.3.flag")
  [ "$line2" = "denied" ]
}

@test "record_response: 引数不足 (cycle のみ) → exit 1" {
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing_args"* ]]
}

@test "record_response: cycle に / を含む (path traversal) → exit 1" {
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response '../etc' 'approved'"
  [ "$status" -eq 1 ]
}

@test "record_response: response が approved/denied 以外 → exit 1" {
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'maybe'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid_response"* ]]
}

@test "record_response: ファイル権限が 0600 で書き出される" {
  bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'approved'"
  perm=$(stat -f '%Lp' "$TMP/aidlc-retro-confirmed-v2.5.3.flag" 2>/dev/null || stat -c '%a' "$TMP/aidlc-retro-confirmed-v2.5.3.flag")
  [ "$perm" = "600" ]
}

# ─── verify 単体 ─────────

@test "verify: 正常 (approved + 鮮度内) → exit 0" {
  bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'approved'"
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 0 ]
}

@test "verify: トークンファイル不在 → exit 4 / token_missing" {
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 4 ]
  [[ "$output" == *"token_missing"* ]]
}

@test "verify: TTL 切れ (1 秒 TTL で 2 秒スリープ) → exit 4 / token_stale" {
  bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'approved'"
  sleep 2
  run bash -c "AIDLC_RETRO_TOKEN_TTL_SECONDS=1 source '$RETRO_LIB' && AIDLC_RETRO_TOKEN_TTL_SECONDS=1 retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 4 ]
  [[ "$output" == *"token_stale"* ]]
}

@test "verify: response が denied → exit 4 / token_denied" {
  bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'denied'"
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 4 ]
  [[ "$output" == *"token_denied"* ]]
}

@test "verify: ファイル形式不正 (1 行のみ) → exit 4 / token_parse_error" {
  echo "2026-05-07T05:30:00Z" > "$TMP/aidlc-retro-confirmed-v2.5.3.flag"
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 4 ]
  [[ "$output" == *"token_parse_error"* ]]
}

@test "verify: ファイル形式不正 (response が approved/denied 以外) → exit 4 / token_parse_error" {
  printf '2026-05-07T05:30:00Z\nmaybe\n' > "$TMP/aidlc-retro-confirmed-v2.5.3.flag"
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 4 ]
  [[ "$output" == *"token_parse_error"* ]]
}

@test "verify: 引数不足 → exit 1" {
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing_args"* ]]
}

@test "verify: cycle path traversal → exit 1" {
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify '../etc'"
  [ "$status" -eq 1 ]
}

# ─── TTL 上書き確認 ─────────

@test "verify: AIDLC_RETRO_TOKEN_TTL_SECONDS=600 で TTL 拡大" {
  bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'approved'"
  sleep 1
  run bash -c "AIDLC_RETRO_TOKEN_TTL_SECONDS=600 source '$RETRO_LIB' && AIDLC_RETRO_TOKEN_TTL_SECONDS=600 retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 0 ]
}

@test "verify: AIDLC_RETRO_TOKEN_TTL_SECONDS が非数値 → デフォルト 300 にフォールバック" {
  bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'approved'"
  run bash -c "AIDLC_RETRO_TOKEN_TTL_SECONDS=abc source '$RETRO_LIB' && AIDLC_RETRO_TOKEN_TTL_SECONDS=abc retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 0 ]
}

# ─── token_io_error 追加検証 ─────────

@test "verify: トークンファイル読み取り権限なし → exit 4 / token_io_error" {
  bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'approved'"
  chmod 000 "$TMP/aidlc-retro-confirmed-v2.5.3.flag"
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify 'v2.5.3'"
  chmod 600 "$TMP/aidlc-retro-confirmed-v2.5.3.flag"
  [ "$status" -eq 4 ]
  [[ "$output" == *"token_io_error"* ]]
}

@test "verify: 行 1 が ISO 8601 形式不正 → exit 4 / token_parse_error" {
  printf 'not-a-timestamp\napproved\n' > "$TMP/aidlc-retro-confirmed-v2.5.3.flag"
  run bash -c "source '$RETRO_LIB' && retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 4 ]
  [[ "$output" == *"token_parse_error"* ]]
}

# ─── retrospective_issue_create 統合: verify ブロック経路 ─────────

@test "issue_create 統合: トークン未発行 → exit 4 / reason=dialog-required" {
  cd "$TMP"
  # gh mock 環境（既存テストと同じ shim）を最小構成で用意
  SHIM_DIR="$TMP/shim"
  mkdir -p "$SHIM_DIR"
  cat > "$SHIM_DIR/gh" <<'SHIM'
#!/usr/bin/env bash
case "$1" in
  auth) exit 0 ;;
  issue)
    case "$2" in
      list) printf '[]\n'; exit 0 ;;
      create) printf 'https://example.com/should-not-be-called\n'; exit 0 ;;
      edit) exit 0 ;;
    esac
    ;;
esac
exit 0
SHIM
  chmod +x "$SHIM_DIR/gh"
  cat > "$SHIM_DIR/git" <<'GITSHIM'
#!/usr/bin/env bash
if [[ "$1" == "remote" && "$2" == "get-url" ]]; then
  printf 'https://github.com/test-owner/test-repo.git\n'
  exit 0
fi
exec /usr/bin/env -u PATH PATH="/usr/bin:/bin:/usr/local/bin" git "$@"
GITSHIM
  chmod +x "$SHIM_DIR/git"
  export PATH="$SHIM_DIR:$PATH"
  echo "test body" > "$TMP/body.md"

  # 対話確認トークン未発行のまま起票試行 → verify が exit 4 でブロック
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$TMP/body.md' 'mirror-only' 'v2.5.1'"
  [ "$status" -eq 4 ]
  [[ "$output" == *"result=failed"* ]]
  [[ "$output" == *"reason=dialog-required"* ]]
  [[ "$output" == *"verify_exit=4"* ]]
}

@test "issue_create 統合: AIDLC_RETRO_RESEND_INTERNAL_BYPASS=1 + AIDLC_RETRO_FORCE_TARGET 必須" {
  # bypass のセキュリティ境界: 環境変数 1 つだけでは bypass 無効、AIDLC_RETRO_FORCE_TARGET 併設必須
  bash -c "source '$RETRO_LIB' && retrospective_dialog_token_record_response 'v2.5.3' 'denied'"
  # bypass フラグだけ set / FORCE_TARGET なし → bypass 無効化されないため denied で blocked
  run bash -c "AIDLC_RETRO_RESEND_INTERNAL_BYPASS=1 source '$RETRO_LIB' && AIDLC_RETRO_RESEND_INTERNAL_BYPASS=1 retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 4 ]
  [[ "$output" == *"token_denied"* ]]

  # bypass フラグ + FORCE_TARGET 併設 → bypass 有効化
  run bash -c "AIDLC_RETRO_RESEND_INTERNAL_BYPASS=1 AIDLC_RETRO_FORCE_TARGET=mirror source '$RETRO_LIB' && AIDLC_RETRO_RESEND_INTERNAL_BYPASS=1 AIDLC_RETRO_FORCE_TARGET=mirror retrospective_dialog_token_verify 'v2.5.3'"
  [ "$status" -eq 0 ]
}
