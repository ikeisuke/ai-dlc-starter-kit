#!/usr/bin/env bats
# Unit 002: retrospective_issue_create() 単体テスト
# Plan §「retrospective_issue_create() 出力契約」/ Logical Design §「Orchestration」を verify する。
#
# gh コマンドはモック shim で挙動制御:
#   GH_MOCK_AUTH=ok|ng                    - gh auth status の挙動
#   GH_MOCK_LIST_RESULT=<json>            - gh issue list の出力 JSON
#   GH_MOCK_CREATE_URL=<url>              - gh issue create が返す URL（空 = 失敗）
#   GH_MOCK_CREATE_FAIL_FOR=<repo>        - 指定 repo への create を失敗させる
#   GH_MOCK_RELABEL_FAIL=1                - gh issue edit を失敗させる
#   GH_MOCK_LOG=<path>                    - 呼出ログ出力先

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  RETRO_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-issue.sh"
  TMP="$(mktemp -d -t aidlc-retro-create.XXXXXX)"
  SHIM_DIR="$TMP/shim"
  mkdir -p "$SHIM_DIR"
  GH_MOCK_LOG="$TMP/gh-calls.log"
  : > "$GH_MOCK_LOG"

  cat > "$SHIM_DIR/gh" <<'SHIM'
#!/usr/bin/env bash
# gh モック
echo "$@" >> "${GH_MOCK_LOG:-/dev/null}"
case "$1" in
  auth)
    if [[ "${GH_MOCK_AUTH:-ok}" == "ok" ]]; then exit 0; else exit 1; fi
    ;;
  issue)
    sub="$2"
    shift 2
    case "$sub" in
      list)
        printf '%s\n' "${GH_MOCK_LIST_RESULT:-[]}"
        exit 0
        ;;
      create)
        # --repo 抽出
        repo=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --repo) repo="$2"; shift 2 ;;
            *) shift ;;
          esac
        done
        if [[ -n "${GH_MOCK_CREATE_FAIL_FOR:-}" && "$repo" == "$GH_MOCK_CREATE_FAIL_FOR" ]]; then
          echo "mock create failed for $repo" >&2
          exit 1
        fi
        if [[ -z "${GH_MOCK_CREATE_URL:-}" ]]; then
          echo "mock create failed (no URL configured)" >&2
          exit 1
        fi
        printf '%s\n' "${GH_MOCK_CREATE_URL}"
        exit 0
        ;;
      edit)
        if [[ "${GH_MOCK_RELABEL_FAIL:-}" == "1" ]]; then
          exit 1
        fi
        exit 0
        ;;
    esac
    ;;
esac
exit 0
SHIM
  chmod +x "$SHIM_DIR/gh"
  export PATH="$SHIM_DIR:$PATH"
  export GH_MOCK_LOG

  # git remote モック（__retro_gh_owner_repo_local 用）
  cat > "$SHIM_DIR/git" <<'GITSHIM'
#!/usr/bin/env bash
if [[ "$1" == "remote" && "$2" == "get-url" ]]; then
  printf 'https://github.com/test-owner/test-repo.git\n'
  exit 0
fi
exec /usr/bin/env -u PATH PATH="/usr/bin:/bin:/usr/local/bin" git "$@"
GITSHIM
  chmod +x "$SHIM_DIR/git"

  echo "test body" > "$TMP/body.md"
  BODY="$TMP/body.md"
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP"
}

_run_create() {
  # $1 mode, $2 cycle, 残りは環境変数追加
  local mode="$1" cycle="$2"
  shift 2
  bash -c "$* source '$RETRO_LIB' && retrospective_issue_create '$BODY' '$mode' '$cycle'"
}

@test "create: feedback_mode=disabled → result=skipped reason=mode-disabled exit 0" {
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'disabled' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=skipped"* ]]
  [[ "$output" == *"reason=mode-disabled"* ]]
}

@test "create: cycle 不正（path traversal） → exit 2" {
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'mirror-only' '../etc'"
  [ "$status" -eq 2 ]
}

@test "create: body_path 不在 → exit 2" {
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '/no/such/body.md' 'mirror-only' 'v2.5.1'"
  [ "$status" -eq 2 ]
}

@test "create: feedback_mode 未知 → exit 2" {
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'unknown-mode' 'v2.5.1'"
  [ "$status" -eq 2 ]
}

@test "create: AIDLC_RETRO_FORCE_TARGET 不正 → exit 2" {
  run bash -c "AIDLC_RETRO_FORCE_TARGET=invalid source '$RETRO_LIB' && AIDLC_RETRO_FORCE_TARGET=invalid retrospective_issue_create '$BODY' 'mirror-only' 'v2.5.1'"
  [ "$status" -eq 2 ]
}

@test "create: cap 超過（current==limit） → result=skipped reason=cap-exceeded mirror_state=skipped:max_exceeded" {
  run bash -c "AIDLC_RETRO_CURRENT_COUNT=3 AIDLC_RETRO_LIMIT=3 source '$RETRO_LIB' && AIDLC_RETRO_CURRENT_COUNT=3 AIDLC_RETRO_LIMIT=3 retrospective_issue_create '$BODY' 'mirror-only' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=skipped"* ]]
  [[ "$output" == *"reason=cap-exceeded"* ]]
  [[ "$output" == *"mirror_state=skipped:max_exceeded"* ]]
}

@test "create: gh 不可（auth ng） → result=spooled exit 0 / spool 生成" {
  cd "$TMP"
  GH_MOCK_AUTH=ng
  export GH_MOCK_AUTH
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'mirror-only' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=spooled"* ]]
  [ -f ".aidlc/cycles/v2.5.1/history/retrospective-spool.md" ]
  grep -q '"target":"mirror"' ".aidlc/cycles/v2.5.1/history/retrospective-spool.md"
}

@test "create: 重複検出 → result=skipped reason=duplicate" {
  cd "$TMP"
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[{"url":"https://example.com/dup","title":"Retrospective: v2.5.1"}]'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'mirror-only' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=skipped"* ]]
  [[ "$output" == *"reason=duplicate"* ]]
  [[ "$output" == *"existing_issue_url=https://example.com/dup"* ]]
  [[ "$output" == *"mirror_state=skipped:duplicate"* ]]
}

@test "create: mirror-only 成功 → result=created issue_url mirror_state=created" {
  cd "$TMP"
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://github.com/ikeisuke/ai-dlc-starter-kit/issues/100'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'mirror-only' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=created"* ]]
  [[ "$output" == *"target=mirror"* ]]
  [[ "$output" == *"issue_url=https://github.com/ikeisuke/ai-dlc-starter-kit/issues/100"* ]]
  [[ "$output" == *"mirror_state=created"* ]]
  # gh 呼出に retrospective + mirror-state:pending ラベルが含まれる
  grep -q 'mirror-state:pending' "$GH_MOCK_LOG"
  # relabel 呼出（add-label / remove-label）が含まれる
  grep -q 'add-label' "$GH_MOCK_LOG"
  grep -q 'remove-label' "$GH_MOCK_LOG"
}

@test "create: local-and-mirror で local 成功 / mirror 失敗 → result=failed reason=mirror-failed-after-local-created exit 1 + spool に partial 記録" {
  cd "$TMP"
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://github.com/test-owner/test-repo/issues/50'
  GH_MOCK_CREATE_FAIL_FOR='ikeisuke/ai-dlc-starter-kit'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL GH_MOCK_CREATE_FAIL_FOR
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'local-and-mirror' 'v2.5.1'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"result=failed"* ]]
  [[ "$output" == *"reason=mirror-failed-after-local-created"* ]]
  [[ "$output" == *"local_issue_url=https://github.com/test-owner/test-repo/issues/50"* ]]
  [ -f ".aidlc/cycles/v2.5.1/history/retrospective-spool.md" ]
  grep -q '"retry_target":"mirror"' ".aidlc/cycles/v2.5.1/history/retrospective-spool.md"
  grep -q '"local_created":"https://github.com/test-owner/test-repo/issues/50"' ".aidlc/cycles/v2.5.1/history/retrospective-spool.md"
}

@test "create: relabel 失敗 → result=failed reason=relabel-failed-mirror exit 1 + spool 退避" {
  cd "$TMP"
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://github.com/ikeisuke/ai-dlc-starter-kit/issues/200'
  GH_MOCK_RELABEL_FAIL=1
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL GH_MOCK_RELABEL_FAIL
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'mirror-only' 'v2.5.1'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"result=failed"* ]]
  [[ "$output" == *"reason=relabel-failed-mirror"* ]]
  [[ "$output" == *"mirror_state=pending"* ]]
  [[ "$output" == *"mirror_issue_url=https://github.com/ikeisuke/ai-dlc-starter-kit/issues/200"* ]]
  [ -f ".aidlc/cycles/v2.5.1/history/retrospective-spool.md" ]
}

@test "create: AIDLC_RETRO_FORCE_TARGET=mirror で local-and-mirror モードを mirror のみに上書き" {
  cd "$TMP"
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://github.com/ikeisuke/ai-dlc-starter-kit/issues/300'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL
  run bash -c "AIDLC_RETRO_FORCE_TARGET=mirror source '$RETRO_LIB' && AIDLC_RETRO_FORCE_TARGET=mirror retrospective_issue_create '$BODY' 'local-and-mirror' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=created"* ]]
  [[ "$output" == *"target=mirror"* ]]
  # local 起票呼出が無いこと
  ! grep -q -- '--repo test-owner/test-repo' "$GH_MOCK_LOG"
}

@test "create: AIDLC_RETRO_SKIP_LOCAL=1 で both 指定でも local 起票スキップ" {
  cd "$TMP"
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://github.com/ikeisuke/ai-dlc-starter-kit/issues/400'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL
  run bash -c "AIDLC_RETRO_SKIP_LOCAL=1 source '$RETRO_LIB' && AIDLC_RETRO_SKIP_LOCAL=1 retrospective_issue_create '$BODY' 'local-and-mirror' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=created"* ]]
  [[ "$output" == *"target=mirror"* ]]
}

@test "create: メタ開発リポ（local==mirror）で target=both を local に縮退" {
  cd "$TMP"
  # git mock を「mirror リポと同一」を返すよう差し替え
  cat > "$SHIM_DIR/git" <<'GITSHIM'
#!/usr/bin/env bash
if [[ "$1" == "remote" && "$2" == "get-url" ]]; then
  printf 'https://github.com/ikeisuke/ai-dlc-starter-kit.git\n'
  exit 0
fi
exec /usr/bin/env -u PATH PATH="/usr/bin:/bin:/usr/local/bin" git "$@"
GITSHIM
  chmod +x "$SHIM_DIR/git"
  GH_MOCK_AUTH=ok
  GH_MOCK_LIST_RESULT='[]'
  GH_MOCK_CREATE_URL='https://github.com/ikeisuke/ai-dlc-starter-kit/issues/500'
  export GH_MOCK_AUTH GH_MOCK_LIST_RESULT GH_MOCK_CREATE_URL
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'local-and-mirror' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"target=local"* ]]
}

@test "create: target=both で duplicate 時 skip（codex review P2 / Unit 002 領域 mirror 重複対応）" {
  cd "$TMP"
  # git mock は default（test-owner/test-repo）→ MIRROR_REPO と異なるので両方検査される
  GH_MOCK_AUTH=ok
  # local 側 list は空、mirror 側 list は重複ありにする mock
  cat > "$SHIM_DIR/gh" <<'SHIM'
#!/usr/bin/env bash
echo "$@" >> "${GH_MOCK_LOG:-/dev/null}"
case "$1" in
  auth) exit 0 ;;
  issue)
    sub="$2"; shift 2
    case "$sub" in
      list)
        # --repo 抽出
        repo=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --repo) repo="$2"; shift 2 ;;
            *) shift ;;
          esac
        done
        # GH_REPO 環境変数優先（gh の挙動模倣）
        if [[ -z "$repo" && -n "${GH_REPO:-}" ]]; then
          repo="$GH_REPO"
        fi
        if [[ "$repo" == "ikeisuke/ai-dlc-starter-kit" ]]; then
          printf '%s\n' '[{"url":"https://example.com/mirror-dup","title":"Retrospective: v2.5.1"}]'
        else
          printf '%s\n' '[]'
        fi
        exit 0
        ;;
      create) printf '%s\n' "${GH_MOCK_CREATE_URL:-https://example.com/issue}"; exit 0 ;;
      edit) exit 0 ;;
    esac
    ;;
esac
exit 0
SHIM
  chmod +x "$SHIM_DIR/gh"
  export GH_MOCK_AUTH
  run bash -c "source '$RETRO_LIB' && retrospective_issue_create '$BODY' 'local-and-mirror' 'v2.5.1'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"result=skipped"* ]]
  [[ "$output" == *"reason=duplicate"* ]]
  [[ "$output" == *"existing_issue_url=https://example.com/mirror-dup"* ]]
}
