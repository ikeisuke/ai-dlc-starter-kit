#!/usr/bin/env bats
# check-test-isolation.sh の動作を end-to-end で検証する。
# 一時的なテスト構造を mktemp で作成し、検査スクリプトを実行して結果を assert する。

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  CHECK_SCRIPT="${REPO_ROOT}/bin/check-test-isolation.sh"
  TMP_REPO="$(mktemp -d -t check-test-isolation-e2e.XXXXXX)"
  cd "$TMP_REPO"
  git init --quiet
  git config user.email "test@example.com"
  git config user.name "Test"
  mkdir -p tests bin
  cp "$CHECK_SCRIPT" bin/check-test-isolation.sh
  chmod +x bin/check-test-isolation.sh
  : > bin/check-test-isolation.allowlist
  git add . >/dev/null
  git commit --quiet -m "init"
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP_REPO"
}

@test "E2E-01: ガードあり (cd \$BATS_TMPDIR + rm -rf) → exit 0" {
  cat > tests/guarded.bats <<'BATS'
teardown() {
  cd "$BATS_TMPDIR"
  rm -rf foo/
}
BATS
  run bash -c "bin/check-test-isolation.sh 2>&1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no violations"* ]]
}

@test "E2E-02: ガードなし (rm -rf only) → exit 1 + regular violation" {
  cat > tests/no_guard.bats <<'BATS'
teardown() {
  rm -rf "$TMP"
}
BATS
  run bash -c "bin/check-test-isolation.sh 2>&1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"rm-rf-without-cd-guard"* ]]
}

@test "E2E-03: 致命パターン (rm -rf \$REPO_ROOT) → exit 1 + severity:fatal" {
  cat > tests/fatal.bats <<'BATS'
teardown() {
  rm -rf "$REPO_ROOT"
}
BATS
  run bash -c "bin/check-test-isolation.sh 2>&1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"severity:fatal"* ]]
}

@test "E2E-04: 出力フォーマット 4 カラム TSV (error\\t<check>\\t<file>:<line>\\t<reason>)" {
  cat > tests/no_guard.bats <<'BATS'
teardown() {
  rm -rf "$TMP"
}
BATS
  run bash -c "bin/check-test-isolation.sh 2>&1"
  [ "$status" -eq 1 ]
  # stderr の violation 行を抽出して列数を確認
  violation_line="$(echo "$output" | grep '^error' | head -1)"
  field_count="$(echo "$violation_line" | awk -F$'\t' '{print NF}')"
  [ "$field_count" -eq 4 ]
}

@test "E2E-05: malformed allowlist (列数不足) → exit 1" {
  cat > tests/guarded.bats <<'BATS'
teardown() {
  cd "$BATS_TMPDIR"
  rm -rf foo/
}
BATS
  printf 'tests/guarded.bats\tteardown\tonly-three-cols\n' > bin/check-test-isolation.allowlist
  run bash -c "bin/check-test-isolation.sh 2>&1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"allowlist-malformed-column-count"* ]]
}

@test "E2E-06: 期限切れ allowlist → exit 1" {
  cat > tests/no_guard.bats <<'BATS'
teardown() {
  rm -rf "$TMP"
}
BATS
  printf 'tests/no_guard.bats\tteardown\trm-rf-without-cd-guard\t2020-01-01\t#999\t2020-12-31\n' > bin/check-test-isolation.allowlist
  run bash -c "bin/check-test-isolation.sh 2>&1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"allowlist-expired"* ]]
}

@test "E2E-07: 致命は allowlist でも非許可 (severity:fatal で exit 1)" {
  cat > tests/fatal.bats <<'BATS'
teardown() {
  rm -rf "$REPO_ROOT"
}
BATS
  printf 'tests/fatal.bats\tteardown\tfatal-rm-rf:"$REPO_ROOT"\t2026-05-06\t#999\t2099-12-31\n' > bin/check-test-isolation.allowlist
  run bash -c "bin/check-test-isolation.sh 2>&1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"severity:fatal"* ]]
}

@test "E2E-08: 不正日付フォーマット → exit 1" {
  cat > tests/guarded.bats <<'BATS'
teardown() {
  cd "$BATS_TMPDIR"
  rm -rf foo/
}
BATS
  printf 'tests/guarded.bats\tteardown\tlegacy\t2026-99-99\t#999\t2099-12-31\n' > bin/check-test-isolation.allowlist
  run bash -c "bin/check-test-isolation.sh 2>&1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"allowlist-malformed-added-date"* ]]
}
