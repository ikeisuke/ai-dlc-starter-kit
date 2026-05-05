#!/usr/bin/env bats
# Unit 002: retrospective-resend.sh CLI テスト
# Plan §「retrospective-resend.sh I/F」を verify する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  RESEND="${REPO_ROOT}/skills/aidlc/scripts/retrospective-resend.sh"
  RETRO_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-issue.sh"
  TMP="$(mktemp -d -t aidlc-retro-resend.XXXXXX)"
  SHIM_DIR="$TMP/shim"
  mkdir -p "$SHIM_DIR"
  GH_MOCK_LOG="$TMP/gh-calls.log"
  : > "$GH_MOCK_LOG"

  cat > "$SHIM_DIR/gh" <<'SHIM'
#!/usr/bin/env bash
echo "$@" >> "${GH_MOCK_LOG:-/dev/null}"
case "$1" in
  auth)
    if [[ "${GH_MOCK_AUTH:-ok}" == "ok" ]]; then exit 0; else exit 1; fi
    ;;
  issue)
    sub="$2"; shift 2
    case "$sub" in
      list) printf '%s\n' "${GH_MOCK_LIST_RESULT:-[]}"; exit 0 ;;
      create) printf '%s\n' "${GH_MOCK_CREATE_URL:-https://example.com/issue/1}"; exit 0 ;;
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
  printf 'https://github.com/test-owner/test-repo.git\n'; exit 0
fi
exec /usr/bin/env -u PATH PATH="/usr/bin:/bin:/usr/local/bin" git "$@"
GITSHIM
  chmod +x "$SHIM_DIR/git"

  export PATH="$SHIM_DIR:$PATH"
  export GH_MOCK_LOG

  CYCLE="v2.5.1"
  SPOOL_DIR="$TMP/.aidlc/cycles/$CYCLE/history"
  mkdir -p "$SPOOL_DIR"
  SPOOL="$SPOOL_DIR/retrospective-spool.md"
  printf 'sample body\n' > "$TMP/body.md"
}

teardown() {
  rm -rf "$TMP"
}

# spool エントリを 1 件作る
_make_spool_with_entry() {
  local target="$1" retry_target="$2" local_created="${3:-}" mirror_created="${4:-}"
  bash -c "source '$RETRO_LIB' && entry=\$(__retro_build_spool_entry '$CYCLE' 'mirror-only' '$target' '$retry_target' 'gh-not-available' '$TMP/body.md' '$local_created' '$mirror_created') && _spool_append '$SPOOL' \"\$entry\""
}

@test "resend: spool 不在で exit 2" {
  cd "$TMP"
  GH_MOCK_AUTH=ok
  export GH_MOCK_AUTH
  run bash "$RESEND" --cycle "$CYCLE"
  [ "$status" -eq 2 ]
  [[ "$output" == *"spool-not-found"* ]] || [[ "$stderr" == *"spool-not-found"* ]]
}

@test "resend: gh 不可で exit 1" {
  cd "$TMP"
  _make_spool_with_entry "mirror" "mirror" "" ""
  GH_MOCK_AUTH=ng
  export GH_MOCK_AUTH
  run bash "$RESEND" --cycle "$CYCLE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"gh-not-available"* ]]
}

@test "resend: --dry-run はエントリを処理せず spool を変更しない" {
  cd "$TMP"
  _make_spool_with_entry "mirror" "mirror" "" ""
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://example.com/issue/9'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL
  before_hash="$(shasum -a 256 < "$SPOOL")"
  run bash "$RESEND" --cycle "$CYCLE" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  after_hash="$(shasum -a 256 < "$SPOOL")"
  [ "$before_hash" = "$after_hash" ]
}

@test "resend: 正常 1 件 → created + spool から削除 + summary" {
  cd "$TMP"
  _make_spool_with_entry "mirror" "mirror" "" ""
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://example.com/issue/200'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL
  run bash "$RESEND" --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=created"* ]]
  [[ "$output" == *"created=1"* ]]
  # spool エントリが削除されている（block 内 0 件）
  remaining="$(awk '/^```ndjson/,/^```$/' "$SPOOL" | grep -c '^{' || true)"
  [ "$remaining" = "0" ]
}

@test "resend: --strict + SHA256 不一致 → exit 1（中断）" {
  cd "$TMP"
  # 不正な entry を直接書き込む
  bash -c "source '$RETRO_LIB' && _spool_append '$SPOOL' '{\"id\":\"bad1\",\"version\":\"1\",\"cycle\":\"$CYCLE\",\"feedback_mode\":\"mirror-only\",\"attempted_at\":\"2025-01-01T00:00:00Z\",\"target\":\"mirror\",\"retry_target\":\"mirror\",\"partial_state\":{\"local_created\":null,\"mirror_created\":null},\"attempt_reason\":\"test\",\"body_b64\":\"aGVsbG8=\",\"body_sha256\":\"deadbeef\"}'"
  GH_MOCK_AUTH=ok
  export GH_MOCK_AUTH
  run bash "$RESEND" --cycle "$CYCLE" --strict
  [ "$status" -eq 1 ]
}

@test "resend: SHA256 不一致 default（非 strict） → 当該エントリのみ skip し他は処理継続" {
  cd "$TMP"
  bash -c "source '$RETRO_LIB' && _spool_append '$SPOOL' '{\"id\":\"bad1\",\"version\":\"1\",\"cycle\":\"$CYCLE\",\"feedback_mode\":\"mirror-only\",\"attempted_at\":\"2025-01-01T00:00:00Z\",\"target\":\"mirror\",\"retry_target\":\"mirror\",\"partial_state\":{\"local_created\":null,\"mirror_created\":null},\"attempt_reason\":\"test\",\"body_b64\":\"aGVsbG8=\",\"body_sha256\":\"deadbeef\"}'"
  GH_MOCK_AUTH=ok
  export GH_MOCK_AUTH
  run bash "$RESEND" --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"sha256-mismatch"* ]]
  [[ "$output" == *"skipped=1"* ]]
}

@test "resend: partial 起票（local_created あり）→ AIDLC_RETRO_SKIP_LOCAL で local 再起票しない / mirror のみ" {
  cd "$TMP"
  _make_spool_with_entry "both" "mirror" "https://github.com/test-owner/test-repo/issues/50" ""
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://github.com/ikeisuke/ai-dlc-starter-kit/issues/700'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL
  run bash "$RESEND" --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"created=1"* ]]
  # local リポへの create 呼出が無いことを gh log で確認
  ! grep -- '--repo test-owner/test-repo' "$GH_MOCK_LOG"
  # mirror リポへの create 呼出はある
  grep -q -- '--repo ikeisuke/ai-dlc-starter-kit' "$GH_MOCK_LOG"
}

@test "resend: 不明引数 → exit 2" {
  cd "$TMP"
  run bash "$RESEND" --unknown-flag
  [ "$status" -eq 2 ]
}

@test "resend: --help → exit 0 + usage 表示" {
  cd "$TMP"
  run bash "$RESEND" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}
