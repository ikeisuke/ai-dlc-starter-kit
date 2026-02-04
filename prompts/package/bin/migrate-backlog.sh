#!/usr/bin/env bash
# migrate-backlog.sh - 旧形式バックログの移行
#
# 使用方法:
#   migrate-backlog.sh [--dry-run] [--no-delete]
#
# オプション:
#   --dry-run: 実際の変更を行わず、移行予定の内容を表示
#   --no-delete: 移行後も元ファイルを削除しない
#
# 出力形式:
#   status:migrated|dry_run|no_file|error
#   migrated_count:3
#   skipped_completed:1
#   skipped_duplicate:0
#   deleted:true|false

set -euo pipefail

# 定数
OLD_BACKLOG="docs/cycles/backlog.md"
NEW_BACKLOG_DIR="docs/cycles/backlog"

# オプション
DRY_RUN=false
NO_DELETE=false

# 使用方法を表示
usage() {
    echo "使用方法: $0 [--dry-run] [--no-delete]"
    echo "  --dry-run: 実際の変更を行わず、移行予定の内容を表示"
    echo "  --no-delete: 移行後も元ファイルを削除しない"
    exit 1
}

# 出力ヘルパー
output() {
    local status="$1"
    local migrated="${2:-0}"
    local skipped_completed="${3:-0}"
    local skipped_duplicate="${4:-0}"
    local deleted="${5:-false}"
    local message="${6:-}"

    echo "status:${status}"
    echo "migrated_count:${migrated}"
    echo "skipped_completed:${skipped_completed}"
    echo "skipped_duplicate:${skipped_duplicate}"
    echo "deleted:${deleted}"
    if [[ -n "$message" ]]; then
        echo "message:${message}"
    fi
}

# スラッグ生成
generate_slug() {
    local title="$1"
    echo "$title" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g' | \
        tr ' ' '-' | \
        sed 's/--*/-/g' | \
        sed 's/^-//;s/-$//' | \
        cut -c1-50
}

# セクションからプレフィックスを決定
get_prefix_from_section() {
    local section="$1"
    case "$section" in
        *延期*)
            echo "deferred"
            ;;
        *技術的負債*|*修正*)
            echo "chore"
            ;;
        *次サイクル*|*検討*)
            echo "feature"
            ;;
        *低優先度*)
            echo "feature"
            ;;
        *)
            echo "feature"
            ;;
    esac
}

# メイン処理
main() {
    # オプション解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-delete)
                NO_DELETE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "不明なオプション: $1" >&2
                usage
                ;;
        esac
    done

    # ファイル存在確認
    if [[ ! -f "$OLD_BACKLOG" ]]; then
        output "no_file" 0 0 0 "false" "旧形式バックログが存在しません"
        return 0
    fi

    # 新形式ディレクトリ作成
    if [[ "$DRY_RUN" == "false" ]]; then
        mkdir -p "$NEW_BACKLOG_DIR"
    fi

    # カウンター変数（process_itemからアクセスするためグローバル）
    migrated_count=0
    skipped_completed=0
    skipped_duplicate=0
    error_count=0
    # パーサー状態（ローカル）
    local current_section=""
    local in_item=false
    local item_title=""
    local item_content=""

    # ファイルを解析
    while IFS= read -r line || [[ -n "$line" ]]; do
        # セクションヘッダー（## で始まる）
        if [[ "$line" =~ ^##[^#] ]]; then
            # 前のアイテムを処理（セクション変更前にフラッシュ）
            if [[ -n "$item_title" ]]; then
                if ! process_item "$item_title" "$item_content" "$current_section"; then
                    (( ++error_count ))
                fi
                item_title=""
                item_content=""
                in_item=false
            fi
            current_section="$line"
            continue
        fi

        # アイテムヘッダー（### で始まる）
        if [[ "$line" =~ ^###[^#] ]]; then
            # 前のアイテムを処理
            if [[ -n "$item_title" ]]; then
                if ! process_item "$item_title" "$item_content" "$current_section"; then
                    (( ++error_count ))
                fi
            fi

            item_title="${line#\#\#\# }"
            item_content=""
            in_item=true
            continue
        fi

        # アイテム内容
        if [[ "$in_item" == "true" ]]; then
            item_content+="$line"$'\n'
        fi
    done < "$OLD_BACKLOG"

    # 最後のアイテムを処理
    if [[ -n "$item_title" ]]; then
        if ! process_item "$item_title" "$item_content" "$current_section"; then
            ((error_count++))
        fi
    fi

    # エラーがあった場合
    if [[ "$error_count" -gt 0 ]]; then
        output "error" "$migrated_count" "$skipped_completed" "$skipped_duplicate" "false" "移行中に${error_count}件のエラーが発生しました"
        return 1
    fi

    # dry-runの場合
    if [[ "$DRY_RUN" == "true" ]]; then
        output "dry_run" "$migrated_count" "$skipped_completed" "$skipped_duplicate" "false"
        return 0
    fi

    # 削除処理
    local deleted="false"
    if [[ "$NO_DELETE" == "false" ]]; then
        \rm -f "$OLD_BACKLOG"
        deleted="true"
    fi

    output "migrated" "$migrated_count" "$skipped_completed" "$skipped_duplicate" "$deleted"
}

# アイテムを処理
process_item() {
    local title="$1"
    local content="$2"
    local section="$3"

    # 完了済みチェック（タイトルに取消線または明確な完了マーク）
    # 注意: 「完了」単独ではなく「対応完了」「完了済み」など明確なパターンのみマッチ
    #       「未完了」「完了条件」などの誤マッチを防止
    if [[ "$title" =~ ~~.*~~ ]] || [[ "$title" =~ 対応済み ]] || [[ "$title" =~ 対応完了 ]] || [[ "$title" =~ 完了済み ]]; then
        (( ++skipped_completed ))
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[スキップ:完了済み] $title"
        fi
        return 0
    fi

    # ファイル名生成
    local prefix
    prefix=$(get_prefix_from_section "$section")
    local slug
    slug=$(generate_slug "$title")

    # 空slugのガード
    if [[ -z "$slug" ]]; then
        echo "[エラー] スラッグ生成失敗: $title" >&2
        return 1
    fi

    local filename="${prefix}-${slug}.md"
    local filepath="${NEW_BACKLOG_DIR}/${filename}"

    # 重複チェック
    if [[ -f "$filepath" ]]; then
        (( ++skipped_duplicate ))
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[スキップ:重複] $title -> $filename"
        fi
        return 0
    fi

    # 新形式ファイル作成
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[移行予定] $title -> $filename"
    else
        cat > "$filepath" << EOF
# ${title}

- **発見日**: 不明
- **発見フェーズ**: 不明
- **発見サイクル**: 不明
- **優先度**: 中

## 概要

${content}

## 詳細

（旧形式から移行）

## 対応案

（要検討）
EOF
    fi

    (( ++migrated_count ))
}

main "$@"
