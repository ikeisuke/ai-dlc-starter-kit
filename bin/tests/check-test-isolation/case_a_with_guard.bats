#!/usr/bin/env bats
# 期待: ガードあり (cd "$BATS_TMPDIR" 等) + rm -rf → no violations

setup() {
  cd "$BATS_TMPDIR"
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf foo/
}

@test "case A: guarded teardown reaches here without violation" {
  [ -d "$BATS_TMPDIR" ]
}
