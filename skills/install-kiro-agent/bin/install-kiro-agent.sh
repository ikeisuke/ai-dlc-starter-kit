#!/usr/bin/env bash
set -euo pipefail

# install-kiro-agent.sh
# KiroCLIエージェント設定ファイルを配置する実行層スクリプト
#
# 終了コード (exit-code-convention.md 準拠):
#   0: 成功（warning付き成功を含む）
#   1: バリデーションエラー（テンプレート不存在、上書き拒否、引数不正）
#   2: システムエラー（権限不足、ディレクトリ作成失敗）

readonly SCRIPT_NAME="install-kiro-agent.sh"
readonly DEFAULT_TARGET_DIR="$HOME/.kiro/agents"

# --- 引数パース ---
SOURCE=""
TARGET_DIR="$DEFAULT_TARGET_DIR"
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            if [[ -z "${2:-}" ]]; then
                echo "reason:invalid_argument"
                echo "error: --source requires a value" >&2
                exit 1
            fi
            SOURCE="$2"
            shift 2
            ;;
        --target-dir)
            if [[ -z "${2:-}" ]]; then
                echo "reason:invalid_argument"
                echo "error: --target-dir requires a value" >&2
                exit 1
            fi
            TARGET_DIR="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            echo "Usage: $SCRIPT_NAME --source <path> [--target-dir <dir>] [--force]"
            echo ""
            echo "Options:"
            echo "  --source      Template file path (required)"
            echo "  --target-dir  Target directory (default: $DEFAULT_TARGET_DIR)"
            echo "  --force       Force overwrite with backup"
            exit 0
            ;;
        *)
            echo "reason:invalid_argument"
            echo "error: unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# --- バリデーション ---
if [[ -z "$SOURCE" ]]; then
    echo "reason:invalid_argument"
    echo "error: --source is required" >&2
    exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
    echo "reason:source_missing"
    echo "error: source file not found: $SOURCE" >&2
    exit 1
fi

# --- ディレクトリ作成 ---
if [[ ! -d "$TARGET_DIR" ]]; then
    if ! mkdir -p "$TARGET_DIR" 2>/dev/null; then
        echo "reason:mkdir_failed"
        echo "error: failed to create directory: $TARGET_DIR" >&2
        exit 2
    fi
fi

# --- 配置先ファイル名（固定） ---
readonly TARGET_FILENAME="aidlc.json"
TARGET_FILE="$TARGET_DIR/$TARGET_FILENAME"

# --- 冪等性チェック ---
if [[ -f "$TARGET_FILE" ]]; then
    if diff -q "$SOURCE" "$TARGET_FILE" >/dev/null 2>&1; then
        echo "status:skipped"
        echo "message:File already up to date."
        exit 0
    fi

    if [[ "$FORCE" != true ]]; then
        echo "reason:overwrite_required"
        echo "error: target file exists and differs: $TARGET_FILE (use --force to overwrite)" >&2
        exit 1
    fi

    # バックアップ作成（一意タイムスタンプ）
    BACKUP_FILE="${TARGET_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    if ! cp "$TARGET_FILE" "$BACKUP_FILE" 2>/dev/null; then
        echo "reason:copy_failed"
        echo "error: failed to create backup: $BACKUP_FILE" >&2
        exit 2
    fi
    echo "backup:$BACKUP_FILE" >&2
fi

# --- ファイルコピー ---
if ! cp "$SOURCE" "$TARGET_FILE" 2>/dev/null; then
    echo "reason:copy_failed"
    echo "error: failed to copy file to: $TARGET_FILE" >&2
    exit 2
fi

# --- post-install verify (任意) ---
if command -v kiro >/dev/null 2>&1; then
    echo "status:success"
else
    echo "status:warning"
    echo "message:kiro CLI not found. File installed but not verified."
fi
