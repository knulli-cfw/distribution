################################################################################
#
# EmulationStation theme "Anbernic DC"
#
################################################################################
ES_THEME_ANBERNIC_DC_VERSION = 8267fe038c2d63d6d78a6b0f6ec113a3899e161e
ES_THEME_ANBERNIC_DC_SITE = $(call github,UzuCore,es-theme-anbernic-dc,$(ES_THEME_ANBERNIC_DC_VERSION))

define ES_THEME_ANBERNIC_DC_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-anbernic-dc
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-anbernic-dc
endef

$(eval $(generic-package))
