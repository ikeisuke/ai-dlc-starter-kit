#!/usr/bin/env bats
# Unit 005 (#667): validate.sh の validate_unit_slug を検証する。
# パターン: ^[a-z0-9][a-z0-9-]{0,63}$

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  VALIDATE="${REPO_ROOT}/skills/aidlc/scripts/lib/validate.sh"
  WRITE_HISTORY="${REPO_ROOT}/skills/aidlc/scripts/write-history.sh"
}

source_validate() {
  # shellcheck disable=SC1090
  source "$VALIDATE"
}

@test "validate_unit_slug: 有効な kebab-case slug を許可" {
  source_validate
  for s in \
    "abc" \
    "1abc" \
    "a-b-c" \
    "fix-rules-md-md040" \
    "aidlc-retrospective-skill-extraction" \
    "z" \
    "0" \
    ; do
    run validate_unit_slug "$s"
    [ "$status" -eq 0 ] || { echo "expected accept: $s" >&2 ; return 1 ; }
  done
}

@test "validate_unit_slug: 空文字を拒否" {
  source_validate
  run validate_unit_slug ""
  [ "$status" -eq 1 ]
}

@test "validate_unit_slug: 大文字を拒否" {
  source_validate
  run validate_unit_slug "ABC"
  [ "$status" -eq 1 ]
  run validate_unit_slug "Abc"
  [ "$status" -eq 1 ]
  run validate_unit_slug "abc-DEF"
  [ "$status" -eq 1 ]
}

@test "validate_unit_slug: 先頭ハイフンを拒否" {
  source_validate
  run validate_unit_slug "-abc"
  [ "$status" -eq 1 ]
}

@test "validate_unit_slug: スラッシュ・パストラバーサルを拒否" {
  source_validate
  run validate_unit_slug "abc/def"
  [ "$status" -eq 1 ]
  run validate_unit_slug "../etc/passwd"
  [ "$status" -eq 1 ]
}

@test "validate_unit_slug: 64 文字超を拒否" {
  source_validate
  # 64 文字（最大長）→ OK
  s64="$(printf 'a%.0s' $(seq 1 64))"
  run validate_unit_slug "$s64"
  [ "$status" -eq 0 ]
  # 65 文字 → reject
  s65="$(printf 'a%.0s' $(seq 1 65))"
  run validate_unit_slug "$s65"
  [ "$status" -eq 1 ]
}

@test "validate_unit_slug: 特殊文字（空白 / 制御文字 / 記号）を拒否" {
  source_validate
  run validate_unit_slug "abc def"
  [ "$status" -eq 1 ]
  run validate_unit_slug "abc.def"
  [ "$status" -eq 1 ]
  run validate_unit_slug "abc_def"
  [ "$status" -eq 1 ]
  run validate_unit_slug 'abc;rm'
  [ "$status" -eq 1 ]
}

@test "write-history.sh: 不正な --unit-slug で exit 1 / invalid-unit-slug" {
  TMPCYCLE="$(mktemp -d /tmp/aidlc-vh-slug-XXXXXX)"
  cd "$TMPCYCLE"
  git init --quiet
  git config user.email t@example.com
  git config user.name t
  git commit --allow-empty -m "init" --quiet
  mkdir -p .aidlc/cycles/v0.0.0/history
  run "$WRITE_HISTORY" \
    --cycle v0.0.0 \
    --phase construction \
    --unit 1 \
    --unit-name X \
    --unit-slug "BAD/SLUG" \
    --step "X" \
    --content "Y"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-unit-slug"* ]]
  cd "$BATS_TMPDIR"
  rm -rf "$TMPCYCLE"
}

@test "write-history.sh: 有効な --unit-slug で書き込み成功" {
  TMPCYCLE="$(mktemp -d /tmp/aidlc-vh-slug-XXXXXX)"
  cd "$TMPCYCLE"
  git init --quiet
  git config user.email t@example.com
  git config user.name t
  git commit --allow-empty -m "init" --quiet
  mkdir -p .aidlc/cycles/v0.0.0/history
  run "$WRITE_HISTORY" \
    --cycle v0.0.0 \
    --phase construction \
    --unit 1 \
    --unit-name X \
    --unit-slug "valid-slug-name" \
    --step "X" \
    --content "Y"
  [ "$status" -eq 0 ]
  [[ "$output" == *"history:"* ]]
  [[ "$output" == *"created"* || "$output" == *"appended"* ]]
  cd "$BATS_TMPDIR"
  rm -rf "$TMPCYCLE"
}
