#!/bin/bash
# Wait for KSP to be ready by monitoring Player.log
# Usage: ./wait-for-ksp-ready.sh [timeout] [pattern]
# Returns 0 if pattern found, 1 if timeout or error
#
# Examples:
#   ./wait-for-ksp-ready.sh                              # Wait for main menu (default)
#   ./wait-for-ksp-ready.sh 300 "MAINMENU"               # Wait for main menu with 5min timeout
#   ./wait-for-ksp-ready.sh 60 "SPACECENTER\|FLIGHT"     # Wait for save loaded

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

TIMEOUT=${1:-300}  # Default 5 minutes
PATTERN=${2:-"to FLIGHT"}  # Default: any transition to FLIGHT scene (AutoLoad: MAINMENU→FLIGHT)
LOG_FILE="$PLAYER_LOG"

# Wait for log file to exist (KSP might not have started yet)
WAIT_FOR_LOG=30
while [ ! -f "$LOG_FILE" ] && [ $WAIT_FOR_LOG -gt 0 ]; do
    sleep 1
    WAIT_FOR_LOG=$((WAIT_FOR_LOG - 1))
done

if [ ! -f "$LOG_FILE" ]; then
    echo "✗ Player.log never created - KSP didn't start?"
    exit 1
fi

# Wait at least 20 seconds for KSP to load before checking
# (KSP takes longer than this, but we'll check periodically)
echo "Waiting 20 seconds for KSP initial load..."
sleep 20

echo "Watching Player.log for pattern: \"$PATTERN\" (timeout: ${TIMEOUT}s)..."

# First check if pattern already exists in recent log (last 500 lines)
# This handles the case where KSP is already running
if tail -500 "$LOG_FILE" 2>/dev/null | grep -q "$PATTERN"; then
    echo "✓ Pattern found in recent log! KSP is already ready."
    exit 0
fi

# Pattern not in recent log, watch for new occurrences
# Use -F (capital) to follow by name, handles log rotation
# grep -m 1 exits after first match
# timeout (gtimeout on macOS, timeout on Linux) kills tail if pattern not found
if [ -z "$TIMEOUT_CMD" ]; then
    echo "  ⚠️  No timeout command found, watching indefinitely..."
    if tail -F "$LOG_FILE" 2>/dev/null | grep -q -m 1 "$PATTERN"; then
        echo "✓ Pattern found! KSP is ready."
        exit 0
    fi
    exit 1
fi
if "$TIMEOUT_CMD" "$TIMEOUT" tail -F "$LOG_FILE" 2>/dev/null | grep -q -m 1 "$PATTERN"; then
    echo "✓ Pattern found! KSP is ready."
    exit 0
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo "✗ Timeout: Pattern not found within ${TIMEOUT} seconds"
    else
        echo "✗ Unexpected error (exit code: $EXIT_CODE)"
    fi
    exit 1
fi
