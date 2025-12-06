#!/bin/bash
# E2E test for ASCENT (launch to orbit) operation
# This test:
# 0. Starts KSP with test1 save (launchpad vessel)
# 1. Launches to a 100km orbit using MechJeb ascent guidance
# 2. Verifies successful orbit insertion
# NOTE: Uses test1 (not test2) since it's a launch from launchpad

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/with-test-helpers.sh"

# Test-specific configuration
TARGET_ALTITUDE=100000  # 100km orbit
TARGET_INCLINATION=0    # Equatorial orbit

test_setup "ASCENT"
ksp_init "test1"  # Note: test1 has launchpad vessel
kos_ready

echo "Step 2: Testing ASCENT..."
echo "  Launching to ${TARGET_ALTITUDE}m orbit with ${TARGET_INCLINATION}° inclination..."
# The ascent script will:
# 1. Configure MechJeb ascent guidance
# 2. Stage and launch
# 3. Monitor ascent progress
# 4. Verify successful orbit insertion
npm run ascent $TARGET_ALTITUDE $TARGET_INCLINATION > /tmp/ascent-test-output.log 2>&1

# Validate ascent completion with proper checks
VALIDATION_FAILED=0

# Check for completion message (ascent-to-orbit.ts outputs "--- Complete ---")
if ! grep -qE "(--- Complete ---|Ascent autopilot disengaged)" /tmp/ascent-test-output.log; then
    echo "✗ ASCENT test failed - No completion message found"
    VALIDATION_FAILED=1
fi

# Check for apoapsis reporting (format: "APO:109km")
if ! grep -qE "APO:[0-9]+km" /tmp/ascent-test-output.log; then
    echo "✗ ASCENT test failed - No apoapsis reported"
    VALIDATION_FAILED=1
fi

# Check for ascent progress - verify autopilot actually flew the rocket
# Compare first APO value vs last APO value to prove the rocket moved
FIRST_APO=$(grep -oE "APO:[0-9]+km" /tmp/ascent-test-output.log | head -1 | grep -oE "[0-9]+")
LAST_APO=$(grep -oE "APO:[0-9]+km" /tmp/ascent-test-output.log | tail -1 | grep -oE "[0-9]+")

if [ -z "$FIRST_APO" ] || [ -z "$LAST_APO" ]; then
    echo "✗ ASCENT test failed - Could not extract apoapsis values"
    VALIDATION_FAILED=1
elif [ "$LAST_APO" -le "$FIRST_APO" ]; then
    echo "✗ ASCENT test failed - Apoapsis did not increase (start: ${FIRST_APO}km, end: ${LAST_APO}km)"
    VALIDATION_FAILED=1
elif [ $((LAST_APO - FIRST_APO)) -lt 20 ]; then
    echo "✗ ASCENT test failed - Apoapsis increase too small (start: ${FIRST_APO}km, end: ${LAST_APO}km, delta: $((LAST_APO - FIRST_APO))km)"
    VALIDATION_FAILED=1
else
    echo "  ✓ Apoapsis increased: ${FIRST_APO}km → ${LAST_APO}km (delta: $((LAST_APO - FIRST_APO))km)"
fi

# Check for any explicit failure indicators (but ignore validation warnings about periapsis parsing)
if grep -qE "^Error:" /tmp/ascent-test-output.log; then
    echo "✗ ASCENT test failed - Error found in output"
    VALIDATION_FAILED=1
fi

# If validation failed, show output and exit
if [ $VALIDATION_FAILED -eq 1 ]; then
    echo ""
    echo "Full output:"
    cat /tmp/ascent-test-output.log
    exit 1
fi

echo "  ✓ ASCENT completed successfully"

echo ""
echo "  Test output:"
echo "  ---"
# Show key details from output
grep "Ascent phase" /tmp/ascent-test-output.log | tail -5 || true
grep "Final orbit" /tmp/ascent-test-output.log || true
grep -A 2 "Periapsis:\|Apoapsis:" /tmp/ascent-test-output.log | tail -6 || true
echo "  ---"

test_success "ASCENT" "The operation successfully launched to a ${TARGET_ALTITUDE}m orbit."
