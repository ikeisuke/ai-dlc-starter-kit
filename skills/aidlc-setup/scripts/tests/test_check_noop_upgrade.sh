#!/usr/bin/env bash
#
# test_check_noop_upgrade.sh - check-noop-upgrade.sh ユニットテスト
#
# 検証シナリオ:
#   1. noop=true (no-changes)
#   2. noop=false (migrate-config-changed)
#   3. noop=false (missing-keys-applied)
#   4. invalid-input (引数不足 / 不正形式 / 不正値)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/../check-noop-upgrade.sh"
PASS=0
FAIL=0

assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $name"
        ((++PASS))
    else
        echo "  FAIL: $name"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        ((++FAIL))
    fi
}

# stdout と exit code の両方を検証
run_case() {
    local name="$1"
    local expected_exit="$2"
    local expected_stdout="$3"
    shift 3
    local actual_stdout
    local actual_exit=0
    actual_stdout="$("$TARGET" "$@" 2>/dev/null)" || actual_exit=$?
    assert_eq "${name} [stdout]" "$expected_stdout" "$actual_stdout"
    assert_eq "${name} [exit]"   "$expected_exit"   "$actual_exit"
}

echo "=== check-noop-upgrade.sh ユニットテスト ==="
echo ""

echo "--- ケース 1: noop=true (no-changes) ---"
run_case "migrated=0 / warnings=0 / missing_applied=0" \
    0 \
    $'noop=true\nreason=no-changes\nerror=' \
    --migrate-config-result "result:completed:migrated=0,skipped=18,warnings=0" \
    --detect-missing-applied 0

run_case "completed-with-warnings status は status のみで判定しない (warnings=0 なら no-changes)" \
    0 \
    $'noop=true\nreason=no-changes\nerror=' \
    --migrate-config-result "result:completed-with-warnings:migrated=0,skipped=5,warnings=0" \
    --detect-missing-applied 0

echo ""
echo "--- ケース 2: noop=false (migrate-config-changed) ---"
run_case "migrated>0 のみ" \
    0 \
    $'noop=false\nreason=migrate-config-changed\nerror=' \
    --migrate-config-result "result:completed:migrated=2,skipped=10,warnings=0" \
    --detect-missing-applied 0

run_case "warnings>0 のみ" \
    0 \
    $'noop=false\nreason=migrate-config-changed\nerror=' \
    --migrate-config-result "result:completed-with-warnings:migrated=0,skipped=10,warnings=1" \
    --detect-missing-applied 0

run_case "migrated>0 と missing_applied=1 同時 (migrate-config-changed が優先)" \
    0 \
    $'noop=false\nreason=migrate-config-changed\nerror=' \
    --migrate-config-result "result:completed:migrated=3,skipped=10,warnings=0" \
    --detect-missing-applied 1

echo ""
echo "--- ケース 3: noop=false (missing-keys-applied) ---"
run_case "migrated=0 / warnings=0 / missing_applied=1" \
    0 \
    $'noop=false\nreason=missing-keys-applied\nerror=' \
    --migrate-config-result "result:completed:migrated=0,skipped=18,warnings=0" \
    --detect-missing-applied 1

echo ""
echo "--- ケース 4: 引数不足 / 不正入力 (exit 2 + 3 行構造) ---"
run_case "--migrate-config-result 欠落" \
    2 \
    $'noop=\nreason=\nerror=missing-arg:--migrate-config-result' \
    --detect-missing-applied 0

run_case "--detect-missing-applied 欠落" \
    2 \
    $'noop=\nreason=\nerror=missing-arg:--detect-missing-applied' \
    --migrate-config-result "result:completed:migrated=0,skipped=18,warnings=0"

run_case "--detect-missing-applied 不正値 (2)" \
    2 \
    $'noop=\nreason=\nerror=invalid-value:--detect-missing-applied=2' \
    --migrate-config-result "result:completed:migrated=0,skipped=18,warnings=0" \
    --detect-missing-applied 2

run_case "result 行が空" \
    2 \
    $'noop=\nreason=\nerror=invalid-input:empty-migrate-config-result' \
    --migrate-config-result "" \
    --detect-missing-applied 0

run_case "result 行が形式不一致 (prefix 違い)" \
    2 \
    $'noop=\nreason=\nerror=invalid-input:malformed-result-line' \
    --migrate-config-result "summary:total=0" \
    --detect-missing-applied 0

run_case "result 行の数値以外" \
    2 \
    $'noop=\nreason=\nerror=invalid-input:malformed-result-line' \
    --migrate-config-result "result:completed:migrated=N,skipped=M,warnings=W" \
    --detect-missing-applied 0

run_case "result 行に末尾ゴミ文字" \
    2 \
    $'noop=\nreason=\nerror=invalid-input:malformed-result-line' \
    --migrate-config-result "result:completed:migrated=0,skipped=0,warnings=0,extra=x" \
    --detect-missing-applied 0

run_case "未知の引数" \
    2 \
    $'noop=\nreason=\nerror=unknown-arg:--unknown' \
    --unknown foo

run_case "--migrate-config-result 値欠落" \
    2 \
    $'noop=\nreason=\nerror=missing-arg-value:--migrate-config-result' \
    --migrate-config-result

run_case "--detect-missing-applied 値欠落" \
    2 \
    $'noop=\nreason=\nerror=missing-arg-value:--detect-missing-applied' \
    --migrate-config-result "result:completed:migrated=0,skipped=18,warnings=0" \
    --detect-missing-applied

# 出力サニタイズ: error= に改行/CR/タブが入っても 3 行固定契約を破らない
run_case "未知の引数 (改行混入) はサニタイズして 3 行契約維持" \
    2 \
    $'noop=\nreason=\nerror=unknown-arg:--inject?injected' \
    "--inject"$'\n'"injected" foo

run_case "--detect-missing-applied 不正値 (タブ混入) はサニタイズ" \
    2 \
    $'noop=\nreason=\nerror=invalid-value:--detect-missing-applied=2?evil' \
    --migrate-config-result "result:completed:migrated=0,skipped=18,warnings=0" \
    --detect-missing-applied $'2\tevil'

echo ""
echo "=== 結果: PASS=${PASS}, FAIL=${FAIL} ==="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
