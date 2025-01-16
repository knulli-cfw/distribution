################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on January 16, 2025
ES_THEME_KNULLI_VERSION = 12b885ac82d269950132707f92b3e6c27d849c52
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
