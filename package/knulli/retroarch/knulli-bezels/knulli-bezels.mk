################################################################################
#
# knulli bezels
#
################################################################################
# Version.: Commits on June 8, 2025
KNULLI_BEZELS_VERSION = 391bc8099649b9344afbe007a25c788a6e89fcbb
KNULLI_BEZELS_SITE = $(call github,chrizzo-hb,knulli-bezels,$(KNULLI_BEZELS_VERSION))

define KNULLI_BEZELS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	cp -rf $(@D)/default-knulli		      $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	cp -rf $(@D)/default-knulli-sp	      $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	(cd $(TARGET_DIR)/usr/share/batocera/datainit/decorations && ln -sf default-knulli default)

endef

$(eval $(generic-package))
