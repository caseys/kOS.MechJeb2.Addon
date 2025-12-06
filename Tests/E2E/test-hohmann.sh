#!/bin/bash
# E2E test for HOHMANN transfer maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Sets target to Mun
# 2. Tests HOHMANN transfer node creation (transfer only, no capture)
# 3. Verifies node was created with proper delta-v and encounter

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

test_setup "HOHMANN TRANSFER"
ksp_init "test2"
kos_ready

echo "Step 2: Testing HOHMANN transfer..."
echo "  Setting target to Mun and creating transfer node..."
# The hohmann script will:
# 1. Verify current orbit
# 2. Set target to Mun
# 3. Create HOHMANN transfer node (transfer only, no capture)
# 4. Verify nodes were created
npm run hohmann > /tmp/hohmann-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/hohmann-test-output.log "HOHMANN"; then
    echo ""
    echo "Full output:"
    cat /tmp/hohmann-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep -A 3 "Target:" /tmp/hohmann-test-output.log || true
grep "Nodes created" /tmp/hohmann-test-output.log || true
grep -A 2 "First node info" /tmp/hohmann-test-output.log || true
grep -i "encounter" /tmp/hohmann-test-output.log || true
echo "  ---"

test_success "HOHMANN TRANSFER" "The operation successfully created a transfer node to Mun."
