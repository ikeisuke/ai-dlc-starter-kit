#!/usr/bin/env bash
#
# test_write_config_alias.sh - write-config.sh レガシーエイリアス対応のユニ��トテスト
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# 共通ライブラリから関数を読み込み
source "${SCRIPT_DIR}/../lib/key-aliases.sh"

# --- テスト用ヘルパー ---
assert_eq() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $test_name"
        ((++PASS))
    else
        echo "  FAIL: $test_name"
        echo "    expected: '$expected'"
        echo "    actual:   '$actual'"
        ((++FAIL))
    fi
}

assert_exit() {
    local test_name="$1"
    local expected_code="$2"
    local actual_code="$3"
    if [[ "$expected_code" == "$actual_code" ]]; then
        echo "  PASS: $test_name (exit=$actual_code)"
        ((++PASS))
    else
        echo "  FAIL: $test_name (expected exit=$expected_code, actual=$actual_code)"
        ((++FAIL))
    fi
}

# --- ユーティリティ関数（write-config.sh から抽出） ---
escape_regex() {
    printf '%s' "$1" | sed 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/\*/\\*/g; s/\^/\\^/g; s/\$/\\$/g'
}

escape_sed_replacement() {
    printf '%s' "$1" | sed -e 's/[\/&\\]/\\&/g'
}

escape_toml_value() {
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    printf '%s' "$v"
}

key_exists_in_section() {
    local file="$1"
    local section="$2"
    local leaf="$3"

    [[ -f "$file" ]] || return 1

    local esc_section
    esc_section=$(escape_regex "$section")
    local esc_leaf
    esc_leaf=$(escape_regex "$leaf")

    local section_line
    section_line=$(grep -n "^\\[${esc_section}\\]$" "$file" 2>/dev/null | head -1 | cut -d: -f1)
    [[ -n "$section_line" ]] || return 1

    local total_lines
    total_lines=$(wc -l < "$file" | tr -d ' ')
    local next_section_line
    next_section_line=$(tail -n +"$((section_line + 1))" "$file" | grep -n "^\\[" | head -1 | cut -d: -f1)

    local end_line
    if [[ -n "$next_section_line" ]]; then
        end_line=$((section_line + next_section_line - 1))
    else
        end_line="$total_lines"
    fi

    sed -n "$((section_line + 1)),${end_line}p" "$file" | grep -q "^${esc_leaf} *= *"
}

resolve_write_target() {
    local input_key="$1"
    local file="$2"

    local canonical_key
    canonical_key=$(aidlc_normalize_key "$input_key")
    local legacy_key
    legacy_key=$(aidlc_get_legacy_key "$canonical_key")

    local canonical_section="${canonical_key%.*}"
    local canonical_leaf="${canonical_key##*.}"

    if [[ -f "$file" ]] && key_exists_in_section "$file" "$canonical_section" "$canonical_leaf"; then
        printf '%s\t%s\t%s\n' "$canonical_section" "$canonical_leaf" "update"
        return 0
    fi

    if [[ -n "$legacy_key" ]]; then
        local legacy_section="${legacy_key%.*}"
        local legacy_leaf="${legacy_key##*.}"
        if [[ -f "$file" ]] && key_exists_in_section "$file" "$legacy_section" "$legacy_leaf"; then
            printf '%s\t%s\t%s\n' "$legacy_section" "$legacy_leaf" "update_legacy"
            return 0
        fi
    fi

    printf '%s\t%s\t%s\n' "$canonical_section" "$canonical_leaf" "create"
    return 0
}

# --- テスト用一時ファイル ---
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# =============================================
echo "=== key_exists_in_section() テスト ==="
echo ""

cat > "$TMPFILE" << 'TOML'
[rules.branch]
mode = "branch"

[rules.git]
merge_method = "merge"
TOML

echo "--- セクション内のキー検出 ---"
ec=0; key_exists_in_section "$TMPFILE" "rules.branch" "mode" || ec=$?
assert_exit "rules.branch/mode が存在" "0" "$ec"

ec=0; key_exists_in_section "$TMPFILE" "rules.git" "merge_method" || ec=$?
assert_exit "rules.git/merge_method が���在" "0" "$ec"

echo ""
echo "--- セクション境界の尊重 ---"
ec=0; key_exists_in_section "$TMPFILE" "rules.git" "mode" || ec=$?
assert_exit "rules.git/mode は不在（別セクション）" "1" "$ec"

ec=0; key_exists_in_section "$TMPFILE" "rules.branch" "merge_method" || ec=$?
assert_exit "rules.branch/merge_method は不在（別セ���ション）" "1" "$ec"

echo ""
echo "--- 存在しないセクション ---"
ec=0; key_exists_in_section "$TMPFILE" "rules.nonexistent" "mode" || ec=$?
assert_exit "存在しないセクション" "1" "$ec"

echo ""
echo "--- 存在しないファイル ---"
ec=0; key_exists_in_section "/tmp/nonexistent-file-xyz.toml" "rules.git" "mode" || ec=$?
assert_exit "存在しないファイル" "1" "$ec"

# =============================================
echo ""
echo "=== resolve_write_target() テスト ==="
echo ""

cat > "$TMPFILE" << 'TOML'
[rules.branch]
mode = "branch"

[rules.git]
merge_method = "merge"
TOML

echo "--- レガシーキー入力 ---"
result=$(resolve_write_target "rules.branch.mode" "$TMPFILE")
assert_eq "レガシーキー入力 → update_legacy" "rules.branch	mode	update_legacy" "$result"

echo ""
echo "--- 正規キー入力（レガシーが既存） ---"
result=$(resolve_write_target "rules.git.branch_mode" "$TMPFILE")
assert_eq "正規キー入力、レガシー既存 → update_legacy" "rules.branch	mode	update_legacy" "$result"

echo ""
echo "--- 非エイリアスキー（既存） ---"
result=$(resolve_write_target "rules.git.merge_method" "$TMPFILE")
assert_eq "非エイリアスキー、既存 → update" "rules.git	merge_method	update" "$result"

echo ""
echo "--- 非エイリアスキー（不在） ---"
result=$(resolve_write_target "rules.git.new_setting" "$TMPFILE")
assert_eq "非エイリアスキー、不在 → create" "rules.git	new_setting	create" "$result"

echo ""
echo "--- エイリアスキー、両方不在 ---"
result=$(resolve_write_target "rules.git.ai_author" "$TMPFILE")
assert_eq "エイリアスキー、両方不在 → create(canonical)" "rules.git	ai_author	create" "$result"

echo ""
echo "--- 正規キーが既存（レガシーより優先） ---"
cat > "$TMPFILE" << 'TOML'
[rules.git]
branch_mode = "ask"
TOML
result=$(resolve_write_target "rules.git.branch_mode" "$TMPFILE")
assert_eq "正規キー既存 → update(canonical優先)" "rules.git	branch_mode	update" "$result"

# =============================================
echo ""
echo "=== escape_regex() テスト ==="
echo ""

result=$(escape_regex "rules.git")
assert_eq "ドット入りセクション名" 'rules\.git' "$result"

result=$(escape_regex "simple_key")
assert_eq "メタ���字なしキー" "simple_key" "$result"

# =============================================
echo ""
echo "=== escape_toml_value() テスト ==="
echo ""

result=$(escape_toml_value 'hello')
assert_eq "通常文字列" "hello" "$result"

result=$(escape_toml_value 'say "hi"')
assert_eq "ダブルクォート含む" 'say \"hi\"' "$result"

result=$(escape_toml_value 'path\to\file')
assert_eq "バックスラッシュ含む" 'path\\to\\file' "$result"

# =============================================
echo ""
echo "=== 結果サマリ ==="
echo "PASS: $PASS / FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
