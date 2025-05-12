#!/bin/sh

# Paths
LED_FILE="/sys/class/power_supply/axp2202-battery/work_led"
LED_STATE="/var/run/led_state"

# Check if a state file exists
if [ ! -f "$LED_STATE" ]; then
    exit 0
fi

# Read current state from the state file
current_state=$(cat "$LED_STATE")

if [ "$current_state" -ne 1 ]; then
    exit 0
fi

led_on() {
    echo 1 > "$LED_FILE"
}

led_off() {
    echo 0 > "$LED_FILE"
}

case "$1" in
    gameStart)
        led_off
        ;;
    gameStop)
        led_on
        ;;
    *)
        echo "Usage: $0 {gameStart|gameStop}"
        ;;
esac

exit 0
