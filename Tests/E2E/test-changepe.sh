#!/bin/bash
# E2E test for CHANGEPE (change periapsis) maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Lowers periapsis from ~90km to 75km (setting new LOW point)
# 2. Verifies node was created with proper delta-v
# 3. Verifies target periapsis is correct

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Test-specific configuration
TARGET_PE_KM=75  # Lower periapsis from ~90km to 75km

test_setup "CHANGEPE (Lower Periapsis)"
ksp_init "test2"
kos_ready

echo "Step 2: Testing CHANGEPE..."
echo "  Lowering periapsis to ${TARGET_PE_KM} km (burn at apoapsis)..."
# The change-periapsis script will:
# 1. Check current orbit
# 2. Create CHANGEPE node to lower periapsis
# 3. Verify node was created and target Pe is correct
npm run change-periapsis $TARGET_PE_KM APOAPSIS > /tmp/changepe-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/changepe-test-output.log "CHANGEPE"; then
    echo ""
    echo "Full output:"
    cat /tmp/changepe-test-output.log
    exit 1
fi

# Additional validation: verify target periapsis value
if ! grep -q "Target periapsis: ${TARGET_PE_KM}" /tmp/changepe-test-output.log; then
    echo "✗ CHANGEPE test failed - Target periapsis not ${TARGET_PE_KM} km"
    echo ""
    echo "Full output:"
    cat /tmp/changepe-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Current orbit" /tmp/changepe-test-output.log || true
grep -A 2 "Periapsis:\|Apoapsis:" /tmp/changepe-test-output.log | head -6 || true
grep "Nodes count" /tmp/changepe-test-output.log || true
grep -A 1 "ΔV:" /tmp/changepe-test-output.log || true
grep "Target periapsis" /tmp/changepe-test-output.log || true
echo "  ---"

test_success "CHANGEPE" "The operation successfully lowered periapsis to ${TARGET_PE_KM} km."
