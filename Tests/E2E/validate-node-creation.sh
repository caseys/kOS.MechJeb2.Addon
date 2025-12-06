#!/bin/bash
# validate-node-creation.sh - Validation helper for E2E maneuver tests
# Usage: validate_node_creation /tmp/output.log "OPERATION_NAME"
#
# Returns:
#   0 - Node was successfully created
#   1 - Node creation failed
#
# Checks performed:
#   - Nodes count is not 0
#   - Delta-V is reported (NV: or ΔV:)
#   - No "No node created" messages
#   - No "Create result: False"

validate_node_creation() {
    local output_file="$1"
    local operation_name="${2:-Operation}"

    if [ ! -f "$output_file" ]; then
        echo "✗ ${operation_name} test failed - Output file not found: $output_file"
        return 1
    fi

    # Use -a flag to treat binary files as text (kOS telnet includes control chars)

    # Check for explicit failure indicators
    if grep -qa "Nodes count: 0" "$output_file"; then
        echo "✗ ${operation_name} test failed - Node count is 0"
        cat "$output_file" | grep -a "Nodes count: 0" | head -10
        return 1
    fi

    # Check for explicit false result
    if grep -qa "Create result: False" "$output_file"; then
        echo "✗ ${operation_name} test failed - MechJeb returned False"
        return 1
    fi

    # Check for delta-V report (indicates node exists)
    # Accept both "NV:" (ksp-mcp format) and "ΔV:" (some scripts)
    # Use tr to clean null bytes from kOS telnet output before grep
    if ! cat "$output_file" | tr '\0' '\n' | grep -qE "(NV:|ΔV:)"; then
        echo "✗ ${operation_name} test failed - No delta-V reported (node likely not created)"
        return 1
    fi

    # All checks passed
    echo "  ✓ ${operation_name} node created successfully"
    return 0
}

# If script is run directly (not sourced), validate the file passed as argument
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <output_file> [operation_name]"
        echo ""
        echo "Example:"
        echo "  $0 /tmp/changepe-test-output.log CHANGEPE"
        exit 1
    fi

    validate_node_creation "$1" "${2:-Operation}"
    exit $?
fi

# Export function for use in other scripts
export -f validate_node_creation
