################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on November 09, 2024
ES_THEME_KNULLI_VERSION = bb9242aaffc621f0c71d504d513dcb26f9a1cc11
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
