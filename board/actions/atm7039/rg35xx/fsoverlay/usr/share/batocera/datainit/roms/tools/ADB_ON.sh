#!/bin/sh


echo "Starting ADB..."

modprobe g_cdc
modprobe usb_f_acm
modprobe g_android
modprobe u_serial

echo 0 > /sys/monitor/usb_port/config/run

# host -> device
echo 1 > /sys/monitor/usb_port/config/idpin_debug
/usbmond.sh USB_A_OUT && /usbmond.sh USB_B_IN

