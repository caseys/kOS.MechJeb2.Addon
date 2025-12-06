#!/bin/bash
# E2E test for CHANGEINCLINATION maneuver operation
# This test:
# 0. Starts KSP with test2 save (ship in orbit around Kerbin)
# 1. Tests CHANGEINCLINATION to change orbit to equatorial (0 degrees)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

test_setup "CHANGEINCLINATION"
ksp_init "test2"
kos_ready

echo "Step 2: Testing CHANGEINCLINATION..."
# The change-inclination script will:
# 1. Check current orbit inclination
# 2. Create CHANGEINCLINATION node to 0 degrees (equatorial)
# 3. Verify node was created with proper delta-v
echo "  Creating inclination change node to 10°..."
npm run change-inclination 10 EQ_NEAREST_AD > /tmp/changeinclination-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/changeinclination-test-output.log "CHANGEINCLINATION"; then
    echo ""
    echo "Full output:"
    cat /tmp/changeinclination-test-output.log
    exit 1
fi

# Show key details from output
echo ""
echo "  Test output:"
echo "  ---"
grep -A 3 "Current orbit" /tmp/changeinclination-test-output.log || true
grep -A 1 "Maneuver node info" /tmp/changeinclination-test-output.log || true
grep -A 3 "Target orbit after burn" /tmp/changeinclination-test-output.log || true
echo "  ---"

test_success "CHANGEINCLINATION" "The operation successfully created a maneuver node to change orbital inclination."
