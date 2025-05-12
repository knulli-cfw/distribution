#!/bin/sh

export LD_LIBRARY_PATH=/usr/local/XSGX/lib:/lib:/usr/lib
export DISPLAY=:0
export HOME=/userdata/system
export SDL_RENDER_DRIVER=opengles2
cd $HOME

SAVEIFS=$IFS
CORE=$1
ROM=\"$2\"

echo "CORE: $CORE"
echo "ROM: $ROM"

eval retroarch -c /userdata/system/.config/retroarch/retroarch.cfg  -L /usr/lib/libretro/${CORE}_libretro.so $ROM --verbose


