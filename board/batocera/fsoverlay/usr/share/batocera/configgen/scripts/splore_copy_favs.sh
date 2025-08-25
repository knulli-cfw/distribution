#!/bin/sh

SYSTEM_CORE="$4"
if [ "$SYSTEM_CORE" != "pico8_official" ]; then
    exit 0
fi

PICO8_ROOT="/userdata/system/.lexaloffle/pico-8"
FAVS_FILE="/userdata/system/.lexaloffle/pico-8/favourites.txt"
CARTS_DIR="/userdata/system/.lexaloffle/pico-8/bbs/carts"
ROMS_DIR="/userdata/roms/pico8/splore"

if [ ! -d "$PICO8_ROOT" ] || [ ! -r "$FAVS_FILE" ]; then
  exit 0
fi

mkdir -p "$ROMS_DIR"

do_copy_favorites() {
    # extract unique slugs from the first field after the leading pipe
    awk -F'[|]' 'NF>=2{ s=$2; gsub(/^[ \t]+|[ \t]+$/, "", s); if(s!="") print s }' "$FAVS_FILE" \
    | sort -u \
    | while read -r slug; do
        for ext in ".p8.png" ".p8" ".png"; do
            src="${CARTS_DIR}/${slug}${ext}"
            [ -f "$src" ] && cp -an -- "$src" "$ROMS_DIR/"
        done
        done
}

case "$1" in
    gameStop)
        do_copy_favorites
        ;;
    *)
        echo "Usage: $0 {gameStop}"
        ;;
esac
