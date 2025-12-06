#!/bin/bash
# Wait for kOS to be initialized on a loaded vessel
# Usage: ./wait-for-kos-vessel.sh [timeout]
# Returns 0 if kOS ready, 1 if timeout or error
#
# Examples:
#   ./wait-for-kos-vessel.sh           # Wait up to 3 minutes (default)
#   ./wait-for-kos-vessel.sh 60        # Wait up to 1 minute

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

TIMEOUT=${1:-180}  # Default 3 minutes
PATTERN="kOS: OnStart:.*READY"
LOG_FILE="$KSP_LOG"
LOOKBACK_LINES=500  # Check last 500 lines for recent initialization

# Verify log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "✗ KSP.log not found at $LOG_FILE"
    echo "  Make sure KSP is running"
    exit 1
fi

echo "Checking for kOS vessel initialization (timeout: ${TIMEOUT}s)..."

# First check if kOS was recently initialized (last 100 lines)
if tail -n "$LOOKBACK_LINES" "$LOG_FILE" 2>/dev/null | grep -q "$PATTERN"; then
    echo "✓ kOS is ready on loaded vessel! (found in recent logs)"
    exit 0
fi

# Not found in recent logs, watch for new initialization
echo "  Not found in recent logs, watching for new initialization..."

# Use -F (capital) to follow by name, handles log rotation
# grep -m 1 exits after first match
# timeout (gtimeout on macOS, timeout on Linux) kills tail if pattern not found
if [ -z "$TIMEOUT_CMD" ]; then
    echo "  ⚠️  No timeout command found, watching indefinitely..."
    if tail -F "$LOG_FILE" 2>/dev/null | grep -q -m 1 "$PATTERN"; then
        echo "✓ kOS is ready on loaded vessel!"
        exit 0
    fi
    exit 1
fi
if "$TIMEOUT_CMD" "$TIMEOUT" tail -F "$LOG_FILE" 2>/dev/null | grep -q -m 1 "$PATTERN"; then
    echo "✓ kOS is ready on loaded vessel!"
    exit 0
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo "✗ Timeout: kOS not initialized within ${TIMEOUT} seconds"
    else
        echo "✗ Unexpected error (exit code: $EXIT_CODE)"
    fi
    exit 1
fi
