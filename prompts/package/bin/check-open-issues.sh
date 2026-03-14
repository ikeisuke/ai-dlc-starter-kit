#!/usr/bin/env bash
#
# check-open-issues.sh - オープンIssueの一覧を取得
#
# 使用方法:
#   ./check-open-issues.sh [--limit N]
#
# パラメータ:
#   --limit N: 取得件数（デフォルト: 10）
#
# 出力形式:
#   - Issueあり: gh issue listの出力（Issue番号、タイトル、ラベル）
#   - Issueなし: "open_issues:none"
#   - エラー: "error:<エラー種別>[:<コンテキスト>]"
#
# 終了コード:
#   0: 正常終了（Issueの有無に関わらず）
#   1: 入力バリデーションエラー
#   2: 操作エラー（gh未インストール、認証失敗、API呼び出し失敗等）
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/validate.sh"

# デフォルト値
LIMIT=10

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --limit)
            if [[ $# -lt 2 ]]; then
                emit_error "missing-limit-value" "--limit requires a value"
                exit 1
            fi
            if ! [[ "$2" =~ ^[1-9][0-9]*$ ]]; then
                emit_error "invalid-limit-value" "--limit value must be a positive integer"
                exit 1
            fi
            LIMIT="$2"
            shift 2
            ;;
        *)
            emit_error "unknown-option" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# GitHub CLIの存在確認
if ! command -v gh >/dev/null 2>&1; then
    emit_error "gh-not-installed" "gh is not installed"
    exit 2
fi

# 認証確認
if ! gh auth status >/dev/null 2>&1; then
    emit_error "gh-not-authenticated" "gh is not authenticated"
    exit 2
fi

# オープンIssueの一覧取得
_tmp_stderr=$(mktemp) || { emit_error "gh-issue-list-failed" "Failed to list issues"; exit 2; }
trap '\rm -f "$_tmp_stderr"' EXIT
result=$(gh issue list --state open --limit "$LIMIT" 2>"$_tmp_stderr") || {
    emit_error "gh-issue-list-failed" "Failed to list issues"
    cat "$_tmp_stderr" >&2
    exit 2
}

if [[ -z "$result" ]]; then
    echo "open_issues:none"
else
    echo "$result"
fi
