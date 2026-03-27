#!/usr/bin/env bash
#
# init-cycle-dir.sh - サイクル用ディレクトリ構造を一括作成
#
# 使用方法:
#   ./init-cycle-dir.sh <VERSION> [OPTIONS]
#
# ARGUMENTS:
#   VERSION       サイクル識別子（例: v1.8.0, v2.0.0-alpha.1, feature-test）
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
#   - skipped-issue-mode: Issue駆動モード（issue/issue-only）のためスキップ
#   - error: 作成失敗（詳細はstderrへ）
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"
source "${SCRIPT_DIR}/lib/validate.sh"

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
  VERSION       サイクル識別子（例: v1.8.0, v2.0.0-alpha.1, feature-test）

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
  skipped-issue-mode - Issue駆動モード（issue/issue-only）のためスキップ
  error              - 作成失敗（詳細はstderrへ）

共通バックログディレクトリ:
  .aidlc/cycles/backlog/ と .aidlc/cycles/backlog-completed/ も作成します。
  ただし、backlog mode が issue または issue-only の場合はスキップします。

例:
  $ init-cycle-dir.sh v1.8.0
  dir:.aidlc/cycles/v1.8.0/plans:created
  dir:.aidlc/cycles/v1.8.0/requirements:created
  ...
  file:.aidlc/cycles/v1.8.0/history/inception.md:created
  dir:.aidlc/cycles/backlog:created
  dir:.aidlc/cycles/backlog-completed:created

  $ init-cycle-dir.sh v1.8.0 --dry-run
  dir:.aidlc/cycles/v1.8.0/plans:would-create
  ...
EOF
}

# バージョン形式を検証
# - 空文字は拒否
# - スラッシュ含有は拒否（パス生成で問題になるため）
# - それ以外は許容（プレリリース、任意の識別子など）
# 戻り値: 0=有効, 1=無効
validate_version() {
    local version="$1"

    # 空文字チェック
    if [[ -z "$version" ]]; then
        emit_error "missing-version" "VERSION argument is required"
        return 1
    fi

    # パストラバーサル防止
    if [[ "$version" == *..* ]]; then
        emit_error "version-path-traversal" "${version}: Version cannot contain path traversal (..)"
        return 1
    fi

    # 2レベル以上のスラッシュ拒否（[name]/vX.X.X の1レベルは許可）
    if [[ "$version" == */*/* ]]; then
        emit_error "version-multiple-slashes" "${version}: Version cannot contain more than one slash"
        return 1
    fi

    # 先頭・末尾スラッシュや空セグメント拒否
    if [[ "$version" == /* ]] || [[ "$version" == */ ]] || [[ "$version" == *"//"* ]]; then
        emit_error "version-invalid-format" "${version}: Invalid format (leading/trailing slash or empty segment)"
        return 1
    fi

    return 0
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
        emit_error "failed-create-directory" "Failed to create directory: ${path}"
        return 1
    fi
}

# backlog modeを取得（resolve-backlog-mode.sh の共通ロジックを使用）
# 戻り値（stdout）: git, git-only, issue, issue-only のいずれか（デフォルト: git）
# resolve-backlog-mode.sh を source
source "${SCRIPT_DIR}/resolve-backlog-mode.sh"

# get_backlog_mode: resolve_backlog_mode を直接使用（ラッパー廃止）

# 共通バックログディレクトリを作成
# 引数: $1=dry_run (true/false)
# 戻り値: 0=成功, 1=失敗
create_common_backlog_dirs() {
    local dry_run="$1"
    local backlog_mode
    local error_count=0

    backlog_mode=$(resolve_backlog_mode)

    # Issue駆動モード（issue/issue-only）の場合はスキップ
    if [[ "$backlog_mode" == "issue" || "$backlog_mode" == "issue-only" ]]; then
        echo "dir:${AIDLC_CYCLES}/backlog:skipped-issue-mode"
        echo "dir:${AIDLC_CYCLES}/backlog-completed:skipped-issue-mode"
        return 0
    fi

    # バックログディレクトリを作成
    local dirs=("${AIDLC_CYCLES}/backlog" "${AIDLC_CYCLES}/backlog-completed")
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
- **成果物**: .aidlc/cycles/${version}/（サイクルディレクトリ）
- **備考**: -

---
EOF
    then
        echo "file:${file_path}:created"
        return 0
    else
        echo "file:${file_path}:error"
        emit_error "failed-create-file" "Failed to create file: ${file_path}"
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
                emit_error "unknown-option" "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$version" ]]; then
                    version="$1"
                else
                    emit_error "unexpected-argument" "Unexpected argument: $1"
                    exit 1
                fi
                ;;
        esac
        shift
    done

    # バージョン引数必須チェック
    if [[ -z "$version" ]]; then
        emit_error "missing-version" "VERSION argument is required"
        echo "Usage: init-cycle-dir.sh <VERSION> [OPTIONS]" >&2
        echo "Run 'init-cycle-dir.sh --help' for more information." >&2
        exit 1
    fi

    # バージョン形式検証
    if ! validate_version "$version"; then
        exit 1
    fi

    local base_path="${AIDLC_CYCLES}/${version}"

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
