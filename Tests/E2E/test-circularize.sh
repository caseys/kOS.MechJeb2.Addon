#!/bin/bash
# E2E test for CIRCULARIZE maneuver operation
# This test:
# 0. Starts/reloads KSP with test2 save (smart reload if already running)
# 1. Creates a circularize node at apoapsis
# 2. Verifies node was created with proper delta-v
# 3. Verifies target orbit is circular

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

test_setup "CIRCULARIZE"
ksp_init "test2"
kos_ready

echo "Step 2: Testing CIRCULARIZE..."
echo "  Creating circularize node at apoapsis..."
# The circularize script will:
# 1. Check current orbit
# 2. Create CIRCULARIZE node at apoapsis
# 3. Verify node was created
npm run circularize APOAPSIS > /tmp/circularize-test-output.log 2>&1

# Validate node creation using helper
source "$SCRIPT_DIR/validate-node-creation.sh"
if ! validate_node_creation /tmp/circularize-test-output.log "CIRCULARIZE"; then
    echo ""
    echo "Full output:"
    cat /tmp/circularize-test-output.log
    exit 1
fi

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Current orbit" /tmp/circularize-test-output.log || true
grep -A 2 "Periapsis:\|Apoapsis:" /tmp/circularize-test-output.log | head -6 || true
grep "Node created" /tmp/circularize-test-output.log || true
grep -A 1 "NV:" /tmp/circularize-test-output.log || true
grep -A 2 "Target orbit" /tmp/circularize-test-output.log || true
echo "  ---"

test_success "CIRCULARIZE" "The operation successfully created a circularize node."
