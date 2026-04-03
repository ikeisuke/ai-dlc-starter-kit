#!/usr/bin/env bash
# skills/配下のファイルでプロジェクトルート相対パス（skills/aidlc/）による
# 参照違反を検出するスクリプト
# Usage: check-skill-references.sh [target_dir] [options]

set -euo pipefail

# デフォルト値
DEFAULT_TARGET_DIR="skills/"

# グローバル変数
REPO_ROOT=""
VERBOSE=false
TARGET_DIR=""
VIOLATION_COUNT=0
FILE_COUNT=0

# 使用法表示
show_usage() {
    cat <<EOF
Usage: $(basename "$0") [target_dir] [options]

skills/配下のファイルでプロジェクトルート相対パス（skills/aidlc/）による
参照違反を検出します。

検出対象:
  - skills/aidlc/ で始まるパス文字列

Arguments:
  target_dir    チェック対象ディレクトリ (デフォルト: skills/)

Options:
  -v, --verbose    詳細出力モード
  -h, --help       このヘルプを表示

Exit codes:
  0  違反なし
  1  違反検出
  2  スクリプトエラー
EOF
}

# 除外パターン: META-001例外（メタ開発固有の正当な参照）
# - guides/: マイグレーションガイド等のドキュメント内参照
# - steps/inception/01-setup.md: STARTER_KIT_DEV判定・参照先ポリシーテーブル
# - aidlc-migrate/: v1→v2マイグレーションスクリプト
# - write-history/SKILL.md: 委譲スキルの注記
EXCLUDE_PATTERNS=(
    "guides/"
    "steps/inception/01-setup.md"
    "aidlc-migrate/"
    "write-history/SKILL.md"
    "scripts/lib/bootstrap.sh"
    "scripts/tests/"
    "scripts/ios-build-check.sh"
    "scripts/get-default-branch.sh"
    "templates/review_summary_template.md"
    "install-kiro-agent/SKILL.md"
)

# 除外パターンに該当するか判定（パスセグメント単位で照合）
is_excluded() {
    local rel_file="$1"
    case "$rel_file" in
        */guides/*|*/steps/inception/01-setup.md|\
        */aidlc-migrate/*|*/write-history/SKILL.md|\
        */scripts/lib/bootstrap.sh|*/scripts/tests/*|\
        */scripts/ios-build-check.sh|*/scripts/get-default-branch.sh|\
        */templates/review_summary_template.md|*/install-kiro-agent/SKILL.md)
            return 0
            ;;
    esac
    return 1
}

# ファイル内の参照違反をチェック
check_file() {
    local file="$1"
    local rel_file="${file#"${REPO_ROOT}/"}"
    local file_violations=0

    # 除外パターンに該当するファイルはスキップ
    if is_excluded "$rel_file"; then
        if $VERBOSE; then
            echo "  [SKIP] $rel_file (excluded)"
        fi
        ((FILE_COUNT++)) || true
        return
    fi

    local result
    result=$(grep -n "skills/aidlc/" "$file" 2>/dev/null) || true

    if [ -n "$result" ]; then
        while IFS= read -r line; do
            echo "${rel_file}:${line}"
            ((file_violations++)) || true
        done <<< "$result"
        VIOLATION_COUNT=$((VIOLATION_COUNT + file_violations))
    elif $VERBOSE; then
        echo "  [OK] $rel_file"
    fi

    ((FILE_COUNT++)) || true
}

# メイン処理
main() {
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                show_usage >&2
                exit 2
                ;;
            *)
                if [ -z "$TARGET_DIR" ]; then
                    TARGET_DIR="$1"
                else
                    echo "Error: Unexpected argument: $1" >&2
                    show_usage >&2
                    exit 2
                fi
                shift
                ;;
        esac
    done

    # リポジトリルート取得
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "Error: Not a git repository. Run this script from within a git repository." >&2
        exit 2
    }

    # スコープ判定: skills/ディレクトリの存在で判定（config依存なし）
    if [ ! -d "${REPO_ROOT}/skills" ]; then
        echo "Skipped: skills/ directory not found"
        exit 0
    fi

    # デフォルトターゲットディレクトリ
    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$DEFAULT_TARGET_DIR"
    fi

    # ターゲットディレクトリを絶対パスに変換
    if [[ "$TARGET_DIR" != /* ]]; then
        TARGET_DIR="${REPO_ROOT}/${TARGET_DIR}"
    fi

    # ターゲットディレクトリ存在確認
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Error: Target directory not found: $TARGET_DIR" >&2
        exit 2
    fi

    # パス正規化（../等のトラバーサルを解決）
    TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

    # リポジトリ外ディレクトリの拒否
    case "$TARGET_DIR" in
        "${REPO_ROOT}"/*)
            ;;
        *)
            echo "Error: Target directory is outside the repository: $TARGET_DIR" >&2
            exit 2
            ;;
    esac

    local rel_target="${TARGET_DIR#"${REPO_ROOT}/"}"

    if $VERBOSE; then
        echo "Checking skill references in ${rel_target}..."
        echo ""
    fi

    # 自スクリプトのパスを取得（除外用）
    local self_path
    self_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")

    # 対象ファイルをチェック（.md, .sh, .toml）
    while IFS= read -r -d '' file; do
        # 自スクリプトは除外
        if [ "$file" = "$self_path" ]; then
            continue
        fi
        check_file "$file"
    done < <(find "$TARGET_DIR" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.toml" \) -print0)

    # サマリー出力
    echo ""
    if [ "$VIOLATION_COUNT" -eq 0 ]; then
        echo "Skill reference check completed: no violations, $FILE_COUNT files checked"
    elif [ "$VIOLATION_COUNT" -eq 1 ]; then
        echo "Skill reference check completed: $VIOLATION_COUNT violation, $FILE_COUNT files checked"
    else
        echo "Skill reference check completed: $VIOLATION_COUNT violations, $FILE_COUNT files checked"
    fi

    # 終了コード
    if [ "$VIOLATION_COUNT" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
