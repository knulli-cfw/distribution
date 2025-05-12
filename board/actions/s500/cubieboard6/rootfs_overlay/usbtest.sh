#!/bin/sh

usb_gandroid0_enable="/sys/class/android_usb/android0/enable"
usb_gandroid0_idVendor="/sys/class/android_usb/android0/idVendor"
usb_gandroid0_idProduct="/sys/class/android_usb/android0/idProduct"
usb_gandroid0_functions="/sys/class/android_usb/android0/functions"

echo "------usbtest"

echo "------adb stop" > /dev/console
/system/bin/stop adbd

echo '0' > $usb_gandroid0_enable
echo "10d6" > $usb_gandroid0_idVendor
echo "0c02" > $usb_gandroid0_idProduct
echo "mass_storage,adb" > $usb_gandroid0_functions
echo '1' > $usb_gandroid0_enable

echo "------adb start" > /dev/console
/system/bin/start adbd
