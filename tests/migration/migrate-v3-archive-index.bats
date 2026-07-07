#!/usr/bin/env bats
# migrate-v3-archive-index.sh のテスト（archive-only migration / v2 cycles 所在 index）

load helpers/setup

teardown() {
  teardown_environment
}

# v2 構造 / v3 構造の cycle を混在させたテスト環境
setup_mixed_cycles() {
  setup_v2v3_environment gen-2.5.5-full

  # v2 構造 cycle（inception intent + units + history + release_notes）
  mkdir -p "${TEST_TMPDIR}/.aidlc/cycles/v1.0.0/inception"
  touch "${TEST_TMPDIR}/.aidlc/cycles/v1.0.0/inception/intent.md"
  mkdir -p "${TEST_TMPDIR}/.aidlc/cycles/v1.0.0/story-artifacts/units"
  mkdir -p "${TEST_TMPDIR}/.aidlc/cycles/v1.0.0/history"
  mkdir -p "${TEST_TMPDIR}/.aidlc/cycles/v1.0.0/operations"
  touch "${TEST_TMPDIR}/.aidlc/cycles/v1.0.0/operations/release_notes.md"

  # v2 構造 cycle（requirements intent + progress.md のみ）
  mkdir -p "${TEST_TMPDIR}/.aidlc/cycles/v2.5.0/requirements"
  touch "${TEST_TMPDIR}/.aidlc/cycles/v2.5.0/requirements/intent.md"
  touch "${TEST_TMPDIR}/.aidlc/cycles/v2.5.0/progress.md"

  # v3 フラット構造 cycle（work-items/ マーカーあり → 対象外）
  mkdir -p "${TEST_TMPDIR}/.aidlc/cycles/v3.0.0/work-items"
}

@test "v3-archive-index: lists v2 cycles and excludes v3 cycles" {
  setup_mixed_cycles
  run run_v3_archive_index
  [ "$status" -eq 0 ]
  [[ "$output" == *"status:generated:count=2"* ]]
  idx="$(cat "${TEST_TMPDIR}/.aidlc/v2-archive.md")"
  [[ "$idx" == *"| v1.0.0 | ✓ | ✓ | - | ✓ | ✓ |"* ]]
  [[ "$idx" == *"| v2.5.0 | ✓ | - | ✓ | - | - |"* ]]
  [[ "$idx" != *"| v3.0.0 |"* ]]
}

@test "v3-archive-index: one-way note included" {
  setup_mixed_cycles
  run run_v3_archive_index
  [ "$status" -eq 0 ]
  idx="$(cat "${TEST_TMPDIR}/.aidlc/v2-archive.md")"
  [[ "$idx" == *"片方向移行"* ]]
}

@test "v3-archive-index: zero cycles generates empty index" {
  setup_v2v3_environment gen-2.5.5-full
  run run_v3_archive_index
  [ "$status" -eq 0 ]
  [[ "$output" == *"status:generated:count=0"* ]]
  idx="$(cat "${TEST_TMPDIR}/.aidlc/v2-archive.md")"
  [[ "$idx" == *"archive 対象の cycle はありません"* ]]
}

@test "v3-archive-index: regeneration is idempotent (no append)" {
  setup_mixed_cycles
  export AIDLC_MIGRATE_NOW="2026-01-01T00:00:00Z"
  run run_v3_archive_index
  [ "$status" -eq 0 ]
  first="$(cat "${TEST_TMPDIR}/.aidlc/v2-archive.md")"
  run run_v3_archive_index
  [ "$status" -eq 0 ]
  second="$(cat "${TEST_TMPDIR}/.aidlc/v2-archive.md")"
  [ "$first" = "$second" ]
  headers="$(grep -c '^# v2 アーカイブ index' "${TEST_TMPDIR}/.aidlc/v2-archive.md")"
  [ "$headers" -eq 1 ]
}

@test "v3-archive-index: output override (repo-relative) writes to custom path" {
  setup_mixed_cycles
  run run_v3_archive_index --output "custom-index.md"
  [ "$status" -eq 0 ]
  [ -f "${TEST_TMPDIR}/custom-index.md" ]
  [ ! -f "${TEST_TMPDIR}/.aidlc/v2-archive.md" ]
}

@test "v3-archive-index: absolute / traversal output rejected (path-guard)" {
  setup_mixed_cycles
  run run_v3_archive_index --output "${TEST_TMPDIR}/abs-index.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:path-rejected:output"* ]]
  run run_v3_archive_index --output "../escape-index.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:path-rejected:output"* ]]
  [ ! -f "${TEST_TMPDIR}/../escape-index.md" ]
}

@test "v3-archive-index: output directory rejected" {
  setup_mixed_cycles
  run run_v3_archive_index --output ".aidlc/cycles"
  [ "$status" -eq 1 ]
  [[ "$output" == *"error:output-is-directory"* ]]
}

@test "v3-archive-index: invalid cycle name skipped with warning" {
  setup_mixed_cycles
  mkdir -p "${TEST_TMPDIR}/.aidlc/cycles/bad|name"
  run run_v3_archive_index
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn:skipped-invalid-cycle-name:bad_name"* ]]
  [[ "$output" == *"status:generated:count=2"* ]]
  idx="$(cat "${TEST_TMPDIR}/.aidlc/v2-archive.md")"
  [[ "$idx" != *"bad|name"* ]]
}
