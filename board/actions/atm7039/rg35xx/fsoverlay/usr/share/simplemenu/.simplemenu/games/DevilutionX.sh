#!/bin/sh

export HOME=/userdata/system

cd /userdata/roms/devilutionx

export SDL_GAMECONTROLLERCONFIG=$(grep "RG35XX" "${HOME}/.config/gamecontrollerdb.txt")

devilutionx

