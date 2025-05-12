consoles="/mnt/SDCARD/.simplemenu/section_groups/arcades.ini"

cat > ${consoles} <<EOF
[CONSOLES]
consoleList = GAMES,APPS,OVERLAYS

[GAMES]
execs = #
romDirs = /mnt/SDCARD/.simplemenu/games/
romExts = .sh,.fgl

[APPS]
execs = #
romDirs = /mnt/SDCARD/.simplemenu/apps/
romExts = .sh,.fgl

[OVERLAYS]
execs = #
romDirs = /mnt/SDCARD/.simplemenu/overlays/
romExts = .sh,.fgl
EOF