#!/usr/bin/env bash
#
# test_parse_gh_error.sh - parse_gh_error() のユニットテスト
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# parse_gh_error を抽出して使用するためソースから関数定義を取り込む
# issue-ops.sh は main "$@" で即実行されるため、関数だけをevalで取得
eval "$(sed -n '/^parse_gh_error()/,/^}/p' "$SCRIPT_DIR/../bin/issue-ops.sh")"

assert_eq() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $test_name"
        ((++PASS))
    else
        echo "  FAIL: $test_name (expected='$expected', actual='$actual')"
        ((++FAIL))
    fi
}

echo "=== parse_gh_error() tests ==="

# ラベル固有エラーパターン
assert_eq "label not found" \
    "label-not-found" \
    "$(parse_gh_error "'status:in-progress' label not found")"

assert_eq "Label not found (case insensitive)" \
    "label-not-found" \
    "$(parse_gh_error "Label 'cycle:v1.0.0' not found")"

assert_eq "could not add label" \
    "label-not-found" \
    "$(parse_gh_error "could not add label: label does not exist")"

# 汎用 not-found パターン（ラベル文脈ではない）
assert_eq "issue not found" \
    "not-found" \
    "$(parse_gh_error "Could not resolve to an issue or pull request")"

assert_eq "generic not found" \
    "not-found" \
    "$(parse_gh_error "not found")"

assert_eq "could not find" \
    "not-found" \
    "$(parse_gh_error "could not find repository")"

# 認証エラーパターン
assert_eq "authentication error" \
    "auth-error" \
    "$(parse_gh_error "authentication required")"

assert_eq "unauthorized" \
    "auth-error" \
    "$(parse_gh_error "HTTP 401: Unauthorized")"

assert_eq "forbidden" \
    "auth-error" \
    "$(parse_gh_error "HTTP 403: Forbidden")"

# 不明エラー
assert_eq "unknown error" \
    "unknown" \
    "$(parse_gh_error "something went wrong")"

assert_eq "empty error" \
    "unknown" \
    "$(parse_gh_error "")"

# パターン優先順位: ラベルエラーが汎用not-foundより優先
assert_eq "label priority over not-found" \
    "label-not-found" \
    "$(parse_gh_error "label 'test' not found in repository")"

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
