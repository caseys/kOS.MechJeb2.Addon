#!/bin/bash
# Wait for kOS telnet to be ready
# Usage: ./wait-for-kos.sh [max_wait_seconds]
#
# Uses fast nc port check - no npm/tsx overhead

MAX_WAIT=${1:-180}  # Default 3 minutes
ELAPSED=0
POLL_INTERVAL=1

check_kos_ready() {
    # Fast port check with nc - returns 0 if telnet responds
    echo "" | nc -w 1 127.0.0.1 5410 2>/dev/null | grep -q "Choose a CPU"
}

echo "Waiting for kOS telnet (max ${MAX_WAIT}s)..."

# Fast path: check if already ready
if check_kos_ready; then
    echo "✓ kOS is ready! (0s)"
    exit 0
fi

# Poll until ready
while [ $ELAPSED -lt $MAX_WAIT ]; do
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))

    if check_kos_ready; then
        echo "✓ kOS is ready! (${ELAPSED}s)"
        exit 0
    fi

    # Status update every 15 seconds
    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s elapsed)"
    fi
done

echo "✗ kOS did not become ready in ${MAX_WAIT} seconds"
exit 1
