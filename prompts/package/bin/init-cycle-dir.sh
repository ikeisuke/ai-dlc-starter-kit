#!/usr/bin/env bash
#
# init-cycle-dir.sh - サイクル用ディレクトリ構造を一括作成
#
# 使用方法:
#   ./init-cycle-dir.sh <VERSION> [OPTIONS]
#
# ARGUMENTS:
#   VERSION       サイクルバージョン（例: v1.8.0）
#
# OPTIONS:
#   -h, --help    ヘルプを表示
#   --dry-run     実際に作成せず、作成予定を表示
#
# 出力形式（stdout）:
#   dir:<パス>:<状態>
#   file:<パス>:<状態>
#   - created: 新規作成
#   - exists: 既存（スキップ）
#   - would-create: 作成予定（--dry-runモード）
#   - skipped-issue-only: issue-onlyモードのためスキップ
#   - error: 作成失敗（詳細はstderrへ）
#

set -euo pipefail

# 作成するディレクトリ一覧（10個）
DIRECTORIES=(
    "plans"
    "requirements"
    "story-artifacts/units"
    "design-artifacts/domain-models"
    "design-artifacts/logical-designs"
    "design-artifacts/architecture"
    "inception"
    "construction/units"
    "operations"
    "history"
)

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: init-cycle-dir.sh <VERSION> [OPTIONS]

サイクル用ディレクトリ構造（10個）と初期ファイルを一括作成します。

ARGUMENTS:
  VERSION       サイクルバージョン（例: v1.8.0）

OPTIONS:
  -h, --help    このヘルプを表示
  --dry-run     実際に作成せず、作成予定を表示

出力形式（stdout）:
  dir:<パス>:<状態>
  file:<パス>:<状態>

状態:
  created            - 新規作成
  exists             - 既存（スキップ）
  would-create       - 作成予定（--dry-runモード）
  skipped-issue-only - issue-onlyモードのためスキップ
  error              - 作成失敗（詳細はstderrへ）

共通バックログディレクトリ:
  docs/cycles/backlog/ と docs/cycles/backlog-completed/ も作成します。
  ただし、backlog mode が issue-only の場合はスキップします。

例:
  $ init-cycle-dir.sh v1.8.0
  dir:docs/cycles/v1.8.0/plans:created
  dir:docs/cycles/v1.8.0/requirements:created
  ...
  file:docs/cycles/v1.8.0/history/inception.md:created
  dir:docs/cycles/backlog:created
  dir:docs/cycles/backlog-completed:created

  $ init-cycle-dir.sh v1.8.0 --dry-run
  dir:docs/cycles/v1.8.0/plans:would-create
  ...
EOF
}

# バージョン形式を検証（vX.X.X形式）
# 戻り値: 0=有効, 1=無効
validate_version() {
    local version="$1"
    if [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        echo "[error] ${version}: Invalid version format. Expected vX.X.X (e.g., v1.8.0)" >&2
        return 1
    fi
}

# ディレクトリを作成
# 引数: $1=パス, $2=dry_run (true/false)
# 戻り値: 0=成功, 1=失敗
create_directory() {
    local path="$1"
    local dry_run="$2"

    if [[ -d "$path" ]]; then
        echo "dir:${path}:exists"
        return 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "dir:${path}:would-create"
        return 0
    fi

    if mkdir -p "$path" 2>/dev/null; then
        echo "dir:${path}:created"
        return 0
    else
        echo "dir:${path}:error"
        echo "[error] ${path}: Failed to create directory" >&2
        return 1
    fi
}

# backlog modeを取得
# 戻り値（stdout）: git, git-only, issue, issue-only のいずれか（デフォルト: git）
get_backlog_mode() {
    local config_file="docs/aidlc.toml"
    local mode=""

    # 設定ファイルが存在しない場合はデフォルト
    if [[ ! -f "$config_file" ]]; then
        echo "git"
        return 0
    fi

    # daselが利用可能な場合はそれを使用
    if command -v dasel &>/dev/null; then
        mode=$(dasel -f "$config_file" -r toml 'backlog.mode' 2>/dev/null || echo "")
    fi

    # daselが利用不可または取得失敗の場合はgrepでフォールバック
    if [[ -z "$mode" ]]; then
        # mode = "xxx" の形式を抽出
        mode=$(grep -E '^\s*mode\s*=' "$config_file" 2>/dev/null | head -1 | sed 's/.*=\s*["'"'"']\?\([^"'"'"']*\)["'"'"']\?.*/\1/' || echo "")
    fi

    # 空または無効な値の場合はデフォルト
    case "$mode" in
        git|git-only|issue|issue-only)
            echo "$mode"
            ;;
        *)
            echo "git"
            ;;
    esac
}

# 共通バックログディレクトリを作成
# 引数: $1=dry_run (true/false)
# 戻り値: 0=成功, 1=失敗
create_common_backlog_dirs() {
    local dry_run="$1"
    local backlog_mode
    local error_count=0

    backlog_mode=$(get_backlog_mode)

    # issue-onlyの場合はスキップ
    if [[ "$backlog_mode" == "issue-only" ]]; then
        echo "dir:docs/cycles/backlog:skipped-issue-only"
        echo "dir:docs/cycles/backlog-completed:skipped-issue-only"
        return 0
    fi

    # バックログディレクトリを作成
    local dirs=("docs/cycles/backlog" "docs/cycles/backlog-completed")
    for dir in "${dirs[@]}"; do
        if ! create_directory "$dir" "$dry_run"; then
            ((error_count++)) || true
        fi
    done

    if [[ $error_count -gt 0 ]]; then
        return 1
    fi
    return 0
}

# history/inception.md を初期化
# 引数: $1=ファイルパス, $2=サイクルバージョン, $3=dry_run (true/false)
# 戻り値: 0=成功, 1=失敗
init_history_file() {
    local file_path="$1"
    local version="$2"
    local dry_run="$3"

    if [[ -f "$file_path" ]]; then
        echo "file:${file_path}:exists"
        return 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "file:${file_path}:would-create"
        return 0
    fi

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')

    if cat > "$file_path" << EOF
# Inception Phase 履歴

## ${timestamp}

- **フェーズ**: サイクルセットアップ
- **実行内容**: サイクル開始
- **プロンプト**: -
- **成果物**: docs/cycles/${version}/（サイクルディレクトリ）
- **備考**: -

---
EOF
    then
        echo "file:${file_path}:created"
        return 0
    else
        echo "file:${file_path}:error"
        echo "[error] ${file_path}: Failed to create file" >&2
        return 1
    fi
}

# メイン処理
main() {
    local dry_run=false
    local version=""
    local error_count=0

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --dry-run)
                dry_run=true
                ;;
            -*)
                echo "[error] Unknown option: $1" >&2
                exit 1
                ;;
            *)
                if [[ -z "$version" ]]; then
                    version="$1"
                else
                    echo "[error] Unexpected argument: $1" >&2
                    exit 1
                fi
                ;;
        esac
        shift
    done

    # バージョン引数必須チェック
    if [[ -z "$version" ]]; then
        echo "[error] VERSION argument is required" >&2
        echo "Usage: init-cycle-dir.sh <VERSION> [OPTIONS]" >&2
        echo "Run 'init-cycle-dir.sh --help' for more information." >&2
        exit 1
    fi

    # バージョン形式検証
    if ! validate_version "$version"; then
        exit 1
    fi

    local base_path="docs/cycles/${version}"

    # 各ディレクトリを作成
    for dir in "${DIRECTORIES[@]}"; do
        local full_path="${base_path}/${dir}"
        if ! create_directory "$full_path" "$dry_run"; then
            ((error_count++)) || true
        fi
    done

    # history/inception.md を初期化
    local history_file="${base_path}/history/inception.md"
    if ! init_history_file "$history_file" "$version" "$dry_run"; then
        ((error_count++)) || true
    fi

    # 共通バックログディレクトリを作成
    if ! create_common_backlog_dirs "$dry_run"; then
        ((error_count++)) || true
    fi

    # 終了コード決定
    if [[ $error_count -gt 0 ]]; then
        exit 2
    fi
    exit 0
}

main "$@"
