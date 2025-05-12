#!/bin/sh

alsactl store 0 /userdata/system/.asound.state

amixer -q set "speaker on off switch" "off"

sync

/etc/init.d/rcK

echo o > /proc/sysrq-trigger 


