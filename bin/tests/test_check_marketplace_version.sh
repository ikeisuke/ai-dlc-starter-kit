#!/usr/bin/env bash
#
# test_check_marketplace_version.sh - bin/check-marketplace-version.sh のテスト
#
# 検証対象（v2.6.0 / Unit 003 / Issue #617）:
#  - リリース関連変更なし → ok
#  - CHANGELOG.md 編集 + version 更新あり → ok
#  - .aidlc/operations.md 編集 + version 未更新 → violation (marketplace_version_unchanged)
#  - CHANGELOG.md 編集 + version 更新あり (CHANGELOG only) → ok
#  - 不正な ref → exit 2
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SRC="${SCRIPT_DIR}/../check-marketplace-version.sh"
LIB_SRC="${SCRIPT_DIR}/../../skills/aidlc/scripts/lib/version.sh"
TMPDIR_BASE=""
COUNTER_FILE=""
ORIG_DIR=""

setup_tmpdir() {
    ORIG_DIR=$(pwd)
    TMPDIR_BASE=$(mktemp -d)
    COUNTER_FILE="${TMPDIR_BASE}/.counters"
    printf '0\n0\n' > "$COUNTER_FILE"
}

cleanup_tmpdir() {
    cd "$ORIG_DIR" 2>/dev/null || true
    if [ -n "$TMPDIR_BASE" ] && [ -d "$TMPDIR_BASE" ]; then
        \rm -rf "$TMPDIR_BASE"
    fi
}
trap cleanup_tmpdir EXIT

_inc_pass() {
    local p f
    { read -r p; read -r f; } < "$COUNTER_FILE"
    printf '%d\n%d\n' "$(( p + 1 ))" "$f" > "$COUNTER_FILE"
}
_inc_fail() {
    local p f
    { read -r p; read -r f; } < "$COUNTER_FILE"
    printf '%d\n%d\n' "$p" "$(( f + 1 ))" > "$COUNTER_FILE"
}

assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $name"
        _inc_pass
    else
        echo "  FAIL: $name"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        _inc_fail
    fi
}

assert_contains() {
    local name="$1" needle="$2" actual="$3"
    if printf '%s' "$actual" | grep -qF "$needle"; then
        echo "  PASS: $name"
        _inc_pass
    else
        echo "  FAIL: $name (expected to contain '$needle')"
        echo "    actual: $actual"
        _inc_fail
    fi
}

# 各ケース毎に独立したリポジトリを作る
init_repo() {
    local repo="$1"
    local initial_version="$2"
    mkdir -p "$repo"
    cd "$repo"
    git init -q -b main
    git config user.email "test@example.com"
    git config user.name "Test"
    mkdir -p bin skills/aidlc/scripts/lib .claude-plugin
    cat > .claude-plugin/marketplace.json <<JSON
{
  "name": "fixture",
  "metadata": {
    "version": "${initial_version}"
  }
}
JSON
    cp "$CHECK_SRC" bin/check-marketplace-version.sh
    chmod +x bin/check-marketplace-version.sh
    cp "$LIB_SRC" skills/aidlc/scripts/lib/version.sh
    git add .
    git commit -q -m "init"
}

# --- テスト ---
echo "=== bin/check-marketplace-version.sh テスト ==="
setup_tmpdir

# ============================================================
# Case 1: リリース関連変更なし → ok
# ============================================================
echo ""
echo "[Case 1] リリース関連変更なし"
init_repo "${TMPDIR_BASE}/case1" "2.5.0"
echo "noop" > README.md
git add README.md && git commit -q -m "non-release change"
ec=0
out=$(bash bin/check-marketplace-version.sh --base HEAD~1 --current HEAD) || ec=$?
assert_eq "case1: 終了コード 0" 0 "$ec"
assert_contains "case1: ok" "marketplace_version_check:ok" "$out"
assert_contains "case1: no_release_relevant_changes" "no_release_relevant_changes" "$out"
cd "$TMPDIR_BASE"

# ============================================================
# Case 2: CHANGELOG.md 編集 + version 更新あり → ok
# ============================================================
echo ""
echo "[Case 2] CHANGELOG.md 編集 + version 更新あり → ok"
init_repo "${TMPDIR_BASE}/case2" "2.5.0"
echo "## 2.6.0" > CHANGELOG.md
jq --indent 2 '.metadata.version = "2.6.0"' .claude-plugin/marketplace.json > .claude-plugin/marketplace.json.tmp
mv .claude-plugin/marketplace.json.tmp .claude-plugin/marketplace.json
git add CHANGELOG.md .claude-plugin/marketplace.json
git commit -q -m "release 2.6.0"
ec=0
out=$(bash bin/check-marketplace-version.sh --base HEAD~1 --current HEAD) || ec=$?
assert_eq "case2: 終了コード 0" 0 "$ec"
assert_contains "case2: ok" "marketplace_version_check:ok" "$out"
assert_contains "case2: base_version" "base_version:2.5.0" "$out"
assert_contains "case2: current_version" "current_version:2.6.0" "$out"
cd "$TMPDIR_BASE"

# ============================================================
# Case 3: .aidlc/operations.md 編集 + version 未更新 → violation
# ============================================================
echo ""
echo "[Case 3] .aidlc/operations.md 編集 + version 未更新 → violation"
init_repo "${TMPDIR_BASE}/case3" "2.5.0"
mkdir -p .aidlc
echo "# operations" > .aidlc/operations.md
git add .aidlc/operations.md
git commit -q -m "edit operations.md without version bump"
ec=0
out=$(bash bin/check-marketplace-version.sh --base HEAD~1 --current HEAD) || ec=$?
assert_eq "case3: 終了コード 1" 1 "$ec"
assert_contains "case3: violation" "marketplace_version_check:violation" "$out"
assert_contains "case3: marketplace_version_unchanged" "marketplace_version_unchanged" "$out"
cd "$TMPDIR_BASE"

# ============================================================
# Case 4: 不正な base ref → exit 2
# ============================================================
echo ""
echo "[Case 4] 不正な base ref → exit 2"
init_repo "${TMPDIR_BASE}/case4" "2.5.0"
ec=0
out=$(bash bin/check-marketplace-version.sh --base origin/nonexistent --current HEAD 2>&1) || ec=$?
assert_eq "case4: 終了コード 2" 2 "$ec"
assert_contains "case4: base_ref_not_found" "base_ref_not_found" "$out"
cd "$TMPDIR_BASE"

# ============================================================
# Case 5: 不正なオプション → exit 2
# ============================================================
echo ""
echo "[Case 5] 不明なオプション → exit 2"
init_repo "${TMPDIR_BASE}/case5" "2.5.0"
ec=0
out=$(bash bin/check-marketplace-version.sh --invalid 2>&1) || ec=$?
assert_eq "case5: 終了コード 2" 2 "$ec"
assert_contains "case5: unknown_option" "unknown_option" "$out"
cd "$TMPDIR_BASE"

# ============================================================
# 結果集計
# ============================================================
cd "$ORIG_DIR"
echo ""
echo "=== テスト結果 ==="
{ read -r pass; read -r fail; } < "$COUNTER_FILE"
echo "PASS: $pass"
echo "FAIL: $fail"
if [ "$fail" -gt 0 ]; then exit 1; fi
exit 0
