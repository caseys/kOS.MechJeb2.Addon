#!/bin/bash
# Clear all maneuver nodes via ksp-mcp daemon
# Usage: ./clear-nodes.sh
# Returns 0 on success, non-zero on failure

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

npm run --prefix "$KSP_MCP_DIR" --silent daemon execute \
    'FOR N IN ALLNODES { REMOVE N. }' 2>/dev/null

echo "✓ Nodes cleared"
