#!/usr/bin/env bash
# markdownlint実行スクリプト（設定による制御付き）
# Usage: run-markdownlint.sh <cycle>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

CYCLE="${1:?Usage: run-markdownlint.sh <cycle>}"

# 設定確認（デフォルト: false = スキップ）
# dasel利用可能時はdaselで読み取り、なければgrepで直接読み取る
if command -v dasel >/dev/null 2>&1; then
    MARKDOWN_LINT=$(cat "${AIDLC_CONFIG}" 2>/dev/null | dasel -i toml 'rules.linting.markdown_lint' 2>/dev/null | tr -d "'" || echo "false")
else
    # dasel未インストール時: awkでセクション内のキー=値行のみ抽出
    MARKDOWN_LINT=$(awk '/^\[rules\.linting\]/{found=1; next} /^\[/{found=0} found && /^[ \t]*markdown_lint[ \t]*=/{gsub(/.*=[ \t]*/, ""); gsub(/[ \t"'"'"']/, ""); print; exit}' "${AIDLC_CONFIG}" 2>/dev/null || echo "false")
fi

# 空の場合はデフォルト値を設定
[ -z "$MARKDOWN_LINT" ] && MARKDOWN_LINT="false"

if [ "$MARKDOWN_LINT" = "true" ]; then
    echo "markdownlintを実行中..."
    if npx markdownlint-cli2 "${AIDLC_CYCLES}/${CYCLE}/**/*.md" "prompts/**/*.md" "*.md"; then
        echo "markdownlint:success"
    else
        echo "markdownlint:error"
        exit 1
    fi
else
    echo "markdownlint:skipped"
fi
