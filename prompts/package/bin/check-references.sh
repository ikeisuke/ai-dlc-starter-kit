#!/usr/bin/env bash
# 参照漏れチェックスクリプト
# プロンプト内の外部ファイル参照が正しいかをチェックする
# Usage: check-references.sh [target_dir] [-v|--verbose] [-h|--help]

set -euo pipefail

# グローバル変数
REPO_ROOT=""
VERBOSE=false
TARGET_DIR=""
VALID_COUNT=0
BROKEN_COUNT=0

# 使用法表示
show_usage() {
    cat <<EOF
Usage: $(basename "$0") [target_dir] [options]

プロンプトファイル内の外部ファイル参照が正しいかをチェックします。

Arguments:
  target_dir    チェック対象ディレクトリ (デフォルト: prompts/package/)

Options:
  -v, --verbose 詳細出力モード
  -h, --help    このヘルプを表示

Exit codes:
  0  参照漏れなし
  1  参照漏れあり
  2  スクリプトエラー
EOF
}

# エラーメッセージ整形
format_error() {
    local file="$1"
    local line_num="$2"
    local ref_path="$3"
    local context="$4"

    echo ""
    echo "ERROR: Broken reference found:"
    echo "  File: ${file}:${line_num}"
    echo "  Reference: \`${ref_path}\`"
    echo "  Context: \"${context}\""
}

# パス解決（リポジトリルート基準）
resolve_path() {
    local repo_root="$1"
    local ref_path="$2"

    # 絶対パスの場合はそのまま返す
    if [[ "$ref_path" == /* ]]; then
        echo "$ref_path"
    else
        echo "${repo_root}/${ref_path}"
    fi
}

# 参照先ファイル存在確認
validate_reference() {
    local repo_root="$1"
    local ref_path="$2"

    local resolved_path
    resolved_path=$(resolve_path "$repo_root" "$ref_path")

    if [ -f "$resolved_path" ]; then
        return 0
    else
        return 1
    fi
}

# 除外対象行（コードブロック・HTMLコメント内）の行番号リストを返す
get_excluded_lines() {
    local file="$1"
    local in_code_block=0
    local in_html_comment=0
    local line_num=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # コードブロック開始/終了（``` または ~~~）
        if [[ "$line" =~ ^(\`\`\`|~~~) ]]; then
            if [ $in_code_block -eq 0 ]; then
                in_code_block=1
            else
                in_code_block=0
            fi
        fi

        # HTMLコメント処理
        if [[ "$line" =~ \<\!-- ]]; then
            if [[ "$line" =~ --\> ]]; then
                # 単行HTMLコメント: この行のみ除外
                echo "$line_num"
            else
                # 複数行HTMLコメント開始
                in_html_comment=1
            fi
        fi

        # 除外対象行を出力（コードブロック内または複数行HTMLコメント内）
        if [ $in_code_block -eq 1 ] || [ $in_html_comment -eq 1 ]; then
            echo "$line_num"
        fi

        # HTMLコメント終了（複数行）
        if [ $in_html_comment -eq 1 ] && [[ "$line" =~ --\> ]]; then
            in_html_comment=0
        fi
    done < "$file"
}

# ファイルから参照パターンを抽出
# grepベースの実装（マルチバイト文字対応）
extract_references() {
    local file="$1"
    local repo_root="$2"

    # ファイルパスをリポジトリルート相対に変換
    local rel_file="${file#"${repo_root}/"}"

    # 除外対象行（コードブロック・HTMLコメント内）の行番号を取得
    local excluded_lines
    excluded_lines=$(get_excluded_lines "$file" | tr '\n' '|')
    excluded_lines="${excluded_lines%|}"  # 末尾の|を削除

    # 参照パターンを含む行を検索
    # パターン: バックティック内のパス + 「を読み込んで」または「を参照して」
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # 除外対象行（コードブロック・HTMLコメント内）はスキップ
        if [ -n "$excluded_lines" ]; then
            if echo "|${excluded_lines}|" | grep -q "|${line_num}|"; then
                continue
            fi
        fi

        # 参照パターンを検出
        if [[ "$line" =~ を読み込んで ]] || [[ "$line" =~ を参照して ]]; then
            # バックティック内のパスを抽出（grep -oで抽出）
            local paths=""
            paths=$(echo "$line" | grep -oE '\`[^\`]+\.(md|toml|sh|json|yaml|yml)\`' 2>/dev/null) || true

            if [ -n "$paths" ]; then
                while IFS= read -r path_with_ticks; do
                    [ -z "$path_with_ticks" ] && continue

                    # バックティックを除去
                    local ref_path="${path_with_ticks//\`/}"

                    # 外部URL（http:// https://）は除外
                    if [[ "$ref_path" =~ ^https?:// ]]; then
                        continue
                    fi

                    # コンテキスト（80文字まで、タブは空白に置換）
                    local context="${line//$'\t'/ }"
                    if [ ${#context} -gt 80 ]; then
                        context="${context:0:77}..."
                    fi

                    # タブ区切りで出力
                    printf "%s\t%d\t%s\t%s\n" "$rel_file" "$line_num" "$ref_path" "$context"
                done <<< "$paths"
            fi
        fi
    done < "$file"
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
        TARGET_DIR="prompts/package/"
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

    # 相対パス表示用
    local rel_target="${TARGET_DIR#"${REPO_ROOT}/"}"
    echo "Checking references in ${rel_target}..."

    # .mdファイルを検索してチェック
    local broken_refs=""

    while IFS= read -r -d '' file; do
        if $VERBOSE; then
            echo "  Checking: ${file#"${REPO_ROOT}/"}" >&2
        fi

        # 参照を抽出
        while IFS=$'\t' read -r src_file line_num ref_path context; do
            [ -z "$src_file" ] && continue

            if validate_reference "$REPO_ROOT" "$ref_path"; then
                ((VALID_COUNT++)) || true
                if $VERBOSE; then
                    echo "    [OK] ${ref_path}" >&2
                fi
            else
                ((BROKEN_COUNT++)) || true
                broken_refs+=$(format_error "$src_file" "$line_num" "$ref_path" "$context")
                broken_refs+=$'\n'
            fi
        done < <(extract_references "$file" "$REPO_ROOT")
    done < <(find "$TARGET_DIR" -type f -name "*.md" -print0)

    # 結果出力
    if [ "$BROKEN_COUNT" -gt 0 ]; then
        echo "$broken_refs"
        echo "${BROKEN_COUNT} broken references found. (${VALID_COUNT} valid, ${BROKEN_COUNT} broken)"
        exit 1
    else
        echo "All references are valid. (${VALID_COUNT} references checked)"
        exit 0
    fi
}

main "$@"
