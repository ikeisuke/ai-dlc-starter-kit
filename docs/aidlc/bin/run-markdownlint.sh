#!/usr/bin/env bash
# markdownlint実行スクリプト（設定による制御付き）
# Usage: run-markdownlint.sh <cycle>

set -euo pipefail

CYCLE="${1:?Usage: run-markdownlint.sh <cycle>}"

# 設定確認（デフォルト: false = スキップ）
# dasel利用可能時はdaselで読み取り、なければgrepで直接読み取る
if command -v dasel >/dev/null 2>&1; then
    MARKDOWN_LINT=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'rules.linting.markdown_lint' 2>/dev/null | tr -d "'" || echo "false")
else
    # dasel未インストール時: awkでセクション内のキー=値行のみ抽出
    MARKDOWN_LINT=$(awk '/^\[rules\.linting\]/{found=1; next} /^\[/{found=0} found && /^[ \t]*markdown_lint[ \t]*=/{gsub(/.*=[ \t]*/, ""); gsub(/[ \t"'"'"']/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "false")
fi

# 空の場合はデフォルト値を設定
[ -z "$MARKDOWN_LINT" ] && MARKDOWN_LINT="false"

if [ "$MARKDOWN_LINT" = "true" ]; then
    echo "markdownlintを実行中..."
    npx markdownlint-cli2 "docs/cycles/${CYCLE}/**/*.md" "prompts/**/*.md" "*.md"
else
    echo "markdownlintはスキップされました（設定: markdown_lint=false）"
fi
