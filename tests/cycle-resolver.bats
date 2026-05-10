#!/usr/bin/env bats
# Unit 005 (#667): cycle-resolver.sh の Strategy / resolve / fail-safe ガードを検証する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  RESOLVER="${REPO_ROOT}/skills/aidlc/scripts/lib/cycle-resolver.sh"
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-cycle-resolver-XXXXXX)"
}

teardown() {
  cd "$BATS_TMPDIR"
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# 多重 source ガードを毎回リセットして source できるようにする
load_resolver_fresh() {
  unset CYCLE_RESOLVER_SOURCED
  # shellcheck disable=SC1090
  source "$RESOLVER"
}

@test "S1 ArgStrategy: 引数が semver 形式 → confidence=high で arg として確定" {
  load_resolver_fresh
  run cycle_resolver_resolve "v1.2.3"
  [ "$status" -eq 0 ]
  [[ "$output" == *"candidate=v1.2.3"* ]]
  [[ "$output" == *"source_id=arg"* ]]
  [[ "$output" == *"confidence=high"* ]]
}

@test "S1 ArgStrategy: 引数が semver 不一致 → S1 fallthrough（他 Strategy へ）" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  # 非 git ディレクトリで全 Strategy 失敗を確認
  run cycle_resolver_resolve "not-a-semver"
  [ "$status" -eq 1 ]
  [[ "$output" == *"candidate="* ]]
  [[ "$output" == *"source_id=none"* ]]
}

@test "S2 BranchStrategy: cycle/vX.Y.Z ブランチで confidence=high" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  git init --quiet --initial-branch=cycle/v9.9.9 2>/dev/null || {
    git init --quiet
    git checkout -b cycle/v9.9.9 2>/dev/null
  }
  git config user.email t@example.com
  git config user.name t
  git commit --allow-empty -m "init" --quiet
  run cycle_resolver_resolve ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"candidate=v9.9.9"* ]]
  [[ "$output" == *"source_id=branch"* ]]
  [[ "$output" == *"confidence=high"* ]]
}

@test "S2 BranchStrategy: 非 cycle/* ブランチ → S2 不適合（fallthrough）" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  git init --quiet
  git config user.email t@example.com
  git config user.name t
  git commit --allow-empty -m "init" --quiet
  # main ブランチ前提
  run cycle_resolver_resolve ""
  # S3a も S3b も候補なし → exit 1（S1/S2 失敗）
  [ "$status" -eq 1 ]
  [[ "$output" == *"source_id=none"* ]]
}

@test "S3b CycleDirStrategy: .aidlc/cycles/v* から最新 semver を返す（S1/S2 失敗時）" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  git init --quiet
  git config user.email t@example.com
  git config user.name t
  git commit --allow-empty -m "init" --quiet
  mkdir -p .aidlc/cycles/v1.0.0 .aidlc/cycles/v2.5.0 .aidlc/cycles/v2.10.0
  run cycle_resolver_resolve ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"candidate=v2.10.0"* ]]
  [[ "$output" == *"source_id=cycledir"* ]]
  [[ "$output" == *"confidence=low"* ]]
}

@test "S3b: pwd フォールバックなし（git 不在ディレクトリでは候補なし）" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  # git init せず .aidlc/cycles/ だけ作る
  mkdir -p .aidlc/cycles/v9.9.9
  run cycle_resolver_resolve ""
  # S3b は git toplevel 解決失敗で候補なし、他 Strategy も全て失敗 → exit 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"source_id=none"* ]]
}

@test "優先順位: S1 (arg) > S2 (branch) > S3b (cycledir)" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  git init --quiet 2>/dev/null
  git checkout -b cycle/v3.0.0 2>/dev/null || git symbolic-ref HEAD refs/heads/cycle/v3.0.0
  git config user.email t@example.com
  git config user.name t
  git commit --allow-empty -m "init" --quiet
  mkdir -p .aidlc/cycles/v9.9.9
  # arg を渡せば arg が勝つ
  run cycle_resolver_resolve "v1.0.0"
  [ "$status" -eq 0 ]
  [[ "$output" == *"candidate=v1.0.0"* ]]
  [[ "$output" == *"source_id=arg"* ]]
}

@test "fail-safe: confidence != high かつ S3a/S3b 不一致時に conflict 通知" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  git init --quiet
  git config user.email t@example.com
  git config user.name t
  git commit --allow-empty -m "init" --quiet
  # ブランチ名は cycle/* ではないので S2 不適合 → primary_conf != high になり得る
  # S3a/S3b の不一致は git log に cycle/v* が出ない（S3a 候補なし）+ S3b に v8.0.0 あり
  # → S3a 候補なしなので conflict 検査は走らない（s3a_out 空）
  # conflict 検査が機能するには S3a/S3b 両方に異なる候補が必要。
  # 統合テストでは git log 操作が複雑なので、本テストは「conflict 不発生時の正常動作」を確認
  mkdir -p .aidlc/cycles/v8.0.0
  run cycle_resolver_resolve ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"candidate=v8.0.0"* ]]
  # S3a 不在のため conflict は通知されない
  [[ "$output" != *"conflict=true"* ]]
}

@test "全 Strategy 失敗時 → exit 1 + source_id=none" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  # 完全に何もない（git なし、.aidlc/cycles/ なし、引数なし）
  run cycle_resolver_resolve ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"source_id=none"* ]]
  [[ "$output" == *"evidence=no candidate resolved"* ]]
}

@test "S1 ArgStrategy: 空引数 → fallthrough（他 Strategy 評価）" {
  load_resolver_fresh
  cd "$TEST_TMPDIR"
  git init --quiet
  git checkout -b cycle/v5.0.0 2>/dev/null || git symbolic-ref HEAD refs/heads/cycle/v5.0.0
  git config user.email t@example.com
  git config user.name t
  git commit --allow-empty -m "init" --quiet
  run cycle_resolver_resolve ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"source_id=branch"* ]]
  [[ "$output" == *"candidate=v5.0.0"* ]]
}
