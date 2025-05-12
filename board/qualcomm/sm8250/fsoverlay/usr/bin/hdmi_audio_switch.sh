#!/bin/sh

check_ingame() {
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:1234/runningGame")

    if [ $? -ne 0 ]; then
        echo "Host unreachable."
        return 1
    fi

    if [ "$HTTP_STATUS" -eq 201 ]; then
        echo "An emulator is running, exiting."
        return 1
    else
        return 0
    fi
}

if check_ingame; then
    exit 1 # We don't want emulation station restarting while a emulator is running
fi

curl http://localhost:1234/quit? # Restarts ES gracefully

while pidof emulationstation > /dev/null; do
        sleep 0.5  # Wait until emulationstation is fully stopped
done

HDMI_STATE="$(cat /sys/devices/platform/soc/6000000.hdmi/extcon/hdmi/state)"

if [ "$HDMI_STATE" = "HDMI=1" ]; then
    batocera-audio set alsa_output._sys_devices_platform_soc_soc_03000000_ahub1_mach_sound_card2.stereo-fallback
else
    batocera-audio set alsa_output._sys_devices_platform_soc_soc_03000000_codec_mach_sound_card0.stereo-fallback
fi

exit 0
