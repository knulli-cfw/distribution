#!/bin/sh

alsactl store 0 -f /userdata/system/.asound.state

#/etc/init.d/rcK
sync

reboot

