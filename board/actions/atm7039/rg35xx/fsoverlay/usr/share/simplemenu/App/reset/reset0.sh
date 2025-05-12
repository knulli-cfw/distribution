#!/bin/sh
echo $0 $*
cd $(dirname "$0")
HOME=/mnt/SDCARD
export SDCARD_PATH=/mnt/SDCARD
export SYSTEM_PATH=${SDCARD_PATH}/Koriki
SETTINGS_INT_FILE="/appconfigs/system.json"
SETTINGS_EXT_FILE="/mnt/SDCARD/system.json"

# Detect flash type
if dmesg|fgrep -q "[FSP] Flash is detected (0x1100, 0x68, 0x40, 0x18) ver1.1"; then
    export SETTINGS_FILE=$SETTINGS_EXT_FILE
else
    export SETTINGS_FILE=$SETTINGS_INT_FILE
fi

# Detect model
if [ ! -f /customer/app/axp_test ]; then
    export MODEL="MM"
else
    export MODEL="MMP"
fi

reset_settings() {
        if [ $MODEL = "MM" ]; then
            cp ${SYSTEM_PATH}/assets/system.json $SETTINGS_FILE
			cp ${SYSTEM_PATH}/assets/last_state.sav ${SDCARD_PATH}/.simplemenu/last_state.sav
            sync
			reboot
            sleep 10s
        else
            cp ${SYSTEM_PATH}/assets/system.mmp.json $SETTINGS_FILE
			cp ${SYSTEM_PATH}/assets/last_state.sav ${SDCARD_PATH}/.simplemenu/last_state.sav
            sync
            reboot
            sleep 10s
        fi
}

reset_settings
