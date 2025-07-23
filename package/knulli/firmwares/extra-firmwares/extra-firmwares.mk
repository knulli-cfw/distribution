################################################################################
#
# extra firmwares
#
################################################################################
# Version.: Commits on Jul 14, 2025
EXTRA_FIRMWARES_VERSION = 4b00afd537c84c049c06619b0d6eaeaca5482091
EXTRA_FIRMWARES_SITE = $(call github,knulli-cfw,extra_firmwares,$(EXTRA_FIRMWARES_VERSION))
EXTRA_FIRMWARES_DEPENDENCIES = alllinuxfirmwares

EXTRA_FIRMWARES_TARGET_DIR=$(TARGET_DIR)/lib/firmware/

define EXTRA_FIRMWARES_INSTALL_TARGET_CMDS
	mkdir -p $(EXTRA_FIRMWARES_TARGET_DIR)
	cp -a $(@D)/* $(EXTRA_FIRMWARES_TARGET_DIR)/
endef

$(eval $(generic-package))
