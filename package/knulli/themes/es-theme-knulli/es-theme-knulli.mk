################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on January 14, 2025
ES_THEME_KNULLI_VERSION = 26807c512a9efcb69b7fd66e0f37276b7ec3a7c9
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
