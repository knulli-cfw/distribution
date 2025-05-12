#!/bin/sh

export SDL_GAMECONTROLLERCONFIG=$(grep "RG35XX" "${HOME}/.config/gamecontrollerdb.txt")

SDL_FULLSCREEN=1 SpaceCadetPinball

