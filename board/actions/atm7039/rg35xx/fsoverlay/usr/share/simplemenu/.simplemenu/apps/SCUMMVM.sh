#!/bin/sh
export HOME=/userdata/system/
cd $HOME
export SDL_GAMECONTROLLERCONFIG=$(grep "RG35XX" "${HOME}/.config/gamecontrolerdb.txt")
scummvm

