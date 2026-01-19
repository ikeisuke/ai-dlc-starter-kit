#!/usr/bin/env bash
#
# label-cycle-issues.sh - 複数Issueへのサイクルラベル一括付与スクリプト
#
# 使用方法:
#   ./label-cycle-issues.sh <CYCLE>
#   ./label-cycle-issues.sh -h | --help
#
# ARGUMENTS:
#   CYCLE    サイクル名（例: v1.8.1）
#
# OPTIONS:
#   -h, --help    ヘルプを表示
#
# 出力形式（stdout）:
#   成功時: issue:<number>:labeled:<label_name>（issue-ops.shの出力を透過）
#   エラー時: issue:<number>:error:<reason>（issue-ops.shの出力を透過）
#   gh未インストール: error:gh-not-available
#   gh未認証: error:gh-not-authenticated
#   引数不足: error:missing-cycle
#   Issue番号なし: （出力なし、正常終了）
#
# 例:
#   $ ./label-cycle-issues.sh v1.8.1
#   issue:81:labeled:cycle:v1.8.1
#   issue:72:labeled:cycle:v1.8.1
#

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: label-cycle-issues.sh <CYCLE>
       label-cycle-issues.sh -h | --help

Unit定義ファイルから関連Issue番号を抽出し、サイクルラベルを一括付与するスクリプト。

ARGUMENTS:
  CYCLE    サイクル名（例: v1.8.1）

OPTIONS:
  -h, --help    このヘルプを表示

出力形式（stdout）:
  成功時:
    issue:<number>:labeled:<label_name>

  エラー時:
    issue:<number>:error:not-found
    issue:<number>:error:unknown
    error:gh-not-available
    error:gh-not-authenticated
    error:missing-cycle

例:
  $ label-cycle-issues.sh v1.8.1
  issue:81:labeled:cycle:v1.8.1
  issue:72:labeled:cycle:v1.8.1
EOF
}

# gh CLIが利用可能かチェック
# 戻り値: 0=利用可能, 1=gh未インストール, 2=gh未認証
check_gh_available() {
    if ! command -v gh >/dev/null 2>&1; then
        return 1
    fi
    if ! gh auth status >/dev/null 2>&1; then
        return 2
    fi
    return 0
}

# Unit定義ファイルからIssue番号を抽出
# 引数: $1=サイクル名
# 出力: Issue番号リスト（改行区切り）
extract_issue_numbers() {
    local cycle="$1"
    local units_dir="docs/cycles/${cycle}/story-artifacts/units"

    # ディレクトリ/ファイル存在チェック（set -eとの整合性のため）
    if [[ ! -d "$units_dir" ]]; then
        return 0
    fi

    # Unitファイルが存在するかチェック（globでファイルリストを取得）
    local -a files
    files=("$units_dir"/*.md)

    # glob展開が失敗した場合（ファイルなし）のチェック
    if [[ ! -e "${files[0]}" ]]; then
        return 0
    fi

    # awkで「## 関連Issue」セクション内の「- #数字」パターンを抽出
    # セクションスコープ: ## 関連Issue から次の ## まで
    # 注: macOS/BSD awkでも動作するようgsub/subを使用
    awk '
        /^## 関連Issue/ { in_section = 1; next }
        /^## / { in_section = 0 }
        in_section && /^- #[0-9]+/ {
            # "#数字" から数字部分を抽出（BSD awk互換）
            line = $0
            gsub(/^- #/, "", line)
            gsub(/[^0-9].*$/, "", line)
            if (line != "") print line
        }
    ' "${files[@]}" 2>/dev/null | sort -n | uniq || true
}

# Issue群にラベルを付与
# 引数: $1=Issue番号リスト（改行区切り）, $2=ラベル名
label_issues() {
    local issue_numbers="$1"
    local label_name="$2"

    if [[ -z "$issue_numbers" ]]; then
        return 0
    fi

    echo "$issue_numbers" | while read -r issue_num; do
        if [[ -n "$issue_num" ]]; then
            # issue-ops.shを呼び出し（エラー時も継続するため || true）
            "${SCRIPT_DIR}/issue-ops.sh" label "$issue_num" "$label_name" || true
        fi
    done
}

# メイン処理
main() {
    # 引数がない場合
    if [[ $# -eq 0 ]]; then
        echo "error:missing-cycle"
        exit 1
    fi

    # 最初の引数を確認
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "error:unknown-option:$1"
            exit 1
            ;;
    esac

    local cycle="$1"

    # gh利用可否確認（set -eとの整合性のため || true で終了コードを捕捉）
    local gh_status=0
    check_gh_available || gh_status=$?
    if [[ $gh_status -eq 1 ]]; then
        echo "error:gh-not-available"
        exit 1
    elif [[ $gh_status -eq 2 ]]; then
        echo "error:gh-not-authenticated"
        exit 1
    fi

    # ラベル名生成
    local label_name="cycle:${cycle}"

    # Issue番号抽出
    local issue_numbers
    issue_numbers=$(extract_issue_numbers "$cycle")

    # Issue番号が見つからない場合は正常終了
    if [[ -z "$issue_numbers" ]]; then
        exit 0
    fi

    # ラベル付与
    label_issues "$issue_numbers" "$label_name"
}

main "$@"
