consoles="/mnt/SDCARD/.simplemenu/section_groups/arcades.ini"

cat > ${consoles} <<EOF
[CONSOLES]
consoleList = GAME BOY,GAME BOY COLOR,GAME BOY ADVANCE,GAME & WATCH,GAME GEAR,ATARI LYNX,NEO GEO POCKET,WONDERSWAN,POKEMON MINI,SUPERVISION

[GAME BOY]
execs = /mnt/SDCARD/.simplemenu/launchers/gambatte_libretro,/mnt/SDCARD/.simplemenu/launchers/gearboy_libretro
romDirs = /mnt/SDCARD/Roms/GB/
romExts = .gb,.gz,.zip,.7z
scaling = 1

[GAME BOY COLOR]
execs = /mnt/SDCARD/.simplemenu/launchers/gambatte_libretro,/mnt/SDCARD/.simplemenu/launchers/gearboy_libretro
romDirs = /mnt/SDCARD/Roms/GBC/
romExts = .gbc,.zip,.7z
scaling = 1

[GAME BOY ADVANCE]
execs = /mnt/SDCARD/.simplemenu/launchers/gpsp_libretro,/mnt/SDCARD/.simplemenu/launchers/mgba_libretro,/mnt/SDCARD/.simplemenu/launchers/mednafen_gba_libretro,/mnt/SDCARD/.simplemenu/launchers/meteor_libretro,/mnt/SDCARD/.simplemenu/launchers/vbam_libretro,/mnt/SDCARD/.simplemenu/launchers/vba_next_libretro
romDirs = /mnt/SDCARD/Roms/GBA/
romExts = .gba,.zip,.7z
scaling = 1

[GAME & WATCH]
execs = /mnt/SDCARD/.simplemenu/launchers/gw_libretro
romDirs = /mnt/SDCARD/Roms/GW/
romExts = .mgw,.zip,.7z
scaling = 1

[GAME GEAR]
execs = /mnt/SDCARD/.simplemenu/launchers/picodrive_libretro,/mnt/SDCARD/.simplemenu/launchers/genesis_plus_gx_libretro,/mnt/SDCARD/.simplemenu/launchers/gearsystem_libretro
romDirs = /mnt/SDCARD/Roms/GG/
romExts = .zip,.gg,.7z
scaling = 1

[ATARI LYNX]
execs = /mnt/SDCARD/.simplemenu/launchers/handy_libretro,/mnt/SDCARD/.simplemenu/launchers/mednafen_lynx_libretro
romDirs = /mnt/SDCARD/Roms/LYNX/
romExts = .zip,.lnx,.7z
scaling = 1

[NEO GEO POCKET]
execs = /mnt/SDCARD/.simplemenu/launchers/mednafen_ngp_libretro
romDirs = /mnt/SDCARD/Roms/NGP/
romExts = .ngp,.ngc,.ngpc,.npc,.zip,.7z
scaling = 1

[WONDERSWAN]
execs = /mnt/SDCARD/.simplemenu/launchers/mednafen_wswan_libretro
romDirs = /mnt/SDCARD/Roms/WS/
romExts = .ws,.wsc,.pc2,.zip,.7z
scaling = 1

[POKEMON MINI]
execs = /mnt/SDCARD/.simplemenu/launchers/pokemini_libretro
romDirs = /mnt/SDCARD/Roms/POKE/
romExts = .min,.zip,.7z
scaling = 1

[SUPERVISION]
execs = /mnt/SDCARD/.simplemenu/launchers/potator_libretro
romDirs = /mnt/SDCARD/Roms/SUPERVISION/
romExts = .bin,.sv,.zip,.7z
scaling = 1
EOF