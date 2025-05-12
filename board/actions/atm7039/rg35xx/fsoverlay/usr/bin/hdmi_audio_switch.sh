#!/bin/sh

if [[ $(cat /sys/devices/virtual/switch/hdmi/state) -eq 1 ]]; then
#        sed -i "s/0,0/0,1/g" /etc/asound.conf
        mount -o bind /usr/share/configs/hdmi_asound.conf /etc/asound.conf
	echo 1 > /sys/class/graphics/fb0/mirror_to_hdmi
	echo 4 > /sys/class/backlight/backlight.2/bl_power
else
#        sed -i "s/0,1/0,0/g" /etc/asound.conf
        umount /etc/asound.conf
	echo 0 > /sys/class/graphics/fb0/mirror_to_hdmi 
	echo 0 > /sys/class/backlight/backlight.2/bl_power
fi


