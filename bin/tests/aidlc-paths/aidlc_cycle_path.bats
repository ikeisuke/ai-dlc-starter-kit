#!/usr/bin/env bats
# aidlc-paths.sh の aidlc_cycle_path 単体テスト
# 観点:
#   - AIDLC_PROJECT_ROOT 未設定 / 空文字 / 絶対パス / 相対パス / 末尾空白
#   - 引数バリデーション (cycle 空 / subpath 未指定 / subpath 空文字)
#   - 多重 source ガード

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  PATHS_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/aidlc-paths.sh"
  cd "$BATS_TEST_TMPDIR"
}

teardown() {
  cd "$BATS_TEST_TMPDIR"
}

@test "aidlc_cycle_path: AIDLC_PROJECT_ROOT 未設定で cwd 相対 path を返す" {
  run bash -c "unset AIDLC_PROJECT_ROOT; source '$PATHS_LIB'; aidlc_cycle_path v9.9.9 history/retrospective-spool.md"
  [ "$status" -eq 0 ]
  [ "$output" = ".aidlc/cycles/v9.9.9/history/retrospective-spool.md" ]
}

@test "aidlc_cycle_path: AIDLC_PROJECT_ROOT 空文字は未設定扱い" {
  run bash -c "AIDLC_PROJECT_ROOT='' source '$PATHS_LIB'; AIDLC_PROJECT_ROOT='' aidlc_cycle_path v9.9.9 history/spool.md"
  [ "$status" -eq 0 ]
  [ "$output" = ".aidlc/cycles/v9.9.9/history/spool.md" ]
}

@test "aidlc_cycle_path: AIDLC_PROJECT_ROOT 絶対パス時は <root>/.aidlc/.. を返す" {
  run bash -c "AIDLC_PROJECT_ROOT=/tmp/foo source '$PATHS_LIB'; AIDLC_PROJECT_ROOT=/tmp/foo aidlc_cycle_path v9.9.9 operations/retrospective.md"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/foo/.aidlc/cycles/v9.9.9/operations/retrospective.md" ]
}

@test "aidlc_cycle_path: AIDLC_PROJECT_ROOT 相対パスはそのまま連結（絶対化なし）" {
  run bash -c "AIDLC_PROJECT_ROOT=../bar source '$PATHS_LIB'; AIDLC_PROJECT_ROOT=../bar aidlc_cycle_path v9.9.9 history/spool.md"
  [ "$status" -eq 0 ]
  [ "$output" = "../bar/.aidlc/cycles/v9.9.9/history/spool.md" ]
}

@test "aidlc_cycle_path: AIDLC_PROJECT_ROOT 末尾空白は trim せずそのまま連結" {
  run bash -c "source '$PATHS_LIB'; AIDLC_PROJECT_ROOT='/tmp/baz ' aidlc_cycle_path v9.9.9 history/spool.md"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/baz /.aidlc/cycles/v9.9.9/history/spool.md" ]
}

@test "aidlc_cycle_path: cycle 空文字で exit 2 + invalid_cycle 診断" {
  run bash -c "source '$PATHS_LIB'; aidlc_cycle_path '' history/spool.md"
  [ "$status" -eq 2 ]
  [[ "$output" == *"aidlc_paths_invalid_cycle"* ]]
}

@test "aidlc_cycle_path: cycle 引数なしで exit 2 + invalid_cycle 診断" {
  run bash -c "source '$PATHS_LIB'; aidlc_cycle_path"
  [ "$status" -eq 2 ]
  [[ "$output" == *"aidlc_paths_invalid_cycle"* ]]
}

@test "aidlc_cycle_path: subpath 未指定で exit 2 + invalid_subpath 診断" {
  run bash -c "source '$PATHS_LIB'; aidlc_cycle_path v9.9.9"
  [ "$status" -eq 2 ]
  [[ "$output" == *"aidlc_paths_invalid_subpath"* ]]
}

@test "aidlc_cycle_path: subpath 空文字で exit 2 + invalid_subpath 診断 (round-1 fix)" {
  run bash -c "source '$PATHS_LIB'; aidlc_cycle_path v9.9.9 ''"
  [ "$status" -eq 2 ]
  [[ "$output" == *"aidlc_paths_invalid_subpath"* ]]
}

@test "aidlc-paths.sh: 多重 source ガード __AIDLC_PATHS_SH_LOADED が動作する" {
  run bash -c "source '$PATHS_LIB'; source '$PATHS_LIB'; echo guard:\$__AIDLC_PATHS_SH_LOADED"
  [ "$status" -eq 0 ]
  [[ "$output" == *"guard:1"* ]]
}
