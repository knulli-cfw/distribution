################################################################################
#
# EmulationStation theme "Anbernic DC"
#
################################################################################
ES_THEME_ANBERNIC_DC_VERSION = e70d44ce686cf64e9fed3b8133b4658e4aaef0fc
ES_THEME_ANBERNIC_DC_SITE = $(call github,UzuCore,es-theme-anbernic-dc,$(ES_THEME_ANBERNIC_DC_VERSION))

define ES_THEME_ANBERNIC__DC_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-anbernic-dc
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-anbernic-dc
endef

$(eval $(generic-package))
