#!/bin/bash

export HOME=/userdata/system
export GAMEDIR="/userdata/roms/ports/malditacastilla"
cd $GAMEDIR

export GMLOADER_DEPTH_DISABLE=1
export GMLOADER_SAVEDIR="$GAMEDIR/gamedata/"
export SDL_GAMECONTROLLERCONFIG=$(grep "RG35XX" "${HOME}/.config/gamecontrollerdb.txt")

echo $SDL_GAMECONTROLLERCONFIG

chmod +x $GAMEDIR/xdelta3
chmod +x $GAMEDIR/gmloader

# If Windows/Linux install, move the data file.
if [ -f 'gamedata/data.win' ] && [ ! -f 'gamedata/game.droid' ]; then
	echo "performing first time setup..." |& tee install_log.txt /dev/tty0
	if [ ! -f 'gamedata/data.win' ]; then
		echo "No data.win, please copy files into the 'gamedata/' folder." |& tee -a install_log.txt /dev/tty0
		sleep 5
		exit 1
	fi

	SHA1SUM=$(sha1sum gamedata/data.win | cut -d ' ' -f 1)
	PATCH=""
	case $SHA1SUM in
		"194692ad55916d9bef7bb910f824c6b5e76e85a1") PATCH=mcex_steam.xdelta ;;
		*)
		echo "Unknown Maldita Castilla EX version, check for updates via PortMaster." |& tee -a install_log.txt /dev/tty0
		echo "If this is wrong, please report the sha1sum code:" |& tee -a install_log.txt /dev/tty0
		echo "sha1sum: $SHA1SUM" |& tee -a install_log.txt /dev/tty0
		sleep 5
		exit 1
		;;
	esac

	./xdelta3 -d -s gamedata/data.win $PATCH gamedata/game.droid |& tee -a install_log.txt /dev/tty0
	if [ $? != 0 ]; then
		echo "First time setup failed." |& tee -a install_log.txt /dev/tty0
		sleep 5
		exit 1
	fi
fi

if [[ -e "gamedata/game.droid" ]]; then
	export GMLOADER_PLATFORM="os_windows"

	echo "Launching Maldita Castilla EX (Retail)" |& tee log.txt /dev/tty0
	./gmloader MalditaEXWrapper.apk |& tee -a log.txt /dev/tty0
else
	echo "Launching Maldita Castilla (Ouya)" |& tee log.txt /dev/tty0
	./gmloader gamedata/Maldita_Castilla_ouya.apk |& tee -a log.txt /dev/tty0
fi

exit 0

