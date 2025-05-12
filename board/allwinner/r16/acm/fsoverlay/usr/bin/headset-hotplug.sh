#!/bin/sh

#SWITCH_STATE=`cat /sys/devices/virtual/switch/audio_jack/state`

case $SWITCH_STATE in
    0)
        echo "New headset"
        amixer -c 1 cset name='Speaker Function' 0
        ;;

    1)
        echo "No headset"
        if [ `cat /sys/devices/virtual/switch/hdmi/state` == "1" ]; then
          amixer -c 1 cset name='Speaker Function' '0'
        else
          amixer -c 1 cset name='Speaker Function' '1'
        fi
        ;;

    *)
        echo "Unexpected state: $SWITCH_STATE"
esac

exit 0
