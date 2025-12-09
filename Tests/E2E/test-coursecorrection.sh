#!/bin/bash
# E2E test for COURSECORRECTION maneuver operation
# This test:
# 0. Starts KSP with test2 save (ship in orbit around Kerbin)
# 1. Creates a Hohmann transfer to Mun
# 2. Executes the transfer burn using MechJeb
# 3. Waits for burn completion
# 4. Tests COURSECORRECTION to fine-tune approach to 50km periapsis
#
# Usage:
#   ./test-coursecorrection.sh           # Full test (creates and executes Hohmann first)
#   ./test-coursecorrection.sh --chained # Chained mode (assumes Hohmann already executed)
#
# Chained mode is used when run after test-hohmann.sh with --execute flag,
# saving 20-40 minutes by reusing the transfer trajectory.

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Parse arguments
CHAINED_MODE=false
for arg in "$@"; do
    case $arg in
        --chained)
            CHAINED_MODE=true
            export CHAINED_TEST=true
            shift
            ;;
    esac
done

# Test-specific configuration
BURN_TIMEOUT=2400  # 40 minutes max for burn (warp + execution)

test_setup "COURSECORRECTION"
ksp_init "test2"
kos_ready

# Source validation helper (needed for both chained and non-chained mode)
source "$SCRIPT_DIR/validate-node-creation.sh"

# Skip Hohmann setup in chained mode
if [ "$CHAINED_MODE" = "true" ]; then
    echo "Step 2: Chained mode - skipping Hohmann setup..."
    echo "  (Assumes previous test left vessel on Mun transfer trajectory)"
    echo ""
else
    echo "Step 2: Executing Hohmann transfer to Mun..."

    # The test2 save already has Mun targeted
    # The hohmann script will:
    # 1. Verify target is set
    # 2. Create transfer nodes
    # 3. Enable MechJeb node executor
    # 4. Wait for burn completion
    echo "  Starting Hohmann transfer (this will take ~20-40 minutes)..."
    echo "  (timeout: ${BURN_TIMEOUT}s)"

    # Use gtimeout on macOS, timeout on Linux
    TIMEOUT_CMD="${TIMEOUT_CMD:-$(command -v gtimeout || command -v timeout || echo "")}"
    if [ -z "$TIMEOUT_CMD" ]; then
        echo "  ⚠️  No timeout command found, running without timeout..."
        npm run hohmann > /tmp/hohmann-coursecorrection-test-output.log 2>&1
    else
        if ! "$TIMEOUT_CMD" "$BURN_TIMEOUT" npm run hohmann > /tmp/hohmann-coursecorrection-test-output.log 2>&1; then
            if [ $? -eq 124 ]; then
                echo "✗ Hohmann transfer timed out after ${BURN_TIMEOUT}s" | tee -a "$RUN_LOG"
                cat /tmp/hohmann-coursecorrection-test-output.log
                exit 1
            fi
            # Non-timeout failure - let validation below handle it
        fi
    fi

    # Validate Hohmann node creation
    if ! validate_node_creation /tmp/hohmann-coursecorrection-test-output.log "HOHMANN"; then
        echo ""
        echo "Full output:"
        cat /tmp/hohmann-coursecorrection-test-output.log
        exit 1
    fi

    echo ""
fi

echo "Step 3: Testing COURSECORRECTION..."
echo "  Fine-tuning approach to 50km periapsis..."
# The course-correction script will:
# 1. Check current encounter
# 2. Create course correction node to 50km periapsis
npm run course-correction 50 > /tmp/coursecorrection-test-output.log 2>&1

# Validate course correction node creation using helper
if ! validate_node_creation /tmp/coursecorrection-test-output.log "COURSECORRECTION"; then
    echo ""
    echo "Full output:"
    cat /tmp/coursecorrection-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Current encounter" /tmp/coursecorrection-test-output.log || true
grep "Target periapsis" /tmp/coursecorrection-test-output.log || true
grep "Node created" /tmp/coursecorrection-test-output.log || true
grep -A 1 "ΔV:" /tmp/coursecorrection-test-output.log || true
echo "  ---"

test_success "COURSECORRECTION" "The operation successfully fine-tuned approach to 50km periapsis."
