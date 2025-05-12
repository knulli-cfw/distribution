#!/bin/sh

ROTATE=$1
HDMISTATUS=$(cat /sys/devices/virtual/switch/hdmi/state)

if [[ ${ROTATE} == "1" ]] || [[ ${HDMISTATUS} == "1" ]]; then
	batocera-settings-set display.rotate 0
        curl http://localhost:1234/quit
else
	batocera-settings-set display.rotate 1
        curl http://localhost:1234/quit
fi

