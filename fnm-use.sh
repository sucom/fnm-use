#!/usr/bin/env bash

# =====================================================================
# Sourced Script Guardrail
# =====================================================================
# Since this script MUST be sourced to alter the active terminal memory,
# using 'exit' would kill the entire window. We use 'return' instead.
if [ "$0" = "$BASH_SOURCE" ]; then
    echo "[Error] This script must be sourced, not executed directly."
    echo "Use: source $0 [version]"
    exit 1
fi

# =====================================================================
# Phase 1: Dynamic Environment & Path Normalization
# =====================================================================
if [ -z "$FNM_DIR" ]; then
    echo "[fnm-use] Error: FNM_DIR environment variable is not defined."
    return 1
fi

# Detect Windows backslashes and translate to Unix paths dynamically
if command -v cygpath >/dev/null 2>&1 && [[ "$FNM_DIR" == *'\'* ]]; then
    FNM_RESOLVED_PATH=$(cygpath -u "$FNM_DIR")
else
    FNM_RESOLVED_PATH="$FNM_DIR"
fi

# Anti-Pollution Guard: Lock in the pristine PATH on the first initialization
if [ -z "$USER_BASE_PATH" ]; then
    export USER_BASE_PATH="$PATH"
fi

# =====================================================================
# Phase 2: Target Version Resolution
# =====================================================================
REQ_VER="$1"

# If no argument is passed, check for local configuration files
if [ -z "$REQ_VER" ]; then
    if [ -f .node-version ]; then
        REQ_VER=$(cat .node-version)
    elif [ -f .nvmrc ]; then
        REQ_VER=$(cat .nvmrc)
    fi
fi

# If still empty, evaluate against the global default path
if [ -z "$REQ_VER" ]; then
    echo "[fnm-use] No version specified and no .node-version/.nvmrc found."
    echo "[fnm-use] Staying on current/global-default."
    node -v
    return 0
fi

# Sanitization: Strip quotes, leading 'v', spaces, and trailing Windows CR (\r) characters
REQ_VER=$(echo "$REQ_VER" | tr -d '"' | sed 's/^v//' | tr -d '\r' | xargs)

# =====================================================================
# Phase 3: Smart Directory Matching (Auto-pick Highest Match)
# =====================================================================
NODE_VERSIONS_DIR="$FNM_RESOLVED_PATH/node-versions"
TARGET_PATH=""
TARGET_NAME=""
MATCH_COUNT=0

# Iterate through matching directories. Alphabetical ordering naturally
# processes higher dot-versions last (overwriting previous matches).
for dir in "$NODE_VERSIONS_DIR/v$REQ_VER"*; do
    # Guard against empty glob matches
    if [ -d "$dir" ]; then
        # Handle both Windows (node.exe) and native Unix binary flavors
        if [ -f "$dir/installation/node.exe" ] || [ -f "$dir/installation/node" ]; then
            MATCH_COUNT=$((MATCH_COUNT + 1))
            TARGET_PATH="$dir/installation" # on windows git-bash
            TARGET_NAME=$(basename "$dir")
        fi

        if [ -f "$dir/installation/bin/node" ]; then
            MATCH_COUNT=$((MATCH_COUNT + 1))
            TARGET_PATH="$dir/installation/bin" # on Mac/Linux
            TARGET_NAME=$(basename "$dir")
        fi
    fi
done

# =====================================================================
# Phase 4: Environment Execution & Verification
# =====================================================================
if [ -n "$TARGET_PATH" ]; then
    if [ "$MATCH_COUNT" -gt 1 ]; then
        echo "[fnm-use] Found $MATCH_COUNT matches. Auto-selecting highest version: $TARGET_NAME"
    else
        echo "[fnm-use] Mounting runtime version: $TARGET_NAME"
    fi

    # Swap the path using the clean memory snapshot
    export PATH="$TARGET_PATH:$USER_BASE_PATH"
    node -v
else
    echo "[fnm-use] Version 'v$REQ_VER' is not installed locally."
    echo "[fnm-use] Run 'fnm install $REQ_VER' to install it first."
    return 1
fi