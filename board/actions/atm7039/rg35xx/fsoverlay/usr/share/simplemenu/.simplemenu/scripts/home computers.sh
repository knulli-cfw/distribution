consoles="/mnt/SDCARD/.simplemenu/section_groups/arcades.ini"

cat > ${consoles} <<EOF
[CONSOLES]
consoleList =ZX SPECTRUM,AMSTRAD CPC,COMMODORE 64,MSX,ATARI ST,AMIGA,WOLF3D,DOOM,QUAKE,DOS,PC98,OPENBOR,PICO-8,TIC-80,SCUMMVM,X68000

[ZX SPECTRUM]
execs = /mnt/SDCARD/.simplemenu/launchers/fuse_libretro
romDirs = /mnt/SDCARD/Roms/ZXS/
romExts = .tzx,.tap,.z80,.rzx,.scl,.trd,.dsk,.zip,.7z

[AMSTRAD CPC]
execs = /mnt/SDCARD/.simplemenu/launchers/crocods_libretro
romDirs = /mnt/SDCARD/Roms/CPC/
romExts = .dsk,.sna,.tap,.cdt,.voc,.cpr,.m3u,.zip,.7z

[COMMODORE 64]
execs = /mnt/SDCARD/.simplemenu/launchers/vice_x64_libretro
romDirs = /mnt/SDCARD/Roms/C64/
romExts = .crt,.d64,.t64,.bin,.g64,.7z,.zip

[MSX]
execs = /mnt/SDCARD/.simplemenu/launchers/bluemsx_libretro,/mnt/SDCARD/.simplemenu/launchers/fmsx_libretro
romDirs = /mnt/SDCARD/Roms/MSX/
romExts = .rom,.ri,.mx1,.mx2,.col,.dsk,.cas,.sg,.sc,.m3u,.zip,.7z

[ATARI ST]
execs = /mnt/SDCARD/.simplemenu/launchers/hatari_libretro
romDirs = /mnt/SDCARD/Roms/ATARIST/
romExts = .a78,.rom

[AMIGA]
execs = /mnt/SDCARD/.simplemenu/launchers/puae_libretro,/mnt/SDCARD/.simplemenu/launchers/uae4arm_libretro,/mnt/SDCARD/.simplemenu/launchers/puae2021_libretro
romDirs = /mnt/SDCARD/Roms/AMIGA/
romExts = .adf,.adz,.dms,.fdi,.ipf,.hdf,.hdz,.lha,.slave,.info,.cue,.ccd,.nrg,.mds,.iso,.chd,.uae,.m3u,.zip,.7z,.rp9

[WOLF3D]
execs = /mnt/SDCARD/.simplemenu/launchers/ecwolf_libretro
romDirs = /mnt/SDCARD/Roms/WOLF3D/
romExts = .wl6,.n3d,.sod,.sdm,.wl1,.pk3,.exe,.zip,.7z

[DOOM]
execs = /mnt/SDCARD/.simplemenu/launchers/prboom_libretro
romDirs = /mnt/SDCARD/Roms/DOOM/
romExts = .wad,.zip,.7z

[QUAKE]
execs = /mnt/SDCARD/.simplemenu/launchers/tyrquake_libretro
romDirs = /mnt/SDCARD/Roms/QUAKE/
romExts = .pak

[DOS]
execs = /mnt/SDCARD/.simplemenu/launchers/dosbox_pure_libretro
romDirs = /mnt/SDCARD/Roms/DOS/
romExts = .zip,.dosz,.exe,.com,.bat,.iso,.cue,.vhd,.m3u,.7z

[PC98]
execs = /mnt/SDCARD/.simplemenu/launchers/nekop2_libretro,/mnt/SDCARD/.simplemenu/launchers/np2kai_libretro
romDirs = /mnt/SDCARD/Roms/PC98/
romExts = .hdi,.fdi

[OPENBOR]
execs = /mnt/SDCARD/.simplemenu/launchers/openbor_standalone
romDirs = /mnt/SDCARD/Roms/OPENBOR/
romExts = .pak

[PICO-8]
execs = /mnt/SDCARD/.simplemenu/launchers/fake08_libretro,/mnt/SDCARD/.simplemenu/launchers/retro8_libretro,/mnt/SDCARD/.simplemenu/launchers/fake8_standalone
romDirs = /mnt/SDCARD/Roms/PICO/
romExts = .png,.p8
aliasFile = /mnt/SDCARD/.simplemenu/alias_PICO-8.txt

[TIC-80]
execs = /mnt/SDCARD/.simplemenu/launchers/tic80_libretro
romDirs = /mnt/SDCARD/Roms/TIC/
romExts = .tic,.7z

[SCUMMVM]
execs = /mnt/SDCARD/.simplemenu/launchers/scummvm_libretro
romDirs = /mnt/SDCARD/Roms/SCUMMVM/
romExts = .scummvm

[X68000]
execs = /mnt/SDCARD/.simplemenu/launchers/px68k_libretro
romDirs = /mnt/SDCARD/Roms/X68000/
romExts = .dim,.zip,.img,.d88,.88d,.hdm,.dup,.2hd,.xdf,.hdf,.cmd,.m3u,.7z
EOF