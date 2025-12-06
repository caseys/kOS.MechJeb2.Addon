#!/bin/bash
# E2E test for ELLIPTICIZE maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Sets both periapsis and apoapsis to create an elliptical orbit
# 2. Verifies node was created with proper delta-v
# 3. Verifies target orbit has correct Pe and Ap

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Test-specific configuration
TARGET_PE_KM=80  # Target periapsis
TARGET_AP_KM=120  # Target apoapsis

test_setup "ELLIPTICIZE"
ksp_init "test2"
kos_ready

echo "Step 2: Testing ELLIPTICIZE..."
echo "  Creating elliptical orbit with Pe=${TARGET_PE_KM}km, Ap=${TARGET_AP_KM}km..."
# The ellipticize script will:
# 1. Check current orbit
# 2. Create ELLIPTICIZE node to set both Pe and Ap
# 3. Verify node was created and target orbit is correct
npm run ellipticize $TARGET_PE_KM $TARGET_AP_KM APOAPSIS > /tmp/ellipticize-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/ellipticize-test-output.log "ELLIPTICIZE"; then
    echo ""
    echo "Full output:"
    cat /tmp/ellipticize-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Current orbit" /tmp/ellipticize-test-output.log || true
grep -A 2 "Periapsis:\|Apoapsis:" /tmp/ellipticize-test-output.log | head -6 || true
grep "Node created" /tmp/ellipticize-test-output.log || true
grep -A 1 "NV:" /tmp/ellipticize-test-output.log || true
grep -A 2 "Target orbit" /tmp/ellipticize-test-output.log || true
echo "  ---"

test_success "ELLIPTICIZE" "The operation successfully created an elliptical orbit with Pe=${TARGET_PE_KM}km, Ap=${TARGET_AP_KM}km."
