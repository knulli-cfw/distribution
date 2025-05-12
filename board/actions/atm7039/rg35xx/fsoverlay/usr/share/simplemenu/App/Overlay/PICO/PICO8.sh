#!/bin/sh
echo $0 $*
cd $(dirname "$0")
HOME=/mnt/SDCARD
./OverlaySelector-PICO8-FAKE-08
sync