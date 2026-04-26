#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

marketplace_exists() {
  local name="$1"
  claude plugin marketplace list 2>/dev/null | grep -Fq "$name"
}

plugin_installed() {
  local name="$1"
  claude plugin list --json 2>/dev/null \
    | grep -Fq "\"name\": \"$name\""
}

if ! marketplace_exists "ai-dlc-starter-kit"; then
  claude plugin marketplace add "$PROJECT_DIR" --scope user
fi

if ! marketplace_exists "ikeisuke-skills"; then
  claude plugin marketplace add ikeisuke/claude-skills --scope user
fi

if ! plugin_installed "aidlc"; then
  claude plugin install aidlc@ai-dlc-starter-kit --scope user
fi

if ! plugin_installed "tools"; then
  claude plugin install tools@ikeisuke-skills --scope user
fi

if ! command -v bats >/dev/null 2>&1; then
  npm install -g bats@1.11.1
fi

if ! command -v markdownlint-cli2 >/dev/null 2>&1; then
  npm install -g markdownlint-cli2
fi

echo "session-start hook completed"
