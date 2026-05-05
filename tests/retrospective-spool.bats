#!/usr/bin/env bats
# Unit 002: spool 操作（_spool_append / _spool_extract_entries / _spool_remove_by_id）の単体テスト
# Plan §「スプールフォーマット v1」を verify する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  RETRO_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-issue.sh"
  TMP="$(mktemp -d -t aidlc-retro-spool.XXXXXX)"
  SPOOL="$TMP/spool.md"
}

teardown() {
  rm -rf "$TMP"
}

@test "spool: 初期化 + 追記でヘッダ + ndjson block + entry が生成される" {
  run bash -c "source '$RETRO_LIB' && _spool_append '$SPOOL' '{\"id\":\"e1\",\"version\":\"1\"}'"
  [ "$status" -eq 0 ]
  [ -f "$SPOOL" ]
  grep -q '<!-- retrospective-spool v1 -->' "$SPOOL"
  grep -q '```ndjson' "$SPOOL"
  grep -q '"id":"e1"' "$SPOOL"
}

@test "spool: 2 件追記すると 2 行 NDJSON" {
  bash -c "source '$RETRO_LIB' && _spool_append '$SPOOL' '{\"id\":\"e1\",\"version\":\"1\"}' && _spool_append '$SPOOL' '{\"id\":\"e2\",\"version\":\"1\"}'"
  run bash -c "source '$RETRO_LIB' && _spool_extract_entries '$SPOOL'"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l | tr -d ' ')" = "2" ]
  [[ "$output" == *'"id":"e1"'* ]]
  [[ "$output" == *'"id":"e2"'* ]]
}

@test "spool: extract_entries はヘッダ無しなら exit 2" {
  printf 'no header\n```ndjson\n{}\n```\n' > "$SPOOL"
  run bash -c "source '$RETRO_LIB' && _spool_extract_entries '$SPOOL'"
  [ "$status" -eq 2 ]
}

@test "spool: extract_entries は spool 不在で exit 2" {
  run bash -c "source '$RETRO_LIB' && _spool_extract_entries '$TMP/nope.md'"
  [ "$status" -eq 2 ]
}

@test "spool: remove_by_id で指定 id 行のみ削除（他は残る）" {
  bash -c "source '$RETRO_LIB' && _spool_append '$SPOOL' '{\"id\":\"keep\",\"version\":\"1\"}' && _spool_append '$SPOOL' '{\"id\":\"drop\",\"version\":\"1\"}'"
  bash -c "source '$RETRO_LIB' && _spool_remove_by_id '$SPOOL' 'drop'"
  run bash -c "source '$RETRO_LIB' && _spool_extract_entries '$SPOOL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"id":"keep"'* ]]
  [[ "$output" != *'"id":"drop"'* ]]
}

@test "spool: lock dir はサブシェル trap で必ず解放される（残留なし）" {
  bash -c "source '$RETRO_LIB' && _spool_append '$SPOOL' '{\"id\":\"e1\",\"version\":\"1\"}'"
  [ ! -e "${SPOOL}.lock" ]
}

@test "spool: tmp ファイルは mv 後に残らない" {
  bash -c "source '$RETRO_LIB' && _spool_append '$SPOOL' '{\"id\":\"e1\",\"version\":\"1\"}'"
  ! ls "$TMP"/spool.md.tmp.* 2>/dev/null
}

@test "spool: __retro_build_spool_entry が必須 11 キーを含む JSON を生成" {
  printf 'sample body\n' > "$TMP/body.md"
  run bash -c "source '$RETRO_LIB' && __retro_build_spool_entry 'v2.5.1' 'mirror-only' 'mirror' 'mirror' 'gh-not-available' '$TMP/body.md' '' ''"
  [ "$status" -eq 0 ]
  for key in id version cycle feedback_mode attempted_at target retry_target partial_state attempt_reason body_b64 body_sha256; do
    [[ "$output" == *"\"$key\""* ]]
  done
}

@test "spool: build_spool_entry の partial_state.local_created は空文字なら null" {
  printf 'sample\n' > "$TMP/body.md"
  run bash -c "source '$RETRO_LIB' && __retro_build_spool_entry 'v2.5.1' 'local-and-mirror' 'both' 'mirror' 'mirror-failed-after-local-created' '$TMP/body.md' 'https://example.com/issues/1' ''"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"local_created":"https://example.com/issues/1"'* ]]
  [[ "$output" == *'"mirror_created":null'* ]]
}

@test "spool: body_sha256 が body の sha256 と一致する" {
  printf 'integrity-test\n' > "$TMP/body.md"
  expected="$(shasum -a 256 < "$TMP/body.md" | cut -d' ' -f1)"
  json="$(bash -c "source '$RETRO_LIB' && __retro_build_spool_entry 'v2.5.1' 'mirror-only' 'mirror' 'mirror' 'gh-not-available' '$TMP/body.md' '' ''")"
  actual="$(printf '%s' "$json" | jq -r '.body_sha256')"
  [ "$expected" = "$actual" ]
}
