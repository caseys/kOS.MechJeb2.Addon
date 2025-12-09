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
# Environment variables:
#   CHAINED_TEST=true  - Skip all init, assume previous test left KSP ready
#   FORCE_RELOAD=true  - Skip fast path, always reload save (for tests that mutate state)
# Optimizations:
#   - Same save + KSP running + kOS responding → clear nodes only (fast)
#   - Different save + KSP running + macOS → AppleScript reload
#   - Different save + KSP running + non-macOS → kill + restart KSP
#   - KSP not running → fresh start
ksp_init() {
    local save_name=${1:-test2}
    local last_save=""

    # Chained mode: skip all initialization, previous test left KSP in required state
    if [ "${CHAINED_TEST:-}" = "true" ]; then
        echo "Step 0: Chained test mode - using existing KSP state..." | tee -a "$RUN_LOG"
        echo "" | tee -a "$RUN_LOG"
        return 0
    fi

    # Read last loaded save
    if [ -f "$LAST_SAVE_FILE" ]; then
        last_save=$(cat "$LAST_SAVE_FILE" 2>/dev/null || true)
    fi

    if pgrep -q KSP; then
        # KSP is running
        if [ "$save_name" = "$last_save" ] && [ "${FORCE_RELOAD:-}" != "true" ]; then
            # Same save - just clear nodes (no reload needed)
            echo "Step 0: Same save '$save_name' - clearing nodes only..." | tee -a "$RUN_LOG"

            # Shutdown daemon to force fresh connection
            npm run --prefix "$KSP_MCP_DIR" --silent daemon shutdown >/dev/null 2>&1 || true

            if "$SCRIPT_DIR/wait-for-kos.sh" 30; then
                if "$SCRIPT_DIR/clear-nodes.sh" 2>&1; then
                    echo "" | tee -a "$RUN_LOG"
                    return 0
                fi
                # Node clearing failed, fall through to reload
                echo "  Node clearing failed, falling back to reload..." | tee -a "$RUN_LOG"
            else
                echo "  kOS not responding, falling back to reload..." | tee -a "$RUN_LOG"
            fi
        fi

        # Different save (or kOS not responding) - need to reload
        if [ "$IS_MACOS" = "true" ]; then
            # macOS: Use AppleScript hot reload
            echo "Step 0: KSP running - reloading save '$save_name'..." | tee -a "$RUN_LOG"

            # Shutdown daemon before reload to force fresh connection after
            npm run --prefix "$KSP_MCP_DIR" --silent daemon shutdown >/dev/null 2>&1 || true

            # Record current log position BEFORE reload (to detect NEW initialization)
            local log_lines_before=$(wc -l < "$PLAYER_LOG" 2>/dev/null || echo 0)
            local start_after=$((log_lines_before + 1))

            "$SCRIPT_DIR/write-autoload-config.sh" "$save_name"
            "$SCRIPT_DIR/LoadSaveKSP.scpt" "$save_name" > /tmp/ksp-reload.log 2>&1

            # Wait for kOS vessel to initialize on the NEW save
            echo "  Waiting for vessel initialization..." | tee -a "$RUN_LOG"
            if ! "$SCRIPT_DIR/wait-for-kos-vessel.sh" 60 "$start_after"; then
                echo "  ⚠️ Vessel initialization timeout" | tee -a "$RUN_LOG"
                exit 1
            fi

            # Also verify kOS telnet is responding
            if ! "$SCRIPT_DIR/wait-for-kos.sh" 30; then
                echo "  ⚠️ kOS telnet timeout" | tee -a "$RUN_LOG"
                exit 1
            fi

            # Record loaded save
            echo "$save_name" > "$LAST_SAVE_FILE"
        else
            # Non-macOS: Kill and restart KSP (AppleScript not available)
            echo "Step 0: KSP running, different save needed - restarting KSP..." | tee -a "$RUN_LOG"
            echo "  (AppleScript reload not available on $(uname))" | tee -a "$RUN_LOG"

            pkill -9 KSP 2>/dev/null || true
            sleep 3

            # Fresh start
            _ksp_fresh_start "$save_name"
        fi
    else
        # KSP not running - fresh start
        _ksp_fresh_start "$save_name"
    fi

    echo "" | tee -a "$RUN_LOG"
}

# Internal helper for fresh KSP start
_ksp_fresh_start() {
    local save_name=$1

    echo "Step 0: Starting KSP with AutoLoad..." | tee -a "$RUN_LOG"
    "$SCRIPT_DIR/start-ksp-autoload.sh" "$save_name" > /tmp/ksp-startup.log 2>&1 &

    # Wait for flight scene (save auto-loads directly)
    "$SCRIPT_DIR/wait-for-ksp-ready.sh" $KSP_STARTUP_WAIT || {
        echo "✗ KSP startup timeout" | tee -a "$RUN_LOG"
        exit 1
    }

    # Wait for kOS vessel initialization
    if ! "$SCRIPT_DIR/wait-for-kos-vessel.sh" 60; then
        echo "✗ Vessel initialization timeout" | tee -a "$RUN_LOG"
        exit 1
    fi

    # Record loaded save
    echo "$save_name" > "$LAST_SAVE_FILE"
}

# kos_ready - Wait for kOS telnet to be ready
# Usage: kos_ready
# Uses fast nc port check on 127.0.0.1:5410 - no daemon overhead
kos_ready() {
    echo "Step 1: Waiting for kOS..." | tee -a "$RUN_LOG"

    # Wait for kOS telnet to be ready (fast nc port check)
    if ! "$SCRIPT_DIR/wait-for-kos.sh" ${MAX_WAIT:-180}; then
        echo "✗ kOS failed to become ready" | tee -a "$RUN_LOG"
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
export -f _ksp_fresh_start
export -f kos_ready
export -f test_success
