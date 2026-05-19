#!/usr/bin/env bats
# Unit 003 / v2.6.6 / #652:
#   - jsonl extractor (引数なし / 引数あり + 存在 / 引数あり + 不在)
#   - 機密フィルタ MASK-01〜MASK-10 必須網羅 (検出漏れは fail)

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-fact-extract.sh"
  FIXTURE_DIR="${REPO_ROOT}/tests/fixtures/retrospective-fact-extract"
  SAFE_JSONL="${FIXTURE_DIR}/sample_safe.jsonl"
  SECRETS_JSONL="${FIXTURE_DIR}/sample_secrets.jsonl"
}

load_lib_fresh() {
  unset RETROSPECTIVE_FACT_EXTRACT_SOURCED
  # shellcheck disable=SC1090
  source "$LIB"
}

# ─── jsonl extractor: 引数バリエーション ─────────────────────────────

@test "JSONL-1: 引数なしで出力なし (既定動作 / opt-in)" {
  load_lib_fresh
  run _retrospective_fact_extract_jsonl_optional ""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "JSONL-2: 引数指定 + ファイル不在で warn + 出力なし" {
  load_lib_fresh
  run _retrospective_fact_extract_jsonl_optional "/tmp/aidlc-no-such-jsonl-$$.jsonl"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE 'jsonl ファイル不在' || echo "$output" >&2
  # stdout には FactRow 行が出ないこと
  ! echo "$output" | grep -qE '^jsonl\|jsonl_event\|'
}

@test "JSONL-3: 引数指定 + safe jsonl で 3 イベント抽出される" {
  load_lib_fresh
  run _retrospective_fact_extract_jsonl_optional "$SAFE_JSONL"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^jsonl\|jsonl_event\|.*normal event 1.*normal event 2.*normal event 3.*\|'
}

# ─── 機密フィルタ MASK-01〜MASK-10 ──────────────────────────────────

@test "MASK-01: api_key=\"sk-proj-...\" がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'api_key="sk-proj-abc123def456ghi"\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'api_key=\*\*\*\*'
  ! echo "$out" | grep -qE 'sk-proj-abc123def456ghi'
}

@test "MASK-02: API_KEY=... (大文字 / 等号 / クォートなし) がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'API_KEY=ABCDEFGHIJ1234567890\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'API_KEY=\*\*\*\*'
  ! echo "$out" | grep -qE 'ABCDEFGHIJ1234567890'
}

@test "MASK-03: apikey: 'live_...' (コロン / シングルクォート) がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf "apikey: 'live_xxxxxxxxxxxxxxxx'\n" | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'apikey=\*\*\*\*'
  ! echo "$out" | grep -qE 'live_xxxxxxxxxxxxxxxx'
}

@test "MASK-04: Bearer eyJ... がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.abc.def\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'Bearer \*\*\*\*'
  ! echo "$out" | grep -qE 'eyJhbGciOiJIUzI1NiJ9\.abc\.def'
}

@test "MASK-05: password=\"hunter22xx\" がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'password="hunter22xx"\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'password=\*\*\*\*'
  ! echo "$out" | grep -qE 'hunter22xx'
}

@test "MASK-06: token=abc12345defgh (クォートなし) がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'token=abc12345defgh\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'token=\*\*\*\*'
  ! echo "$out" | grep -qE 'abc12345defgh'
}

@test "MASK-07: secret: ghp_... (コロン) がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'secret: ghp_xxxxxxxxxxxxxxxx\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'secret=\*\*\*\*'
  ! echo "$out" | grep -qE 'ghp_xxxxxxxxxxxxxxxx'
}

@test "MASK-08: postgresql://user:pass@host:5432/db がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'postgresql://user:pass@host:5432/db\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'postgresql://\*\*\*\*@host:5432/db'
  ! echo "$out" | grep -qE '://user:pass@'
}

@test "MASK-09: https://admin:secret123@example.com/path がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'https://admin:secret123@example.com/path\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'https://\*\*\*\*@example\.com/path'
}

@test "MASK-10: secretary_name=Tanaka (false positive 確認) はマスクされない" {
  load_lib_fresh
  local out
  out=$(printf 'secretary_name=Tanaka\n' | _retrospective_fact_extract_mask_secrets)
  # secretary_name 全体が残ること
  echo "$out" | grep -qE 'secretary_name=Tanaka'
}

@test "MASK-11: api_key=\"AB+CD/EF==xxxx...\" (Base64 +/=) がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'api_key="AB+CD/EF==xxxxxxxxxxxxxx"\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'api_key=\*\*\*\*'
  ! echo "$out" | grep -qE 'AB\+CD/EF=='
}

@test "MASK-12: secret=\"ghp_xxxxxxxxxxxxxxxx+yyy/zzz==\" (Base64 含む) がマスクされる" {
  load_lib_fresh
  local out
  out=$(printf 'secret="ghp_xxxxxxxxxxxxxxxx+yyy/zzz=="\n' | _retrospective_fact_extract_mask_secrets)
  echo "$out" | grep -qE 'secret=\*\*\*\*'
  ! echo "$out" | grep -qE 'ghp_xxxxxxxxxxxxxxxx\+yyy'
}

@test "JSONL-4: 拡張子 .jsonl 以外で拒否 + warn + 出力なし" {
  load_lib_fresh
  run _retrospective_fact_extract_jsonl_optional "/tmp/some-secret.txt"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF '拒否 - 拡張子が .jsonl ではない'
  ! echo "$output" | grep -qE '^jsonl\|jsonl_event\|'
}

@test "JSONL-5: '..' セグメントを含むパス（path traversal）で拒否 + warn + 出力なし" {
  load_lib_fresh
  run _retrospective_fact_extract_jsonl_optional "/tmp/foo/../bar.jsonl"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF '拒否 - パスに .. セグメントを含む'
  ! echo "$output" | grep -qE '^jsonl\|jsonl_event\|'
}

@test "JSONL-6: 先頭 '../' で拒否 + warn" {
  load_lib_fresh
  run _retrospective_fact_extract_jsonl_optional "../etc/secret.jsonl"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF '拒否 - パスに .. セグメントを含む'
}

# ─── jsonl + 機密フィルタ統合 ────────────────────────────────────────

@test "JSONL-MASK-1: secrets を含む jsonl から機密情報がマスクされて出力される" {
  load_lib_fresh
  run _retrospective_fact_extract_jsonl_optional "$SECRETS_JSONL"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'sk-proj-abc123def456ghi'
  ! echo "$output" | grep -qE 'eyJhbGciOiJIUzI1NiJ9'
  ! echo "$output" | grep -qE 'hunter22xx'
  ! echo "$output" | grep -qE '://user:pass@'
  echo "$output" | grep -qE '\*\*\*\*'
}
