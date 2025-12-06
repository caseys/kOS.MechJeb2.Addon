#!/bin/bash
# E2E test for LAN (longitude of ascending node) maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Changes the longitude of ascending node
# 2. Verifies node was created with proper delta-v

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Test-specific configuration
TARGET_LAN=0  # Target longitude of ascending node in degrees (0 = prime meridian)

test_setup "LAN"
ksp_init "test2"
kos_ready

echo "Step 2: Testing LAN..."
echo "  Changing longitude of ascending node to ${TARGET_LAN}°..."
# The lan script will:
# 1. Check current orbit
# 2. Create LAN node to rotate ascending node
# 3. Verify node was created
npm run lan $TARGET_LAN APOAPSIS > /tmp/lan-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/lan-test-output.log "LAN"; then
    echo ""
    echo "Full output:"
    cat /tmp/lan-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Current orbit" /tmp/lan-test-output.log || true
grep -A 3 "Inclination:\|LAN:" /tmp/lan-test-output.log | head -8 || true
grep "Node created" /tmp/lan-test-output.log || true
grep -A 1 "NV:" /tmp/lan-test-output.log || true
echo "  ---"

test_success "LAN" "The operation successfully adjusted longitude of ascending node to ${TARGET_LAN}°."
