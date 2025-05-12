#!/bin/sh

echo "simplemenu" > /userdata/system/customlauncher

killall -9 retroarch-launcher.sh simplemenu retroarch

retroarch-launcher.sh

