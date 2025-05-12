#!/bin/sh

# Flag path
PAUSE_FLAG="/var/run/battery_saver.pause"

do_gamestart() {
    local SYSTEM_NAME="$1"

    if [ "$SYSTEM_NAME" = "mpv" ]; then
        touch "$PAUSE_FLAG"
    else
        rm -f "$PAUSE_FLAG"
    fi
}

do_gamestop() {
    rm -f "$PAUSE_FLAG"
}

# Main
SYSTEM_NAME="$2"

case "$1" in
    gameStart)
        do_gamestart "$SYSTEM_NAME"
        ;;
    gameStop)
        do_gamestop
        ;;
    *)
        echo "Usage: $0 {gameStart} <system_name>"
        ;;
esac

exit 0
