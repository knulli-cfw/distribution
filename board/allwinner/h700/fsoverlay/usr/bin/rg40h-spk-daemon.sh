#!/bin/sh
trap 'exit 0' SIGTERM

BOARD=$(cat /boot/boot/batocera.board)
if [ "$BOARD" != "rg40xx-h" ]; then
    /etc/init.d/S98rg40h-spk-daemon stop
	exit 1
fi

# The RG40XX-H has swapped audio channels for speakers, but not for headphones.
#
# The new kernel in version 1.0.3 of the stock firmware resolves this bug, but
# we currently use a patched version of an older stock kernel (to fix cardinal
# snapping issues), and upgrading it isn't trivial.
#
# For now, poll spk_state (0 -> headphones plugged, 1 -> headphones unplugged)
# and swap DACL and DACR when the state changes.


LAST_STATE=""

sleep 5 # Wait for boot processes to finish

while true; do
	STATE="$(cat /sys/class/power_supply/axp2202-battery/spk_state)"
	if [ "$STATE" != "$LAST_STATE" ]; then
		case "$STATE" in
			0)
				# Headphones: Normal channel mapping
				amixer -c 0 set 'OutputL Mixer DACL' on
				amixer -c 0 set 'OutputL Mixer DACR' off
				amixer -c 0 set 'OutputR Mixer DACL' off
				amixer -c 0 set 'OutputR Mixer DACR' on
				;;
			1)
				# Speakers: Reversed channel mapping
				amixer -c 0 set 'OutputL Mixer DACL' off
				amixer -c 0 set 'OutputL Mixer DACR' on
				amixer -c 0 set 'OutputR Mixer DACL' on
				amixer -c 0 set 'OutputR Mixer DACR' off
				;;
		esac
	fi
	LAST_STATE="$STATE"
	sleep 1
done

exit 0
