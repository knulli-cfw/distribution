#!/bin/sh

echo "------usbdbg $1"

# shutdown usb monitor
echo 0 > /sys/monitor/usb_port/config/run

if [ $1 = host ];then
	# device -> host
    echo 0 > /sys/monitor/usb_port/config/idpin_debug
	/usbmond.sh USB_B_OUT && /usbmond.sh USB_A_IN
else
	# host -> device
    echo 1 > /sys/monitor/usb_port/config/idpin_debug
	/usbmond.sh USB_A_OUT && /usbmond.sh USB_B_IN
fi
