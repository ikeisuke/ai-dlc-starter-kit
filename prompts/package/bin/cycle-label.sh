#!/usr/bin/env bash
#
# cycle-label.sh - サイクルラベルの確認と作成
#
# 使用方法:
#   ./cycle-label.sh <version>
#
# ARGUMENTS:
#   version     サイクルバージョン（例: v1.8.0）
#
# OPTIONS:
#   -h, --help    ヘルプを表示
#
# 出力形式（stdout）:
#   label:cycle:<version>:<状態>
#   - created: 新規作成
#   - exists: 既存（スキップ）
#   - error: 作成失敗（詳細はstderrへ）
#

set -euo pipefail

# ラベル属性
LABEL_COLOR="7057FF"

# ヘルプメッセージを表示
show_help() {
    cat << 'EOF'
Usage: cycle-label.sh <version>

サイクルラベル（cycle:<version>）の確認と作成を行います。

ARGUMENTS:
  version     サイクルバージョン（例: v1.8.0）

OPTIONS:
  -h, --help    このヘルプを表示

出力形式（stdout）:
  label:cycle:<version>:<状態>

状態:
  created       - 新規作成
  exists        - 既存（スキップ）
  error         - 作成失敗（詳細はstderrへ）

例:
  $ cycle-label.sh v1.8.0
  label:cycle:v1.8.0:created

  $ cycle-label.sh v1.8.0
  label:cycle:v1.8.0:exists
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
    if ! gh label list --limit 1000 --json name -q '.[].name'; then
        echo "error:label-list-failed" >&2
        return 1
    fi
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
    local version=""

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                if [[ -z "$version" ]]; then
                    version="$1"
                else
                    echo "Error: Too many arguments" >&2
                    exit 1
                fi
                ;;
        esac
        shift
    done

    # バージョン引数の存在確認
    if [[ -z "$version" ]]; then
        echo "error:missing-version" >&2
        exit 1
    fi

    # ラベル名を生成
    local label_name="cycle:${version}"
    local label_description="サイクル ${version}"

    # gh CLI利用可否確認
    if ! check_gh_available; then
        exit 1
    fi

    # 既存ラベル一覧を一括取得
    local existing_labels
    if ! existing_labels=$(get_existing_labels); then
        exit 1
    fi

    # ラベルの存在確認と作成
    if label_exists "$label_name" "$existing_labels"; then
        echo "label:${label_name}:exists"
    else
        if create_label "$label_name" "$LABEL_COLOR" "$label_description"; then
            echo "label:${label_name}:created"
        else
            echo "label:${label_name}:error"
            exit 2
        fi
    fi

    exit 0
}

main "$@"
