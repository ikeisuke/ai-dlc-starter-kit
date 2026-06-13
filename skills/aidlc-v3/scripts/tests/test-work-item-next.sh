#!/usr/bin/env bash
#
# test-work-item-next.sh - work-item-next.sh の選定規則 + 境界 (a)-(e) の自己完結テスト
#
# 外部テストフレームワークに依存しない。v2 の .aidlc/ を一切触らず、隔離サンドボックス
# （mktemp -d）内に work item fixture を構築して依存解決の選定結果を検証する。
#
# 検証対象:
#   - 終了コード規約 0/1/2（引数なし / dir 不在 / 0 件 / 正常）
#   - 候補 status 規約（新規候補は pending のみ / done・withdrawn・blocked は候補外）
#   - 境界 (a) pending + 依存 done で選定 / (b) 未完了依存は除外 / (c) withdrawn 依存は候補外 /
#     (d) 不在 dependency は WARN + 候補外 / (e) 複数候補は id 昇順先頭
#   - resume 優先（D2）: in_progress があれば最小 id を返す / 複数 in_progress は WARN
#   - 出力フォーマット next:<id>:<size>:<path>（path = <dir>/<filename>）/ 候補なし next:none
#
# Usage: test-work-item-next.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SCRIPT_DIR SCRIPTS_DIR
readonly NEXT="$SCRIPTS_DIR/work-item-next.sh"

PASS=0
FAIL=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# assert_out <期待文字列> <説明> -- <コマンド...> : stdout 完全一致
assert_out() {
    local expected="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    local out
    out="$("$@" 2>/dev/null)"
    if [[ "$out" == "$expected" ]]; then
        PASS=$((PASS + 1)); echo "  ok   : $desc"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc (expected '$expected', got '$out')"
    fi
}

# assert_rc <期待rc> <説明> -- <コマンド...>
assert_rc() {
    local expected="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    "$@" >/dev/null 2>&1
    local rc=$?
    if [[ "$rc" == "$expected" ]]; then
        PASS=$((PASS + 1)); echo "  ok   : $desc (rc=$rc)"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc (expected rc=$expected, got rc=$rc)"
    fi
}

# assert_stderr_has <期待部分文字列> <説明> -- <コマンド...> : stderr に部分一致
assert_stderr_has() {
    local needle="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    local errout
    errout="$("$@" 2>&1 >/dev/null)"
    if [[ "$errout" == *"$needle"* ]]; then
        PASS=$((PASS + 1)); echo "  ok   : $desc"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc (stderr lacked '$needle': '$errout')"
    fi
}

# put_wi <dir> <id> <slug> <status> <size> <deps> : work item fixture を置く
put_wi() {
    local dir="$1" id="$2" slug="$3" status="$4" size="$5" deps="$6"
    mkdir -p "$dir"
    cat > "$dir/${id}-${slug}.md" <<EOF
---
id: "$id"
status: $status
size: $size
risk: low
assigned: null
dependencies: [$deps]
---

# Work Item $id $slug
EOF
}

# 新しい空の work-items dir を作る
new_dir() {
    local d="$TMPROOT/$1/work-items"
    mkdir -p "$d"
    echo "$d"
}

echo "== 静的検査 =="
assert_rc 0 "bash -n: work-item-next.sh" -- bash -n "$NEXT"
if command -v shellcheck >/dev/null 2>&1; then
    assert_rc 0 "shellcheck: work-item-next.sh" -- shellcheck "$NEXT"
else
    echo "  skip : shellcheck 未導入"
fi

echo "== 終了コード規約 =="
assert_rc 1 "引数なしは exit 1" -- "$NEXT"
assert_rc 1 "ディレクトリ不在は exit 1" -- "$NEXT" "$TMPROOT/nodir"
empty="$(new_dir empty)"
assert_rc 1 "work item 0 件は exit 1" -- "$NEXT" "$empty"

echo "== 終了コード規約: exit 2（システムエラー）=="
# 読み取り不可ディレクトリ（root 実行時は -r が真になり得るため通常ユーザー前提）
urd="$(new_dir unreadable_dir)"
put_wi "$urd" 001 a pending tiny ""
chmod 000 "$urd"
assert_rc 2 "読み取り不可ディレクトリは exit 2" -- "$NEXT" "$urd"
chmod 755 "$urd"
# 読み取り不可 work item ファイル
urf="$(new_dir unreadable_file)"
put_wi "$urf" 001 a pending tiny ""
chmod 000 "$urf/001-a.md"
assert_rc 2 "読み取り不可 work item は exit 2" -- "$NEXT" "$urf"
chmod 644 "$urf/001-a.md"

echo "== 境界 (a): pending + 依存 done で選定 =="
da="$(new_dir bound_a)"
put_wi "$da" 001 first "done" tiny ""
put_wi "$da" 002 second pending tiny '"001"'
assert_out "next:002:tiny:$da/002-second.md" "依存 done の pending を選定" -- "$NEXT" "$da"

echo "== 境界 (b): 未完了依存（pending）は除外 =="
db="$(new_dir bound_b)"
put_wi "$db" 001 first pending tiny ""
put_wi "$db" 002 second pending tiny '"001"'
# 001 は依存なし pending で選定される（002 は 001 が未 done のため除外）。id 昇順で 001。
assert_out "next:001:tiny:$db/001-first.md" "依存 pending の item は除外され依存なし item が選定" -- "$NEXT" "$db"

echo "== 境界 (b'): 全 pending が未完了依存を持つと候補なし =="
db2="$(new_dir bound_b2)"
put_wi "$db2" 001 first in_progress tiny ""
put_wi "$db2" 002 second pending tiny '"001"'
# 001 は in_progress（resume 優先で返る）。pending 002 は依存未 done。
assert_out "next:001:tiny:$db2/001-first.md" "in_progress 依存の pending は除外（resume が優先）" -- "$NEXT" "$db2"

echo "== 境界 (b''): blocked 依存を持つ pending は候補外（非充足）=="
dblk="$(new_dir blocked_dep)"
put_wi "$dblk" 001 first blocked tiny ""
put_wi "$dblk" 002 second pending tiny '"001"'
# 001 は blocked（新規候補外）。002 は依存 001 が非 done のため候補外 → next:none。
assert_out "next:none" "blocked 依存を持つ pending は候補外で next:none" -- "$NEXT" "$dblk"

echo "== 境界 (c): withdrawn 依存は候補外（自動充足しない）=="
dc="$(new_dir bound_c)"
put_wi "$dc" 001 first withdrawn tiny ""
put_wi "$dc" 002 second pending tiny '"001"'
assert_out "next:none" "withdrawn 依存を持つ pending は候補外で next:none" -- "$NEXT" "$dc"

echo "== 境界 (d): 不在 dependency は WARN + 候補外 =="
dd="$(new_dir bound_d)"
put_wi "$dd" 002 second pending tiny '"999"'
assert_out "next:none" "不在依存を持つ pending は候補外" -- "$NEXT" "$dd"
assert_stderr_has "dependency '999' not found" "不在依存で WARN を出す" -- "$NEXT" "$dd"

echo "== 境界 (e): 複数候補は id 昇順先頭 =="
de="$(new_dir bound_e)"
put_wi "$de" 001 alpha "done" tiny ""
put_wi "$de" 003 gamma pending normal '"001"'
put_wi "$de" 002 beta pending tiny '"001"'
assert_out "next:002:tiny:$de/002-beta.md" "複数候補は id 昇順で 002 を先頭選定" -- "$NEXT" "$de"

echo "== 非ゼロ埋め id は数値昇順（2 < 10 / glob 辞書順非依存）=="
dnum="$(new_dir num_order)"
put_wi "$dnum" 2 beta pending tiny ""
put_wi "$dnum" 10 jay pending normal ""
# glob 辞書順では 10-jay.md が先だが、数値昇順で id=2 を選定すべき。
assert_out "next:2:tiny:$dnum/2-beta.md" "複数 pending は数値昇順で id=2 を選定" -- "$NEXT" "$dnum"
dnumi="$(new_dir num_order_ip)"
put_wi "$dnumi" 2 beta in_progress tiny ""
put_wi "$dnumi" 10 jay in_progress normal ""
assert_out "next:2:tiny:$dnumi/2-beta.md" "複数 in_progress も数値昇順で id=2 を選定" -- "$NEXT" "$dnumi"

echo "== 候補なし（全 done / withdrawn）は next:none + exit 0 =="
dn="$(new_dir none_all)"
put_wi "$dn" 001 a "done" tiny ""
put_wi "$dn" 002 b withdrawn tiny ""
assert_out "next:none" "全 done/withdrawn は next:none" -- "$NEXT" "$dn"
assert_rc 0 "候補なしは exit 0" -- "$NEXT" "$dn"

echo "== 候補 status 規約: blocked は新規候補外 =="
dbl="$(new_dir blocked_excl)"
put_wi "$dbl" 001 a blocked tiny ""
assert_out "next:none" "blocked のみは新規候補外で next:none" -- "$NEXT" "$dbl"

echo "== resume 優先（D2）=="
dr="$(new_dir resume1)"
put_wi "$dr" 001 a "done" tiny ""
put_wi "$dr" 002 b in_progress normal '"001"'
put_wi "$dr" 003 c pending tiny '"001"'
# 003 は依存 done で候補だが、in_progress 002 が resume 優先される。
assert_out "next:002:normal:$dr/002-b.md" "in_progress があれば pending より優先（resume）" -- "$NEXT" "$dr"

echo "== resume 優先: 複数 in_progress は WARN + 最小 id =="
dr2="$(new_dir resume2)"
put_wi "$dr2" 002 b in_progress tiny ""
put_wi "$dr2" 003 c in_progress normal ""
assert_out "next:002:tiny:$dr2/002-b.md" "複数 in_progress は最小 id を返す" -- "$NEXT" "$dr2"
assert_stderr_has "multiple in_progress" "複数 in_progress で WARN" -- "$NEXT" "$dr2"

echo "== size 同梱出力（Unit 003 入力契約）=="
ds="$(new_dir size_out)"
put_wi "$ds" 001 a pending risky ""
assert_out "next:001:risky:$ds/001-a.md" "出力に size(risky) が含まれる" -- "$NEXT" "$ds"

echo "== 空 dependencies の pending は依存充足（vacuous）で選定 =="
dz="$(new_dir empty_deps)"
put_wi "$dz" 001 a pending tiny ""
assert_out "next:001:tiny:$dz/001-a.md" "空依存の pending は選定" -- "$NEXT" "$dz"

echo "== 複数依存の全 done で選定 / 一部未 done で除外 =="
dm="$(new_dir multi_dep)"
put_wi "$dm" 001 a "done" tiny ""
put_wi "$dm" 002 b "done" tiny ""
put_wi "$dm" 003 c pending tiny '"001", "002"'
assert_out "next:003:tiny:$dm/003-c.md" "複数依存が全 done で選定" -- "$NEXT" "$dm"
dm2="$(new_dir multi_dep2)"
put_wi "$dm2" 001 a "done" tiny ""
put_wi "$dm2" 002 b pending tiny ""
put_wi "$dm2" 003 c pending tiny '"001", "002"'
# 003 は 002 が未 done で除外。002 は依存なし pending で選定（id 昇順）。
assert_out "next:002:tiny:$dm2/002-b.md" "複数依存の一部未 done item は除外され依存なし item が選定" -- "$NEXT" "$dm2"

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
