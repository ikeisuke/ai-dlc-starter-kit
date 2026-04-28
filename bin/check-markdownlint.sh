#!/usr/bin/env bash
#
# check-markdownlint.sh - PostToolUse hook for Edit/Write tools
#
# Runs markdownlint-cli2 on edited .md files and emits warnings to stderr.
# Always exits 0 (warn-only, never blocks edits).
#
# Usage: Called as a PostToolUse hook with JSON on stdin.
#   { "tool_name": "Edit"|"Write", "tool_input": { "file_path": "..." }, ... }

set -euo pipefail

# Check jq availability (required for JSON parsing)
if ! command -v jq >/dev/null 2>&1; then
    echo "⚠ check-markdownlint: jq が見つかりません。hookが動作不能です。" >&2
    exit 0
fi

# Read hook input from stdin
input="$(cat)"

# Extract tool_name - skip if not Edit or Write.
# JSON parse failure is treated as hook malfunction (style aligned with check-utf8-corruption.sh).
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" || {
    echo "⚠ check-markdownlint: JSON解析に失敗しました。hookが動作不能です。" >&2
    exit 0
}
case "$tool_name" in
    Edit|Write) ;;
    *) exit 0 ;;
esac

# Extract file path; same JSON-parse warning policy as above.
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)" || {
    echo "⚠ check-markdownlint: JSON解析に失敗しました。hookが動作不能です。" >&2
    exit 0
}
if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    exit 0
fi

# Skip non-Markdown files (extension check)
case "$file_path" in
    *.md) ;;
    *) exit 0 ;;
esac

# Skip large files (>1MB) to avoid performance impact
MAX_SIZE=1048576
file_size="$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null)" || true
if [ "${file_size:-0}" -gt "$MAX_SIZE" ]; then
    exit 0
fi

# Resolve markdownlint-cli2 invocation:
#   1. Direct binary (preferred, faster)
#   2. Fallback to `npx --no-install markdownlint-cli2` (project default per
#      skills/aidlc/config/defaults.toml: `command = "npx markdownlint-cli2"`)
#   3. Skip silently if neither is available (optional tool, safe-skip)
if command -v markdownlint-cli2 >/dev/null 2>&1; then
    markdownlint-cli2 "$file_path" >&2 || true
elif command -v npx >/dev/null 2>&1 && npx --no-install markdownlint-cli2 --version >/dev/null 2>&1; then
    npx --no-install markdownlint-cli2 "$file_path" >&2 || true
fi

exit 0
