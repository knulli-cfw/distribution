#!/bin/sh

usb_gandroid0_enable="/sys/class/android_usb/android0/enable"
usb_gandroid0_idVendor="/sys/class/android_usb/android0/idVendor"
usb_gandroid0_idProduct="/sys/class/android_usb/android0/idProduct"
usb_gandroid0_functions="/sys/class/android_usb/android0/functions"
usb_gandroid0_lun0="/sys/class/android_usb/android0/f_mass_storage/lun0/file"
usb_gandroid0_lun1="/sys/class/android_usb/android0/f_mass_storage/lun1/file"
usb_gandroid0_iManufacturer="/sys/class/android_usb/android0/iManufacturer"
usb_gandroid0_iProduct="/sys/class/android_usb/android0/iProduct"

echo "------usbmond shell: $1"

if [ $1 = USB_B_IN ];then
	echo "------USB_B_IN: device mode" > /dev/console
	
	echo "USB_B_IN" > /sys/monitor/usb_port/config/usb_con_msg

	echo "Anbernic" > $usb_gandroid0_iManufacturer
	echo "RG35XX" > $usb_gandroid0_iProduct
	echo '0' > $usb_gandroid0_enable
	echo "10d6" > $usb_gandroid0_idVendor
	
#	if [ $2 = MTP ];then
#		echo "4e42" > $usb_gandroid0_idProduct
#		echo "mtp,adb" > $usb_gandroid0_functions
#	else
		echo "0c02" > $usb_gandroid0_idProduct
		echo "mass_storage,adb" > $usb_gandroid0_functions
#	fi
	
	echo '1' > $usb_gandroid0_enable

	# Don't start adbd by default
	echo "------adb start in B_IN" > /dev/console
	adbd &
fi

if [ $1 = USB_B_OUT ];then
	# in case that adbd has been started
	echo "------adb stop in B_OUT" > /dev/console
	killall adbd
	sleep 1

	echo "USB_B_OUT" > /sys/monitor/usb_port/config/usb_con_msg
	echo "------USB_B_OUT: device mode" > /dev/console

	echo "" > /sys/class/android_usb/android0/f_mass_storage/lun0/file
	echo "" > /sys/class/android_usb/android0/f_mass_storage/lun1/file
fi

if [ $1 = USB_A_IN ];then
	echo "USB_A_IN" > /sys/monitor/usb_port/config/usb_con_msg
fi

if [ $1 = USB_A_OUT ];then
	echo "USB_A_OUT" > /sys/monitor/usb_port/config/usb_con_msg
fi

# mount disk/partition to PC
if [ $1 = ADD_LUN ];then
X	echo "------usbmond shell: $1 $2"
	if [ $2 = LUN0 ];then
		echo $3 > $usb_gandroid0_lun0
	elif [ $2 = LUN1 ];then
		echo $3 > $usb_gandroid0_lun1
	elif [ $2 = LUN2 ];then
		echo $3 > $usb_gandroid0_lun0
		echo $4 > $usb_gandroid0_lun1
	fi
fi

# umount disk/partition to PC
if [ $1 = REMOVE_LUN ];then
	echo "------usbmond shell: $1 $2"
	if [ $2 = LUN0 ];then
		echo  > $usb_gandroid0_lun0
	elif [ $2 = LUN1 ];then
		echo  > $usb_gandroid0_lun1
	fi
fi

if [ $1 = RNDIS ]; then
	killall -9 adbd
        echo "Anbernic" > $usb_gandroid0_iManufacturer
        echo "RG35XX" > $usb_gandroid0_iProduct
        echo '0' > $usb_gandroid0_enable
        echo "10d6" > $usb_gandroid0_idVendor
	echo "0c02" > $usb_gandroid0_idProduct
	echo "rndis" > $usb_gandroid0_functions
	echo 1 > /sys/class/android_usb/android0/f_rndis/wceis
	
	# Create dir for dnsmasq
	mkdir -p /var/lib/misc
	dnsmasq
	dropbear -R
	echo '1' > $usb_gandroid0_enable
	(
		sleep 2
		ip addr add 172.16.0.1/24 dev rndis0
		ip link set rndis0 up
	) &
fi

