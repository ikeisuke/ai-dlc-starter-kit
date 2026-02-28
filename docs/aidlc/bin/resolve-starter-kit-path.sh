#!/usr/bin/env bash
#
# resolve-starter-kit-path.sh - スターターキットのルートパスを解決
#
# 使用方法:
#   ./resolve-starter-kit-path.sh [OPTIONS]
#
# OPTIONS:
#   -h, --help    ヘルプを表示
#
# 出力形式（stdout）:
#   path:<パス>
#   mode:<META_DEV|GHQ|MANUAL_REQUIRED>
#
# 終了コード:
#   0: パス解決成功
#   1: パス解決失敗（手動入力が必要）
#

set -euo pipefail

show_help() {
    cat << 'EOF'
Usage: resolve-starter-kit-path.sh [OPTIONS]

スターターキット（ai-dlc-starter-kit）のルートパスを自動解決します。

判定順序:
  1. メタ開発モード: prompts/package/ が存在 → カレントディレクトリ
  2. ghq: ghq root から標準パスを構築
  3. 手動: 上記いずれも失敗 → 終了コード1

OPTIONS:
  -h, --help    このヘルプを表示

出力形式（stdout）:
  path:<パス>
  mode:<META_DEV|GHQ|MANUAL_REQUIRED>
EOF
}

# 引数解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: unknown option: $1" >&2
            exit 2
            ;;
    esac
done

# 1. メタ開発モード判定
if [[ -d "prompts/package" ]]; then
    echo "path:."
    echo "mode:META_DEV"
    exit 0
fi

# 2. ghq判定
if command -v ghq >/dev/null 2>&1; then
    ghq_root=$(ghq root)
    starter_kit_path="${ghq_root}/github.com/ikeisuke/ai-dlc-starter-kit"
    if [[ -d "${starter_kit_path}/prompts/package" ]]; then
        echo "path:${starter_kit_path}"
        echo "mode:GHQ"
        exit 0
    fi
fi

# 3. 手動入力が必要
echo "path:"
echo "mode:MANUAL_REQUIRED"
echo "スターターキットのパスを自動解決できませんでした。" >&2
echo "スターターキットの絶対パスを手動で指定してください。" >&2
echo "例: /path/to/ai-dlc-starter-kit" >&2
exit 1
