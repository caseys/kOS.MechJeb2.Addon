#!/bin/bash
# Verify AutoLoad.cfg is valid
# Usage: ./verify-autoload.sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

if [ ! -f "$AUTOLOAD_CONFIG" ]; then
    echo "✗ AutoLoad.cfg not found at: $AUTOLOAD_CONFIG"
    exit 1
fi

echo "AutoLoad.cfg contents:"
cat "$AUTOLOAD_CONFIG"
echo ""

# Parse and verify
SAVE_DIR=$(grep "directory = " "$AUTOLOAD_CONFIG" | sed 's/.*directory = //' | tr -d ' ')
SAVE_NAME=$(grep "savegame = " "$AUTOLOAD_CONFIG" | sed 's/.*savegame = //' | tr -d ' ')

SAVE_PATH="$KSP_SAVES/$SAVE_DIR/$SAVE_NAME.sfs"
if [ -f "$SAVE_PATH" ]; then
    echo "✓ Configuration valid"
    echo "  Will load: $SAVE_PATH"
else
    echo "✗ Save file NOT found: $SAVE_PATH"
    exit 1
fi
