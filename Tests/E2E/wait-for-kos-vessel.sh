#!/bin/bash
# Wait for kOS vessel initialization after save load
# Usage: ./wait-for-kos-vessel.sh [max_wait_seconds] [start_line]
#
# This script watches the KSP Player.log for the kOS initialization
# pattern that indicates a vessel with kOS parts has loaded and is ready.
#
# The pattern "kOS: OnStart:.*READY" appears when kOS completes its
# initialization on a vessel, which happens after a save loads.
#
# If start_line is provided, only checks for pattern AFTER that line
# (used after reload to ignore old initializations).
#
# Requires: PLAYER_LOG environment variable (set by config.sh)

MAX_WAIT=${1:-60}  # Default 60 seconds
START_LINE=${2:-0}  # Line to start searching from (0 = check recent logs too)

# Source config if not already sourced
SCRIPT_DIR="${SCRIPT_DIR:-$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )}"
if [ -z "$PLAYER_LOG" ]; then
    source "$SCRIPT_DIR/config.sh"
fi

PATTERN="kOS: OnStart:.*READY"

# If no start line provided, check recent logs (fast path for fresh starts)
if [ "$START_LINE" -eq 0 ]; then
    if tail -500 "$PLAYER_LOG" 2>/dev/null | grep -q "$PATTERN"; then
        echo "✓ kOS vessel already initialized"
        exit 0
    fi
fi

# Watch for new initialization using polling (more reliable than tail -F with timeout)
echo "Waiting for kOS vessel initialization (max ${MAX_WAIT}s)..."

ELAPSED=0
POLL_INTERVAL=2
while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Check for pattern after START_LINE
    if [ "$START_LINE" -gt 0 ]; then
        # Only check lines after START_LINE
        if tail -n +"$START_LINE" "$PLAYER_LOG" 2>/dev/null | grep -q "$PATTERN"; then
            echo "✓ kOS vessel initialized (${ELAPSED}s)"
            exit 0
        fi
    else
        # Check recent logs
        if tail -500 "$PLAYER_LOG" 2>/dev/null | grep -q "$PATTERN"; then
            echo "✓ kOS vessel initialized (${ELAPSED}s)"
            exit 0
        fi
    fi

    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))

    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s elapsed)"
    fi
done

echo "✗ kOS vessel did not initialize in ${MAX_WAIT}s"
exit 1
