#!/bin/sh

# Paths
LED_FILE="/sys/class/power_supply/axp2202-battery/work_led"
LED_STATE="/var/run/led_state"

# Create state file if it doesn't exist
if [ ! -f "$LED_STATE" ]; then
    echo 0 > "$LED_STATE"
fi

led_on() {
    echo 1 > "$LED_FILE"
}

led_off() {
    echo 0 > "$LED_FILE"
}

check_ingame() {
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:1234/runningGame")
    if [ $? -ne 0 ]; then
        return 0
    fi
    if [ "$HTTP_STATUS" -eq 201 ]; then
        return 1
    else
        return 0
    fi
}

# Read current state from the state file
current_state=$(cat "$LED_STATE")

case "$current_state" in
    0)
        for i in $(seq 1 3); do
            led_on
            sleep 0.1
            led_off
            sleep 0.1
        done
        if check_ingame; then
            led_off
        else
            led_on
        fi
        echo 1 > "$LED_STATE"
        ;;
    1)
        led_off
        echo 2 > "$LED_STATE"
        ;;
    2)
        led_on
        echo 0 > "$LED_STATE"
        ;;
esac

exit 0
