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
# - guides/: ガイド文書内のパス例・準拠状況テーブル
# - steps/common/review-flow.md: 規範記述（Round 4+ 新領域判定の境界条件テーブル / 列の記述ガイダンスのパス例）
# - steps/common/rules-core.md: 公開 API スクリプト層の規約セクション（v2.6.1 Unit 004 / Issue #689）。
#   `skills/aidlc/scripts/read-config.sh` を全スキルから参照可能な公開 API として明文化する規約記述を含む
# - aidlc-feedback/steps/feedback.md: 公開 API スクリプト層への正当な参照（v2.6.1 Unit 004 / Issue #689）。
#   `bash skills/aidlc/scripts/read-config.sh` をリポジトリルート相対の絶対参照として呼び出す
# - aidlc-feedback/SKILL.md: 公開 API スクリプト層への参照説明（v2.6.1 Unit 003 / Issue #690）。
#   パス解決セクションで他スキル（aidlc プラグイン等）の scripts/ 参照例として
#   `bash skills/aidlc/scripts/read-config.sh ...` を明示する
# - aidlc/steps/develop.md: 公開 API スクリプト層への正当な参照（v3.0.0-alpha.5 / Unit 001 / #736）。
#   depth_level 解決に `bash skills/aidlc/scripts/read-config.sh rules.depth_level.level` を
#   リポジトリルート相対の絶対参照として呼び出す + review-routing.md / review-flow.md への委譲参照
#   （rules-core.md の公開 API スクリプト層の規約に準拠 / aidlc-feedback と同パターン）
# - aidlc/steps/doctor.md: 公開 API スクリプト層への正当な参照（v3.0.0-alpha.7 / Unit 003 / #733）。
#   doctor の `[config]` 領域が `skills/aidlc/scripts/read-config.sh rules.depth_level.level` を
#   wrap する出力仕様記述（develop.md と同じ公開 API スクリプト層パターン）
# - scripts/doctor.sh: doctor 実行実装。パス解決コメント + `[config]` 領域の read-config.sh wrap
# - aidlc-migrate/: v2→v3 マイグレーションスキル（state-init.sh 2 候補解決の説明記述）
# - scripts/lib/bootstrap.sh: AIDLC_BASE 解決の bootstrap で
#   `skills/aidlc/scripts/lib` ディレクトリ存在チェックの文字列を含む（自己参照）
EXCLUDE_PATTERNS=(
    "guides/"
    "steps/common/review-flow.md"
    "steps/common/rules-core.md"
    "aidlc-feedback/steps/feedback.md"
    "aidlc-feedback/SKILL.md"
    "aidlc/steps/develop.md"
    "aidlc/steps/doctor.md"
    "aidlc-migrate/"
    "scripts/doctor.sh"
    "scripts/lib/bootstrap.sh"
    "scripts/tests/"
)

# 除外パターンに該当するか判定（パスセグメント単位で照合）
is_excluded() {
    local rel_file="$1"
    case "$rel_file" in
        */guides/*|\
        */steps/common/review-flow.md|*/steps/common/rules-core.md|\
        */aidlc-feedback/steps/feedback.md|*/aidlc-feedback/SKILL.md|\
        */aidlc/steps/develop.md|*/aidlc/steps/doctor.md|\
        */aidlc-migrate/*|\
        */scripts/doctor.sh|*/scripts/lib/bootstrap.sh|\
        */scripts/tests/*)
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
