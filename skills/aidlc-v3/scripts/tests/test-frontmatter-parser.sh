#!/usr/bin/env bash
#
# test-frontmatter-parser.sh - 共有 frontmatter parser（lib/frontmatter.sh）の conformance suite（T2'）
#
# 共有 parser へ集約後の 3 consumer（work-item-validate.sh / work-item-next.sh /
# work-item-status.sh）が、同一 fixture に対して consumer 別の期待 RC マトリクスを満たすことを
# 固定する。集約リファクタが既存の受理/拒否境界を壊していないことを実行可能契約として保証する
# （Unit 001 / #733 T2'）。外部テストフレームワーク非依存・mktemp 隔離サンドボックス。
#
# マトリクスの意味（consumer 境界 / logical_design.md §conformance）:
#   - validate     : data-model §4 の厳格 schema 検証（構造/enum/必須キー/id整合/依存実在）
#   - next         : 依存解決 + resume 選定（id はファイル名由来 / enum 非検証）
#   - status_read  : status 行一意性 + status enum（status 専用）
#   - status_write : 上記 + 期待現在 status 一致時に atomic 書換
#   各 fixture の期待 RC は移行前の現行スクリプト実挙動を baseline 観測して確定した固定値であり、
#   「移行前実挙動 == 移行後実挙動」を不変条件とする。
#
# Usage: test-frontmatter-parser.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SCRIPT_DIR SCRIPTS_DIR
readonly LIB="$SCRIPTS_DIR/lib/frontmatter.sh"
readonly VALIDATE="$SCRIPTS_DIR/work-item-validate.sh"
readonly NEXT="$SCRIPTS_DIR/work-item-next.sh"
readonly STATUS="$SCRIPTS_DIR/work-item-status.sh"

PASS=0
FAIL=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

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

# 有効な本文（必須 6 セクション）。validate の本文セクション検証を満たす。
valid_body() {
    cat <<'EOF'

# Work Item

## Goal
g
## Scope
s
## Acceptance Criteria
a
## Traceability
t
## Size / Risk
sr
## Dependencies
d
EOF
}

# fresh_dir : 新しい空の work-items dir を作って echo
_dir_seq=0
fresh_dir() {
    _dir_seq=$((_dir_seq + 1))
    local d="$TMPROOT/case_$_dir_seq/work-items"
    mkdir -p "$d"
    echo "$d"
}

# matrix_case <label> <dir> <file> <write_expected_current> <write_next> <v_rc> <n_rc> <sr_rc> <sw_rc>
#   1 fixture に対し validate / next / status_read / status_write の 4 RC を検証する。
#   status_write はファイルを改変するため最後に実行し、改変前のコピーから復元する。
matrix_case() {
    local label="$1" dir="$2" file="$3" wcur="$4" wnext="$5"
    local v="$6" n="$7" sr="$8" sw="$9"
    echo "-- $label"
    assert_rc "$v"  "$label / validate"      -- bash "$VALIDATE" "$dir"
    assert_rc "$n"  "$label / next"          -- bash "$NEXT" "$dir"
    assert_rc "$sr" "$label / status_read"   -- bash "$STATUS" --read "$dir/$file"
    cp "$dir/$file" "$dir/../.bak_$file"
    assert_rc "$sw" "$label / status_write"  -- bash "$STATUS" "$dir/$file" "$wcur" "$wnext"
    cp "$dir/../.bak_$file" "$dir/$file"
}

echo "== 静的検査 =="
assert_rc 0 "bash -n: lib/frontmatter.sh" -- bash -n "$LIB"
assert_rc 0 "bash -n: test-frontmatter-parser.sh" -- bash -n "$SCRIPT_DIR/test-frontmatter-parser.sh"
if command -v shellcheck >/dev/null 2>&1; then
    assert_rc 0 "shellcheck: lib/frontmatter.sh" -- shellcheck "$LIB"
    assert_rc 0 "shellcheck: test-frontmatter-parser.sh" -- shellcheck "$SCRIPT_DIR/test-frontmatter-parser.sh"
else
    echo "  skip : shellcheck 未導入"
fi

echo ""
echo "== 互換保存セット: 受理ケース =="

# #1 受理: unquoted id / 全 enum 正 / 空 dependencies
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#1 valid unquoted id / empty deps" "$d" "001-a.md" pending in_progress 0 0 0 0

# #2 受理: quoted id "001" / 複数要素 dependencies（依存先 done を同梱して実在検証を満たす）
d="$(fresh_dir)"
{ printf -- '---\nid: "001"\nstatus: pending\nsize: normal\nrisk: low\nassigned: null\ndependencies: [002, 003]\n---'; valid_body; } > "$d/001-a.md"
{ printf -- '---\nid: 002\nstatus: done\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n---'; valid_body; } > "$d/002-b.md"
{ printf -- '---\nid: 003\nstatus: done\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n---'; valid_body; } > "$d/003-c.md"
# validate=0（全 valid）/ next=0（001 pending + 依存 done で選定）/ status_read,write は 001 を対象
matrix_case "#2 valid quoted id / multi deps" "$d" "001-a.md" pending in_progress 0 0 0 0

# #R3 受理（回帰固定 / codex premerge R3）: 本文中に水平線 --- を含んでも後続必須セクションを欠落判定しない
d="$(fresh_dir)"
{
  printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n---\n'
  printf -- '# Work Item\n\n## Goal\ng\n\n---\n\n## Scope\ns\n## Acceptance Criteria\na\n## Traceability\nt\n## Size / Risk\nsr\n## Dependencies\nd\n'
} > "$d/001-a.md"
matrix_case "#R3 body horizontal-rule --- not truncating sections" "$d" "001-a.md" pending in_progress 0 0 0 0

# 受理: assigned が quoted string / bare token（raw 抽出で quoted と bare を区別 / fm_scalar_raw）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: "alice"\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
assert_rc 0 "assigned quoted string は valid" -- bash "$VALIDATE" "$d"
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: bob\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
assert_rc 0 "assigned bare token は valid" -- bash "$VALIDATE" "$d"

echo ""
echo "== 互換保存セット: 拒否ケース（consumer 別 RC マトリクス）=="

# #3 拒否（全 consumer）: 閉じ --- 不在（frontmatter ブロック未終端 / #733 R7）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n'; valid_body; } > "$d/001-a.md"
matrix_case "#3 missing closing --- (#733/R7)" "$d" "001-a.md" pending in_progress 1 1 1 1

# #4 status 不正 enum: validate/status は拒否、next は候補外（exit 0 / next:none）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: bogus\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#4 bad status enum" "$d" "001-a.md" pending in_progress 1 0 1 1

# #5 size 不正 enum: validate のみ拒否（next は size 非検証で素通り / status は size 非読取）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: huge\nrisk: low\nassigned: null\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#5 bad size enum (validate-only reject)" "$d" "001-a.md" pending in_progress 1 0 0 0

# #6 risk 不正 enum: validate のみ拒否（next/status は risk 非読取）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: extreme\nassigned: null\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#6 bad risk enum (validate-only reject)" "$d" "001-a.md" pending in_progress 1 0 0 0

# #7 id 片側引用符: validate のみ拒否（next は id をファイル名由来で解決 / status は id 非読取）
d="$(fresh_dir)"
{ printf -- '---\nid: "001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#7 single-side-quoted id (validate-only reject)" "$d" "001-a.md" pending in_progress 1 0 0 0

# #8 dependencies malformed（ハイフン結合 [001-002]）: validate/next 拒否（status は deps 非読取 / #733 R4/R5）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: [001-002]\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#8 deps hyphen-join (#733/R4R5)" "$d" "001-a.md" pending in_progress 1 1 0 0

# #9 dependencies 行不在: validate（必須キー欠落）/ next（fail-closed）拒否 / status は deps 非読取
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#9 missing dependencies line" "$d" "001-a.md" pending in_progress 1 1 0 0

# #10 status 行 2 個（重複キー）: validate（重複キー）/ status（曖昧）拒否 / next は先頭一致で素通り
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nstatus: done\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#10 duplicate status line" "$d" "001-a.md" pending in_progress 1 0 1 1

# #11 dependencies malformed（空白区切り [001 002]）: validate/next 拒否 / status は deps 非読取
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: [001 002]\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#11 deps space-separated" "$d" "001-a.md" pending in_progress 1 1 0 0

# 追加拒否: assigned が配列/マップ（string|null 違反 / validate のみ拒否）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: [a]\ndependencies: []\n---'; valid_body; } > "$d/001-a.md"
assert_rc 1 "assigned array は validate 拒否" -- bash "$VALIDATE" "$d"

echo ""
echo "== #733 意図的拒否強化セット（既知 malformed / partial-parse クラスの回帰固定）=="
# Intent 成功基準（intent.md）: #733 で検出された既知 malformed / partial-parse クラスは
# 拒否 fixture として固定する。これらは alpha.3 premerge（R3-R7）で既に拒否化済みであり、
# 本セクションはその拒否境界を回帰固定する（追加の取りこぼしは観測されず before=after=拒否）。
# 対象 shared API を呼ぶ consumer のみ拒否し、読まない consumer は責務どおり拒否しない。

# #733-a: 閉じ --- 不在（partial-parse でファイル末尾まで frontmatter 誤認）→ fm_extract_block fail-closed
#         対象 API: fm_extract_block / 全 consumer 拒否（1/1/1/1）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: []\n# no closing fence\n'; valid_body; } > "$d/001-a.md"
matrix_case "#733-a missing-closing (API: fm_extract_block)" "$d" "001-a.md" pending in_progress 1 1 1 1

# #733-b: dependencies 配列の片側引用符 ["001]（partial-parse で要素を誤認）→ fm_deps fail-closed
#         対象 API: fm_deps / validate・next 拒否、status は deps 非読取で拒否しない（1/1/0/0）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: ["001]\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#733-b deps single-quote element (API: fm_deps)" "$d" "001-a.md" pending in_progress 1 1 0 0

# #733-c: 非配列 dependencies（dependencies: 999）→ fm_deps fail-closed（array 形式必須）
#         対象 API: fm_deps / validate・next 拒否、status は deps 非読取で拒否しない（1/1/0/0）
d="$(fresh_dir)"
{ printf -- '---\nid: 001\nstatus: pending\nsize: tiny\nrisk: low\nassigned: null\ndependencies: 999\n---'; valid_body; } > "$d/001-a.md"
matrix_case "#733-c non-array dependencies (API: fm_deps)" "$d" "001-a.md" pending in_progress 1 1 0 0

echo ""
echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
