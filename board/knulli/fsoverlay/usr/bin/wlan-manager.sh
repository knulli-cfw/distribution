#!/bin/bash

RFKILL_DIR="/sys/class/rfkill"

enabled_first_wlan=false

# Loop to enable first wlan and disable any others found. (many handhelds seem to have multiple wlans)
if [[ -d "$RFKILL_DIR" ]]; then
    for device in $RFKILL_DIR/rfkill*; do
        if [[ "$(cat $device/type)" == "wlan" ]]; then
            if [ "$enabled_first_wlan" = false ]; then
                echo 1 > "$device/state"
                enabled_first_wlan=true
            else
                echo 0 > "$device/state"
            fi
        fi
    done
fi
