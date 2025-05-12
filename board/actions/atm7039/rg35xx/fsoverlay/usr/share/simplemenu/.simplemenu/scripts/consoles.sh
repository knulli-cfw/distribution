consoles="/mnt/SDCARD/.simplemenu/section_groups/arcades.ini"

cat > ${consoles} <<EOF
[CONSOLES]
consoleList = NES,FDS,SNES,MSU-1,SGB,VIRTUAL BOY,SEGA SG-1000,MASTER SYSTEM,SEGA GENESIS,SEGA CD,SEGA 32X,ATARI 2600,ATARI 5200,ATARI 7800,INTELLIVISION,NEO GEO CD,PC ENGINE,PC ENGINE CD,PLAYSTATION

[NES]
execs = /mnt/SDCARD/.simplemenu/launchers/fceumm_libretro,/mnt/SDCARD/.simplemenu/launchers/nestopia_libretro
romDirs = /mnt/SDCARD/Roms/FC/
romExts = .nes,.zip,.7z

[FDS]
execs = /mnt/SDCARD/.simplemenu/launchers/fceumm_libretro,/mnt/SDCARD/.simplemenu/launchers/nestopia_libretro
romDirs = /mnt/SDCARD/Roms/FDS/
romExts = .fds,.zip,.7z

[SNES]
execs = /mnt/SDCARD/.simplemenu/launchers/mednafen_supafaust_libretro,/mnt/SDCARD/.simplemenu/launchers/snes9x2005_libretro,/mnt/SDCARD/.simplemenu/launchers/snes9x2005_plus_libretro,/mnt/SDCARD/.simplemenu/launchers/snes9x2002_libretro,/mnt/SDCARD/.simplemenu/launchers/snes9x2010_libretro,/mnt/SDCARD/.simplemenu/launchers/snes9x_libretro,/mnt/SDCARD/.simplemenu/launchers/snes9x_next_libretro,/mnt/SDCARD/.simplemenu/launchers/quicknes_libretro
romDirs = /mnt/SDCARD/Roms/SFC/
romExts = .smc,.sfc,.zip,.7z

[MSU-1]
execs = /mnt/SDCARD/.simplemenu/launchers/msu1_libretro
romDirs = /mnt/SDCARD/Roms/MSU1/
romExts = .smc,.sfc,.zip,.7z
aliasFile = /mnt/SDCARD/.simplemenu/alias_MSU-1.txt

[SGB]
execs = /mnt/SDCARD/.simplemenu/launchers/msgb_libretro
romDirs = /mnt/SDCARD/Roms/SGB/
romExts = .gb,.gbc,.zip,.7z

[VIRTUAL BOY]
execs = /mnt/SDCARD/.simplemenu/launchers/mednafen_vb_libretro
romDirs = /mnt/SDCARD/Roms/VB/
romExts = .vb,.vboy,.bin,.zip,.7z

[SEGA SG-1000]
execs = /mnt/SDCARD/.simplemenu/launchers/gearsystem_libretro,/mnt/SDCARD/.simplemenu/launchers/genesis_plus_gx_libretro
romDirs = /mnt/SDCARD/Roms/SEGASGONE/
romExts = .zip,.sg,.7z

[MASTER SYSTEM]
execs = /mnt/SDCARD/.simplemenu/launchers/picodrive_libretro,/mnt/SDCARD/.simplemenu/launchers/genesis_plus_gx_libretro,/mnt/SDCARD/.simplemenu/launchers/gearsystem_libretro
romDirs = /mnt/SDCARD/Roms/MS/
romExts = .zip,.sms,.7z

[SEGA GENESIS]
execs = /mnt/SDCARD/.simplemenu/launchers/picodrive_libretro,/mnt/SDCARD/.simplemenu/launchers/genesis_plus_gx_libretro
romDirs = /mnt/SDCARD/Roms/MD/
romExts = .zip,.bin,.smd,.md,.mdx,.gen,.7z

[SEGA CD]
execs = /mnt/SDCARD/.simplemenu/launchers/picodrive_libretro,/mnt/SDCARD/.simplemenu/launchers/genesis_plus_gx_libretro
romDirs = /mnt/SDCARD/Roms/SEGACD/
romExts = .bin,.chd,.cue

[SEGA 32X]
execs = /mnt/SDCARD/.simplemenu/launchers/picodrive_libretro
romDirs = /mnt/SDCARD/Roms/THIRTYTWOX/
romExts = .zip,.32x,.7z

[ATARI 2600]
execs = /mnt/SDCARD/.simplemenu/launchers/stella2014_libretro
romDirs = /mnt/SDCARD/Roms/ATARI/
romExts = .bin,.a26,.zip,.7z

[ATARI 5200]
execs = /mnt/SDCARD/.simplemenu/launchers/a5200_libretro,/mnt/SDCARD/.simplemenu/launchers/atari800_libretro
romDirs = /mnt/SDCARD/Roms/FIFTYTWOHUNDRED/
romExts = .bin,.a52,.zip,.7z

[ATARI 7800]
execs = /mnt/SDCARD/.simplemenu/launchers/prosystem_libretro
romDirs = /mnt/SDCARD/Roms/SEVENTYEIGHTHUNDRED/
romExts = .bin,.a78,.zip,.7z

[INTELLIVISION]
execs = /mnt/SDCARD/.simplemenu/launchers/freeintv_libretro
romDirs = /mnt/SDCARD/Roms/INTELLI/
romExts = .int,.bin

[NEO GEO CD]
execs = /mnt/SDCARD/.simplemenu/launchers/neocd_libretro
romDirs = /mnt/SDCARD/Roms/NEOCD/
romExts = .zip,.chd

[PC ENGINE]
execs = /mnt/SDCARD/.simplemenu/launchers/mednafen_pce_fast_libretro,/mnt/SDCARD/.simplemenu/launchers/mednafen_supergrafx_libretro
romDirs = /mnt/SDCARD/Roms/PCE/
romExts = .pce,.tg16,.cue,.zip,.7z

[PC ENGINE CD]
execs = /mnt/SDCARD/.simplemenu/launchers/mednafen_pce_fast_libretro,/mnt/SDCARD/.simplemenu/launchers/mednafen_supergrafx_libretro
romDirs = /mnt/SDCARD/Roms/PCECD/
romExts = .pce,.tg16,.cue,.chd,.zip,.7z

[PLAYSTATION]
execs = /mnt/SDCARD/.simplemenu/launchers/pcsx_rearmed_libretro,/mnt/SDCARD/.simplemenu/launchers/pcsx_rearmed_libretro_old,/mnt/SDCARD/.simplemenu/launchers/pcsx_rearmed_libretro_shaun
romDirs = /mnt/SDCARD/Roms/PS/
romExts = .bin,.pbp,.chd,.zip,.cue,.img,.iso,.m3u
EOF