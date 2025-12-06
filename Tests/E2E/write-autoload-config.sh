#!/bin/bash
# Write AutoLoad.cfg for KSP-AutoLoad mod
# Usage: ./write-autoload-config.sh <save_name>
# Example: ./write-autoload-config.sh test1  (for ascent)
#          ./write-autoload-config.sh test2  (for maneuvers)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

SAVE_NAME="${1:-test2}"
SAVE_DIR="a_test"

# Create flat ConfigNode format (VALIDATED - no braces!)
cat > "$AUTOLOAD_CONFIG" << EOF
directory = $SAVE_DIR
savegame = $SAVE_NAME
EOF

echo "✓ AutoLoad configured: saves/$SAVE_DIR/$SAVE_NAME.sfs"
