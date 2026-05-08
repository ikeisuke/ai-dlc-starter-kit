#!/usr/bin/env bats
# Unit 003 (#654 / DR-002): write-history.sh の check_history_staged_status() 警告経路テスト
# step5↔step8 分裂（履歴ファイルが Unit 完了 commit に含まれない事故）の構造的予防として、
# write-history.sh が --mode base 完了時に履歴ファイルの staged 状態を判定し、
# unstaged の場合に stderr に警告を出力する経路を検証する。
#
# warning 契約 (SoT: .aidlc/cycles/v2.5.5/plans/unit-003-plan.md § warning 契約):
#   - 出力先: stderr 一本化
#   - 文言:   "warning: history file unstaged: <絶対パス>"
#   - exit:   常に 0（後方互換性保護）
#
# 検証ケース（3 ケース）:
#   (a) unstaged → stderr warning + stdout には warning なし + exit 0
#   (b) staged → stderr warning なし + exit 0
#   (c) git リポジトリ外 → stderr warning なし + exit 0（警告スキップ）

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  WRITE_HISTORY="${REPO_ROOT}/skills/aidlc/scripts/write-history.sh"
  TEST_TMPDIR="$(mktemp -d)"
  TEST_REPO="${TEST_TMPDIR}/repo"
  mkdir -p "${TEST_REPO}"

  # write-history.sh は project root（.aidlc/config.toml）を要求する。
  # 全ケース共通でテンプレート config.toml を配置する。
  # （実 config.toml の最小限フィールドのみを stub する）
  mkdir -p "${TEST_REPO}/.aidlc"
  cat > "${TEST_REPO}/.aidlc/config.toml" <<'EOF'
[project]
name = "test-project"
EOF
}

teardown() {
  # check-test-isolation 規約: 削除前に safe cd ガード（BATS 一時ディレクトリへ移動）
  cd "$BATS_TMPDIR"
  if [ -n "${TEST_TMPDIR:-}" ] && [ -d "${TEST_TMPDIR}" ]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# 共通: --mode base で write-history.sh を実行し stdout/stderr を分離取得する。
# 引数: $1=stdout 受け取りファイル / $2=stderr 受け取りファイル / $3=作業ディレクトリ
# AIDLC_PROJECT_ROOT 環境変数で project root を注入する（bootstrap.sh の git rev-parse 経路を回避）。
run_write_history_base() {
  local stdout_file="$1"
  local stderr_file="$2"
  local workdir="$3"
  local content_file="${TEST_TMPDIR}/content.txt"
  printf 'test content\n' > "${content_file}"

  ( cd "${workdir}" && \
    AIDLC_PROJECT_ROOT="${workdir}" bash "${WRITE_HISTORY}" \
      --cycle 'v2.5.5' \
      --phase 'construction' \
      --unit '99' \
      --unit-name 'test-unit' \
      --unit-slug 'test-unit' \
      --step 'test-step' \
      --content-file "${content_file}" \
      > "${stdout_file}" 2> "${stderr_file}"
  )
  return $?
}

# ---------------------------------------------------------------
# Case (a): unstaged → stderr warning + stdout には warning なし + exit 0
# Round 1（統合レビュー）指摘 #1 対応: warning 契約 SoT の完全一致を assert する。
# ---------------------------------------------------------------
@test "write-history --mode base: unstaged → stderr warning + exit 0" {
  ( cd "${TEST_REPO}" && git init -q && \
    git config user.email "test@example.com" && \
    git config user.name "Test User" )

  local stdout_file="${TEST_TMPDIR}/case_a_stdout.txt"
  local stderr_file="${TEST_TMPDIR}/case_a_stderr.txt"

  run_write_history_base "${stdout_file}" "${stderr_file}" "${TEST_REPO}"
  exit_code=$?

  [ "${exit_code}" -eq 0 ]

  # stdout から作成された履歴ファイルパスを抽出
  HISTORY_PATH="$(grep -oE 'history:[^:]+:' "${stdout_file}" | head -1 | sed -E 's|^history:||; s|:$||')"
  [ -n "${HISTORY_PATH}" ]

  # stderr に warning 契約 SoT の完全一致行が含まれる（パス部分まで含めて assert）
  # SoT: "warning: history file unstaged: <絶対パス>"
  grep -Fxq "warning: history file unstaged: ${HISTORY_PATH}" "${stderr_file}"

  # stdout 側には warning なし（既存の history:<path>:created/appended 出力のみ）
  ! grep -qF "warning" "${stdout_file}"

  # stdout に既存契約の history:<path>:created/appended 出力が含まれる
  grep -qE "^history:.*:(created|appended)$" "${stdout_file}"
}

# ---------------------------------------------------------------
# Case (b): staged → stderr warning なし + exit 0
#
# `git diff --cached --name-only -- <path>` は **index と HEAD の差分**を返す:
#  - HEAD なし（initial commit 未作成）+ ファイル git add 済み
#    → 出力に当該パスが含まれる → check_history_staged_status は staged 判定 → 警告なし
# 本ケースはこの経路（コードレビュー Round 1 指摘 #2 対応で再設計）を再現し、
# `! grep -qF "warning: history file unstaged:"` を必須 assert する。
#
# **仕様妥協の明示（統合レビュー Round 1 指摘 #2 対応）**:
# 本実装の staged 判定は「`git diff --cached --name-only` の出力に対象パスが含まれる」かを見るため、
# 「過去に一度でも index に登録されていれば staged 判定」となる。これは write-history 2 回目 append の
# 「最新差分が staged 済みか」までは検証しない仕様妥協であり、初回 append + git add 後に append → commit
# の運用前提（ステップ 5 で履歴作成 → git add → ステップ 8 で commit）の検出に最適化されている。
# 詳細は計画書 § warning 契約および Unit 履歴 construction_unit03.md を参照。
# ---------------------------------------------------------------
@test "write-history --mode base: staged → 警告なし + exit 0" {
  ( cd "${TEST_REPO}" && git init -q && \
    git config user.email "test@example.com" && \
    git config user.name "Test User" )

  # 1 回目: 履歴ファイル新規作成（このとき unstaged 警告は出るが、本ケースでは検証対象外）
  local stdout1="${TEST_TMPDIR}/case_b_stdout1.txt"
  local stderr1="${TEST_TMPDIR}/case_b_stderr1.txt"
  run_write_history_base "${stdout1}" "${stderr1}" "${TEST_REPO}"

  # stdout から作成された履歴ファイルパスを抽出
  HISTORY_PATH="$(grep -oE 'history:[^:]+:' "${stdout1}" | head -1 | sed -E 's|^history:||; s|:$||')"
  [ -n "${HISTORY_PATH}" ]
  [ -f "${HISTORY_PATH}" ]

  # 履歴ファイルを git add（index に登録 = staged 化）
  ( cd "${TEST_REPO}" && git add "${HISTORY_PATH}" )

  # 2 回目: 同じ履歴ファイルへの append 経路で staged 判定 PASS を検証
  # HEAD なし + index に登録あり → `git diff --cached --name-only -- <path>` は当該パスを返す
  # → check_history_staged_status は staged 判定 → warning なし
  local stdout2="${TEST_TMPDIR}/case_b_stdout2.txt"
  local stderr2="${TEST_TMPDIR}/case_b_stderr2.txt"
  run_write_history_base "${stdout2}" "${stderr2}" "${TEST_REPO}"
  exit_code=$?

  [ "${exit_code}" -eq 0 ]

  # 既存契約の stdout 出力が引き続き機能する
  grep -qE "^history:.*:appended$" "${stdout2}"

  # SoT (warning 契約) 必須 assert: stderr に warning が含まれない（staged 判定済み）
  ! grep -qF "warning: history file unstaged:" "${stderr2}"
}

# ---------------------------------------------------------------
# Case (c): git リポジトリ外 → stderr warning なし + exit 0（警告スキップ）
# ---------------------------------------------------------------
@test "write-history --mode base: git リポジトリ外 → 警告スキップ + exit 0" {
  # git init せず、TEST_REPO 内で write-history.sh を実行
  local stdout_file="${TEST_TMPDIR}/case_c_stdout.txt"
  local stderr_file="${TEST_TMPDIR}/case_c_stderr.txt"

  run_write_history_base "${stdout_file}" "${stderr_file}" "${TEST_REPO}"
  exit_code=$?

  [ "${exit_code}" -eq 0 ]

  # git リポジトリ外のため check_history_staged_status は warning スキップ
  ! grep -qF "warning: history file unstaged" "${stderr_file}"

  # stdout 側は既存契約通り
  grep -qE "^history:.*:(created|appended)$" "${stdout_file}"
}
