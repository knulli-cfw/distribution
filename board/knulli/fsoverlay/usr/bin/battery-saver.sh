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
# v2.0                                                #
#######################################################

LOCK="/var/run/battery-saver.lock"

exec 200>"$LOCK"
flock -n 200 || exit 1

trap 'cleanup' EXIT

STATE="active"
STATE_FLAG="/var/run/activity_state.flag"
PAUSE_FLAG="/var/run/battery_saver.pause"
BRIGHTNESS="$(batocera-brightness)"
GOVERNOR=""
SAVED_GOVERNOR=""

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
    local duration=200  # Total animation duration in milliseconds
    local min_steps=2   # Minimum number of steps
    local max_steps=6   # Maximum number of steps

    # Calculate the total distance
    local distance=$((target - current))
    local abs_distance=$((distance > 0 ? distance : -distance))

    # Determine the number of steps
    local steps=$((abs_distance > max_steps ? max_steps : abs_distance))
    steps=$((steps < min_steps ? min_steps : steps))

    # Make needed calculations
    local step=$((distance / steps))
    step=$((step == 0 ? (distance > 0 ? 1 : -1) : step))
    local remainder=$((distance % steps))
    local sleep_duration=$(awk "BEGIN {print $duration / ($steps * 1000)}")

    local final_step=$((steps - 1))

    for ((i = 0; i < steps; i++)); do
        # Adjust current based on remainder and direction
        if ((i == 0 && distance > 0)); then
            # Apply remainder first if increasing brightness
            current=$((current + step + remainder))
        elif ((i == final_step && distance < 0)); then
            # Apply remainder last if decreasing brightness
            current=$((current + step + remainder))
        else
            current=$((current + step))
        fi

        # Prevent overshooting
        if ((step > 0 && current > target)) || ((step < 0 && current < target)); then
            current=$target
        fi

        # Apply brightness
        batocera-brightness "$current"
        sleep "$sleep_duration"

        # Exit loop early if we hit the target
        if [ "$current" -eq "$target" ]; then
            break
        fi
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
            STATE="active"
            echo "1" > "$STATE_FLAG"
        ;;
        shutdown)
            batocera-brightness dispoff
            amixer set Master mute
            batocera-es-swissknife --emukill
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
            batocera-brightness dispoff
            amixer set Master mute
            batocera-es-swissknife --emukill
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
        input_detected=false
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
                CREATE | DELETE)
                    continue # Restart the loop so a new inotifywait is started for any controller changes that happened
                    ;;
                ACCESS)
                    LOOP_COUNT=0
                    input_detected=true
                    if [ "$STATE" = "inactive" ]; then
                        do_activity
                    fi
                    sleep 1 # Throttles to reduce cpu usage during frequent inputs especially with multiple controllers
                    ;;
            esac
        fi

        if [ "$input_detected" = "false" ] && [ ! -f "$PAUSE_FLAG" ]; then
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
