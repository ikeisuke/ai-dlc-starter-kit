#!/usr/bin/env bats
# 期待: ガードなし + rm -rf → check-test-isolation.sh で violation 検出
# このファイル自体はテストとして実行されるが、cwd 依存パターンを意図的に含む。
# 検出器の対象になるよう、bin/check-test-isolation.allowlist へ allowlist 登録される。

teardown() {
  rm -rf "$TMP"
}

@test "case B: this file intentionally has no cd guard before rm -rf (allowlist test fixture)" {
  skip "fixture for check-test-isolation.sh detection test"
}
