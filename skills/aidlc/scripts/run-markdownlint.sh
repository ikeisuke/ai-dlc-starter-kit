#!/usr/bin/env bash
# markdownlint実行スクリプト（設定による制御付き）
# Usage: run-markdownlint.sh <cycle>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

CYCLE="${1:?Usage: run-markdownlint.sh <cycle>}"

# 設定取得: rules.linting.enabled（新キー優先、旧キーmarkdown_lintフォールバック）
LINT_ENABLED=""
LINT_COMMAND=""

# read-config.shで取得を試みる（dasel必須。未インストール時はフォールバック）
if LINT_ENABLED=$("${SCRIPT_DIR}/read-config.sh" rules.linting.enabled 2>/dev/null); then
    : # 新キーで取得成功
elif LINT_ENABLED=$("${SCRIPT_DIR}/read-config.sh" rules.linting.markdown_lint 2>/dev/null); then
    : # 旧キーフォールバック
else
    # read-config.sh失敗（dasel未インストール等）: config.tomlを直接読み取り
    if [ -f "${AIDLC_CONFIG}" ]; then
        LINT_ENABLED=$(awk '/^\[rules\.linting\]/{found=1; next} /^\[/{found=0} found && /^[ \t]*enabled[ \t]*=/{gsub(/.*=[ \t]*/, ""); gsub(/[ \t"'"'"']/, ""); print; exit}' "${AIDLC_CONFIG}" 2>/dev/null || echo "")
        if [ -z "$LINT_ENABLED" ]; then
            # 旧キーフォールバック
            LINT_ENABLED=$(awk '/^\[rules\.linting\]/{found=1; next} /^\[/{found=0} found && /^[ \t]*markdown_lint[ \t]*=/{gsub(/.*=[ \t]*/, ""); gsub(/[ \t"'"'"']/, ""); print; exit}' "${AIDLC_CONFIG}" 2>/dev/null || echo "")
        fi
    fi
fi

[ -z "$LINT_ENABLED" ] && LINT_ENABLED="false"

if [ "$LINT_ENABLED" = "true" ]; then
    # コマンド取得
    LINT_COMMAND=$("${SCRIPT_DIR}/read-config.sh" rules.linting.command 2>/dev/null) || true
    [ -z "$LINT_COMMAND" ] && LINT_COMMAND="npx markdownlint-cli2"

    echo "markdownlintを実行中..." >&2
    # セキュリティ: evalを使用しない。コマンドはそのまま実行
    if $LINT_COMMAND "${AIDLC_CYCLES}/${CYCLE}/**/*.md" "prompts/**/*.md" "*.md"; then
        echo "markdownlint:success"
    else
        echo "markdownlint:error"
        exit 1
    fi
else
    echo "markdownlint:skipped"
fi
