################################################################################
#
# EmulationStation theme "Anbernic"
#
################################################################################
ES_THEME_ANBERNIC_VERSION = 6b868454cad63296a3f36b1d3c5307d60f23ac2b
ES_THEME_ANBERNIC_SITE = $(call github,UzuCore,es-theme-anbernic-dc,$(ES_THEME_ANBERNIC_VERSION))

define ES_THEME_ANBERNIC_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-anbernic
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-anbernic
endef

$(eval $(generic-package))
