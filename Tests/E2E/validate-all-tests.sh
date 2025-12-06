#!/bin/bash
# validate-all-tests.sh
# Master validation script to run all 12 E2E tests and capture results

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RESULTS_FILE="/tmp/test-validation-results.txt"

echo "=========================================" | tee "$RESULTS_FILE"
echo "E2E Test Validation - All 12 Tests" | tee -a "$RESULTS_FILE"
echo "Started: $(date)" | tee -a "$RESULTS_FILE"
echo "=========================================" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# Array of test names (in mission order - like a real space mission)
# 1. Launch & orbit establishment
# 2. Basic orbit adjustments
# 3. Plane changes
# 4. Interplanetary transfer
# 5. Rendezvous operations
# 6. Utility maneuvers
# (landing would be last, but not yet implemented)
TESTS=(
    "ascent"              # Launch from pad to orbit
    "circularize"         # Circularize after ascent
    "changeap"            # Adjust apoapsis
    "changepe"            # Adjust periapsis
    "ellipticize"         # Create elliptical orbit
    "changeinclination"   # Change orbital plane
    "lan"                 # Adjust longitude of ascending node
    "longitude"           # Adjust longitude
    "hohmann"             # Transfer to another body
    "coursecorrection"    # Fine-tune transfer trajectory
    "killrelvel"          # Match velocity with target
    "resonant"            # Resonant orbit for satellite deployment
)

PASSED=0
FAILED=0
FAILED_TESTS=()

for test in "${TESTS[@]}"; do
    echo "----------------------------------------" | tee -a "$RESULTS_FILE"
    echo "Testing: $test" | tee -a "$RESULTS_FILE"
    echo "----------------------------------------" | tee -a "$RESULTS_FILE"

    # Run test in foreground, capturing output
    # Use script command to properly handle PTY and process substitution
    TEST_LOG="/tmp/test-${test}-validation.log"

    # Run test and wait for FULL completion
    set +e  # Don't exit on error - we want to capture the result
    "$SCRIPT_DIR/test-${test}.sh" 2>&1 | tee "$TEST_LOG"
    TEST_EXIT_CODE=${PIPESTATUS[0]}
    set -e

    if [ $TEST_EXIT_CODE -eq 0 ]; then
        echo "✅ PASSED: test-${test}.sh" | tee -a "$RESULTS_FILE"
        ((PASSED++))
    else
        echo "❌ FAILED: test-${test}.sh (exit code: $TEST_EXIT_CODE)" | tee -a "$RESULTS_FILE"
        ((FAILED++))
        FAILED_TESTS+=("$test")

        # Show last 30 lines of failed test output
        echo "" | tee -a "$RESULTS_FILE"
        echo "Last 30 lines of output:" | tee -a "$RESULTS_FILE"
        tail -30 "$TEST_LOG" | tee -a "$RESULTS_FILE"
    fi

    echo "" | tee -a "$RESULTS_FILE"
done

# Summary
echo "=========================================" | tee -a "$RESULTS_FILE"
echo "VALIDATION SUMMARY" | tee -a "$RESULTS_FILE"
echo "=========================================" | tee -a "$RESULTS_FILE"
echo "Total Tests: 12" | tee -a "$RESULTS_FILE"
echo "Passed: $PASSED" | tee -a "$RESULTS_FILE"
echo "Failed: $FAILED" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

if [ $FAILED -gt 0 ]; then
    echo "Failed Tests:" | tee -a "$RESULTS_FILE"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - test-${test}.sh" | tee -a "$RESULTS_FILE"
    done
    echo "" | tee -a "$RESULTS_FILE"
fi

echo "Finished: $(date)" | tee -a "$RESULTS_FILE"
echo "Full results: $RESULTS_FILE" | tee -a "$RESULTS_FILE"

# Individual test logs saved to /tmp/test-<name>-validation.log
echo "" | tee -a "$RESULTS_FILE"
echo "Individual test logs:" | tee -a "$RESULTS_FILE"
for test in "${TESTS[@]}"; do
    echo "  /tmp/test-${test}-validation.log" | tee -a "$RESULTS_FILE"
done

# Exit with failure if any tests failed
if [ $FAILED -gt 0 ]; then
    echo "" | tee -a "$RESULTS_FILE"
    echo "❌ VALIDATION FAILED - $FAILED test(s) failed" | tee -a "$RESULTS_FILE"
    exit 1
else
    echo "" | tee -a "$RESULTS_FILE"
    echo "✅ ALL TESTS PASSED!" | tee -a "$RESULTS_FILE"
    exit 0
fi
