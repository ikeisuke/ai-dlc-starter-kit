#!/usr/bin/env bash
#
# init-labels.sh - バックログ管理用の共通ラベルを一括作成
#
# 使用方法:
#   ./init-labels.sh [OPTIONS]
#
# OPTIONS:
#   -h, --help    ヘルプを表示
#   --dry-run     実際に作成せず、作成予定のラベルを表示
#
# 出力形式（stdout）:
#   label:<ラベル名>:<状態>
#   - created: 新規作成
#   - exists: 既存（スキップ）
#   - would-create: 作成予定（--dry-runモード）
#   - error: 作成失敗（詳細はstderrへ）
#

set -euo pipefail

# ラベル定義（name|color|description）
LABELS=(
    "backlog|0052CC|バックログアイテム"
    "type:feature|A2EEEF|新機能"
    "type:bugfix|D73A4A|バグ修正"
    "type:chore|FEF2C0|雑務"
    "type:refactor|C5DEF5|リファクタリング"
    "type:docs|0075CA|ドキュメント"
    "type:perf|F9D0C4|パフォーマンス"
    "type:security|D93F0B|セキュリティ"
    "priority:high|B60205|優先度: 高"
    "priority:medium|FBCA04|優先度: 中"
    "priority:low|0E8A16|優先度: 低"
)

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: init-labels.sh [OPTIONS]

バックログ管理用の共通ラベル（11個）を一括作成します。

OPTIONS:
  -h, --help    このヘルプを表示
  --dry-run     実際に作成せず、作成予定のラベルを表示

出力形式（stdout）:
  label:<ラベル名>:<状態>

状態:
  created       - 新規作成
  exists        - 既存（スキップ）
  would-create  - 作成予定（--dry-runモード）
  error         - 作成失敗（詳細はstderrへ）

例:
  $ init-labels.sh
  label:backlog:created
  label:type:feature:exists
  ...

  $ init-labels.sh --dry-run
  label:backlog:would-create
  label:type:feature:exists
  ...
EOF
}

# gh CLIが利用可能かチェック
# 戻り値: 0=利用可能, 1=利用不可
check_gh_available() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "error:gh-not-installed" >&2
        return 1
    fi
    if ! gh auth status >/dev/null 2>&1; then
        echo "error:gh-not-authenticated" >&2
        return 1
    fi
    return 0
}

# 既存ラベル一覧を取得
# 出力: 改行区切りのラベル名一覧
# 戻り値: 0=成功, 1=失敗
get_existing_labels() {
    gh label list --json name -q '.[].name'
}

# ラベルが存在するかチェック
# 引数: $1=ラベル名, $2=既存ラベル一覧（改行区切り）
# 戻り値: 0=存在する, 1=存在しない
label_exists() {
    local label_name="$1"
    local existing_labels="$2"

    # 完全一致で確認（--でオプション解釈を防止）
    echo "$existing_labels" | grep -Fxq -- "$label_name"
}

# ラベルを作成
# 引数: $1=ラベル名, $2=色, $3=説明
# 戻り値: 0=成功, 1=失敗
# 注: ghのエラーメッセージはstderrに出力される
create_label() {
    local name="$1"
    local color="$2"
    local description="$3"
    local error_output

    # ghの成功メッセージ（stdout）は抑制、エラー（stderr）はキャプチャ
    # リダイレクト順序: まずstdoutを/dev/nullに、次にstderrをstdout(キャプチャ対象)に
    if error_output=$(gh label create "$name" --color "$color" --description "$description" 2>&1 1>/dev/null); then
        return 0
    else
        echo "[error] ${name}: ${error_output}" >&2
        return 1
    fi
}

# メイン処理
main() {
    local dry_run=false
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
            *)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done

    # gh CLI利用可否確認
    if ! check_gh_available; then
        exit 1
    fi

    # 既存ラベル一覧を一括取得
    local existing_labels
    if ! existing_labels=$(get_existing_labels); then
        echo "error:label-list-failed" >&2
        exit 1
    fi

    # 各ラベルを処理
    for label_def in "${LABELS[@]}"; do
        # パイプ区切りで分割
        IFS='|' read -r name color description <<< "$label_def"

        if label_exists "$name" "$existing_labels"; then
            echo "label:${name}:exists"
        elif [[ "$dry_run" == "true" ]]; then
            echo "label:${name}:would-create"
        else
            if create_label "$name" "$color" "$description"; then
                echo "label:${name}:created"
            else
                echo "label:${name}:error"
                ((error_count++)) || true
            fi
        fi
    done

    # 終了コード決定
    if [[ $error_count -gt 0 ]]; then
        exit 2
    fi
    exit 0
}

main "$@"
