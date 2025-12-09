#!/bin/bash
# Wait for KSP to be ready by monitoring Player.log
# Usage: ./wait-for-ksp-ready.sh [timeout] [pattern]
# Returns 0 if pattern found, 1 if timeout or error
#
# Optimized for speed:
# - Checks if KSP already ready FIRST (instant return)
# - No hardcoded sleep delays
# - Event-driven log watching with timeout
#
# Examples:
#   ./wait-for-ksp-ready.sh                              # Wait for flight scene
#   ./wait-for-ksp-ready.sh 300 "MAINMENU"               # Wait for main menu
#   ./wait-for-ksp-ready.sh 60 "SPACECENTER\|FLIGHT"     # Wait for save loaded

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

TIMEOUT=${1:-300}  # Default 5 minutes
PATTERN=${2:-"to FLIGHT"}  # Default: transition to FLIGHT scene
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

# FAST PATH: Check if pattern already exists in recent log
# This handles the case where KSP is already running and ready
if tail -500 "$LOG_FILE" 2>/dev/null | grep -q "$PATTERN"; then
    echo "✓ Pattern found in recent log! KSP is already ready."
    exit 0
fi

# Not ready yet - watch for the pattern
echo "Watching Player.log for pattern: \"$PATTERN\" (timeout: ${TIMEOUT}s)..."

# Use tail -F to follow log, grep -m 1 exits on first match
# timeout kills tail if pattern not found within limit
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
