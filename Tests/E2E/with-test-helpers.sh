#!/bin/bash
# with-test-helpers.sh - Common test infrastructure for E2E tests
# Usage: source "$SCRIPT_DIR/with-test-helpers.sh"
#
# This script provides 4 helper functions:
#   test_setup "TEST_NAME"          - Initialize logging, config, banner
#   ksp_init "save_name"            - Start or reload KSP with save
#   kos_ready                       - Wait for kOS telnet server
#   test_success "NAME" "message"   - Print success footer, write status file
#

# Source central configuration (requires SCRIPT_DIR to be set by caller)
if [ -z "$SCRIPT_DIR" ]; then
    echo "ERROR: SCRIPT_DIR must be set before sourcing with-test-helpers.sh"
    exit 1
fi
source "$SCRIPT_DIR/config.sh"

# test_setup - Initialize test environment
# Usage: test_setup "OPERATION"
# Sets up logging, configuration, and prints test banner
test_setup() {
    if [ -z "$1" ]; then
        echo "ERROR: test_setup requires TEST_NAME as first argument"
        exit 1
    fi

    local test_name="$1"
    local test_name_lower=$(echo "$test_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    # Logging setup
    export LOG_FILE="/tmp/test-${test_name_lower}.log"
    export STATUS_FILE="/tmp/test-${test_name_lower}.status"
    export RUN_LOG="/tmp/test-${test_name_lower}-run.log"

    # Clear old status
    rm -f "$STATUS_FILE"

    # Note: Don't use exec > >(tee ...) here - it conflicts with validate-all-tests.sh's piping
    # Logging is handled by the caller (validate-all-tests.sh uses | tee)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Test started - logging to $LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Test started" >> "$RUN_LOG"

    # Print test banner
    echo "=========================================" | tee -a "$RUN_LOG"
    echo "${test_name} E2E Test" | tee -a "$RUN_LOG"
    echo "=========================================" | tee -a "$RUN_LOG"
    echo "" | tee -a "$RUN_LOG"

    # Configuration
    export KOS_HOST="127.0.0.1"
    export KOS_PORT=5410
    export KSP_STARTUP_WAIT=420
    export MAX_WAIT=180

    # Script directory (already set by caller, but export it)
    export SCRIPT_DIR
    export PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
}

# ksp_init - Initialize KSP (start or reload)
# Usage: ksp_init "test2"
# Handles both KSP startup and reload based on whether KSP is already running
ksp_init() {
    local save_name=${1:-test2}
    local max_retries=${KSP_INIT_RETRIES:-3}
    local retry_count=0

    # Check if KSP is already running
    if pgrep -q KSP; then
        echo "Step 0: KSP running - reloading save..." | tee -a "$RUN_LOG"
        "$SCRIPT_DIR/write-autoload-config.sh" "$save_name"
        "$SCRIPT_DIR/LoadSaveKSP.scpt" "$save_name" > /tmp/ksp-reload.log 2>&1

        # Retry vessel init with max retries
        while [ $retry_count -lt $max_retries ]; do
            if "$SCRIPT_DIR/wait-for-kos-vessel.sh" 60; then
                break
            fi
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                echo "  ⚠️  Vessel initialization timeout, retrying ($retry_count/$max_retries)..." | tee -a "$RUN_LOG"
                sleep 10
            fi
        done

        if [ $retry_count -ge $max_retries ]; then
            echo "✗ Vessel initialization failed after $max_retries attempts" | tee -a "$RUN_LOG"
            exit 1
        fi
    else
        echo "Step 0: Starting KSP with AutoLoad..." | tee -a "$RUN_LOG"
        "$SCRIPT_DIR/start-ksp-autoload.sh" "$save_name" > /tmp/ksp-startup.log 2>&1 &

        # Wait for flight scene (save auto-loads directly)
        "$SCRIPT_DIR/wait-for-ksp-ready.sh" $KSP_STARTUP_WAIT || {
            echo "✗ KSP startup timeout" | tee -a "$RUN_LOG"
            exit 1
        }

        # Retry vessel init with max retries
        while [ $retry_count -lt $max_retries ]; do
            if "$SCRIPT_DIR/wait-for-kos-vessel.sh" 60; then
                break
            fi
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                echo "  ⚠️  Vessel initialization timeout, retrying ($retry_count/$max_retries)..." | tee -a "$RUN_LOG"
                sleep 10
            fi
        done

        if [ $retry_count -ge $max_retries ]; then
            echo "✗ Vessel initialization failed after $max_retries attempts" | tee -a "$RUN_LOG"
            exit 1
        fi
    fi

    echo "" | tee -a "$RUN_LOG"
}

# kos_ready - Wait for kOS telnet server
# Usage: kos_ready
# Waits for kOS telnet server to be ready and accessible
kos_ready() {
    echo "Step 1: Waiting for kOS telnet server..." | tee -a "$RUN_LOG"

    # KSP_MCP_DIR is set by config.sh
    cd "$KSP_MCP_DIR"

    # Wait for kOS telnet server
    if ! "$SCRIPT_DIR/wait-for-kos.sh" ${MAX_WAIT:-180}; then
        echo "✗ kOS telnet server failed to start" | tee -a "$RUN_LOG"
        exit 1
    fi

    echo "" | tee -a "$RUN_LOG"
}

# test_success - Print success footer and write status file
# Usage: test_success "OPERATION" "The operation successfully did X."
# Prints success message and creates STATUS_FILE marker
test_success() {
    local operation=$1
    local message=$2

    echo "" | tee -a "$RUN_LOG"
    echo "=========================================" | tee -a "$RUN_LOG"
    echo "✅ Test complete!" | tee -a "$RUN_LOG"
    echo "=========================================" | tee -a "$RUN_LOG"
    echo "" | tee -a "$RUN_LOG"
    echo "${operation} is working correctly." | tee -a "$RUN_LOG"
    if [ -n "$message" ]; then
        echo "$message" | tee -a "$RUN_LOG"
    fi
    echo "" | tee -a "$RUN_LOG"

    # Write success marker
    echo "SUCCESS" > "$STATUS_FILE"
}

# Export all functions so they're available in calling scripts
export -f test_setup
export -f ksp_init
export -f kos_ready
export -f test_success
