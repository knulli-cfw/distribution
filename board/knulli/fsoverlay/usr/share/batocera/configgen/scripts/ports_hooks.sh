#!/bin/sh

# Paths
XBOX_LAYOUT_FLAG="/var/run/ports_xbox_layout.flag"

do_gamestart() {
    local SYSTEM_NAME="$1"
    local GAME_NAME="$2"

    # Extract the base game name
    GAME_NAME="${GAME_NAME##*/}"

    # Check for user set game-specific setting
    if [ -n "${GAME_NAME}" ]; then
        XBOX_LAYOUT_SETTING="${SYSTEM_NAME}[\"${GAME_NAME}\"].xbox_layout"
        XBOX_LAYOUT="$(/usr/bin/batocera-settings-get "${XBOX_LAYOUT_SETTING}")"
    fi

    # If no user set game-specific setting, check for system-specific setting
    if [ -z "${XBOX_LAYOUT}" ] && [ -n "${SYSTEM_NAME}" ]; then
        XBOX_LAYOUT_SETTING="${SYSTEM_NAME}.xbox_layout"
        XBOX_LAYOUT="$(/usr/bin/batocera-settings-get "${XBOX_LAYOUT_SETTING}")"
    fi


    if [ -n "$XBOX_LAYOUT" ]; then
        touch "$XBOX_LAYOUT_FLAG"
    else
        rm -f "$XBOX_LAYOUT_FLAG"
    fi
}

# Check for events
SYSTEM_NAME="$2"
GAME_NAME="$5"

case "$1" in
    gameStart)
        do_gamestart "$SYSTEM_NAME" "$GAME_NAME"
        ;;
    *)
        echo "Usage: $0 {gameStart}"
        ;;
esac

exit 0
