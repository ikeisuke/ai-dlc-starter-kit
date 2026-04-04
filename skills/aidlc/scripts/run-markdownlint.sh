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

# 設定取得: 新キー rules.linting.enabled を優先、config.tomlに未定義なら旧キーフォールバック
# defaults.tomlに enabled=false が定義されているため、read-config.shは常に成功する。
# そのため、config.tomlに新キーが明示定義されているかを先に確認し、
# 未定義の��合のみ旧キー markdown_lint をフォールバックとして読み取る。
if "${SCRIPT_DIR}/read-config.sh" rules.linting.enabled 2>/dev/null | grep -qE '^(true|false)$'; then
    # config.toml（またはdefaults.toml）に新キーが存在
    # 旧キーが config.toml に明示定義されているかチェック
    OLD_KEY_VAL=$("${SCRIPT_DIR}/read-config.sh" rules.linting.markdown_lint 2>/dev/null) || true
    NEW_KEY_IN_CONFIG=$(awk '/^\[rules\.linting\]/{found=1; next} /^\[/{found=0} found && /^[ \t]*enabled[ \t]*=/{print "yes"; exit}' "${AIDLC_CONFIG}" 2>/dev/null || echo "")
    if [ -z "$NEW_KEY_IN_CONFIG" ] && [ -n "$OLD_KEY_VAL" ]; then
        # config.tomlに新キー未定義だが旧キーあり → 旧キー優先
        LINT_ENABLED="$OLD_KEY_VAL"
    else
        LINT_ENABLED=$("${SCRIPT_DIR}/read-config.sh" rules.linting.enabled 2>/dev/null) || true
    fi
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
    # コマンド取得（read-config.sh → config.toml直接読み取りフォールバック）
    LINT_COMMAND=$("${SCRIPT_DIR}/read-config.sh" rules.linting.command 2>/dev/null) || true
    if [ -z "$LINT_COMMAND" ] && [ -f "${AIDLC_CONFIG}" ]; then
        # no-daselフォールバック: config.tomlから直接読み取り
        LINT_COMMAND=$(awk '/^\[rules\.linting\]/{found=1; next} /^\[/{found=0} found && /^[ \t]*command[ \t]*=/{gsub(/.*=[ \t]*/, ""); gsub(/^[ \t"'"'"']+/, ""); gsub(/[ \t"'"'"']+$/, ""); print; exit}' "${AIDLC_CONFIG}" 2>/dev/null || echo "")
    fi
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
