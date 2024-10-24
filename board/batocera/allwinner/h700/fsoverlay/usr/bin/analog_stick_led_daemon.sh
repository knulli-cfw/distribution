#!/bin/bash

BOARD=$(cat /boot/boot/batocera.board)
# We only want the script to run for these devices
if [ "$BOARD" != "rg40xx-h" ] && [ "$BOARD" != "rg40xx-v" ] && [ "$BOARD" != "rg-cubexx" ]; then
    exit 1
fi

# Define RGB LED keys for batocera.conf
KEY_LED_MODE="led.mode"
KEY_LED_BRIGHTNESS="led.brightness"
KEY_LED_SPEED="led.speed"
KEY_LED_COLOUR="led.colour"
KEY_LED_COLOUR_RIGHT="led.colour.right"
KEY_LED_BATTERY_LOW_THRESHOLD="led.battery.low"
KEY_LED_BATTERY_CHARGING_ENABLED="led.battery.charging"

# Paths to variables
VAR_LED_PID="/var/run/analog_stick_led_daemon.led.pid"
VAR_LED_VALUES="/var/run/analog_stick_led_daemon.values"

# Last change date of batocera.conf
LAST_CONF_CHANGE_DATE=$(date -r "/userdata/system/batocera.conf")

# Sleep interval for daemon
UPDATE_INTERVAL_SECONDS=1

# Max loop count for daemon
MAX_LOOP_COUNT=60

# Constants for different LED Daemon modes (different from LED modes!)
MODE_OFF=0
MODE_DEFAULT=1
MODE_BATTERY_WARNING=2
MODE_BATTERY_DANGER=3
MODE_BATTERY_CHARGING=4

# Define some default RGB LED settings
DEFAULT_LED_MODE=1
DEFAULT_BRIGHTNESS=100
DEFAULT_SPEED=15
DEFAULT_COLOUR=(148 255 0)
DEFAULT_BATTERY_LOW_THRESHOLD=20
DEFAULT_BATTERY_VERY_LOW_THRESHOLD=5
DEFAULT_BATTERY_CHARGING_ENABLED=1

# Colours and mode for low battery
BATTERY_WARNING_MODE=2
BATTERY_WARNING_COLOUR=(255 255 0)
BATTERY_DANGER_COLOUR=(255 0 0)

# Paths to battery values
BATTERY_DIR=$(ls -d /sys/class/power_supply/*{BAT,bat}* 2>/dev/null | head -1)
KEY_BATTERY_CAPACITY="$BATTERY_DIR/capacity"
KEY_BATTERY_STATUS="$BATTERY_DIR/status"

# Battery status names
BATTERY_CHARGING="Charging"
BATTERY_DISCHARGING="Discharging"
BATTERY_FULL="Full"

# Initialize thresholds
THRESHOLD_WARNING=$DEFAULT_BATTERY_LOW_THRESHOLD
THRESHOLD_DANGER=$DEFAULT_BATTERY_VERY_LOW_THRESHOLD
INDICATE_CHARGING=$DEFAULT_BATTERY_CHARGING_ENABLED

# Initialize current applied brightness
APPLIED_BRIGHTNESS=-1

# Initialize last known applied brightness
LAST_APPLIED_BRIGHTNESS=-1

# Initialize last known RGB LED settings
LAST_LED_VALUES=-1

# Initialize last/current LED mode
LAST_MODE=-1
CURRENT_BATTERY_MODE=-1

# Sets LED variables to given values.
setLedValues() {

  printf "\nUpdating LED values to\nMode: $1\nBrightness: $2\nSpeed: $3\nColor Left: $4 $5 $6\nColor Right: $7 $8 $9\n\n"
  echo "$1 $2 $3 $4 $5 $6 $7 $8 $9" > $VAR_LED_VALUES

}

# Clears all LED variables by removing the files.
clearLedValues() {

  LAST_LED_VALUES=-1
  if [ -f "$VAR_LED_VALUES" ]; then
    rm $VAR_LED_VALUES
  fi

  echo "Removed all variables from previous session."

}

# Initializes all missing LED values in batocera.conf
# once before launching the daemon processes.
initializeLedValues() {

  # Read existing LED settings from batocera.conf
  LED_MODE=$(batocera-settings-get $KEY_LED_MODE)
  LED_BRIGHTNESS=$(batocera-settings-get $KEY_LED_BRIGHTNESS)
  LED_SPEED=$(batocera-settings-get $KEY_LED_SPEED)
  LED_COLOUR=($(batocera-settings-get $KEY_LED_COLOUR))
  LED_BATTERY_LOW_THRESHOLD=($(batocera-settings-get $KEY_LED_BATTERY_LOW_THRESHOLD))
  LED_BATTERY_CHARGING_ENABLED=($(batocera-settings-get $KEY_LED_BATTERY_CHARGING_ENABLED))
  
  # Initialize all unset LED-related conf settings with default values
  if [[ ! -n $LED_MODE ]] || [ $LED_MODE -lt 0 ] || [ $LED_MODE -gt 6 ]; then
    batocera-settings-set $KEY_LED_MODE $DEFAULT_LED_MODE
  fi
  if [[ ! -n $LED_BRIGHTNESS ]] || [ $LED_BRIGHTNESS -lt 0 ] || [ $LED_BRIGHTNESS -gt 255 ]; then
    batocera-settings-set $KEY_LED_BRIGHTNESS $DEFAULT_BRIGHTNESS
  fi
  if [[ ! -n $LED_SPEED ]] || [ -z $LED_SPEED ] || [ $LED_SPEED -lt 0 ] || [ $LED_SPEED -gt 255 ]; then
    batocera-settings-set $KEY_LED_SPEED $DEFAULT_SPEED
  fi
  if [ -z $LED_COLOUR ] || [ "${#LED_COLOUR[@]}" -lt 3 ] || [ -z ${LED_COLOUR[0]} ] || [ ${LED_COLOUR[0]} -lt 0 ] || [ ${LED_COLOUR[0]} -gt 255 ] || [ -z ${LED_COLOUR[1]} ] || [ ${LED_COLOUR[1]} -lt 0 ] || [ ${LED_COLOUR[1]} -gt 255 ] || [ -z ${LED_COLOUR[2]} ] || [ ${LED_COLOUR[2]} -lt 0 ] || [ ${LED_COLOUR[2]} -gt 255 ]; then
    batocera-settings-set $KEY_LED_COLOUR "$(printf "%s" "${DEFAULT_COLOUR[*]}")"
  fi
  if [[ ! -n $LED_BATTERY_LOW_THRESHOLD ]] || [ -z $LED_BATTERY_LOW_THRESHOLD ] || [ $LED_BATTERY_LOW_THRESHOLD -lt 0 ] || [ $LED_BATTERY_LOW_THRESHOLD -gt 100 ]; then
    batocera-settings-set $KEY_LED_BATTERY_LOW_THRESHOLD $DEFAULT_BATTERY_LOW_THRESHOLD
  fi
  if [[ ! -n $LED_BATTERY_CHARGING_ENABLED ]] || [ -z $LED_BATTERY_CHARGING_ENABLED ] || [ $LED_BATTERY_CHARGING_ENABLED -lt 0 ] || [ $LED_BATTERY_CHARGING_ENABLED -gt 1 ]; then
    batocera-settings-set $KEY_LED_BATTERY_CHARGING_ENABLED $DEFAULT_BATTERY_CHARGING_ENABLED
  fi

}

# Reads led-related settings from batocera.conf and updates
# the file at VAR_LED_VALUES with a new set of values if possible.
# Leaves VAR_LED_VALUES as is in case that any of the relevant
# values from batocera.conf is missing or invalid.
readLedValues() {

  # Read LED settings from batocera.conf
  LED_MODE=$(batocera-settings-get $KEY_LED_MODE)
  LED_BRIGHTNESS=$(batocera-settings-get $KEY_LED_BRIGHTNESS)
  LED_SPEED=$(batocera-settings-get $KEY_LED_SPEED)
  LED_COLOUR=($(batocera-settings-get $KEY_LED_COLOUR))
  LED_COLOUR_RIGHT=($(batocera-settings-get $KEY_LED_COLOUR_RIGHT))

  # Ensure mode is set and within valid range
  if [[ ! -n $LED_MODE ]] || [ $LED_MODE -lt 0 ] || [ $LED_MODE -gt 6 ]; then
    echo "Invalid or missing LED mode ($LED_MODE) - no LED settings applied."
    return
  fi
  
  # Ensure brightness is set and within valid range
  if [[ ! -n $LED_BRIGHTNESS ]] || [ $LED_BRIGHTNESS -lt 0 ] || [ $LED_BRIGHTNESS -gt 255 ]; then
    echo "Invalid or missing LED brightness ($LED_BRIGHTNESS) - no LED settings applied."
    return
  fi

  # Ensure speed is provided for modes 5 and 6 and within the valid range (0-255)
  if [[ ! -n $LED_SPEED ]] || [ -z $LED_SPEED ] || [ $LED_SPEED -lt 0 ] || [ $LED_SPEED -gt 255 ]; then
    echo "Invalid or missing LED speed ($LED_SPEED) - no LED settings applied."
    return
  fi

  # Ensure RGB colours for modes 1-4 are set and within valid range
  if [ -z $LED_COLOUR ] || [ "${#LED_COLOUR[@]}" -lt 3 ] || [ -z ${LED_COLOUR[0]} ] || [ ${LED_COLOUR[0]} -lt 0 ] || [ ${LED_COLOUR[0]} -gt 255 ] || [ -z ${LED_COLOUR[1]} ] || [ ${LED_COLOUR[1]} -lt 0 ] || [ ${LED_COLOUR[1]} -gt 255 ] || [ -z ${LED_COLOUR[2]} ] || [ ${LED_COLOUR[2]} -lt 0 ] || [ ${LED_COLOUR[2]} -gt 255 ]; then
    echo "Invalid or missing LED colours - no LED settings applied."
    return
  fi

  # Determine if overrides for the right sticks exist and are within valid range, ignore them if not
  if [ -z $LED_COLOUR_RIGHT ] || [ "${#LED_COLOUR_RIGHT[@]}" -lt 3 ] || [ -z ${LED_COLOUR_RIGHT[0]} ] || [ ${LED_COLOUR_RIGHT[0]} -lt 0 ] || [ ${LED_COLOUR_RIGHT[0]} -gt 255 ] || [ -z ${LED_COLOUR_RIGHT[1]} ] || [ ${LED_COLOUR_RIGHT[1]} -lt 0 ] || [ ${LED_COLOUR_RIGHT[1]} -gt 255 ] || [ -z ${LED_COLOUR_RIGHT[2]} ] || [ ${LED_COLOUR_RIGHT[2]} -lt 0 ] || [ ${LED_COLOUR_RIGHT[2]} -gt 255 ]; then
    echo "No LED colour overrides for the right stick found - using regular colors on the right stick (${DEFAULT_COLOUR[@]})"
    LED_COLOUR_RIGHT=(${LED_COLOUR[0]} ${LED_COLOUR[1]} ${LED_COLOUR[2]})
  fi

  # Update LED variable
  setLedValues $LED_MODE $LED_BRIGHTNESS $LED_SPEED ${LED_COLOUR[0]} ${LED_COLOUR[1]} ${LED_COLOUR[2]} ${LED_COLOUR_RIGHT[0]} ${LED_COLOUR_RIGHT[1]} ${LED_COLOUR_RIGHT[2]}

}

# Reads battery thresholds from batocera.conf.
# Uses default values as fallback if batocera.conf
# does not have any values present.
readBatteryValues() {

  # Determine battery indication setup
  THRESHOLD_WARNING=($(batocera-settings-get $KEY_LED_BATTERY_LOW_THRESHOLD))
  THRESHOLD_DANGER=$DEFAULT_BATTERY_VERY_LOW_THRESHOLD
  INDICATE_CHARGING=($(batocera-settings-get $KEY_LED_BATTERY_CHARGING_ENABLED))

  # If warning threshold is invalid, use default as fallback
  if [[ ! -n $LED_BATTERY_LOW_THRESHOLD ]] || [ -z $LED_BATTERY_LOW_THRESHOLD ] || [ $LED_BATTERY_LOW_THRESHOLD -lt 0 ] || [ $LED_BATTERY_LOW_THRESHOLD -gt 100 ]; then
    THRESHOLD_WARNING=$DEFAULT_BATTERY_LOW_THRESHOLD
  fi
  
  # If warning threshold is lesser than default danger threshold, use it as danger threshold instead
  if [[ $THRESHOLD_WARNING -eq $DEFAULT_BATTERY_VERY_LOW_THRESHOLD ]] || [[ $THRESHOLD_WARNING -lt $DEFAULT_BATTERY_VERY_LOW_THRESHOLD ]]; then
    THRESHOLD_DANGER=$THRESHOLD_WARNING
    THRESHOLD_WARNING=0
  fi
  
  if [[ ! -n $LED_BATTERY_CHARGING_ENABLED ]] || [ -z $LED_BATTERY_CHARGING_ENABLED ] || [ $LED_BATTERY_CHARGING_ENABLED -lt 0 ] || [ $LED_BATTERY_CHARGING_ENABLED -gt 1 ]; then
    INDICATE_CHARGING=$DEFAULT_BATTERY_CHARGING_ENABLED
  fi

}


# This function calculates and updates the value for APPLIED_BRIGHTNESS.
# The applied brightness is the percentage of the LED brightness (which
# is configured in 'led.brightness') which corresponds to the current
# screen brightness percentage.
updateAppliedBrightness() {

    # Retrieve LED brightness from batocera.conf
	LED_BRIGHTNESS=$(batocera-settings-get $KEY_LED_BRIGHTNESS)

    # Determine current screen brightness:
    SCREEN_BRIGHTNESS_PERCENT=$(batocera-brightness)

    # Determine current HDMI state:
    HDMI_STATE="$(cat /sys/devices/platform/soc/6000000.hdmi/extcon/hdmi/state)"

    # Calculate applied brightness based on screen brightness percentage of LED brightness.
    APPLIED_BRIGHTNESS=$(( ${LED_BRIGHTNESS}*${SCREEN_BRIGHTNESS_PERCENT}/100 ))

    # If currently plugged to HDMI or brightness calculation crapped out, let's just use the LED brightness at 100%.
    if [ "$HDMI_STATE" = "HDMI=1" ] || [ -z $APPLIED_BRIGHTNESS ]; then
      APPLIED_BRIGHTNESS=${LAST_LED_VALUES[1]}
    fi

}

# Updates CURRENT_BATTERY_MODE by setting it to
#  * MODE_BATTERY_CHARGING if charging
#  * MODE_BATTERY_WARNING if low charge
#  * MODE_BATTERY_DANGER if very low charge
#  * -1 otherwise
updateCurrentBatteryMode() {
  
  # Initialize
  LAST_BATTERY_MODE=$CURRENT_BATTERY_MODE
  CURRENT_BATTERY_MODE=-1

  # If any battery status indicator is enabled/has a threshold above 0 and any battery status information is available
  if ([ $THRESHOLD_WARNING -gt 1 ] || [ $THRESHOLD_DANGER -gt 1 ] || [ $INDICATE_CHARGING -eq 1 ]) && [ ! -z $KEY_BATTERY_STATUS ] && [ -f $KEY_BATTERY_STATUS ]; then
    BATTERY_STATUS=$(cat $KEY_BATTERY_STATUS)
    # If battery status is not null and battery is charging
    if [ ! -z $BATTERY_STATUS ] && [ $BATTERY_STATUS == $BATTERY_CHARGING ] && [ $INDICATE_CHARGING -eq 1 ]; then
      CURRENT_BATTERY_MODE=$MODE_BATTERY_CHARGING
    # If previous battery mode wasn't charging and the condition for battery check wasn't met, just keep last battery mode.
    elif [ $LAST_BATTERY_MODE -ne $MODE_BATTERY_CHARGING ] && ! $1; then
      CURRENT_BATTERY_MODE=$LAST_BATTERY_MODE
    # If battery status is not null and battery is discharging, any warning thresholds is larger than 0 and there is capacity information available
    elif [ ! -z $BATTERY_STATUS ] && [ $BATTERY_STATUS == $BATTERY_DISCHARGING ] && ([ $THRESHOLD_WARNING -gt 0 ] || [ $THRESHOLD_DANGER -gt 0 ]) && [ ! -z $KEY_BATTERY_CAPACITY ] && [ -f $KEY_BATTERY_CAPACITY ]; then
      BATTERY_CHARGE=$(cat $KEY_BATTERY_CAPACITY)
      if [ $THRESHOLD_DANGER -gt 0 ] && ([ $BATTERY_CHARGE == $THRESHOLD_DANGER ] || [ $BATTERY_CHARGE -lt $THRESHOLD_DANGER ]); then
        CURRENT_BATTERY_MODE=$MODE_BATTERY_DANGER
      elif [ $THRESHOLD_WARNING -gt 0 ] && ([ $BATTERY_CHARGE == $THRESHOLD_WARNING ] || [ $BATTERY_CHARGE -lt $THRESHOLD_WARNING ]); then
        CURRENT_BATTERY_MODE=$MODE_BATTERY_WARNING
      fi
    fi
  fi

}

# Function actually applies the LED settings, based on
# batocera.conf settings, battery status, and current
# display brightness.
applyLedSettings() {

  # Update applied brightness
  updateAppliedBrightness

  # Null check for LAST_MODE
  if [ -z "$LAST_MODE" ]; then
    LAST_MODE=-1
  fi

  # If battery is charging and either last mode was different or a change in brightness has been registered
  if [ $CURRENT_BATTERY_MODE -eq $MODE_BATTERY_CHARGING ] && ([ $LAST_MODE -ne $MODE_BATTERY_CHARGING ] || [ $APPLIED_BRIGHTNESS -ne $LAST_APPLIED_BRIGHTNESS ]); then
    echo "Going to LED mode 'charging'"
    /usr/bin/analog_stick_led.sh $BATTERY_WARNING_MODE $APPLIED_BRIGHTNESS ${DEFAULT_COLOUR[0]} ${DEFAULT_COLOUR[1]} ${DEFAULT_COLOUR[2]} ${DEFAULT_COLOUR[0]} ${DEFAULT_COLOUR[1]} ${DEFAULT_COLOUR[2]}
    LAST_MODE=$MODE_BATTERY_CHARGING
    LAST_APPLIED_BRIGHTNESS=$APPLIED_BRIGHTNESS

  # If battery is low and either last mode was different or a change in brightness has been registered
  elif [ $CURRENT_BATTERY_MODE -eq $MODE_BATTERY_WARNING ] && ([ $LAST_MODE -ne $MODE_BATTERY_WARNING ] || [ $APPLIED_BRIGHTNESS -ne $LAST_APPLIED_BRIGHTNESS ]); then
    echo "Going to LED mode 'warning'"
    /usr/bin/analog_stick_led.sh $BATTERY_WARNING_MODE $APPLIED_BRIGHTNESS ${BATTERY_WARNING_COLOUR[0]} ${BATTERY_WARNING_COLOUR[1]} ${BATTERY_WARNING_COLOUR[2]} ${BATTERY_WARNING_COLOUR[0]} ${BATTERY_WARNING_COLOUR[1]} ${BATTERY_WARNING_COLOUR[2]}
    LAST_MODE=$MODE_BATTERY_WARNING
    LAST_APPLIED_BRIGHTNESS=$APPLIED_BRIGHTNESS
 
   # If battery is dangerously low and either last mode was different or a change in brightness has been registered
  elif [ $CURRENT_BATTERY_MODE -eq $MODE_BATTERY_DANGER ] && ([ $LAST_MODE -ne $MODE_BATTERY_DANGER ] || [ $APPLIED_BRIGHTNESS -ne $LAST_APPLIED_BRIGHTNESS ]); then
    echo "Going to LED mode 'danger'"
    /usr/bin/analog_stick_led.sh $MODE_BATTERY_DANGER $APPLIED_BRIGHTNESS ${BATTERY_DANGER_COLOUR[0]} ${BATTERY_DANGER_COLOUR[1]} ${BATTERY_DANGER_COLOUR[2]} ${BATTERY_DANGER_COLOUR[0]} ${BATTERY_DANGER_COLOUR[1]} ${BATTERY_DANGER_COLOUR[2]}
    LAST_MODE=$MODE_BATTERY_DANGER
    LAST_APPLIED_BRIGHTNESS=$APPLIED_BRIGHTNESS
  
  # If battery mode is none of the known battery modes
  elif [ $CURRENT_BATTERY_MODE -ne $MODE_BATTERY_CHARGING ] && [ $CURRENT_BATTERY_MODE -ne $MODE_BATTERY_WARNING ] && [ $CURRENT_BATTERY_MODE -ne $MODE_BATTERY_DANGER ]; then
  
    # Read LED variables from file:
    if [ -f $VAR_LED_VALUES ]; then
      LED_VALUES=($(cat $VAR_LED_VALUES))
      if [ "${#LED_VALUES[@]}" -lt 9 ]; then
        echo "Invalid number of LED values (${#LED_VALUES[@]}/9) - keeping last known values instead."
      elif [ "${#LED_VALUES[@]}" -eq 9 ] && [ "$(printf "%s" "${LED_VALUES[*]}")" != "$(printf "%s" "${LAST_LED_VALUES[*]}")" ]; then
        LED_SETTINGS_CHANGE_DETECTED=true
        LAST_LED_VALUES=(${LED_VALUES[0]} ${LED_VALUES[1]} ${LED_VALUES[2]} ${LED_VALUES[3]} ${LED_VALUES[4]} ${LED_VALUES[5]} ${LED_VALUES[6]} ${LED_VALUES[7]} ${LED_VALUES[8]})
      fi
    fi
  
    # Let's make LED values human-readable to avoid headaches:
    LED_MODE=${LAST_LED_VALUES[0]}
    LED_BRIGHTNESS=${LAST_LED_VALUES[1]}
    LED_SPEED=${LAST_LED_VALUES[2]}
    LED_LEFT_R=${LAST_LED_VALUES[3]}
    LED_LEFT_G=${LAST_LED_VALUES[4]}
    LED_LEFT_B=${LAST_LED_VALUES[5]}
    LED_RIGHT_R=${LAST_LED_VALUES[6]}
    LED_RIGHT_G=${LAST_LED_VALUES[7]}
    LED_RIGHT_B=${LAST_LED_VALUES[8]}
  
    # If LED mode was set to 0 (off) and last mode was different
    if [ $LAST_MODE -ne $MODE_OFF ] && [ $LED_MODE -eq 0 ]; then
      echo "Turning off RGB LEDs."
      /usr/bin/analog_stick_led.sh $LED_MODE
      LAST_MODE=$MODE_OFF
    
    # If a change in LED variables was detected or the last mode was different or applied brightness has changed
    elif [ $LED_MODE -gt 0 ] && ($LED_SETTINGS_CHANGE_DETECTED || [ $LAST_MODE -ne $MODE_DEFAULT ] || [ $APPLIED_BRIGHTNESS -ne $LAST_APPLIED_BRIGHTNESS ]); then
      echo "Going to normal LED mode"
      if [ $LED_MODE -lt 5 ]; then
        /usr/bin/analog_stick_led.sh $LED_MODE $APPLIED_BRIGHTNESS  $LED_RIGHT_R $LED_RIGHT_G $LED_RIGHT_B $LED_LEFT_R $LED_LEFT_G $LED_LEFT_B
      else
        /usr/bin/analog_stick_led.sh $LED_MODE $APPLIED_BRIGHTNESS $LED_SPEED
      fi
      LAST_MODE=$MODE_DEFAULT
      LED_SETTINGS_CHANGE_DETECTED=false
      LAST_APPLIED_BRIGHTNESS=$APPLIED_BRIGHTNESS
    fi
  fi

}

# Applies changes to the LEDs based on LED variables and battery status.
ledDaemon() {

  LOOP_COUNT=0
  # Apply updated LED settings when variables or battery capacity/status has changed
  while :; do

    # Determine the last-modified date of batocera.conf
    CURRENT_CONF_CHANGE_DATE=$(date -r "/userdata/system/batocera.conf")

    # Only check for details if batocera.conf has recently been changed
    if [ "$LAST_CONF_CHANGE_DATE" != "$CURRENT_CONF_CHANGE_DATE" ]; then
      readLedValues
      readBatteryValues
      LAST_CONF_CHANGE_DATE=$CURRENT_CONF_CHANGE_DATE
    fi
    
    READ_CAPACITY=false
    if [ $LOOP_COUNT -eq $MAX_LOOP_COUNT ]; then
      READ_CAPACITY=true
      LOOP_COUNT=0
    else
      LOOP_COUNT=$((LOOP_COUNT+1))
    fi

    updateCurrentBatteryMode $READ_CAPACITY
    
    applyLedSettings

    # Sleep until interval is over
    sleep $UPDATE_INTERVAL_SECONDS
  done

}

# Starts the daemon.
start() {
  # Clear variables from previous run if required
  if [ $# -eq 1 ] && [ "$1" == "clear" ]; then
    clearLedValues
  fi

  # Initialize missing values in batocera.conf
  initializeLedValues

  # If no variables are set from previous session,
  # initialize led settings from batocera.conf
  if [ ! -f "$VAR_LED_VALUES" ]; then
    readLedValues
  fi
  # Read battery values from batocera.conf.
  readBatteryValues

  # Read battery values at start
  updateCurrentBatteryMode

  # Launch LED daemon
  ledDaemon &
  LED_PID=$!
  echo $LED_PID > $VAR_LED_PID
  echo "Started analog stick RGB LED daemon."

}

# Stops the daemon.
stop() {
  kill $(cat $VAR_LED_PID)
  rm $VAR_LED_PID
  /usr/bin/analog_stick_led.sh 0
  echo "Stopped analog stick RGB LED daemon."
}

# Restarts the daemon.
restart() {
  stop
  start $1
}

# Temporarily stops the deamon, runs the given
# animation and restarts the daemon when the animation
# has concluded.
runAnimation() {
  # Check if daemon is running
  if [ ! -f $VAR_LED_PID ]; then
    echo "Unable to run animation: RGB LED daemon is not running (missing PID)."
    exit -1
  fi
  # Read current process ID
  LED_PID=$(cat $VAR_LED_PID)
  # If daemon is running, temporarily stop and run animation
  if ps -p $LED_PID > /dev/null; then
    # Stop daemon without turning of LEDs
    kill $LED_PID
    updateAppliedBrightness
    # Play rainbow animation
    if [ $# -eq 1 ] && [ "$1" == "rainbow" ]; then
      /usr/bin/analog_stick_led.sh 6 $APPLIED_BRIGHTNESS 50
      LAST_APPLIED_BRIGHTNESS=$APPLIED_BRIGHTNESS
      sleep 1.5
    fi
    # Restart LED daemon with latest settings
    start
  else
   echo "Unable to run animation: RGB LED daemon is not running (missing process with PID $LED_PID)."
   exit -1
  fi
}

# Prints instructions to stdout.
printInstructions() {
  echo "Usage: $0 [operation] [arguments]"
  echo "Daemon for analog stick RGB LED control on Anbernic devices"
  echo "from the RG40XX H/V series."
  echo ""
  echo "Possible operations:"
  echo "  start      Launches the LED daemon with default behavior."
  echo "  restart    Restarts the LED daemon."
  echo "  import     Re-imports settings from batocera.conf."
  echo "  set        Temporarily overrides settings from batocera.conf"
  echo "             with manually set RGB colors. Example:"
  echo "             $0 set 148 255 0"
  echo "  animation  Runs the given animation. Example:"
  echo "             $0 animation rainbow"
  echo "             Supported animations: rainbow"
  echo ""
  echo "Requires analog_stick_led.sh to be installed."
  echo "Only works on RG40XX H/V devices."
}

if [ $# -eq 0 ]; then
  printInstructions
  exit 1
elif [ "$1" == "start" ]; then
  start $2
elif [ "$1" == "stop" ]; then
  stop
elif [ "$1" == "restart" ]; then
  restart $2
elif [ "$1" == "import" ]; then
  readLedValues
elif [ "$1" == "animation" ]; then
  if [ $# -eq 2 ] && [ "$2" == "rainbow" ]; then
    runAnimation $2
  else
    printInstructions
  fi
elif [ $# -eq 4 ] && [ "$1" == "set" ]; then
  BRIGHTNESS=$(batocera-settings-get $KEY_LED_BRIGHTNESS)
  SPEED=$(batocera-settings-get $KEY_LED_SPEED)
  setLedValues 1 $BRIGHTNESS $SPEED $2 $3 $4 $2 $3 $4
else 
  printInstructions
fi
