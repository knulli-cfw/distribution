#!/bin/bash

export HOME=/userdata/system
export GAMEDIR="/userdata/roms/ports/curseofissyos"
cd $GAMEDIR

export GMLOADER_DEPTH_DISABLE=1
export GMLOADER_SAVEDIR="$GAMEDIR/gamedata/"
export SDL_GAMECONTROLLERCONFIG=$(grep "RG35XX" "${HOME}/.config/gamecontrollerdb.txt")

# Fix for older releases
if [[ x"$SDL_GAMECONTROLLERCONFIG" == x ]]; then
	export SDL_GAMECONTROLLERCONFIG='19000000010000000100000000010000,RG35XX Gamepad,a:b1,b:b0,back:b7,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftshoulder:b5,lefttrigger:+a2,rightshoulder:b6,righttrigger:+a5,guide:b9,start:b8,x:b3,y:b2,platform:Linux,'
fi

chmod +x $GAMEDIR/gmloader

# Kill the evmapy utility if it's running

./gmloader IssyosWrapper.apk |& tee log.txt /dev/tty0
