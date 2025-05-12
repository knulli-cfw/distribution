#!/bin/bash

export HOME=/userdata/system
export GAMEDIR="/userdata/roms/ports/spelunkyclassichd"
cd $GAMEDIR

export GMLOADER_DEPTH_DISABLE=1
export GMLOADER_SAVEDIR="$GAMEDIR/gamedata/"

export SDL_GAMECONTROLLERCONFIG=$(grep "RG35XX" "${HOME}/.config/gamecontrollerdb.txt")

chmod +x $GAMEDIR/xdelta3
chmod +x $GAMEDIR/gmloader

./gmloader gamedata/spelunky_classic_hd-android-armv7.apk 2>&1 | tee "$GAMEDIR/log.txt"

