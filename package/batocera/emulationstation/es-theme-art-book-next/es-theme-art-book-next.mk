################################################################################
#
# EmulationStation theme "Art Book Next"
#
################################################################################
# Version.: Commits on May 17, 2024
ES_THEME_ART_BOOK_NEXT_VERSION = 8a14b1b45fdc41c808ac0c24cf90b0cb0f087d62
ES_THEME_ART_BOOK_NEXT_SITE = $(call github,UzuCore,es-theme-art-book-dc,$(ES_THEME_ART_BOOK_NEXT_VERSION))

define ES_THEME_ART_BOOK_NEXT_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-dc
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-dc
endef

$(eval $(generic-package))
