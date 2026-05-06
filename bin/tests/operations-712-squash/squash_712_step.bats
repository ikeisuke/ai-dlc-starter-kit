#!/usr/bin/env bats
# operations-release.sh squash-712 サブコマンドの契約テスト (7 ケース)
# 観点:
#   1. squash_enabled=false → squash:skipped + reason=squash_enabled=false
#   2. slot 行なし → squash:skipped + reason=release_prep_commit_missing
#   3. slot 値空 → squash:skipped + reason=release_prep_commit_missing
#   4. slot 値が 39 桁 (不正) → squash:failed:reason=format_error
#   5. 対象 0 件 → squash:skipped + reason=no_commits
#   6. 通常系 (複数コミット) → squash:success:<sha> + 1 行に圧縮
#   7. git commit 失敗 → rollback (reset --hard ORIG_HEAD) + squash:failed:reason=git_op_failed:1

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  OPS_REL="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"
  TEMPLATE="${REPO_ROOT}/skills/aidlc/templates/operations_progress_template.md"
  READ_CONFIG="${REPO_ROOT}/skills/aidlc/scripts/read-config.sh"

  TMP_REPO="$(mktemp -d -t aidlc-squash712-test.XXXXXX)"
  cd "$TMP_REPO"
  git init --quiet
  git config user.email "test@example.com"
  git config user.name "Test"
  git config commit.gpgsign false
  CYCLE="v9.9.9"
  mkdir -p ".aidlc/cycles/${CYCLE}/operations"
  echo "init" > README.md

  # config.toml の最小構成（read-config.sh が squash_enabled を取得できるように）
  cat > .aidlc/config.toml <<'EOF'
[project]
name = "test-project"

[rules.git]
squash_enabled = true
EOF

  cp "$TEMPLATE" ".aidlc/cycles/${CYCLE}/operations/progress.md"
  # 全ファイルを git で tracked にして clean な状態を確立
  git add .
  git commit --quiet -m "initial"
}

teardown() {
  cd "$BATS_TEST_TMPDIR"
  rm -rf "$TMP_REPO"
}

# ヘルパー: progress.md slot に SHA を書き込み + git commit (実 Operations フローでは record-release-prep-commit が行う)
__write_slot() {
  local sha="$1"
  sed -i.bak -E "s|^<!-- release_prep_commit:.*-->[[:space:]]*$|<!-- release_prep_commit: ${sha} -->|" ".aidlc/cycles/${CYCLE}/operations/progress.md"
  rm -f ".aidlc/cycles/${CYCLE}/operations/progress.md.bak"
  git add ".aidlc/cycles/${CYCLE}/operations/progress.md"
  git commit --quiet -m "set release_prep_commit slot" || true
}

@test "squash-712 (1): squash_enabled=false → squash:skipped + reason" {
  # config.toml を書き換え
  cat > .aidlc/config.toml <<'EOF'
[project]
name = "test-project"
[rules.git]
squash_enabled = false
EOF
  __write_slot "$(git rev-parse HEAD)"
  run bash "$OPS_REL" squash-712 --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"squash:skipped"* ]]
  [[ "$output" == *"squash_enabled=false"* ]]
}

@test "squash-712 (2): slot 行なし → squash:skipped + release_prep_commit_missing" {
  # template に slot 行なし
  cat > ".aidlc/cycles/${CYCLE}/operations/progress.md" <<'EOF'
## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=false
EOF
  run bash "$OPS_REL" squash-712 --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"squash:skipped"* ]]
  [[ "$output" == *"release_prep_commit_missing"* ]]
}

@test "squash-712 (3): slot 値空 → squash:skipped + release_prep_commit_missing" {
  # 初期状態 (template) は slot 値空
  run bash "$OPS_REL" squash-712 --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"squash:skipped"* ]]
  [[ "$output" == *"release_prep_commit_missing"* ]]
}

@test "squash-712 (4): slot 値が 39 桁 (不正) → squash:failed:reason=format_error" {
  __write_slot "abc1234"  # 7 桁: 不正
  run bash "$OPS_REL" squash-712 --cycle "$CYCLE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"squash:failed:reason=format_error"* ]]
  [[ "$output" == *"release_prep_commit_format_error"* ]]
}

@test "squash-712 (5): 対象 0 件 (slot 値 = HEAD) → squash:skipped + no_commits" {
  # slot 値を現 HEAD で書く（commit せず modified のまま / squash-712 は git status をチェックしないため OK）
  HEAD_SHA=$(git rev-parse HEAD)
  sed -i.bak -E "s|^<!-- release_prep_commit:.*-->[[:space:]]*$|<!-- release_prep_commit: ${HEAD_SHA} -->|" ".aidlc/cycles/${CYCLE}/operations/progress.md"
  rm -f ".aidlc/cycles/${CYCLE}/operations/progress.md.bak"
  run bash "$OPS_REL" squash-712 --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"squash:skipped"* ]]
  [[ "$output" == *"no_commits"* ]]
}

@test "squash-712 (6): 通常系 (3 commits) → squash:success + 1 行に圧縮" {
  BASE_SHA=$(git rev-parse HEAD)
  __write_slot "$BASE_SHA"  # progress.md slot 更新コミットも作成（§7.7.1 相当）
  # 3 つの追加コミットを作成（§7.12 レビュー反映コミット相当）
  echo "a" > a.txt; git add a.txt; git commit --quiet -m "wip a"
  echo "b" > b.txt; git add b.txt; git commit --quiet -m "wip b"
  echo "c" > c.txt; git add c.txt; git commit --quiet -m "wip c"
  run bash "$OPS_REL" squash-712 --cycle "$CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"squash:success:"* ]]
  # base からの差分が 1 コミットに圧縮されていること（slot コミット + 3 wip → 1 squash）
  COMMIT_COUNT=$(git log "${BASE_SHA}..HEAD" --oneline | wc -l | tr -d ' ')
  [ "$COMMIT_COUNT" -eq 1 ]
  # 作業ツリーは clean（progress.md の更新は slot コミットで取り込み済みのため untracked/modified が残らない）
  [ -z "$(git status --porcelain)" ]
}

@test "squash-712 (7): git commit 失敗 → rollback で開始前と一致" {
  BASE_SHA=$(git rev-parse HEAD)
  __write_slot "$BASE_SHA"
  echo "a" > a.txt; git add a.txt; git commit --quiet -m "wip a"
  echo "b" > b.txt; git add b.txt; git commit --quiet -m "wip b"
  HEAD_BEFORE=$(git rev-parse HEAD)
  TREE_BEFORE=$(git rev-parse HEAD^{tree})
  # pre-commit hook で人工的に commit を失敗させる
  mkdir -p .git/hooks
  cat > .git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x .git/hooks/pre-commit
  run bash "$OPS_REL" squash-712 --cycle "$CYCLE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"squash:failed:reason=git_op_failed:1"* ]]
  [[ "$output" == *"squash_712:commit-failed"* ]]
  # rollback により HEAD と tree が開始前と一致
  HEAD_AFTER=$(git rev-parse HEAD)
  TREE_AFTER=$(git rev-parse HEAD^{tree})
  [ "$HEAD_AFTER" = "$HEAD_BEFORE" ]
  [ "$TREE_AFTER" = "$TREE_BEFORE" ]
  # 作業ツリーは clean
  [ -z "$(git status --porcelain)" ]
  # クリーンアップ
  rm -f .git/hooks/pre-commit
}
