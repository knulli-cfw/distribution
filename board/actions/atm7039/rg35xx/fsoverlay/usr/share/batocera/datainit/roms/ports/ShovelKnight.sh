#!/bin/bash

export HOME="/userdata/system"
export GAMEDIR="/userdata/roms/ports/shovelknight"
export SDL_ASSERT=always_ignore

# Fix for nonsense paths in previous packaging...
if [ -d "$GAMEDIR/gamedata/shovelknight/32" ]; then
	cd "$GAMEDIR/gamedata/shovelknight/32"
else
	cd "$GAMEDIR/gamedata/32"
fi

# Available through libShovelKnight.so hacks
export SDL_VIDEO_GL_DRIVER="$GAMEDIR/box86/native/libGL.so.1"
export SDL_VIDEO_EGL_DRIVER="$GAMEDIR/box86/native/libEGL.so.1"
export LD_LIBRARY_PATH="$GAMEDIR/box86/lib:$GAMEDIR/box86/native"
export LIBGL_NOBANNER=0
export LIBGL_ES=2
export LIBGL_GL=21
export LIBGL_FB=1
export BOX86_LOG=0
export BOX86_LD_LIBRARY_PATH="$GAMEDIR/box86/lib:$(pwd)/:$(pwd)/lib/"
export BOX86_DYNAREC=1
export BOX86_FORCE_ES=20
export BOX86_ALLOWMISSINGLIBS=1
export BOX86_DLSYM_ERROR=1
#export SDL_GAMECONTROLLERCONFIG='19000000010000000100000000010000,RG35XX Gamepad,a:b1,b:b0,back:b7,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftshoulder:b5,lefttrigger:+a2,rightshoulder:b6,righttrigger:+a5,guide:b9,start:b8,x:b3,y:b2,platform:Linux,'

export SDL_GAMECONTROLLERCONFIG=$(grep "RG35XX" "${HOME}/.config/gamecontrollerdb.txt")

# Load the Shovel Knight specific hacks (no steam nag, use $SHOVELKNIGHT_SAVE_PATH, ...)
export BOX86_LD_PRELOAD="$GAMEDIR/libShovelKnight.so"

# Ensure all binaries are executable.
chmod +x "$GAMEDIR/box86/box86"
chmod +x ShovelKnight

# Ensure savedir exists
export SHOVELKNIGHT_SAVE_PATH="$GAMEDIR/savedata"
mkdir -p "$SHOVELKNIGHT_SAVE_PATH"

$GAMEDIR/box86/box86 ./ShovelKnight 2>&1 | tee $GAMEDIR/log.txt

