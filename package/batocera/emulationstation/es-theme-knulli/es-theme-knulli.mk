################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on October 20, 2024
ES_THEME_KNULLI_VERSION = 53c6cca944f3f050fea4e1a1ed20fcba1edf7553
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
