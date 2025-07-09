#!/bin/sh

BATTSAVER_DIR="/var/run/battery-saver/"
PAUSE_FLAG="/var/run/battery-saver/gamestart-hook.pause"

mkdir -p "$BATTSAVER_DIR"

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
