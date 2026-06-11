#!/usr/bin/env bash
#
# test-state-scripts.sh - state-read.sh / state-write.sh / state-validate.sh の動作テスト
#
# 外部テストフレームワークに依存しない自己完結型ハーネス（jq のみ前提）。
# 正常系・異常系・終了コード（0/1/2）・atomic 性を検証する。
#
# Usage: test-state-scripts.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SCRIPT_DIR SCRIPTS_DIR
readonly READ="$SCRIPTS_DIR/state-read.sh"
readonly WRITE="$SCRIPTS_DIR/state-write.sh"
readonly VALIDATE="$SCRIPTS_DIR/state-validate.sh"

if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not found (前提不備)" >&2
    exit 2
fi

BASH_BIN="$(command -v bash)"
readonly BASH_BIN

PASS=0
FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# 有効な state.json を生成する
make_valid_state() {
    local path="$1"
    cat > "$path" <<'JSON'
{
  "schema_version": "3.0",
  "current_cycle": "v3.0.0",
  "define_completed": false,
  "release": {
    "pr_number": null,
    "ready": false,
    "merge_approved": false
  },
  "updated_at": "2026-06-04T00:00:00Z"
}
JSON
}

# assert_rc <期待rc> <説明> -- <コマンド...>
assert_rc() {
    local expected="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    "$@" >/dev/null 2>&1
    local rc=$?
    if [[ "$rc" == "$expected" ]]; then
        PASS=$((PASS + 1))
        echo "  ok   : $desc (rc=$rc)"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL : $desc (expected rc=$expected, got rc=$rc)"
    fi
}

# assert_out <期待文字列> <説明> -- <コマンド...>
assert_out() {
    local expected="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    local out
    out="$("$@" 2>/dev/null)"
    if [[ "$out" == "$expected" ]]; then
        PASS=$((PASS + 1))
        echo "  ok   : $desc (out=$out)"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL : $desc (expected out='$expected', got out='$out')"
    fi
}

echo "== 静的検査（bash -n / shellcheck） =="
for s in "$VALIDATE" "$READ" "$WRITE"; do
    assert_rc 0 "bash -n: $(basename "$s")" -- bash -n "$s"
done
if command -v shellcheck >/dev/null 2>&1; then
    assert_rc 0 "shellcheck: 3 スクリプト（重大警告なし）" -- shellcheck "$VALIDATE" "$READ" "$WRITE"
else
    echo "  skip : shellcheck 未導入のため静的検査をスキップ"
fi

echo "== state-validate.sh =="
v="$TMPDIR_TEST/valid.json"; make_valid_state "$v"
assert_rc 0 "valid state は有効" -- "$VALIDATE" "$v"

# 必須フィールド欠落
for f in schema_version current_cycle define_completed release updated_at; do
    bad="$TMPDIR_TEST/miss_$f.json"; make_valid_state "$bad"
    jq "del(.$f)" "$v" > "$bad"
    assert_rc 1 "必須欠落: $f は無効" -- "$VALIDATE" "$bad"
done

# release サブフィールド欠落
for sf in pr_number ready merge_approved; do
    bad="$TMPDIR_TEST/miss_rel_$sf.json"
    jq "del(.release.$sf)" "$v" > "$bad"
    assert_rc 1 "release サブフィールド欠落: $sf は無効" -- "$VALIDATE" "$bad"
done

# 型不正
jq '.define_completed = "no"' "$v" > "$TMPDIR_TEST/type1.json"
assert_rc 1 "型不正: define_completed が string は無効" -- "$VALIDATE" "$TMPDIR_TEST/type1.json"
jq '.release.pr_number = 1.5' "$v" > "$TMPDIR_TEST/type2.json"
assert_rc 1 "型不正: pr_number=1.5（非整数）は無効" -- "$VALIDATE" "$TMPDIR_TEST/type2.json"
jq '.release.pr_number = "5"' "$v" > "$TMPDIR_TEST/type3.json"
assert_rc 1 "型不正: pr_number が string は無効" -- "$VALIDATE" "$TMPDIR_TEST/type3.json"
jq '.schema_version = 3' "$v" > "$TMPDIR_TEST/type_sv.json"
assert_rc 1 "型不正: schema_version 非 string は無効" -- "$VALIDATE" "$TMPDIR_TEST/type_sv.json"
jq '.current_cycle = 1' "$v" > "$TMPDIR_TEST/type_cc.json"
assert_rc 1 "型不正: current_cycle 非 string は無効" -- "$VALIDATE" "$TMPDIR_TEST/type_cc.json"
jq '.release = "x"' "$v" > "$TMPDIR_TEST/type_rel.json"
assert_rc 1 "型不正: release 非 object は無効" -- "$VALIDATE" "$TMPDIR_TEST/type_rel.json"
jq '.updated_at = 123' "$v" > "$TMPDIR_TEST/type_ua.json"
assert_rc 1 "型不正: updated_at 非 string は無効" -- "$VALIDATE" "$TMPDIR_TEST/type_ua.json"
jq '.release.ready = "yes"' "$v" > "$TMPDIR_TEST/type_rr.json"
assert_rc 1 "型不正: release.ready 非 boolean は無効" -- "$VALIDATE" "$TMPDIR_TEST/type_rr.json"
jq '.release.merge_approved = 1' "$v" > "$TMPDIR_TEST/type_rm.json"
assert_rc 1 "型不正: release.merge_approved 非 boolean は無効" -- "$VALIDATE" "$TMPDIR_TEST/type_rm.json"

# pr_number 整数/null は有効
jq '.release.pr_number = 0' "$v" > "$TMPDIR_TEST/ok_zero.json"
assert_rc 0 "pr_number=0（境界）は有効" -- "$VALIDATE" "$TMPDIR_TEST/ok_zero.json"
jq '.release.pr_number = 123' "$v" > "$TMPDIR_TEST/ok_int.json"
assert_rc 0 "pr_number=123 は有効" -- "$VALIDATE" "$TMPDIR_TEST/ok_int.json"

# ISO 8601
jq '.updated_at = "2026-99-99T99:99:99+99:99"' "$v" > "$TMPDIR_TEST/iso_bad.json"
assert_rc 1 "ISO8601 不正（範囲外）は無効" -- "$VALIDATE" "$TMPDIR_TEST/iso_bad.json"
jq '.updated_at = "2026-06-04"' "$v" > "$TMPDIR_TEST/iso_bad2.json"
assert_rc 1 "ISO8601 不正（日付のみ）は無効" -- "$VALIDATE" "$TMPDIR_TEST/iso_bad2.json"
jq '.updated_at = "2026-06-04T12:30:45+09:00"' "$v" > "$TMPDIR_TEST/iso_off.json"
assert_rc 0 "ISO8601（オフセット形式）は有効" -- "$VALIDATE" "$TMPDIR_TEST/iso_off.json"

# JSON 不正 / ファイル不存在 / 読み取り不可
printf '%s' '{broken' > "$TMPDIR_TEST/broken.json"
assert_rc 1 "壊れた JSON は無効（exit 1）" -- "$VALIDATE" "$TMPDIR_TEST/broken.json"
assert_rc 1 "ファイル不存在は exit 1" -- "$VALIDATE" "$TMPDIR_TEST/nope.json"
noread="$TMPDIR_TEST/noread.json"; make_valid_state "$noread"; chmod 000 "$noread"
assert_rc 2 "読み取り不可は exit 2（システムエラー）" -- "$VALIDATE" "$noread"
chmod 644 "$noread"
# jq 不在（PATH を空にして command -v jq を失敗させる）→ exit 2
assert_rc 2 "validate: jq 不在は exit 2" -- env PATH="" "$BASH_BIN" "$VALIDATE" "$v"

echo "== state-read.sh =="
r="$TMPDIR_TEST/read.json"; make_valid_state "$r"
assert_out "3.0" "schema_version を読める" -- "$READ" schema_version "$r"
assert_out "v3.0.0" "current_cycle を読める" -- "$READ" current_cycle "$r"
assert_out "false" "define_completed を読める" -- "$READ" define_completed "$r"
assert_out "null" "release.pr_number（明示 null）を読める" -- "$READ" release.pr_number "$r"
assert_out "false" "release.ready を読める" -- "$READ" release.ready "$r"
assert_out "false" "release.merge_approved を読める" -- "$READ" release.merge_approved "$r"
assert_out "2026-06-04T00:00:00Z" "updated_at を読める" -- "$READ" updated_at "$r"
assert_rc 0 "明示 null は exit 0" -- "$READ" release.pr_number "$r"
assert_rc 1 "未知フィールドは exit 1" -- "$READ" foo.bar "$r"
assert_rc 1 "引数なしは exit 1" -- "$READ"
# キー欠落（不完全 state）
echo '{"schema_version":"3.0"}' > "$TMPDIR_TEST/partial.json"
assert_rc 1 "キー欠落は exit 1（明示 null と区別）" -- "$READ" release.pr_number "$TMPDIR_TEST/partial.json"
assert_rc 1 "read: ファイル不存在は exit 1" -- "$READ" schema_version "$TMPDIR_TEST/nope.json"
noread2="$TMPDIR_TEST/noread2.json"; make_valid_state "$noread2"; chmod 000 "$noread2"
assert_rc 2 "read: 読み取り不可は exit 2" -- "$READ" schema_version "$noread2"
chmod 644 "$noread2"
assert_rc 2 "read: jq 不在は exit 2" -- env PATH="" "$BASH_BIN" "$READ" schema_version "$r"

echo "== state-write.sh =="
w="$TMPDIR_TEST/write.json"; make_valid_state "$w"
assert_rc 0 "define_completed=true 書き込み成功" -- env AIDLC_STATE_NOW="2026-06-11T00:00:00Z" "$WRITE" define_completed true "$w"
assert_out "true" "書き込み後 define_completed=true" -- "$READ" define_completed "$w"
assert_out "2026-06-11T00:00:00Z" "updated_at が自動更新される" -- "$READ" updated_at "$w"
assert_rc 0 "release.pr_number=42 書き込み成功" -- env AIDLC_STATE_NOW="2026-06-11T00:00:01Z" "$WRITE" release.pr_number 42 "$w"
assert_out "42" "書き込み後 pr_number=42" -- "$READ" release.pr_number "$w"
assert_rc 0 "release.pr_number=null 書き込み成功" -- env AIDLC_STATE_NOW="2026-06-11T00:00:02Z" "$WRITE" release.pr_number null "$w"
assert_out "null" "書き込み後 pr_number=null" -- "$READ" release.pr_number "$w"
assert_rc 0 "release.ready=true 書き込み成功" -- env AIDLC_STATE_NOW="2026-06-11T00:00:03Z" "$WRITE" release.ready true "$w"

# 異常系
assert_rc 1 "許可外フィールド schema_version は exit 1" -- "$WRITE" schema_version 4.0 "$w"
assert_rc 1 "許可外フィールド updated_at は exit 1（自動更新のみ）" -- "$WRITE" updated_at "2026-01-01T00:00:00Z" "$w"
assert_rc 1 "未知フィールドは exit 1" -- "$WRITE" foo bar "$w"
assert_rc 1 "bool に不正値は exit 1" -- "$WRITE" define_completed yes "$w"
assert_rc 1 "pr_number に非整数は exit 1" -- "$WRITE" release.pr_number abc "$w"
assert_rc 1 "pr_number に先頭ゼロ 001 は exit 1" -- "$WRITE" release.pr_number 001 "$w"
assert_rc 1 "pr_number に先頭ゼロ -01 は exit 1" -- "$WRITE" release.pr_number -01 "$w"
assert_rc 1 "引数不足は exit 1" -- "$WRITE" define_completed
assert_rc 1 "write: ファイル不存在は exit 1（更新専用）" -- "$WRITE" define_completed true "$TMPDIR_TEST/nope.json"
noread3="$TMPDIR_TEST/noread3.json"; make_valid_state "$noread3"; chmod 000 "$noread3"
assert_rc 2 "write: 読み取り不可は exit 2" -- "$WRITE" define_completed true "$noread3"
chmod 644 "$noread3"
# 依存スクリプト state-validate.sh の不備（実行不可 / 不在）→ exit 2
depdir="$TMPDIR_TEST/dep"; mkdir -p "$depdir"
cp "$READ" "$WRITE" "$VALIDATE" "$depdir/"
chmod +x "$depdir"/state-read.sh "$depdir"/state-write.sh "$depdir"/state-validate.sh
make_valid_state "$depdir/s.json"
chmod 000 "$depdir/state-validate.sh"
assert_rc 2 "write: 依存 state-validate.sh が実行不可は exit 2" -- "$depdir/state-write.sh" define_completed true "$depdir/s.json"
rm -f "$depdir/state-validate.sh"
assert_rc 2 "write: 依存 state-validate.sh が不在は exit 2" -- "$depdir/state-write.sh" define_completed true "$depdir/s.json"

# atomic 性: 元が invalid な state への書き込みは検証失敗で exit 1、元ファイルを保持
inv="$TMPDIR_TEST/invalid.json"
echo '{"schema_version":"3.0","current_cycle":"v3.0.0","define_completed":false,"release":{"pr_number":null,"ready":false}}' > "$inv"
before="$(cat "$inv")"
assert_rc 1 "invalid state への書き込みは検証失敗で exit 1" -- "$WRITE" define_completed true "$inv"
after="$(cat "$inv")"
if [[ "$before" == "$after" ]]; then
    PASS=$((PASS + 1)); echo "  ok   : 検証失敗時に元ファイルが保持される（atomic）"
else
    FAIL=$((FAIL + 1)); echo "  FAIL : 検証失敗時に元ファイルが変更された"
fi
# 一時ファイルが残らないこと
leftover="$(find "$TMPDIR_TEST" -name '.state.json.*' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$leftover" == "0" ]]; then
    PASS=$((PASS + 1)); echo "  ok   : 失敗時に temp file が残らない"
else
    FAIL=$((FAIL + 1)); echo "  FAIL : temp file が残存（$leftover 個）"
fi

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
