#!/bin/bash
# Configuration for E2E tests - source this from other scripts
# All paths MUST be configured - no hardcoded defaults

# Determine script directory if not set
SCRIPT_DIR="${SCRIPT_DIR:-$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )}"

# Load .env if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Validate required configuration
if [ -z "$KSP_DIR" ]; then
    echo "ERROR: KSP_DIR environment variable not set"
    echo "Create Tests/E2E/.env with: KSP_DIR=/path/to/Kerbal Space Program"
    echo ""
    echo "Example .env file:"
    echo "  KSP_DIR=/Volumes/Flatty/SteamLibrary/steamapps/common/Kerbal Space Program"
    exit 1
fi

# Verify KSP_DIR exists
if [ ! -d "$KSP_DIR" ]; then
    echo "ERROR: KSP_DIR does not exist: $KSP_DIR"
    exit 1
fi

# Derived paths from KSP_DIR
export KSP_DIR
export KSP_SAVES="${KSP_DIR}/saves"
export KSP_GAMEDATA="${KSP_DIR}/GameData"
export KSP_LOG="${KSP_DIR}/KSP.log"
export AUTOLOAD_CONFIG="${KSP_GAMEDATA}/KSP-AutoLoad/AutoLoad.cfg"

# Platform-specific: KSP executable and Player.log
case "$(uname)" in
    Darwin)
        export KSP_APP="${KSP_APP:-${KSP_DIR}/KSP.app}"
        export PLAYER_LOG="${PLAYER_LOG:-$HOME/Library/Logs/Squad/KSP/Player.log}"
        ;;
    Linux)
        export KSP_APP="${KSP_APP:-${KSP_DIR}/KSP.x86_64}"
        export PLAYER_LOG="${PLAYER_LOG:-$HOME/.config/unity3d/Squad/Kerbal Space Program/Player.log}"
        ;;
    *)
        echo "WARNING: Unknown platform $(uname), you may need to set KSP_APP and PLAYER_LOG manually"
        export KSP_APP="${KSP_APP:-${KSP_DIR}/KSP}"
        export PLAYER_LOG="${PLAYER_LOG:-${KSP_DIR}/KSP_Data/output_log.txt}"
        ;;
esac

# Detect timeout command: gtimeout (macOS with coreutils) or timeout (Linux)
export TIMEOUT_CMD="${TIMEOUT_CMD:-$(command -v gtimeout || command -v timeout || echo "")}"

# ksp-mcp directory (required for test scripts)
if [ -z "$KSP_MCP_DIR" ]; then
    # Try to find it as a sibling directory
    _sibling="$(cd "$SCRIPT_DIR/../.." && pwd)/../ksp-mcp"
    if [ -d "$_sibling" ]; then
        export KSP_MCP_DIR="$_sibling"
    else
        echo "ERROR: KSP_MCP_DIR not set and ksp-mcp not found at $_sibling"
        echo "Set KSP_MCP_DIR in your .env file"
        exit 1
    fi
fi
export KSP_MCP_DIR
