#!/bin/bash
# E2E test for LONGITUDE (longitude of periapsis) maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Changes the longitude of periapsis
# 2. Verifies node was created with proper delta-v

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Test-specific configuration
TARGET_LONGITUDE=45  # Target longitude of periapsis in degrees

test_setup "LONGITUDE"
ksp_init "test2"
kos_ready

echo "Step 2: Testing LONGITUDE..."
echo "  Changing longitude of periapsis to ${TARGET_LONGITUDE}°..."
# The longitude script will:
# 1. Check current orbit
# 2. Create LONGITUDE node to rotate periapsis
# 3. Verify node was created
npm run longitude $TARGET_LONGITUDE APOAPSIS > /tmp/longitude-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/longitude-test-output.log "LONGITUDE"; then
    echo ""
    echo "Full output:"
    cat /tmp/longitude-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Current orbit" /tmp/longitude-test-output.log || true
grep -A 3 "Periapsis:\|Apoapsis:" /tmp/longitude-test-output.log | head -8 || true
grep "Node created" /tmp/longitude-test-output.log || true
grep -A 1 "NV:" /tmp/longitude-test-output.log || true
echo "  ---"

test_success "LONGITUDE" "The operation successfully adjusted longitude of periapsis to ${TARGET_LONGITUDE}°."
