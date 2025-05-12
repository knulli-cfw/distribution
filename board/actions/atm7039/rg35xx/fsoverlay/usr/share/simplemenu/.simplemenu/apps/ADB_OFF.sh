#!/bin/sh

echo "Stopping ADB..."

killall -9 adbd 

echo 0 > /sys/monitor/usb_port/config/run

# host -> device
echo 1 > /sys/monitor/usb_port/config/idpin_debug
/usbmond.sh USB_B_OUT && /usbmond.sh USB_A_IN

