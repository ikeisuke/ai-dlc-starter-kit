#!/usr/bin/env bash
#
# sync-prompts.sh - prompts/package配下をdocs/aidlc/に一括同期
#
# 使用方法:
#   ./sync-prompts.sh [OPTIONS]
#
# OPTIONS:
#   -h, --help           ヘルプを表示
#   --dest <DIR>         同期先ベースディレクトリ（デフォルト: docs/aidlc/）
#   --only <TARGETS>     特定ターゲットのみ同期（カンマ区切り）
#   --dry-run            実際に同期せず、実行予定を表示
#
# 同期対象ターゲット:
#   prompts, templates, guides, bin
#
# 出力形式（stdout）:
#   sync:<ターゲット名>:<状態>
#   - synced: 同期完了
#   - skipped: ソースが存在しないためスキップ
#   - would-sync: 同期予定（--dry-runモード）
#   - error: 同期失敗（詳細はstderrへ）
#

set -euo pipefail

# 設定
SOURCE_DIR="prompts/package/"
DEFAULT_DEST="docs/aidlc/"
SYNC_TARGETS=(prompts templates guides bin)

# グローバル変数
DEST_DIR=""
ONLY_TARGETS=()
DRY_RUN=false

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: sync-prompts.sh [OPTIONS]

prompts/package配下の4つのリソースディレクトリをdocs/aidlc/に一括同期します。

OPTIONS:
  -h, --help           このヘルプを表示
  --dest <DIR>         同期先ベースディレクトリ（デフォルト: docs/aidlc/）
  --only <TARGETS>     特定ターゲットのみ同期（カンマ区切り）
  --dry-run            実際に同期せず、実行予定を表示

同期対象ターゲット:
  prompts, templates, guides, bin

出力形式（stdout）:
  sync:<ターゲット名>:<状態>

状態:
  synced      - 同期完了
  skipped     - ソースが存在しないためスキップ
  would-sync  - 同期予定（--dry-runモード）
  error       - 同期失敗（詳細はstderrへ）

例:
  $ sync-prompts.sh
  sync:prompts:synced
  sync:templates:synced
  ...

  $ sync-prompts.sh --dest /tmp/test/ --only prompts,guides
  sync:prompts:synced
  sync:guides:synced

  $ sync-prompts.sh --dry-run
  sync:prompts:would-sync
  sync:templates:would-sync
  ...
EOF
}

# rsyncが利用可能かチェック
# 戻り値: 0=利用可能, 1=利用不可
check_rsync_available() {
    if ! command -v rsync >/dev/null 2>&1; then
        echo "[error] rsync is not installed" >&2
        return 1
    fi
    return 0
}

# 同期元ディレクトリの存在確認
# 引数: $1=ターゲット名
# 戻り値: 0=存在, 1=不存在
validate_source() {
    local target="$1"
    local source_path="${SOURCE_DIR}${target}/"
    [[ -d "$source_path" ]]
}

# 単一ターゲットの同期を実行
# 引数: $1=ターゲット名
# 戻り値: 0=成功, 1=失敗
sync_target() {
    local target="$1"
    local source_path="${SOURCE_DIR}${target}/"
    local dest_path="${DEST_DIR}${target}/"
    local rsync_opts=("-a" "--delete" "-v")

    # 同期元存在確認
    if ! validate_source "$target"; then
        echo "sync:${target}:skipped"
        return 0
    fi

    # 同期先ディレクトリ作成（dry-runでも作成して rsync -n が正常動作するようにする）
    mkdir -p "$dest_path"

    # dry-runモード: rsync -n で実行予定を表示
    if [[ "$DRY_RUN" == "true" ]]; then
        rsync_opts+=("-n")
        local error_output
        if error_output=$(rsync "${rsync_opts[@]}" "$source_path" "$dest_path" 2>&1); then
            echo "sync:${target}:would-sync"
            return 0
        else
            echo "[error] ${target}: ${error_output}" >&2
            echo "sync:${target}:error"
            return 1
        fi
    fi

    # rsync実行
    local error_output
    if error_output=$(rsync "${rsync_opts[@]}" "$source_path" "$dest_path" 2>&1); then
        echo "sync:${target}:synced"
        return 0
    else
        echo "[error] ${target}: ${error_output}" >&2
        echo "sync:${target}:error"
        return 1
    fi
}

# ターゲットが--onlyリストに含まれるかチェック
# 引数: $1=ターゲット名
# 戻り値: 0=含まれる（または--only未指定）, 1=含まれない
is_target_selected() {
    local target="$1"

    # --only未指定の場合は全ターゲット対象
    if [[ ${#ONLY_TARGETS[@]} -eq 0 ]]; then
        return 0
    fi

    # 配列に含まれるかチェック
    for selected in "${ONLY_TARGETS[@]}"; do
        if [[ "$selected" == "$target" ]]; then
            return 0
        fi
    done
    return 1
}

# ターゲットが有効かチェック
# 引数: $1=ターゲット名
# 戻り値: 0=有効, 1=無効
is_valid_target() {
    local target="$1"
    for valid in "${SYNC_TARGETS[@]}"; do
        if [[ "$valid" == "$target" ]]; then
            return 0
        fi
    done
    return 1
}

# --onlyで指定されたターゲットをバリデート
# 戻り値: 0=全て有効, 1=無効なターゲットあり
validate_only_targets() {
    if [[ ${#ONLY_TARGETS[@]} -eq 0 ]]; then
        return 0
    fi

    local invalid_targets=()
    for target in "${ONLY_TARGETS[@]}"; do
        if ! is_valid_target "$target"; then
            invalid_targets+=("$target")
        fi
    done

    if [[ ${#invalid_targets[@]} -gt 0 ]]; then
        echo "[error] Invalid target(s): ${invalid_targets[*]}" >&2
        echo "[error] Valid targets are: ${SYNC_TARGETS[*]}" >&2
        return 1
    fi
    return 0
}

# コマンドライン引数を解析
# グローバル変数 DEST_DIR, ONLY_TARGETS, DRY_RUN を設定
parse_args() {
    # デフォルト値設定
    DEST_DIR="$DEFAULT_DEST"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --dest)
                if [[ $# -lt 2 ]]; then
                    echo "[error] --dest requires a directory argument" >&2
                    exit 1
                fi
                DEST_DIR="$2"
                # 末尾スラッシュを確保
                [[ "$DEST_DIR" != */ ]] && DEST_DIR="${DEST_DIR}/"
                shift
                ;;
            --only)
                if [[ $# -lt 2 ]]; then
                    echo "[error] --only requires a comma-separated list of targets" >&2
                    exit 1
                fi
                IFS=',' read -ra ONLY_TARGETS <<< "$2"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            *)
                echo "[error] Unknown option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done
}

# メイン処理
main() {
    local error_count=0

    # 引数解析
    parse_args "$@"

    # rsync利用可否確認
    if ! check_rsync_available; then
        exit 1
    fi

    # --onlyターゲットのバリデーション
    if ! validate_only_targets; then
        exit 1
    fi

    # 各ターゲットを処理
    for target in "${SYNC_TARGETS[@]}"; do
        if is_target_selected "$target"; then
            if ! sync_target "$target"; then
                ((error_count++)) || true
            fi
        fi
    done

    # 終了コード決定
    if [[ $error_count -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
