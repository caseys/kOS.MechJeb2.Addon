#!/bin/bash
# Debug AutoLoad issues

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config.sh"

echo "=== AutoLoad Debug ==="
echo ""

echo "1. AutoLoad.cfg:"
cat "$AUTOLOAD_CONFIG" 2>/dev/null || echo "  Not found!"
echo ""

echo "2. Saves in a_test:"
ls -lh "$KSP_SAVES/a_test/" 2>/dev/null || echo "  Directory not found!"
echo ""

echo "3. KSP Process:"
pgrep KSP && echo "  Running (PID: $(pgrep KSP))" || echo "  Not running"
echo ""

echo "4. Recent Player.log:"
tail -20 "$PLAYER_LOG" 2>/dev/null || echo "  Not found"
