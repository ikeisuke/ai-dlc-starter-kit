#!/usr/bin/env bats
# Unit 004 (#643): 移管対象 3 関数の関数レベル契約テスト
# 各 helper を独立して source した状態で、関数の入出力契約が移管前後で同一であることを検証

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  HELPER_VALIDATE="${REPO_ROOT}/skills/aidlc/scripts/lib/aidlc-validate.sh"
  HELPER_GH="${REPO_ROOT}/skills/aidlc/scripts/lib/aidlc-gh.sh"
  HELPER_SPOOL="${REPO_ROOT}/skills/aidlc/scripts/lib/aidlc-spool.sh"
  TMP="$(mktemp -d -t aidlc-helpers-migration.XXXXXX)"
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP"
}

# ─── aidlc-validate.sh: __retro_validate_cycle ─────────

@test "validate: __retro_validate_cycle 正常 cycle で exit 0" {
  run bash -c "source '$HELPER_VALIDATE' && __retro_validate_cycle 'v2.5.3'"
  [ "$status" -eq 0 ]
}

@test "validate: __retro_validate_cycle 空文字で exit 2 / cycle_invalid" {
  run bash -c "source '$HELPER_VALIDATE' && __retro_validate_cycle ''"
  [ "$status" -eq 2 ]
  [[ "$output" == *"cycle_invalid"* ]]
}

@test "validate: __retro_validate_cycle path traversal で exit 2" {
  run bash -c "source '$HELPER_VALIDATE' && __retro_validate_cycle '../etc'"
  [ "$status" -eq 2 ]
}

@test "validate: __retro_validate_cycle 禁止文字で exit 2" {
  run bash -c "source '$HELPER_VALIDATE' && __retro_validate_cycle 'cycle/with/slash'"
  [ "$status" -eq 2 ]
}

# ─── aidlc-gh.sh: __retro_gh_status ─────────

@test "gh: __retro_gh_status は available/unavailable/not-installed のいずれか" {
  run bash -c "source '$HELPER_GH' && __retro_gh_status"
  [ "$status" -eq 0 ]
  [[ "$output" == "available" || "$output" == "unavailable" || "$output" == "not-installed" ]]
}

# ─── aidlc-spool.sh: _spool_extract_entries ─────────

@test "spool: _spool_extract_entries 不在 spool で exit 2" {
  run bash -c "source '$HELPER_SPOOL' && _spool_extract_entries '$TMP/no-such-spool.md'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"spool_not_found"* ]]
}

@test "spool: _spool_extract_entries ヘッダ無しで exit 2" {
  printf 'no header here\n' > "$TMP/bad-spool.md"
  run bash -c "source '$HELPER_SPOOL' && _spool_extract_entries '$TMP/bad-spool.md'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"spool_header_missing"* ]]
}

@test "spool: _spool_extract_entries 有効 spool で NDJSON 抽出" {
  cat > "$TMP/spool.md" <<'EOF'
<!-- retrospective-spool v1 -->

```ndjson
{"id":"a","cycle":"v2.5.3"}
{"id":"b","cycle":"v2.5.3"}
```
EOF
  run bash -c "source '$HELPER_SPOOL' && _spool_extract_entries '$TMP/spool.md'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"id":"a"'* ]]
  [[ "$output" == *'"id":"b"'* ]]
}

# ─── 境界完全分離検証 ─────────

@test "境界完全分離: aidlc-validate.sh は他 helper を source しない" {
  ! grep -E "^(source|\.)[[:space:]]+.*(retrospective-issue|predecessor-issue|aidlc-(gh|spool|paths))\.sh" "$HELPER_VALIDATE"
}

@test "境界完全分離: aidlc-gh.sh は他 helper を source しない" {
  ! grep -E "^(source|\.)[[:space:]]+.*(retrospective-issue|predecessor-issue|aidlc-(validate|spool|paths))\.sh" "$HELPER_GH"
}

@test "境界完全分離: aidlc-spool.sh は他 helper を source しない" {
  ! grep -E "^(source|\.)[[:space:]]+.*(retrospective-issue|predecessor-issue|aidlc-(validate|gh|paths))\.sh" "$HELPER_SPOOL"
}

# ─── 多重 source ガード検証 ─────────

@test "多重 source ガード: aidlc-validate.sh を 2 回 source しても重複定義エラーなし" {
  run bash -c "source '$HELPER_VALIDATE' && source '$HELPER_VALIDATE' && __retro_validate_cycle 'v2.5.3'"
  [ "$status" -eq 0 ]
}

@test "多重 source ガード: aidlc-gh.sh を 2 回 source しても重複定義エラーなし" {
  run bash -c "source '$HELPER_GH' && source '$HELPER_GH' && __retro_gh_status"
  [ "$status" -eq 0 ]
}

@test "多重 source ガード: aidlc-spool.sh を 2 回 source しても重複定義エラーなし" {
  run bash -c "source '$HELPER_SPOOL' && source '$HELPER_SPOOL' && _spool_extract_entries '$TMP/no-such.md'"
  [ "$status" -eq 2 ]
}
