#!/bin/sh

export HOME=/userdata/system

cd /userdata/roms/ports/eduke32

export SDL_GAMECONTROLLERCONFIG=$(grep "RG35XX" "${HOME}/.config/gamecontrolerdb.txt")

eduke32
