#!/bin/bash
# Launch KSP with AutoLoad (cross-platform)
# Usage: ./start-ksp-autoload.sh [save_name]
# Example: ./start-ksp-autoload.sh test1  (for ascent)
#          ./start-ksp-autoload.sh test2  (for maneuvers)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

SAVE_NAME="${1:-test2}"
SAVE_DIR="a_test"

echo "========================================="
echo "KSP AutoLoad Startup"
echo "========================================="

# Step 1: Write AutoLoad.cfg
echo "Step 1: Writing AutoLoad.cfg..."
"$SCRIPT_DIR/write-autoload-config.sh" "$SAVE_NAME"

# Step 2: Quit KSP if running (cross-platform)
if pgrep -q KSP; then
    echo "Step 2: Quitting existing KSP..."
    if [ "$IS_MACOS" = "true" ]; then
        # macOS: Try graceful quit first
        osascript -e 'tell application "KSP" to quit' 2>/dev/null || true
        sleep 5
    fi
    # All platforms: Force kill if still running
    pgrep -q KSP && pkill -9 KSP && sleep 2
fi

# Step 3: Clear logs
echo "Step 3: Clearing old logs..."
rm -f "$PLAYER_LOG"

# Step 4: Verify save exists
echo "Step 4: Verifying save file..."
if [ ! -f "$KSP_SAVES/$SAVE_DIR/$SAVE_NAME.sfs" ]; then
    echo "✗ ERROR: Save not found: $KSP_SAVES/$SAVE_DIR/$SAVE_NAME.sfs"
    exit 1
fi
echo "  ✓ Save verified"

# Step 5: Launch KSP (cross-platform)
echo "Step 5: Launching KSP..."
if [ "$IS_MACOS" = "true" ]; then
    # macOS: Use 'open' for .app bundles
    open "$KSP_APP"
else
    # Linux/other: Run executable directly in background
    "$KSP_APP" &
fi
echo "  KSP launched! AutoLoad will load save automatically."
echo "  Estimated time to flight scene: 3-5 minutes"

# Step 6: Record loaded save (for save reuse optimization)
echo "$SAVE_NAME" > "$LAST_SAVE_FILE"
