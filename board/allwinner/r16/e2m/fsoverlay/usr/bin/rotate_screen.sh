#!/bin/sh

ROTATE=$1

if [[ ${ROTATE} == "1" ]]; then
	batocera-settings-set display.rotate 0
        batocera-settings-set global.retroarch.aspect_ratio_index 8
        curl http://localhost:1234/quit
else
	batocera-settings-set display.rotate 1
        batocera-settings-set global.retroarch.aspect_ratio_index 0
        curl http://localhost:1234/quit
fi

