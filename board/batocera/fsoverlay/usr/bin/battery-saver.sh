#!/bin/bash
#######################################################
#                                                     #
#    ############################################     #
#    ############################################     #
#    ##                                           ##  #
#    ##          Script by Mikhailzrick           ##  #
#    ##                                           ##  #
#    ############################################     #
#    ############################################     #
# v2.3                                                #
#######################################################

BATTSAVER_DIR="/var/run/battery-saver/"
mkdir -p "$BATTSAVER_DIR"

LOCK="/var/run/battery-saver/battery-saver.lock"

exec 200>"$LOCK"
flock -n 200 || exit 1

trap 'cleanup' EXIT

STATE="active"

STATE_FLAG="/var/run/battery-saver/activity_state.flag"
BRIGHTNESS="$(batocera-brightness)"
GOVERNOR=""
SAVED_GOVERNOR=""

echo "1" > "$STATE_FLAG"

# Called on exit
cleanup() {
    if [ "$STATE" = "inactive" ] && [ -n "$BRIGHTNESS" ]; then
        batocera-brightness "$BRIGHTNESS"
    fi

    # Restore audio and state if exit while inactive but not duriung shutdown process
    if [ ! -f /var/run/shutdown.flag ]; then
        batocera-audio setSystemVolume unmute
        echo "1" > "$STATE_FLAG"
    fi

    rm -f "$LOCK"
    exit 0
}

check_pause() {
    shopt -s nullglob
    for _ in "$BATTSAVER_DIR"/*.pause; do
        shopt -u nullglob
        return 0  # Found pause file
    done
    shopt -u nullglob
    return 1  # No pause file found
}

initialize_settings() {
    MODE="$(/usr/bin/batocera-settings-get system.batterysaver.mode)"
    if [[ -z "$MODE" || ! "$MODE" =~ ^(dim|dispoff|suspend|shutdown|none)$ ]]; then
        MODE="dim" # default can be dim|suspend|shutdown|none
        /usr/bin/batocera-settings-set system.batterysaver.mode "$MODE"
    fi

    TIMER="$(/usr/bin/batocera-settings-get system.batterysaver.timer)"
    if [[ -z "$TIMER" || ! "$TIMER" =~ ^[0-9]+$ || "$TIMER" -lt 60 ]]; then
        TIMER="300" # default in seconds
        /usr/bin/batocera-settings-set system.batterysaver.timer "$TIMER"
    fi

    EXTENDED_MODE="$(/usr/bin/batocera-settings-get system.batterysaver.extendedmode)"
    if [[ -z "$EXTENDED_MODE" || ! "$EXTENDED_MODE" =~ ^(suspend|shutdown|none)$ ]]; then
        EXTENDED_MODE="suspend" # default can be suspend|shutdown|none
        /usr/bin/batocera-settings-set system.batterysaver.extendedmode "$EXTENDED_MODE"
    fi

    EXTENDED_TIMER="$(/usr/bin/batocera-settings-get system.batterysaver.extendedtimer)"
    if [[ -z "$EXTENDED_TIMER" || ! "$EXTENDED_TIMER" =~ ^[0-9]+$ || "$EXTENDED_TIMER" -lt 60 ]]; then
        EXTENDED_TIMER="900" # default in seconds. Only applicable if mode is dim or dispoff
        /usr/bin/batocera-settings-set system.batterysaver.extendedtimer "$EXTENDED_TIMER"
    fi

    AGGRESSIVE="$(/usr/bin/batocera-settings-get system.batterysaver.aggressive)"
    if [[ -z "$AGGRESSIVE" || ! "$AGGRESSIVE" =~ ^(1|0)$ ]]; then
        AGGRESSIVE="0" # default
        /usr/bin/batocera-settings-set system.batterysaver.aggressive "$AGGRESSIVE"
    fi
}

animate_brightness() {
    local current=$1
    local target=$2
    local duration=300  # Total animation duration in milliseconds
    local min_steps=3   # Minimum number of steps
    local max_steps=6   # Maximum number of steps

    local distance=$((target - current))
    local abs_distance=$((distance > 0 ? distance : -distance))
    local steps=$((abs_distance > max_steps ? max_steps : abs_distance))
    steps=$((steps < min_steps ? min_steps : steps))

    local step=$((distance / steps))
    step=$((step == 0 ? (distance > 0 ? 1 : -1) : step))
    local remainder=$((distance % steps))
    local sleep_duration=$(awk "BEGIN {printf \"%.4f\", $duration / ($steps * 1000)}")

    local -a levels=()
    for ((i = 0; i < steps; i++)); do
        if ((i == 0 && distance > 0)); then
            current=$((current + step + remainder))
        elif ((i == steps - 1 && distance < 0)); then
            current=$((current + step + remainder))
        else
            current=$((current + step))
        fi
        if ((step > 0 && current > target)) || ((step < 0 && current < target)); then
            current=$target
        fi
        levels+=("$current")
    done

    for level in "${levels[@]}"; do
        batocera-brightness "$level"
        sleep "$sleep_duration"
    done
}

do_inactivity() {
    STATE="inactive"
    echo "0" > "$STATE_FLAG"
    case "$MODE" in
        dim)
            BRIGHTNESS="$(batocera-brightness)"
            if [ "$BRIGHTNESS" -gt 1 ]; then
                animate_brightness "$BRIGHTNESS" 1
            fi

            batocera-audio setSystemVolume mute

            if [ "$AGGRESSIVE" == "1" ]; then
                GOVERNOR="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
                if [ "$GOVERNOR" != "powersave" ]; then
                    SAVED_GOVERNOR="$GOVERNOR"
                    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                        echo "powersave" > "$cpu"
                    done
                fi

                if [ "$(batocera-settings-get global.retroachievements)" = "0" ]; then
                    /etc/init.d/S20connman stop
                fi
            fi
        ;;
        dispoff)
            batocera-audio setSystemVolume mute
            batocera-brightness dispoff
        ;;
        suspend)
            pm-is-supported --suspend && pm-suspend
            do_activity
        ;;
        shutdown)
            knulli-shutdown -s
        ;;
    esac
}

do_extended_inactivity() {
    case "$EXTENDED_MODE" in
        suspend)
            pm-is-supported --suspend && pm-suspend
            do_activity
        ;;
        shutdown)
            knulli-shutdown -s
        ;;
    esac
}

do_activity() {
    STATE="active"
    echo "1" > "$STATE_FLAG"
    case "$MODE" in
        dim)
            if [ "$AGGRESSIVE" == "1" ] && [ -n "$SAVED_GOVERNOR" ]; then
                for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                    echo "$SAVED_GOVERNOR" > "$cpu"
                done

                if [ "$(batocera-settings-get global.retroachievements)" = "0" ]; then
                    /etc/init.d/S20connman start
                fi
            fi

            batocera-audio setSystemVolume unmute

            local CUR_BRIGHTNESS="$(batocera-brightness)"
            if [ "$CUR_BRIGHTNESS" != "$BRIGHTNESS" ]; then
                animate_brightness "$CUR_BRIGHTNESS" "$BRIGHTNESS"
            fi
        ;;
        dispoff)
            batocera-brightness dispon
            batocera-audio setSystemVolume unmute
        ;;
    esac
}

monitor_controllers() {
    while true; do
        local TIMEOUT=""

        if [ "$STATE" = "inactive" ]; then
            TIMEOUT="$EXTENDED_TIMER"
        else
            TIMEOUT="$TIMER"
        fi

        # Use inotifywait with a variable timeout to determine system inactivity
        event_data=$(timeout "$TIMEOUT" inotifywait -q -e create -e delete -e access --exclude '^.*\/$' "/dev/input/" 2>/dev/null)

        if [[ -n "$event_data" ]]; then
            # Parse event type. We only need "event".
            read -r _ event _ <<< "$event_data"

            case "$event" in
                CREATE* | DELETE*)
                    sleep 0.5 # Makes sure multiple events don't trigger loop restart
                    continue # Restart the loop so a new inotifywait is started for any controller changes that happened
                    ;;
                ACCESS)
                    if [ "$STATE" = "inactive" ]; then
                        do_activity
                    fi
                    sleep 1 # Throttles to reduce cpu usage during frequent inputs especially with multiple controllers
                    continue # Restart the loop
                    ;;
            esac
        fi

        if ! check_pause; then
            if [ "$STATE" = "active" ]; then
                do_inactivity
            elif [ "$STATE" = "inactive" ]; then
                do_extended_inactivity
            fi
        fi
    done
}

initialize_settings
monitor_controllers

rm -f "$LOCK"
exit 0
