#!/bin/bash
# Reusable helper: Wait for kOS telnet server to be ready
# Usage: ./wait-for-kos.sh [max_wait_seconds]

MAX_WAIT=${1:-180}  # Default 3 minutes
ELAPSED=0

echo "Waiting for kOS telnet server (max ${MAX_WAIT}s)..."

while [ $ELAPSED -lt $MAX_WAIT ]; do
    # First check if port is open
    if nc -z 127.0.0.1 5410 2>/dev/null; then
        # Port is open, now verify kOS is responding with CPU menu
        # Send a newline and check if we get "Choose a CPU" response
        if echo "" | nc -w 2 127.0.0.1 5410 2>/dev/null | grep -q "Choose a CPU"; then
            echo "✓ kOS telnet server is ready!"
            exit 0
        fi
    fi
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    if [ $((ELAPSED % 30)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s elapsed)"
    fi
done

echo "✗ kOS telnet server did not become ready in ${MAX_WAIT} seconds"
exit 1
