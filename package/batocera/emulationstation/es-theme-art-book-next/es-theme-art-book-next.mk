################################################################################
#
# EmulationStation theme "Art Book Next"
#
################################################################################
# Version.: Commits on May 17, 2024
ES_THEME_ART_BOOK_NEXT_VERSION = a95b6b7d0063a99ecc88eacc6af7ee5815b5d119
ES_THEME_ART_BOOK_NEXT_SITE = $(call github,UzuCore,es-theme-art-book-dc,$(ES_THEME_ART_BOOK_NEXT_VERSION))

define ES_THEME_ART_BOOK_NEXT_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-next
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-next
endef

$(eval $(generic-package))
