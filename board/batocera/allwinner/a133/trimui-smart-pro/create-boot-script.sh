#!/bin/bash

# HOST_DIR = host dir
# BOARD_DIR = board specific dir
# BUILD_DIR = base dir/build
# BINARIES_DIR = images dir
# TARGET_DIR = target dir
# BATOCERA_BINARIES_DIR = batocera binaries sub directory

HOST_DIR=$1
BOARD_DIR=$2
BUILD_DIR=$3
BINARIES_DIR=$4
TARGET_DIR=$5
BATOCERA_BINARIES_DIR=$6

mkdir -p "${BATOCERA_BINARIES_DIR}/boot/boot"     || exit 1

cp "${BOARD_DIR}/uImage"             "${BATOCERA_BINARIES_DIR}/boot/uImage"               || exit 1
cp "${BOARD_DIR}/uInitrd"            "${BATOCERA_BINARIES_DIR}/boot/uInitrd"              || exit 1
cp "${BINARIES_DIR}/rootfs.squashfs" "${BATOCERA_BINARIES_DIR}/boot/boot/batocera.update" || exit 1
cp "${BOARD_DIR}/batocera-boot.conf" "${BATOCERA_BINARIES_DIR}/boot/batocera-boot.conf"   || exit 1
cp "${BOARD_DIR}/bootlogo.bmp"       "${BATOCERA_BINARIES_DIR}/boot/bootlogo.bmp"         || exit 1

cp -r "${BOARD_DIR}/partitions"		"${BATOCERA_BINARIES_DIR}"				|| exit 1

touch "${BATOCERA_BINARIES_DIR}/boot/boot/autoresize"

exit 0
