#!/usr/bin/env bash
#
# check-utf8-corruption.sh - PostToolUse hook for Write tool
#
# Detects U+FFFD (replacement character) in written files.
# Warns on stderr but never blocks the write (always exits 0).
#
# Usage: Called as a PostToolUse hook with JSON on stdin.
#   { "tool_name": "Write", "tool_input": { "file_path": "..." }, ... }

set -euo pipefail

# Check required commands
for cmd in jq file grep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "⚠ check-utf8-corruption: $cmd が見つかりません。hookが動作不能です。" >&2
        exit 0
    fi
done

# Read hook input from stdin
input="$(cat)"

# Extract tool_name - skip if not Write
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" || {
    echo "⚠ check-utf8-corruption: JSON解析に失敗しました。hookが動作不能です。" >&2
    exit 0
}
if [ "$tool_name" != "Write" ]; then
    exit 0
fi

# Extract file path
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)" || true
if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    exit 0
fi

# Skip large files (>1MB) to avoid performance impact
MAX_SIZE=1048576
file_size="$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null)" || true
if [ "${file_size:-0}" -gt "$MAX_SIZE" ]; then
    exit 0
fi

# Skip binary files
file_type="$(file -b --mime-type "$file_path" 2>/dev/null)" || true
case "$file_type" in
    text/*|application/json|application/xml|application/javascript)
        # Text-like files: proceed with check
        ;;
    *)
        # Binary or unknown: skip
        exit 0
        ;;
esac

# Detect U+FFFD (UTF-8 bytes: EF BF BD)
count="$(LC_ALL=C grep -c $'\xef\xbf\xbd' "$file_path" 2>/dev/null)" || true
if [ "${count:-0}" -gt 0 ]; then
    echo "⚠ UTF-8文字化け検出: $file_path に U+FFFD（置換文字）が ${count} 行見つかりました。文字化けの可能性があります。" >&2
fi

exit 0
