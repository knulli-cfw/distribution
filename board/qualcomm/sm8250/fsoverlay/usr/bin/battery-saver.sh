#!/bin/bash

LOCK="/var/run/battery-saver.lock"

exec 200>"$LOCK"
flock -n 200 || exit 1

trap 'cleanup' SIGTERM

STATE="active"
BRIGHTNESS="$(batocera-brightness)"
LOOP_COUNT=0 # This should always be 0
JS_DEVICES=()

MODE="$(/usr/bin/batocera-settings-get system.batterysavermode)"
if [[ -z "$MODE" || ! "$MODE" =~ ^(dim|suspend|shutdown)$ ]]; then
    MODE="dim" # default can be dim|suspend|shutdown
    /usr/bin/batocera-settings-set system.batterysavermode "$MODE"
fi

TIMER="$(/usr/bin/batocera-settings-get system.batterysavertimer)"
if [[ -z "$TIMER" || ! "$TIMER" =~ ^[0-9]+$ || "$TIMER" -lt 60 ]]; then
    TIMER="300" # default in seconds
    /usr/bin/batocera-settings-set system.batterysavertimer "$TIMER"
fi

# Called with SIGTERM so brightness is restored before saving to batocera.conf when shutting down and display is dimmed
cleanup() {
    if [ "$STATE" = "inactive" ]; then
        batocera-brightness "$BRIGHTNESS"
    fi

    local pids
    pids=$(pgrep -P $$)
    if [ -n "$pids" ]; then
        kill -TERM $pids 2>/dev/null || true
    fi

    # Kill any lingering processes
    pkill -f "jstest --event" 2>/dev/null || true

    rm -f "$LOCK"
    exit 0
}

js_update() {
    JS_DEVICES=()
    for js_device in /dev/input/js*; do
        if [ -e "$js_device" ]; then
            JS_DEVICES+=("$js_device")
        fi
    done
}

do_inactivity() {
    STATE="inactive"
    case "$MODE" in
        dim)
            BRIGHTNESS="$(batocera-brightness)"
            if [ "$BRIGHTNESS" -gt 6 ]; then
                batocera-brightness 6
            fi
            batocera-audio setSystemVolume mute
        ;;
        suspend)
            pm-is-supported --suspend && pm-suspend
            LOOP_COUNT=0
            STATE="active"
        ;;
        shutdown)
            echo disable > /sys/kernel/debug/dispdbg/command
            echo lcd0 > /sys/kernel/debug/dispdbg/name
            echo 1 > /sys/kernel/debug/dispdbg/start
            amixer set Master mute
            batocera-es-swissknife --emukill
            /usr/bin/poweroff.sh
        ;;
    esac
}

do_activity() {
    if [ "$MODE" = "dim" ]; then
        STATE="active"
        batocera-brightness $BRIGHTNESS
        batocera-audio setSystemVolume unmute
    fi
}

monitor_controllers() {
    local JS_REFRESH_INTERVAL=10 # Number of loops before controller refresh (by default 1 loop per second)

    while true; do
        if (( LOOP_COUNT % JS_REFRESH_INTERVAL == 0 )); then
            js_update
        fi

        # Wait a bit if no controllers are detected
        if [ ${#JS_DEVICES[@]} -eq 0 ]; then
            sleep 1
            continue
        fi

        for i in "${!JS_DEVICES[@]}"; do
            js="${JS_DEVICES[$i]}"

            if timeout 1 jstest --event "$js" 2>/dev/null | grep -Ev 'type 129|type 130' | grep -m 1 -q "Event"; then
                LOOP_COUNT=0

                # Check if detected input device is first and reorder if not
                if [ "$i" -ne 0 ]; then
                    JS_DEVICES=("$js" "${JS_DEVICES[@]:0:$i}" "${JS_DEVICES[@]:$((i + 1))}")
                fi

                if [ "$STATE" = "inactive" ]; then
                    do_activity
                fi

                break # If input is detected don't need to continue looping through other devices
            fi
        done

        ((LOOP_COUNT++))
        if (( LOOP_COUNT >= TIMER )); then
            if [ "$STATE" = "active" ]; then
                do_inactivity
            fi
        fi
    done
}

js_update
monitor_controllers

rm -f "$LOCK"
exit 0
