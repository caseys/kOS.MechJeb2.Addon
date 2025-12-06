#!/bin/bash
# E2E test for RESONANT ORBIT maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Creates a resonant orbit (orbital period ratio with target body)
# 2. Verifies node was created with proper delta-v

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Test-specific configuration
TARGET_BODY="Mun"
ORBIT_NUMERATOR=2
ORBIT_DENOMINATOR=1  # 2:1 resonance (vessel orbits twice while Mun orbits once)

test_setup "RESONANT ORBIT"
ksp_init "test2"
kos_ready

echo "Step 2: Testing RESONANT ORBIT..."
echo "  Creating ${ORBIT_NUMERATOR}:${ORBIT_DENOMINATOR} resonance with ${TARGET_BODY}..."
# The resonant-orbit script will:
# 1. Set target
# 2. Create resonant orbit node
# 3. Verify node was created
npm run resonant-orbit $TARGET_BODY $ORBIT_NUMERATOR $ORBIT_DENOMINATOR > /tmp/resonant-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/resonant-test-output.log "RESONANT"; then
    echo ""
    echo "Full output:"
    cat /tmp/resonant-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Current orbit" /tmp/resonant-test-output.log || true
grep "Target:" /tmp/resonant-test-output.log || true
grep "Node created" /tmp/resonant-test-output.log || true
grep -A 1 "NV:" /tmp/resonant-test-output.log || true
echo "  ---"

test_success "RESONANT ORBIT" "The operation successfully created a ${ORBIT_NUMERATOR}:${ORBIT_DENOMINATOR} resonant orbit with ${TARGET_BODY}."
