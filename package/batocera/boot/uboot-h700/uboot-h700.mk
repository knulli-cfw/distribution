################################################################################
#
# uboot-h700
#
################################################################################

UBOOT_H700_VERSION = 24aafd7efc6827dc44cae0bfc28c08d989b34869
UBOOT_H700_SITE = https://git.sr.ht/~tokyovigilante/u-boot/archive
#UBOOT_H700_DL_SUBDIR = archive
UBOOT_H700_SOURCE = $(UBOOT_H700_VERSION).tar.gz

UBOOT_H700_LICENSE = GPL

define UBOOT_H700_BUILD_CMDS
	@echo "---- See github repository build.sh for build instructions. -----"
endef

define UBOOT_H700_INSTALL_TARGET_CMDS
	cp -rv $(@D)/staging/* $(BINARIES_DIR)
endef

$(eval $(generic-package))
