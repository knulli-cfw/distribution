#!/bin/bash -e
set -x
# PWD = source dir
# BASE_DIR = build dir
# BUILD_DIR = base dir/build
# HOST_DIR = base dir/host
# BINARIES_DIR = images dir
# TARGET_DIR = target dir

##### constants ################
BATOCERA_BINARIES_DIR="${BINARIES_DIR}/knulli"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
RELEASES_DIR="${BASE_DIR}/releases"
UPDATES_DIR="${BASE_DIR}/updates"
################################

##### find images to build #####
BATOCERA_TARGET=$(grep -E "^BR2_PACKAGE_BATOCERA_TARGET_[A-Z_0-9]*=y$" "${BR2_CONFIG}" | grep -vE "_ANY=" | grep -vE "_GLES[0-9]*=" | sed -e s+'^BR2_PACKAGE_BATOCERA_TARGET_\([A-Z_0-9]*\)=y$'+'\1'+)
BATOCERA_LOWER_TARGET=$(echo "${BATOCERA_TARGET}" | tr '[:upper:]' '[:lower:]')
BATOCERA_IMAGES_TARGETS=$(grep -E "^BR2_TARGET_BATOCERA_IMAGES[ ]*=[ ]*\".*\"[ ]*$" "${BR2_CONFIG}" | sed -e s+"^BR2_TARGET_BATOCERA_IMAGES[ ]*=[ ]*\"\(.*\)\"[ ]*$"+"\1"+)
if test -z "${BATOCERA_IMAGES_TARGETS}"
then
    echo "no BR2_TARGET_BATOCERA_IMAGES defined." >&2
    exit 1
fi
################################

#### common parent dir to al images #
if echo "${BATOCERA_IMAGES_TARGETS}" | grep -qE '^[^ ]*$'
then
    # single board directory
    IMGMODE=single
else
    # when there are several one, the first one is the common directory where to find the create-boot-script.sh directory
    IMGMODE=multi
fi

#### clean the (previous if exists) target directory ###
if test -d "${BATOCERA_BINARIES_DIR}"
then
    rm -rf "${BATOCERA_BINARIES_DIR}" || exit 1
fi
mkdir -p "${BATOCERA_BINARIES_DIR}/images" || exit 1

##### build images #############
#SUFFIXVERSION=$(cat "${TARGET_DIR}/usr/share/batocera/batocera.version" | sed -e s+'^\([0-9\.]*\).*$'+'\1'+) # xx.yy version
SUFFIXVERSION=$(awk '{if ($1 ~ /^[0-9\.]+$/) print $1; else print $1}' "${TARGET_DIR}/usr/share/batocera/batocera.version") # Handle numeric and codename strings versions

SUFFIXDATE=$(date +%Y%m%d)

#### build the images ###########
for BATOCERA_PATHSUBTARGET in ${BATOCERA_IMAGES_TARGETS}
do
    BATOCERA_SUBTARGET=$(basename "${BATOCERA_PATHSUBTARGET}")

    #### create the update signatures #####
    KNULLI_SIGNATURES_SCRIPT="${BR2_EXTERNAL_BATOCERA_PATH}/board/batocera/scripts/generate_signature.sh"
    bash "${KNULLI_SIGNATURES_SCRIPT}" "${BR2_EXTERNAL_BATOCERA_PATH}/board/batocera/${BATOCERA_PATHSUBTARGET}" "${BINARIES_DIR}" || exit 1

    #### prepare the boot dir ######
    BOOTNAMEDDIR="${BATOCERA_BINARIES_DIR}/boot_${BATOCERA_SUBTARGET}"
    rm -rf "${BOOTNAMEDDIR}" || exit 1 # remove in case or rerun
    BATOCERA_POST_IMAGE_SCRIPT="${BR2_EXTERNAL_BATOCERA_PATH}/board/batocera/${BATOCERA_PATHSUBTARGET}/create-boot-script.sh"
    bash "${BATOCERA_POST_IMAGE_SCRIPT}" "${HOST_DIR}" "${BR2_EXTERNAL_BATOCERA_PATH}/board/batocera/${BATOCERA_PATHSUBTARGET}" "${BUILD_DIR}" "${BINARIES_DIR}" "${TARGET_DIR}" "${BATOCERA_BINARIES_DIR}" || exit 1
    # add some common files
    cp     "${BINARIES_DIR}/batocera-boot.conf" "${BATOCERA_BINARIES_DIR}/boot/" || exit 1
    echo   "${BATOCERA_SUBTARGET}" > "${BATOCERA_BINARIES_DIR}/boot/boot/batocera.board" || exit 1

    #### boot.tar.gz ###############
    echo "creating images/${BATOCERA_SUBTARGET}/boot.tar.gxz"
    mkdir -p "${BATOCERA_BINARIES_DIR}/images/${BATOCERA_SUBTARGET}" || exit 1
    (cd "${BATOCERA_BINARIES_DIR}/boot" && tar -cf - * | pigz -9 > "${BATOCERA_BINARIES_DIR}/images/${BATOCERA_SUBTARGET}/knulli-${BATOCERA_LOWER_TARGET}-${BATOCERA_SUBTARGET}-${SUFFIXVERSION}-${SUFFIXDATE}_boot.tar.gz") || exit 1

    # rename the squashfs : the .update is the version that will be renamed at boot to replace the old version
    mv "${BATOCERA_BINARIES_DIR}/boot/boot/batocera.update" "${BATOCERA_BINARIES_DIR}/boot/boot/batocera" || exit 1

    # create *.img
    if [ "${BATOCERA_LOWER_TARGET}" = "${BATOCERA_SUBTARGET}" ]; then
        BATOCERAIMG="${BATOCERA_BINARIES_DIR}/images/${BATOCERA_SUBTARGET}/knulli-${BATOCERA_SUBTARGET}-${SUFFIXVERSION}-${SUFFIXDATE}.img"
    else
        BATOCERAIMG="${BATOCERA_BINARIES_DIR}/images/${BATOCERA_SUBTARGET}/knulli-${BATOCERA_LOWER_TARGET}-${BATOCERA_SUBTARGET}-${SUFFIXVERSION}-${SUFFIXDATE}.img"
    fi
    echo "creating images/${BATOCERA_SUBTARGET}/"$(basename "${BATOCERAIMG}")"..." >&2
    rm -rf "${GENIMAGE_TMP}" || exit 1
    GENIMAGEDIR="${BR2_EXTERNAL_BATOCERA_PATH}/board/batocera/${BATOCERA_PATHSUBTARGET}"
    GENIMAGEFILE="${GENIMAGEDIR}/genimage.cfg"
    FILES=$(find "${BATOCERA_BINARIES_DIR}/boot" -type f | sed -e s+"^${BATOCERA_BINARIES_DIR}/boot/\(.*\)$"+"file \1 \{ image = '\1' }"+ | tr '\n' '@')
    cat "${GENIMAGEFILE}" | sed -e s+'@files'+"${FILES}"+ | tr '@' '\n' > "${BATOCERA_BINARIES_DIR}/genimage.cfg" || exit 1

    # install syslinux
    if grep -qE "^BR2_TARGET_SYSLINUX=y$" "${BR2_CONFIG}"
    then
	GENIMAGEBOOTFILE="${GENIMAGEDIR}/genimage-boot.cfg"
	echo "installing syslinux" >&2
	cat "${GENIMAGEBOOTFILE}" | sed -e s+'@files'+"${FILES}"+ | tr '@' '\n' > "${BATOCERA_BINARIES_DIR}/genimage-boot.cfg" || exit 1
    genimage --rootpath="${TARGET_DIR}" --inputpath="${BATOCERA_BINARIES_DIR}/boot" --outputpath="${BATOCERA_BINARIES_DIR}" --config="${BATOCERA_BINARIES_DIR}/genimage-boot.cfg" --tmppath="${GENIMAGE_TMP}" || exit 1
    "${HOST_DIR}/bin/syslinux" -i "${BATOCERA_BINARIES_DIR}/boot.vfat" -d "/boot/syslinux" || exit 1
    # remove genimage temp path as sometimes genimage v14 fails to start
    rm -rf ${GENIMAGE_TMP}
    mkdir ${GENIMAGE_TMP}
    fi
    ###
    "${HOST_DIR}/bin/genimage" --rootpath="${TARGET_DIR}" --inputpath="${BATOCERA_BINARIES_DIR}/boot" --outputpath="${BATOCERA_BINARIES_DIR}" --config="${BATOCERA_BINARIES_DIR}/genimage.cfg" --tmppath="${GENIMAGE_TMP}" || exit 1
 
    rm -f "${BATOCERA_BINARIES_DIR}/boot.vfat" || exit 1
    rm -f "${BATOCERA_BINARIES_DIR}/userdata.ext4" || exit 1
    mv "${BATOCERA_BINARIES_DIR}/batocera.img" "${BATOCERAIMG}" || exit 1
    pigz "${BATOCERAIMG}" || exit 1

    # rename the boot to boot_arch
    mv "${BATOCERA_BINARIES_DIR}/boot" "${BOOTNAMEDDIR}" || exit 1

    # copy the version file needed for version check
    cp "${TARGET_DIR}/usr/share/batocera/batocera.version" "${BATOCERA_BINARIES_DIR}/images/${BATOCERA_SUBTARGET}" || exit 1

    # copy the update signature files
    cp "${BINARIES_DIR}/firmware.sig" "${BATOCERA_BINARIES_DIR}/images/${BATOCERA_SUBTARGET}" || exit 1
done

#### Create the rootfs patches ##########
# Only process if there are previous rootfs files to diff against
if ls "${RELEASES_DIR}/"*"_rootfs.squashfs" 1> /dev/null 2>&1; then
    # Calculate the current rootfs.squashfs md5sum
    CURRENT_ROOTFS_MD5SUM=$(md5sum "${BINARIES_DIR}/rootfs.squashfs" | awk '{ print $1 }')
    for ROOTFS_TARGET in "${RELEASES_DIR}/"*"_rootfs.squashfs"
    do
        # ROOTFS_TARGET is in the form of md5sum_rootfs.squashfs. We need to extract the md5sum into a variable
        ROOTFS_MD5SUM=$(basename "${ROOTFS_TARGET}" | sed -e s+'^\([0-9a-f]*\)_rootfs.squashfs$'+'\1'+)
        echo "Creating delta from ${ROOTFS_TARGET} (source) to current rootfs.squashfs (target) with source md5sum ${ROOTFS_MD5SUM}"
        # create the delta.xdelta3 patch that can be applied to the old rootfs to get the new rootfs
        xdelta3 -e -S none -s "${ROOTFS_TARGET}" "${BINARIES_DIR}/rootfs.squashfs" "${UPDATES_DIR}/${ROOTFS_MD5SUM}_to_${CURRENT_ROOTFS_MD5SUM}.patch" || exit 1
    done
else
    echo "No previous rootfs files found in ${RELEASES_DIR} - skipping delta creation"
fi

#### md5 and sha256 #######################
for FILE in "${BATOCERA_BINARIES_DIR}/images/"*"/knulli-"*"_boot.tar.gz" "${BATOCERA_BINARIES_DIR}/images/"*"/knulli-"*".img.gz"
do
    echo "creating ${FILE}.md5"
    CKS=$(md5sum "${FILE}" | sed -e s+'^\([^ ]*\) .*$'+'\1'+)
    echo "${CKS}" > "${FILE}.md5"
    echo "${CKS}  $(basename "${FILE}")" >> "${BATOCERA_BINARIES_DIR}/MD5SUMS"
    echo "creating ${FILE}.sha256"
    CKS=$(sha256sum "${FILE}" | sed -e s+'^\([^ ]*\) .*$'+'\1'+)
    echo "${CKS}" > "${FILE}.sha256"
    echo "${CKS}  $(basename "${FILE}")" >> "${BATOCERA_BINARIES_DIR}/SHA256SUMS"
done

#### update the target dir with some information files
cp "${TARGET_DIR}/usr/share/batocera/batocera.version" "${BATOCERA_BINARIES_DIR}" || exit 1
"${BR2_EXTERNAL_BATOCERA_PATH}"/scripts/linux/systemsReport.sh "${PWD}" "${BATOCERA_BINARIES_DIR}" || exit 1
