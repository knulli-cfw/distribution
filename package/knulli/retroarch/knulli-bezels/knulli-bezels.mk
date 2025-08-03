################################################################################
#
# knulli bezels
#
################################################################################
# Version.: Commits on July 5, 2025
KNULLI_BEZELS_VERSION = 38b4327e6ac61e79d2d59a0d623d465948df5d69
KNULLI_BEZELS_SITE = $(call github,chrizzo-hb,knulli-bezels,$(KNULLI_BEZELS_VERSION))

define KNULLI_BEZELS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	cp -rf $(@D)/default-knulli		      $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	cp -rf $(@D)/default-knulli-sp	      $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	(cd $(TARGET_DIR)/usr/share/batocera/datainit/decorations && ln -sf default-knulli default)

endef

$(eval $(generic-package))
