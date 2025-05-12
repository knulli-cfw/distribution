#!/bin/sh

BOARD_DIR="$(dirname $0)"
#GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
#GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

#rm -rf "${GENIMAGE_TMP}"

cp "${BOARD_DIR}/uEnv.txt" "${BINARIES_DIR}"
cp "${BOARD_DIR}/boot_logo.bmp.gz" "${BINARIES_DIR}"
cp "${BOARD_DIR}/2100mAh-gpu.dtb" "${BINARIES_DIR}"
cp "${BOARD_DIR}/2600mAh-gpu.dtb" "${BINARIES_DIR}"
mkdir -p "${BINARIES_DIR}/boot"
cp "${BINARIES_DIR}/rootfs.ext2" "${BINARIES_DIR}/boot/batocera"
cp "${BOARD_DIR}/batocera.board" "${BINARIES_DIR}/boot/batocera.board"

#genimage                           \
#	--rootpath "${TARGET_DIR}"     \
#	--tmppath "${GENIMAGE_TMP}"    \
#	--inputpath "${BINARIES_DIR}"  \
#	--outputpath "${BINARIES_DIR}" \
#	--config "${GENIMAGE_CFG}"
#
#exit $?
