#!/bin/bash
# AI-DLC Session Title Script (macOS only)
# Sets terminal tab title and iTerm2 badge for session identification.
# Uses osascript (Apple Events) - requires macOS.
# On non-macOS, silently exits 0.
# Usage: aidlc-session-title.sh <project_name> <cycle> <phase> [unit]
# Always exits 0 (non-blocking).

# macOS check
if [ "$(uname -s)" != "Darwin" ]; then
  exit 0
fi

PROJECT_NAME="${1:-}"
CYCLE="${2:-}"
PHASE="${3:-}"
UNIT="${4:-}"

if [ -z "$PROJECT_NAME" ] || [ -z "$PHASE" ]; then
  exit 0
fi

# Sanitize inputs: strip control characters (0x00-0x1F, 0x7F)
PROJECT_NAME=$(printf '%s' "$PROJECT_NAME" | tr -d '\000-\037\177')
CYCLE=$(printf '%s' "$CYCLE" | tr -d '\000-\037\177')
PHASE=$(printf '%s' "$PHASE" | tr -d '\000-\037\177')
UNIT=$(printf '%s' "$UNIT" | tr -d '\000-\037\177')

# Build title: project / [cycle /] phase [/ unit]
TITLE="$PROJECT_NAME"
[ -n "$CYCLE" ] && TITLE="$TITLE / $CYCLE"
TITLE="$TITLE / $PHASE"
[ -n "$UNIT" ] && TITLE="$TITLE / $UNIT"

# --- Find parent TTY device ---
get_parent_tty() {
  local pid=$$
  while [ "$pid" -gt 1 ]; do
    local tty_name
    tty_name=$(ps -p "$pid" -o tty= 2>/dev/null | tr -d ' ')
    if [ -n "$tty_name" ] && [ "$tty_name" != "??" ]; then
      echo "/dev/$tty_name"
      return 0
    fi
    pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
    [ -z "$pid" ] && break
  done
  return 1
}

# --- Set title based on terminal ---
case "${TERM_PROGRAM:-}" in
  iTerm.app)
    # Tab title via osascript (on run argv to prevent injection)
    osascript - "$TITLE" <<'APPLESCRIPT' 2>/dev/null
on run argv
  tell application "iTerm2"
    tell current session of current tab of current window
      set name to item 1 of argv
    end tell
  end tell
end run
APPLESCRIPT

    # Badge via iTerm2 escape sequence to parent TTY
    PARENT_TTY=$(get_parent_tty)
    if [ -n "$PARENT_TTY" ] && [ -w "$PARENT_TTY" ]; then
      BADGE=$(printf '%s' "$TITLE" | base64 | tr -d '\r\n')
      printf "\033]1337;SetBadgeFormat=%s\007" "$BADGE" > "$PARENT_TTY" 2>/dev/null
    fi
    ;;
  Apple_Terminal)
    # Tab title via osascript (on run argv to prevent injection)
    osascript - "$TITLE" <<'APPLESCRIPT' 2>/dev/null
on run argv
  tell application "Terminal"
    set custom title of front window to item 1 of argv
  end tell
end run
APPLESCRIPT
    ;;
  *)
    # Fallback: write escape sequence to parent TTY
    PARENT_TTY=$(get_parent_tty)
    if [ -n "$PARENT_TTY" ] && [ -w "$PARENT_TTY" ]; then
      printf '\033]0;%s\007' "$TITLE" > "$PARENT_TTY" 2>/dev/null
    fi
    ;;
esac

exit 0
