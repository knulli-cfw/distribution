#!/bin/sh

alsactl store 0 /userdata/system/.asound.state

amixer -q set "speaker on off switch" "off"

/etc/init.d/rcK
sync

echo b > /proc/sysrq-trigger 

