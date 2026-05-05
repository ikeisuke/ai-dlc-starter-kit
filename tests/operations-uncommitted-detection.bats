#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 005: pre-merge uncommitted detection guard 単体テスト
# Plan §6 / Domain §6 / Logical Design §1.2 を verify する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TMP="$(mktemp -d -t aidlc-u5.XXXXXX)"
  RELEASE_SH="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"

  cd "$TMP"

  # 独立 git リポ
  git init -q -b main
  git config user.email "test@example.com"
  git config user.name "test"
  printf 'init\n' > README.md
  git add README.md
  git commit -q -m "init"
}

teardown() {
  cd "$REPO_ROOT"
  rm -rf "$TMP"
}

# U1: 実行系 / dirty 状態で merge-pr --dry-run → exit 1
@test "U1: dirty 状態 + --dry-run で pre-flight が exit 1 + stderr pre-merge-uncommitted-detected" {
  printf 'modified\n' >> README.md  # 未コミット差分作成

  run --separate-stderr "$RELEASE_SH" merge-pr --pr 1 --method squash --dry-run
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"pre-merge-uncommitted-detected"* ]]
}

# U2: 実行系 / clean 状態で merge-pr --dry-run → exit 0 + pre-flight pass 表示
@test "U2: clean 状態 + --dry-run で pre-flight pass + exit 0" {
  run "$RELEASE_SH" merge-pr --pr 1 --method squash --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"pre-flight-pass"* ]]
}

# U3: 実行系 / dirty + --skip-checks で escape hatch
@test "U3: dirty 状態 + --skip-checks で pre-flight skip（escape hatch / dry-run pass）" {
  printf 'modified\n' >> README.md

  run --separate-stderr "$RELEASE_SH" merge-pr --pr 1 --method squash --dry-run --skip-checks
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"pre-merge-uncommitted-detected"* ]]
}

# U4: 文書 / review-flow.md L50 の三段階フロー
@test "U4: review-flow.md L50 が三段階フロー（修正コミット → 履歴記録 → 履歴コミット）を含む" {
  local review_flow="${REPO_ROOT}/skills/aidlc/steps/common/review-flow.md"
  grep -F "(2a)" "$review_flow"
  grep -F "(2b)" "$review_flow"
  grep -F "(2c)" "$review_flow"
}

# U5: 文書 / operations-release.md §7.12 / §7.13
@test "U5: operations-release.md §7.12 verify-git 再実行案内 + §7.13 merge-pr pre-flight 記述" {
  local ops_release="${REPO_ROOT}/skills/aidlc/steps/operations/operations-release.md"
  grep -F "verify-git" "$ops_release"
  grep -F "pre-merge-uncommitted-detected" "$ops_release"
}

# U6: 回帰 / #579 post-merge write-history exit 3 ガード（実動作テスト）
@test "U6: write-history.sh post-merge ガード（exit 3）が実動作で発火" {
  local write_history="${REPO_ROOT}/skills/aidlc/scripts/write-history.sh"

  # 最小ダミーサイクル構造
  mkdir -p .aidlc/cycles/v0.0.1/history

  run "$write_history" \
    --cycle v0.0.1 \
    --phase operations \
    --operations-stage post-merge \
    --step "1.5" \
    --content "regression test for #579 guard"
  [ "$status" -eq 3 ]
}

# U7: 境界値 / status:error 時の挙動（warn + 続行 / 誤停止しない）
@test "U7: validate-git.sh status:error 相当 → __operations_release_pre_flight_check が return 0 + warn 出力" {
  # source 経由で __operations_release_pre_flight_check を直接テストする
  # （shim path 注入できない構造のため、関数を抽出して error 経路を直接 verify）
  source "$RELEASE_SH" || true

  # SCRIPT_DIR を一時的に shim ディレクトリに切り替え
  local shim_dir="$TMP/shim"
  mkdir -p "$shim_dir"
  cat > "$shim_dir/validate-git.sh" <<'SHIM'
#!/usr/bin/env bash
echo "status:error"
exit 2
SHIM
  chmod +x "$shim_dir/validate-git.sh"

  local original_script_dir="$SCRIPT_DIR"
  SCRIPT_DIR="$shim_dir"
  run --separate-stderr __operations_release_pre_flight_check
  SCRIPT_DIR="$original_script_dir"

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"pre-merge-uncommitted-unknown"* ]]
}

# U8: 境界値 / status: 行欠落時の挙動（unknown 扱いで warn + 続行）
@test "U8: validate-git.sh 出力に status: 行が無い場合 unknown 扱いで return 0 + warn" {
  source "$RELEASE_SH" || true

  local shim_dir="$TMP/shim2"
  mkdir -p "$shim_dir"
  cat > "$shim_dir/validate-git.sh" <<'SHIM'
#!/usr/bin/env bash
echo "no status line"
exit 0
SHIM
  chmod +x "$shim_dir/validate-git.sh"

  local original_script_dir="$SCRIPT_DIR"
  SCRIPT_DIR="$shim_dir"
  run --separate-stderr __operations_release_pre_flight_check
  SCRIPT_DIR="$original_script_dir"

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"pre-merge-uncommitted-unknown"* ]]
}
