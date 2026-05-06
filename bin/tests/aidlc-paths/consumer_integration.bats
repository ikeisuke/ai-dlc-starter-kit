#!/usr/bin/env bats
# producer/consumer の AIDLC_PROJECT_ROOT 整合性ブラックボックス検証
# 判定主軸 (primary): NDJSON / 公開 IF
# 判定補助 (secondary): stderr の path= トークン
#
# producer = retrospective-issue.sh の __retro_spool_path
# consumer = predecessor-issue.sh の predecessor_resolve_issue (NDJSON file_path)
# consumer = retrospective-resend.sh の SPOOL_PATH (stderr path=)

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  PATHS_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/aidlc-paths.sh"
  RETRO_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-issue.sh"
  PRED_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/predecessor-issue.sh"
  RESEND_BIN="${REPO_ROOT}/skills/aidlc/scripts/retrospective-resend.sh"
  cd "$BATS_TEST_TMPDIR"
}

teardown() {
  cd "$BATS_TEST_TMPDIR"
}

@test "producer: __retro_spool_path は AIDLC_PROJECT_ROOT 設定下で <root>/.aidlc/.. を返す" {
  run bash -c "AIDLC_PROJECT_ROOT=/tmp/aidlc-cross-test source '$RETRO_LIB'; AIDLC_PROJECT_ROOT=/tmp/aidlc-cross-test __retro_spool_path v9.9.9"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/aidlc-cross-test/.aidlc/cycles/v9.9.9/history/retrospective-spool.md" ]
}

@test "producer: __retro_spool_path は AIDLC_PROJECT_ROOT 未設定で cwd 相対 path を返す (後方互換)" {
  run bash -c "unset AIDLC_PROJECT_ROOT; source '$RETRO_LIB'; __retro_spool_path v9.9.9"
  [ "$status" -eq 0 ]
  [ "$output" = ".aidlc/cycles/v9.9.9/history/retrospective-spool.md" ]
}

@test "consumer: predecessor_resolve_issue は AIDLC_PROJECT_ROOT 設定下で v2_5_0_compat 経路の NDJSON file_path に <root>/.aidlc/.. を返す (primary)" {
  # AIDLC_PROJECT_ROOT 配下に compat fixture を配置 → predecessor_resolve_issue が gh 不在経路で v2_5_0_compat を返す
  ROOT="$BATS_TEST_TMPDIR/proj"
  COMPAT_DIR="$ROOT/.aidlc/cycles/v9.9.9/operations"
  mkdir -p "$COMPAT_DIR"
  : > "$COMPAT_DIR/retrospective.md"

  # gh コマンドを stub: not-installed 相当を返して __retro_gh_status を unavailable にし、v2_5_0_compat 経路へ誘導
  STUB_DIR="$BATS_TEST_TMPDIR/stub"
  mkdir -p "$STUB_DIR"
  cat > "$STUB_DIR/gh" <<'STUB'
#!/usr/bin/env bash
# auth-status は失敗、その他は空応答 + exit 1 で gh_status=unavailable にする
exit 1
STUB
  chmod +x "$STUB_DIR/gh"

  run bash -c "
    export PATH='$STUB_DIR':\"\$PATH\"
    export AIDLC_PROJECT_ROOT='$ROOT'
    source '$PRED_LIB'
    predecessor_resolve_issue v9.9.9
  "
  [ "$status" -eq 0 ]
  # NDJSON 出力に file_path として <root>/.aidlc/cycles/.. が含まれていれば producer/consumer 整合
  expected_file_path="$ROOT/.aidlc/cycles/v9.9.9/operations/retrospective.md"
  [[ "$output" == *"\"file_path\":\"$expected_file_path\""* ]] || {
    echo "expected file_path: $expected_file_path"
    echo "actual output: $output"
    return 1
  }
}

@test "consumer: retrospective-resend.sh は AIDLC_PROJECT_ROOT 設定下で stderr path= に <root>/.aidlc/.. を出力 (secondary)" {
  # AIDLC_PROJECT_ROOT 配下に最新 cycle ディレクトリを配置 (cycle 自動決定経路は cwd 直書き = #644 で defer 済のため --cycle 明示)
  ROOT="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$ROOT/.aidlc/cycles/v9.9.9/history"
  # gh stub: __retro_gh_status を available にして spool ファイル不在経由の error path で stderr 出力する
  STUB_DIR="$BATS_TEST_TMPDIR/stub"
  mkdir -p "$STUB_DIR"
  cat > "$STUB_DIR/gh" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    auth) [[ "$2" == "status" ]] && exit 0 ;;
    *) exit 0 ;;
esac
STUB
  chmod +x "$STUB_DIR/gh"

  cd "$ROOT"  # cycle 自動決定が落ちないように cwd も合わせる (#644 defer 領域)
  run bash -c "
    export PATH='$STUB_DIR':\"\$PATH\"
    export AIDLC_PROJECT_ROOT='$ROOT'
    bash '$RESEND_BIN' --cycle v9.9.9 --dry-run 2>&1
  "
  # spool ファイル不在 → exit 2 + error spool-not-found path=<root>/.aidlc/...
  [ "$status" -eq 2 ]
  [[ "$output" == *"path=$ROOT/.aidlc/cycles/v9.9.9/history/retrospective-spool.md"* ]] || {
    echo "expected path token: path=$ROOT/.aidlc/cycles/v9.9.9/history/retrospective-spool.md"
    echo "actual output: $output"
    return 1
  }
}

@test "consumer: retrospective-resend.sh は AIDLC_PROJECT_ROOT 未設定で cwd 相対 path を出力 (後方互換)" {
  ROOT="$BATS_TEST_TMPDIR/proj-noroot"
  mkdir -p "$ROOT/.aidlc/cycles/v9.9.9/history"
  cd "$ROOT"
  STUB_DIR="$BATS_TEST_TMPDIR/stub-noroot"
  mkdir -p "$STUB_DIR"
  cat > "$STUB_DIR/gh" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    auth) [[ "$2" == "status" ]] && exit 0 ;;
    *) exit 0 ;;
esac
STUB
  chmod +x "$STUB_DIR/gh"

  run bash -c "
    unset AIDLC_PROJECT_ROOT
    export PATH='$STUB_DIR':\"\$PATH\"
    bash '$RESEND_BIN' --cycle v9.9.9 --dry-run 2>&1
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"path=.aidlc/cycles/v9.9.9/history/retrospective-spool.md"* ]] || {
    echo "expected cwd-relative path token"
    echo "actual output: $output"
    return 1
  }
}
