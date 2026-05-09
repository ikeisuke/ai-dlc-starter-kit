#!/usr/bin/env bats
# Unit 002: migrate-backlog.sh の generate_slug が UTF-8 多バイト境界を分断せず
# 正確に 50 文字（コードポイント）で切り詰めることを検証する。
#
# 9 ケース構成（計画 7 ケース + 境界補強 (h)(i)）:
#   (a) 日本語切り詰め発火（フィルタ通過後 51 文字以上）
#   (b) LC_ALL=C 環境
#   (c) ASCII 純 51 文字
#   (d) ASCII 50 文字ちょうど不変
#   (e) ASCII 49 文字不変
#   (f) 空文字
#   (g) 記号のみ入力（除去後空 slug）
#   (h) 日本語 50 文字ちょうど不変（境界補強）
#   (i) 日本語 49 文字不変（境界補強）

# main ガード化済みのため source は副作用なし
SCRIPT_PATH="${BATS_TEST_DIRNAME}/../../skills/aidlc-setup/scripts/migrate-backlog.sh"

setup() {
    # shellcheck disable=SC1090
    source "${SCRIPT_PATH}"
}

# 入力定義
JP_INPUT_51=$(printf 'あ%.0s' {1..51})
JP_INPUT_50=$(printf 'い%.0s' {1..50})
JP_INPUT_49=$(printf 'う%.0s' {1..49})
ASCII_INPUT_51=$(printf 'a%.0s' {1..51})
ASCII_INPUT_50=$(printf 'b%.0s' {1..50})
ASCII_INPUT_49=$(printf 'c%.0s' {1..49})

# UTF-8 文字数（コードポイント）を計測するヘルパー
codepoint_length() {
    printf '%s' "$1" | perl -CSD -Mutf8 -ne 'chomp; print length($_)'
}

# 不正 UTF-8 シーケンスがないか検証
assert_valid_utf8() {
    printf '%s' "$1" | iconv -f UTF-8 -t UTF-8 >/dev/null
}

@test "(a) 日本語切り詰め発火: フィルタ通過後 51 文字超を 50 文字に切り詰める" {
    result="$(generate_slug "${JP_INPUT_51}")"
    actual_len="$(codepoint_length "$result")"
    [ "$actual_len" -eq 50 ]
    assert_valid_utf8 "$result"
}

@test "(b) LC_ALL=C 環境でも (a) と同一の文字数を返す（呼び出し側ロケール非依存）" {
    result="$(LC_ALL=C generate_slug "${JP_INPUT_51}")"
    actual_len="$(codepoint_length "$result")"
    [ "$actual_len" -eq 50 ]
    assert_valid_utf8 "$result"
}

@test "(c) ASCII 純 51 文字: 先頭 50 文字に切り詰め" {
    result="$(generate_slug "${ASCII_INPUT_51}")"
    [ "${#result}" -eq 50 ]
    [ "$result" = "$(printf 'a%.0s' {1..50})" ]
}

@test "(d) ASCII 50 文字ちょうど: 不変" {
    result="$(generate_slug "${ASCII_INPUT_50}")"
    [ "${#result}" -eq 50 ]
    [ "$result" = "${ASCII_INPUT_50}" ]
}

@test "(e) ASCII 49 文字: 不変（切り詰め非発火）" {
    result="$(generate_slug "${ASCII_INPUT_49}")"
    [ "${#result}" -eq 49 ]
    [ "$result" = "${ASCII_INPUT_49}" ]
}

@test "(f) 空文字: 空文字列を返す" {
    result="$(generate_slug "")"
    [ -z "$result" ]
}

@test "(g) 記号のみ入力: 既存パイプで全削除され空文字列を返す" {
    result="$(generate_slug "!!!@#\$%")"
    [ -z "$result" ]
}

@test "(h) 日本語 50 文字ちょうど: 不変（境界確認）" {
    result="$(generate_slug "${JP_INPUT_50}")"
    actual_len="$(codepoint_length "$result")"
    [ "$actual_len" -eq 50 ]
    assert_valid_utf8 "$result"
}

@test "(i) 日本語 49 文字: 不変（境界確認）" {
    result="$(generate_slug "${JP_INPUT_49}")"
    actual_len="$(codepoint_length "$result")"
    [ "$actual_len" -eq 49 ]
    assert_valid_utf8 "$result"
}
