consoles="/mnt/SDCARD/.simplemenu/section_groups/arcades.ini"

cat > ${consoles} <<EOF
[CONSOLES]
consoleList =MAME,CPS1,CPS2,CPS3,NEO GEO,FINALBURN ALPHA,FINALBURN NEO,DAPHNE

[MAME]
execs = /mnt/SDCARD/.simplemenu/launchers/mame2003_plus_libretro,/mnt/SDCARD/.simplemenu/launchers/fbneo_libretro,/mnt/SDCARD/.simplemenu/launchers/fbalpha2012_libretro,/mnt/SDCARD/.simplemenu/launchers/km_mame2003_xtreme_libretro,/mnt/SDCARD/.simplemenu/launchers/mame2000_libretro,/mnt/SDCARD/.simplemenu/launchers/mame2010_libretro
romDirs = /mnt/SDCARD/Roms/ARCADE/
romExts = .zip
aliasFile = /mnt/SDCARD/.simplemenu/alias.txt

[CPS1]
execs = /mnt/SDCARD/.simplemenu/launchers/fbalpha2012_cps1_libretro,/mnt/SDCARD/.simplemenu/launchers/fbneo_libretro
romDirs = /mnt/SDCARD/Roms/CPS1/
romExts = .zip
aliasFile = /mnt/SDCARD/.simplemenu/alias.txt

[CPS2]
execs = /mnt/SDCARD/.simplemenu/launchers/fbalpha2012_cps2_libretro,/mnt/SDCARD/.simplemenu/launchers/fbneo_libretro
romDirs = /mnt/SDCARD/Roms/CPS2/
romExts = .zip
aliasFile = /mnt/SDCARD/.simplemenu/alias.txt

[CPS3]
execs = /mnt/SDCARD/.simplemenu/launchers/fbalpha2012_cps3_libretro,/mnt/SDCARD/.simplemenu/launchers/fbneo_libretro
romDirs = /mnt/SDCARD/Roms/CPS3/
romExts = .zip
aliasFile = /mnt/SDCARD/.simplemenu/alias.txt

[NEO GEO]
execs = /mnt/SDCARD/.simplemenu/launchers/fbalpha2012_neogeo_libretro
romDirs = /mnt/SDCARD/Roms/NEOGEO/
romExts = .zip,.7z
aliasFile = /mnt/SDCARD/.simplemenu/alias.txt

[FINALBURN ALPHA]
execs = /mnt/SDCARD/.simplemenu/launchers/fbalpha2012_libretro,/mnt/SDCARD/.simplemenu/launchers/fbalpha_libretro
romDirs = /mnt/SDCARD/Roms/FBA/
romExts = .zip
aliasFile = /mnt/SDCARD/.simplemenu/alias.txt

[FINALBURN NEO]
execs = /mnt/SDCARD/.simplemenu/launchers/fbneo_libretro
romDirs = /mnt/SDCARD/Roms/FBN/
romExts = .zip
aliasFile = /mnt/SDCARD/.simplemenu/alias.txt

[DAPHNE]
execs = /mnt/SDCARD/.simplemenu/launchers/daphne_libretro
romDirs = /mnt/SDCARD/Roms/DAPHNE/
romExts = .zip
EOF
