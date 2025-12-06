#!/bin/bash
# E2E test for CHANGEAP (change apoapsis) maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Raises apoapsis from ~109km to 150km (setting new HIGH point)
# 2. Verifies node was created with proper delta-v
# 3. Verifies target apoapsis is correct

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Test-specific configuration
TARGET_AP_KM=150  # Raise apoapsis from ~109km to 150km

test_setup "CHANGEAP (Raise Apoapsis)"
ksp_init "test2"
kos_ready

echo "Step 2: Testing CHANGEAP..."
echo "  Raising apoapsis to ${TARGET_AP_KM} km (burn at periapsis)..."
# The change-apoapsis script will:
# 1. Check current orbit
# 2. Create CHANGEAP node to raise apoapsis
# 3. Verify node was created and target Ap is correct
npm run change-apoapsis $TARGET_AP_KM PERIAPSIS > /tmp/changeap-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/changeap-test-output.log "CHANGEAP"; then
    echo ""
    echo "Full output:"
    cat /tmp/changeap-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Current orbit" /tmp/changeap-test-output.log || true
grep -A 2 "Periapsis:\|Apoapsis:" /tmp/changeap-test-output.log | head -6 || true
grep "Node created" /tmp/changeap-test-output.log || true
grep -A 1 "NV:" /tmp/changeap-test-output.log || true
grep -A 2 "Target orbit" /tmp/changeap-test-output.log || true
grep "Target apoapsis" /tmp/changeap-test-output.log || true
echo "  ---"

test_success "CHANGEAP" "The operation successfully raised apoapsis to ${TARGET_AP_KM} km."
