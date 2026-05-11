#!/usr/bin/env bats
# Unit 003 (#677 / v2.6.2): write-history.sh の --mode operations-round 経路 auto-commit テスト
#
# 設計 SoT: .aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_003_fix_squash712_history_integration_logical_design.md
#
# 検証ケース:
#   (a) auto-commit 正常系: append + git commit が成功し history-commit:<sha>:operations-round-round-<N> 出力
#   (b) --no-commit opt-out: append のみ実行、auto-commit skip、history-commit 出力なし
#   (c) dry-run + auto-commit: would-append + history-commit:would-commit:operations-round-round-<N> 出力、副作用なし
#   (d) 事前 staged ガード: 対象ファイルが事前 staged 状態だと auto-commit skip + warning（exit 0 維持）
#   (e) 非 git 環境ガード: git リポジトリ外で実行すると auto-commit skip + warning（exit 0 維持）
#   (f) --no-commit が --mode operations-round 以外で指定 → warning + exit 0、flag は無視

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  WRITE_HISTORY="${REPO_ROOT}/skills/aidlc/scripts/write-history.sh"
  TMP="$(mktemp -d -t aidlc-write-history-op-commit.XXXXXX)"
  cd "$TMP"
  CYCLE="v2.6.2"

  # テスト用 git リポジトリを初期化
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  # main ブランチ作成
  git checkout -q -b main 2>/dev/null || true

  mkdir -p ".aidlc/cycles/${CYCLE}/history"
  # 必須 config.toml stub
  cat > ".aidlc/config.toml" <<EOF
[project]
name = "test-project"
EOF
  # 初期 commit
  git add .aidlc/config.toml
  git commit -q -m "init"

  # AIDLC_PROJECT_ROOT を tmp に向ける
  export AIDLC_PROJECT_ROOT="$TMP"
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP"
}

# ─── 共通ヘルパ ─────────

_call_op_round() {
  # 残り引数を operations-round 必須引数に追加して呼び出す
  bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase operations \
    --step "テストステップ" \
    --content "operations round content" \
    --mode operations-round \
    --round 1 \
    --findings 0 \
    --critical 0 --high 0 --medium 0 --low 0 \
    --resolved-count 0 --deferred-count 0 \
    "$@"
}

# ─── (a) auto-commit 正常系 ─────────

@test "operations-round: auto-commit 正常系 → history-commit:<sha>:operations-round-round-1 出力" {
  run _call_op_round
  [ "$status" -eq 0 ]
  [[ "$output" == *":appended"* ]] || [[ "$output" == *":created"* ]]
  [[ "$output" == *"history-commit:"* ]]
  [[ "$output" == *":operations-round-round-1"* ]]

  # working tree が clean であること（auto-commit が動いた証拠）
  run git status --porcelain -- ".aidlc/cycles/${CYCLE}/history/operations.md"
  [ -z "$output" ]

  # HEAD コミット message に round 1 が含まれること
  run git log -1 --pretty=%s
  [[ "$output" == *"§7.12 レビュー round 1 履歴記録"* ]]
}

# ─── (b) --no-commit opt-out ─────────

@test "operations-round: --no-commit opt-out → append のみ実行、history-commit 出力なし" {
  run _call_op_round --no-commit
  [ "$status" -eq 0 ]
  [[ "$output" == *":appended"* ]] || [[ "$output" == *":created"* ]]
  [[ "$output" != *"history-commit:"* ]]

  # append のみなので unstaged 差分が残る
  run git status --porcelain -- ".aidlc/cycles/${CYCLE}/history/operations.md"
  [ -n "$output" ]
}

# ─── (c) dry-run + auto-commit ─────────

@test "operations-round: dry-run + auto-commit → would-append + history-commit:would-commit 出力" {
  run _call_op_round --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *":would-append"* ]] || [[ "$output" == *":would-create"* ]]
  [[ "$output" == *"history-commit:would-commit:operations-round-round-1"* ]]

  # ファイルが新規作成されていない
  [ ! -f ".aidlc/cycles/${CYCLE}/history/operations.md" ]
}

# ─── (d) 事前 staged ガード ─────────

@test "operations-round: 事前 staged → auto-commit skip + warning（exit 0 維持）" {
  # 事前に履歴ファイルを作成し staged にする
  printf 'pre-existing staged content\n' > ".aidlc/cycles/${CYCLE}/history/operations.md"
  git add ".aidlc/cycles/${CYCLE}/history/operations.md"

  run _call_op_round
  [ "$status" -eq 0 ]
  [[ "$output" == *":appended"* ]]
  # auto-commit skip
  [[ "$output" != *"history-commit:"*"operations-round-round-1"* ]]
  # stderr に warning が出る（run の output は stdout+stderr 結合）
  [[ "$output" == *"warning: history file already staged"* ]]
}

# ─── (e) 非 git 環境ガード ─────────

@test "operations-round: 非 git 環境 → auto-commit skip + warning（exit 0 維持）" {
  # 別の non-git tmp dir に AIDLC_PROJECT_ROOT を向ける
  local non_git_tmp
  non_git_tmp="$(mktemp -d -t aidlc-non-git.XXXXXX)"
  mkdir -p "${non_git_tmp}/.aidlc/cycles/${CYCLE}/history"
  cat > "${non_git_tmp}/.aidlc/config.toml" <<EOF
[project]
name = "test-project"
EOF
  export AIDLC_PROJECT_ROOT="$non_git_tmp"
  cd "$non_git_tmp"

  run _call_op_round
  [ "$status" -eq 0 ]
  [[ "$output" == *":appended"* ]] || [[ "$output" == *":created"* ]]
  # auto-commit skip + warning
  [[ "$output" != *"history-commit:"*"operations-round-round-1"* ]]
  [[ "$output" == *"warning: not inside a git repository"* ]]

  cd "$TMP"
  rm -rf "$non_git_tmp"
}

# ─── (f) --no-commit 誤指定検知 ─────────

@test "operations-round 以外で --no-commit → warning + exit 0、flag は無視" {
  # --mode base + --no-commit
  run bash "$WRITE_HISTORY" \
    --cycle "$CYCLE" \
    --phase construction \
    --unit 99 \
    --unit-name "Test Unit" \
    --unit-slug test-unit \
    --step "テストステップ" \
    --content "construction base content" \
    --mode base \
    --no-commit
  [ "$status" -eq 0 ]
  [[ "$output" == *":created"* ]] || [[ "$output" == *":appended"* ]]
  [[ "$output" == *"warning: --no-commit is only effective with --mode operations-round"* ]]
  [[ "$output" == *"got mode: base"* ]]
}
