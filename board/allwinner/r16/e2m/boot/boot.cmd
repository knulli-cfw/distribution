setenv bootm_boot_mode sec
setenv bootargs console=ttyS0,115200 loglevel=0 root=/dev/mmcblk0p2 rootwait panic=10
fatload mmc 1 0x48000000 boot/uInitrd
fatload mmc 1 0x42000000 boot/linux
bootm 0x42000000 0x48000000


