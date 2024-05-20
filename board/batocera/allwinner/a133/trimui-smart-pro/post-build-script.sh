#!/bin/sh -x
BOARD_DIR="$(dirname $0)"
echo "BOARD_DIR"
echo $BOARD_DIR
cp $BOARD_DIR/bootlogo.bmp $BINARIES_DIR/bootlogo.bmp 
cp $BOARD_DIR/uImage $BINARIES_DIR/uImage 
cp $BOARD_DIR/batocera-boot.conf $BINARIES_DIR/batocera-boot.conf
cp $BOARD_DIR/uInitrd $BINARIES_DIR/uInitrd
cp -r $BOARD_DIR/* $BINARIES_DIR/

# We don't really need this but the batocera image script requires it
#cp -r $BOARD_DIR/tools $BINARIES_DIR/
mkdir -p $BINARIES_DIR/tools

