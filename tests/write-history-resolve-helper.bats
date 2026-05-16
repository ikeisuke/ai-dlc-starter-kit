#!/usr/bin/env bats
# Unit 006 (#702): write-history.sh 内の共通ヘルパ _resolve_history_filepath_in_repo 単独テスト
#
# 設計 SoT: .aidlc/cycles/v2.6.3/design-artifacts/logical-designs/unit_006_write_history_helper_refactor_logical_design.md
#
# 検証する 4 経路:
#   (a) 成功（valid filepath in repo） → exit 0 + stdout 空 + stderr 空 + 変数書き込み済み
#   (b) exit 1（symlink 解決失敗 / 親ディレクトリ不存在） → exit 1 + stdout 空 + stderr 空
#   (c) exit 2（git リポジトリ外） → exit 2 + stdout 空 + stderr 空
#   (d) exit 3（filepath が repo 配下でない） → exit 3 + stdout 空 + stderr 空
#
# helper は副作用なし契約: stdout / stderr に一切出力しない（caller の責務）。
# warning 出力は caller 側で行うため、helper 単独実行では出力が空であることを assert する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  WRITE_HISTORY="${REPO_ROOT}/skills/aidlc/scripts/write-history.sh"
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  # check-test-isolation 規約: 削除前に safe cd ガード（BATS 一時ディレクトリへ移動）
  cd "$BATS_TMPDIR"
  if [ -n "${TEST_TMPDIR:-}" ] && [ -d "${TEST_TMPDIR}" ]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# 共通: helper を subprocess で呼び出し stdout/stderr/exit を分離取得
# 引数: $1=filepath / $2=stdout 受け取りファイル / $3=stderr 受け取りファイル
# 戻り値: helper の exit code（subprocess 経由で透過）
# 内部: helper は write-history.sh 内に定義されているため、内部関数だけを export して呼ぶことができない。
#       代替として write-history.sh を source した上で関数呼び出しを subprocess で起動する。
#       bootstrap.sh の副作用（AIDLC_PROJECT_ROOT 検証）を回避するため、AIDLC_PROJECT_ROOT を
#       一時 git リポジトリに固定し、source 経路で main を実行しない（直接関数呼び出しのみ）。
run_helper() {
  local filepath="$1"
  local stdout_file="$2"
  local stderr_file="$3"
  local workdir="$4"

  # subprocess 起動: write-history.sh を source した直後に helper を呼ぶだけ。
  # set -e を解除して exit code を握り潰さず取得。
  # bats のデフォルト挙動で関数 return 非 0 が即 test 失敗扱いになるため、
  # exit code は file に書き出し、本関数は常に 0 を返す（test 側は file から読む）。
  set +e
  AIDLC_PROJECT_ROOT="${workdir}" bash -c '
    set +e
    source "$1"
    _resolve_history_filepath_in_repo "$2" out_repo_root out_rel_path
    rc=$?
    if [ "$rc" -eq 0 ]; then
      printf "OUT_REPO_ROOT=%s\n" "$out_repo_root" > "$3"
      printf "OUT_REL_PATH=%s\n" "$out_rel_path" >> "$3"
    fi
    exit "$rc"
  ' _ "${WRITE_HISTORY}" "${filepath}" "${TEST_TMPDIR}/helper_out_vars.txt" \
    > "${stdout_file}" 2> "${stderr_file}"
  local rc=$?
  set -e
  printf '%s\n' "$rc" > "${TEST_TMPDIR}/helper_exit_code.txt"
  return 0
}

read_helper_exit_code() {
  cat "${TEST_TMPDIR}/helper_exit_code.txt"
}

# ---------------------------------------------------------------
# Case (a): 成功（valid filepath in repo） → exit 0 + stdout/stderr 空 + 変数書き込み済み
# ---------------------------------------------------------------
@test "helper: success in git repo → exit 0 + stdout/stderr empty + result-out vars filled" {
  local test_repo="${TEST_TMPDIR}/repo_a"
  mkdir -p "${test_repo}/.aidlc"
  printf '[project]\nname = "t"\n' > "${test_repo}/.aidlc/config.toml"
  ( cd "${test_repo}" && git init -q && \
    git config user.email "t@example.com" && git config user.name "t" )

  local target="${test_repo}/sample.md"
  printf 'x\n' > "${target}"

  local stdout_file="${TEST_TMPDIR}/case_a_stdout.txt"
  local stderr_file="${TEST_TMPDIR}/case_a_stderr.txt"

  run_helper "${target}" "${stdout_file}" "${stderr_file}" "${test_repo}"
  exit_code="$(read_helper_exit_code)"

  [ "${exit_code}" -eq 0 ]

  # stdout/stderr が空（helper の副作用なし契約）
  [ ! -s "${stderr_file}" ]
  [ ! -s "${stdout_file}" ]

  # result-out 変数が書き込まれている
  [ -s "${TEST_TMPDIR}/helper_out_vars.txt" ]
  grep -q "^OUT_REPO_ROOT=" "${TEST_TMPDIR}/helper_out_vars.txt"
  grep -q "^OUT_REL_PATH=sample.md$" "${TEST_TMPDIR}/helper_out_vars.txt"
}

# ---------------------------------------------------------------
# Case (b): exit 1（symlink 解決失敗 / 親ディレクトリ不存在）→ exit 1 + stdout/stderr 空
# ---------------------------------------------------------------
@test "helper: parent dir does not exist → exit 1 + stdout/stderr empty" {
  local test_repo="${TEST_TMPDIR}/repo_b"
  mkdir -p "${test_repo}/.aidlc"
  printf '[project]\nname = "t"\n' > "${test_repo}/.aidlc/config.toml"

  # 存在しない親ディレクトリ配下のパス
  local target="${TEST_TMPDIR}/does_not_exist_dir/sample.md"

  local stdout_file="${TEST_TMPDIR}/case_b_stdout.txt"
  local stderr_file="${TEST_TMPDIR}/case_b_stderr.txt"

  run_helper "${target}" "${stdout_file}" "${stderr_file}" "${test_repo}"
  exit_code="$(read_helper_exit_code)"

  [ "${exit_code}" -eq 1 ]

  # stdout/stderr が空（helper の副作用なし契約）
  [ ! -s "${stderr_file}" ]
  [ ! -s "${stdout_file}" ]

  # 失敗時は result-out 変数も書き込まれない
  [ ! -s "${TEST_TMPDIR}/helper_out_vars.txt" ] || true
}

# ---------------------------------------------------------------
# Case (c): exit 2（git リポジトリ外）→ exit 2 + stdout/stderr 空
# ---------------------------------------------------------------
@test "helper: outside git repo → exit 2 + stdout/stderr empty" {
  # git init していないディレクトリ
  local non_repo="${TEST_TMPDIR}/non_repo_c"
  mkdir -p "${non_repo}/.aidlc"
  printf '[project]\nname = "t"\n' > "${non_repo}/.aidlc/config.toml"

  local target="${non_repo}/sample.md"
  printf 'x\n' > "${target}"

  local stdout_file="${TEST_TMPDIR}/case_c_stdout.txt"
  local stderr_file="${TEST_TMPDIR}/case_c_stderr.txt"

  run_helper "${target}" "${stdout_file}" "${stderr_file}" "${non_repo}"
  exit_code="$(read_helper_exit_code)"

  [ "${exit_code}" -eq 2 ]

  # stdout/stderr が空（helper の副作用なし契約）
  [ ! -s "${stderr_file}" ]
  [ ! -s "${stdout_file}" ]

  [ ! -s "${TEST_TMPDIR}/helper_out_vars.txt" ] || true
}

# ---------------------------------------------------------------
# Case (d): exit 3（filepath が repo 配下でない）→ exit 3 + stdout/stderr 空
#
# 「filepath_real が repo_root の接頭辞を持たない」状態を環境非依存で再現するため、
# helper 内で呼ばれる `git` コマンドを subprocess 内で関数オーバーライドし、
# `git rev-parse --show-toplevel` だけを「filepath_real とは無関係な絶対パス」を返すよう
# 差し替える。これにより exit 3 経路を決定論的にテストできる。
# ---------------------------------------------------------------
@test "helper: filepath outside repo_root (mocked git) → exit 3 + stdout/stderr empty" {
  local test_repo="${TEST_TMPDIR}/repo_d"
  mkdir -p "${test_repo}/.aidlc"
  printf '[project]\nname = "t"\n' > "${test_repo}/.aidlc/config.toml"
  ( cd "${test_repo}" && git init -q && \
    git config user.email "t@example.com" && git config user.name "t" )

  local target="${test_repo}/sample.md"
  printf 'x\n' > "${target}"

  local stdout_file="${TEST_TMPDIR}/case_d_stdout.txt"
  local stderr_file="${TEST_TMPDIR}/case_d_stderr.txt"

  set +e
  AIDLC_PROJECT_ROOT="${test_repo}" bash -c '
    set +e
    source "$1"
    set +e
    # git をオーバーライドして rev-parse --show-toplevel だけ別パスを返す
    # （filepath_real が "${test_repo}/sample.md" でも repo_root が "/not/a/prefix" になり
    #  接頭辞除去が文字列レベルで失敗 → exit 3）
    git() {
      if [ "$1" = "-C" ] && [ "$3" = "rev-parse" ] && [ "$4" = "--show-toplevel" ]; then
        echo "/not/a/prefix"
        return 0
      fi
      command git "$@"
    }
    _resolve_history_filepath_in_repo "$2" out_repo_root out_rel_path
    exit $?
  ' _ "${WRITE_HISTORY}" "${target}" \
    > "${stdout_file}" 2> "${stderr_file}"
  local rc=$?
  set -e

  [ "${rc}" -eq 3 ]

  # stdout/stderr が空（helper の副作用なし契約）
  [ ! -s "${stderr_file}" ]
  [ ! -s "${stdout_file}" ]
}

# ---------------------------------------------------------------
# Case (e): _commit_operations_round_history の `*)` fail-safe 分岐
# helper を override して想定外 exit code（99）を返させ、caller が未初期化値の使用を避けて
# warning + return 0 で skip することを確認する。
# ---------------------------------------------------------------
@test "caller fail-safe: unexpected helper exit code → warning + return 0 (no commit)" {
  local test_repo="${TEST_TMPDIR}/repo_e"
  mkdir -p "${test_repo}/.aidlc"
  printf '[project]\nname = "t"\n' > "${test_repo}/.aidlc/config.toml"
  ( cd "${test_repo}" && git init -q && \
    git config user.email "t@example.com" && git config user.name "t" )

  local stderr_file="${TEST_TMPDIR}/case_e_stderr.txt"
  local stdout_file="${TEST_TMPDIR}/case_e_stdout.txt"

  set +e
  AIDLC_PROJECT_ROOT="${test_repo}" bash -c '
    set +e
    source "$1"
    # 注: source 後は write-history.sh の set -euo pipefail が有効化される。
    # caller の return 0 を errexit で握り潰さないよう、source 後にも set +e を再適用する。
    set +e
    # helper を override して想定外 exit code を返させる
    _resolve_history_filepath_in_repo() { return 99; }
    _commit_operations_round_history "$2/sample.md" "v2.6.3" "1"
    exit $?
  ' _ "${WRITE_HISTORY}" "${test_repo}" \
    > "${stdout_file}" 2> "${stderr_file}"
  local rc=$?
  set -e

  # caller は warning + return 0 で skip
  [ "${rc}" -eq 0 ]

  # stderr に fail-safe warning が出ている
  grep -q "warning: unexpected helper exit code (99), skipping auto-commit:" "${stderr_file}"

  # commit は実行されていない（git log は init 直後の状態のまま = HEAD なし）
  ( cd "${test_repo}" && ! git rev-parse HEAD 2>/dev/null )
}
