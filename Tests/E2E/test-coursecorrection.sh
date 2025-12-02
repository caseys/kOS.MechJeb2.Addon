#!/bin/bash
# E2E test for COURSECORRECTION maneuver operation
# This test:
# 0. Starts KSP with test2 save (ship in orbit around Kerbin)
# 1. Creates a Hohmann transfer to Mun
# 2. Executes the transfer burn using MechJeb
# 3. Waits for burn completion
# 4. Tests COURSECORRECTION to fine-tune approach to 50km periapsis

set -e

echo "========================================="
echo "COURSECORRECTION E2E Test"
echo "========================================="
echo ""

# Configuration
KOS_HOST="127.0.0.1"
KOS_PORT=5410
KSP_STARTUP_WAIT=420  # 7 minutes max for KSP to fully load
MAX_WAIT=300  # 5 minutes max wait for kOS to be ready after startup
BURN_TIMEOUT=2400  # 40 minutes max for burn (warp + execution)

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

echo "Step 0: Starting KSP with test2 save..."
# Kill existing KSP if running
osascript -e 'tell application "KSP" to quit' 2>/dev/null || true
sleep 3

# Start KSP in background
"$SCRIPT_DIR/StartKSP.scpt" test2 > /tmp/ksp-startup.log 2>&1 &
KSP_PID=$!

echo "  KSP starting (PID: $KSP_PID)..."
echo "  Waiting up to $(($KSP_STARTUP_WAIT / 60)) minutes for startup..."

# Wait for KSP startup to complete
ELAPSED=0
while [ $ELAPSED -lt $KSP_STARTUP_WAIT ]; do
    # Check if StartKSP.scpt has finished
    if ! ps -p $KSP_PID > /dev/null 2>&1; then
        echo "  ✓ KSP startup script completed"
        break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
    echo "    Startup progress: ${ELAPSED}s / ${KSP_STARTUP_WAIT}s"
done

if [ $ELAPSED -ge $KSP_STARTUP_WAIT ]; then
    echo "✗ KSP did not start in time"
    exit 1
fi

echo ""

echo "Step 1: Executing Hohmann transfer to Mun..."
cd /Users/casey/src/ksp-mcp

# Give kOS a moment to initialize after KSP loads
echo "  Waiting 10 seconds for kOS to fully initialize..."
sleep 10

# The test2 save already has Mun targeted
# The hohmann script will:
# 1. Verify target is set
# 2. Create transfer nodes
# 3. Enable MechJeb node executor
# 4. Wait for burn completion
echo "  Starting Hohmann transfer (this will take ~20-40 minutes)..."
npm run hohmann || {
    echo "✗ Hohmann transfer failed"
    exit 1
}

echo ""
echo "Step 2: Testing COURSECORRECTION..."
# The course-correction script will:
# 1. Check current encounter
# 2. Create course correction node to 50km periapsis
npm run course-correction 50 || {
    echo "✗ Course correction failed"
    exit 1
}

echo ""
echo "========================================="
echo "Test complete!"
echo "========================================="
