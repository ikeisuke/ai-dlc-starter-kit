#!/usr/bin/env bash
#
# test_detect_phase.sh - detect_phase() のテスト
#
set -uo pipefail

PASS=0
FAIL=0

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $label"
        ((PASS++))
    else
        echo "  FAIL: $label (expected='$expected', actual='$actual')"
        ((FAIL++))
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# 実ファイルからsource（mainガードにより関数定義のみ読み込まれる）
AIDLC_PROJECT_ROOT="$PROJECT_ROOT" source "$PROJECT_ROOT/skills/aidlc/scripts/aidlc-cycle-info.sh"

echo "=== detect_phase() tests ==="

# テスト用一時ディレクトリ
TMPDIR_BASE=$(mktemp -d)
AIDLC_CYCLES="$TMPDIR_BASE/cycles"

echo ""
echo "--- unknown ケース ---"
assert_eq "empty version" "unknown" "$(detect_phase "")"
assert_eq "nonexistent dir" "unknown" "$(detect_phase "v99.99.99")"

echo ""
echo "--- inception ケース ---"
mkdir -p "$AIDLC_CYCLES/v1.0.0"
assert_eq "empty cycle dir" "inception" "$(detect_phase "v1.0.0")"

mkdir -p "$AIDLC_CYCLES/v1.0.0/inception"
assert_eq "inception dir only" "inception" "$(detect_phase "v1.0.0")"

echo ""
echo "--- construction ケース ---"
mkdir -p "$AIDLC_CYCLES/v1.0.0/story-artifacts/units"
touch "$AIDLC_CYCLES/v1.0.0/story-artifacts/units/001-test.md"
assert_eq "units with md file" "construction" "$(detect_phase "v1.0.0")"

echo ""
echo "--- operations ケース ---"
mkdir -p "$AIDLC_CYCLES/v1.0.0/operations"
touch "$AIDLC_CYCLES/v1.0.0/operations/progress.md"
assert_eq "operations progress exists" "operations" "$(detect_phase "v1.0.0")"

echo ""
echo "--- units without md files ---"
mkdir -p "$AIDLC_CYCLES/v2.0.0/story-artifacts/units"
assert_eq "units dir empty" "inception" "$(detect_phase "v2.0.0")"

# クリーンアップ
rm -rf "$TMPDIR_BASE"

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
