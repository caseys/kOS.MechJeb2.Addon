#!/bin/bash
# E2E test for KILLRELVEL (kill relative velocity) maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Sets target to Mun
# 2. Creates KILLRELVEL node to match velocity with target
# 3. Verifies node was created with proper delta-v

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Test-specific configuration
TARGET="Mun"

test_setup "KILLRELVEL"
ksp_init "test2"
kos_ready

echo "Step 2: Testing KILLRELVEL..."
echo "  Setting target to ${TARGET} and creating velocity match node..."
# The kill-rel-vel script will:
# 1. Set target to Mun
# 2. Create KILLRELVEL node to match velocity
# 3. Verify node was created
npm run kill-rel-vel $TARGET CLOSEST_APPROACH > /tmp/killrelvel-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/killrelvel-test-output.log "KILLRELVEL"; then
    echo ""
    echo "Full output:"
    cat /tmp/killrelvel-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Target:" /tmp/killrelvel-test-output.log || true
grep "Current relative velocity" /tmp/killrelvel-test-output.log || true
grep "Node created" /tmp/killrelvel-test-output.log || true
grep -A 1 "NV:" /tmp/killrelvel-test-output.log || true
echo "  ---"

test_success "KILLRELVEL" "The operation successfully created velocity match node with ${TARGET}."
