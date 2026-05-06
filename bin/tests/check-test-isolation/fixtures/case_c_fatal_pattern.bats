#!/usr/bin/env bats
# 期待: 致命パターン (rm -rf "$REPO_ROOT") → severity:fatal violation 検出
# このファイル自体はテストとして実行されるが、致命パターンを意図的に含む。
# 致命パターンは allowlist 不可だが、本ファイルは fixture として bin/tests/check-test-isolation/ 配下に置く。
# check-test-isolation.sh は致命を検出して exit 1 を返す（このファイル単独では）。

teardown() {
  rm -rf "$REPO_ROOT"
}

@test "case C: this file intentionally has fatal pattern (fixture for detection test)" {
  skip "fixture for check-test-isolation.sh fatal pattern detection test"
}
