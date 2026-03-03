#!/usr/bin/env bash
# Bashコードブロック内コマンド置換検出スクリプト
# プロンプト内のBashコードブロックで $() やバッククォートによる
# コマンド置換が使用されていないかをチェックする
# Usage: check-bash-substitution.sh [target_dir] [options]

set -euo pipefail

# デフォルト値
DEFAULT_TARGET_DIR="prompts/package/prompts/"
DEFAULT_TARGET_PATTERN="*.md"

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

プロンプト内のBashコードブロックでコマンド置換が使用されていないかをチェックします。

検出対象:
  - \$() によるコマンド置換
  - バッククォート(\`) によるコマンド置換

Arguments:
  target_dir    チェック対象ディレクトリ (デフォルト: prompts/package/prompts/)

Options:
  -v, --verbose    詳細出力モード
  -h, --help       このヘルプを表示

Exit codes:
  0  違反なし
  1  違反検出
  2  スクリプトエラー
EOF
}

# ファイル内のBashコードブロックをチェック
check_file() {
    local file="$1"
    local rel_file="${file#"${REPO_ROOT}/"}"
    local file_violations=0

    # awkでBashコードブロック内のコマンド置換を検出
    local result
    result=$(awk '
        /^[ ]{0,3}(`{3,}|~{3,})[ ]*bash([ ]|$)/ {
            # フェンス開始文字と長さを記録
            match($0, /^[ ]{0,3}(`{3,}|~{3,})/)
            fence_char = substr($0, RSTART, RLENGTH)
            gsub(/^[ ]+/, "", fence_char)
            fence_len = length(fence_char)
            fence_type = substr(fence_char, 1, 1)
            in_bash = 1
            next
        }
        in_bash && /^[ ]{0,3}(`{3,}|~{3,})[ ]*$/ {
            # 閉じフェンスの判定: 同じ文字で同じ長さ以上
            match($0, /^[ ]{0,3}(`{3,}|~{3,})/)
            close_char = substr($0, RSTART, RLENGTH)
            gsub(/^[ ]+/, "", close_char)
            close_len = length(close_char)
            close_type = substr(close_char, 1, 1)
            if (close_type == fence_type && close_len >= fence_len) {
                in_bash = 0
            }
            next
        }
        in_bash && /\$\(/ {
            printf "%s:%d: $() command substitution found: %s\n", FILENAME, FNR, $0
        }
        in_bash && /`/ {
            printf "%s:%d: backtick command substitution found: %s\n", FILENAME, FNR, $0
        }
    ' "$file" 2>/dev/null) || true

    if [ -n "$result" ]; then
        # ファイルパスをリポジトリ相対パスに変換して出力
        echo "$result" | sed "s|${file}|${rel_file}|g"
        file_violations=$(echo "$result" | wc -l | tr -d ' ')
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

    local rel_target="${TARGET_DIR#"${REPO_ROOT}/"}"

    if $VERBOSE; then
        echo "Checking bash code blocks for command substitution in ${rel_target}..."
        echo ""
    fi

    # 対象ファイルをチェック
    while IFS= read -r -d '' file; do
        check_file "$file"
    done < <(find "$TARGET_DIR" -type f -name "$DEFAULT_TARGET_PATTERN" -print0)

    # サマリー出力
    echo ""
    if [ "$VIOLATION_COUNT" -eq 0 ]; then
        echo "Bash substitution check completed: no violations, $FILE_COUNT files checked"
    elif [ "$VIOLATION_COUNT" -eq 1 ]; then
        echo "Bash substitution check completed: $VIOLATION_COUNT violation, $FILE_COUNT files checked"
    else
        echo "Bash substitution check completed: $VIOLATION_COUNT violations, $FILE_COUNT files checked"
    fi

    # 終了コード
    if [ "$VIOLATION_COUNT" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
