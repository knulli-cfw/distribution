################################################################################
#
# EmulationStation theme "Art Book Next"
#
################################################################################
# Version.: Commits on May 17, 2024
ES_THEME_ART_BOOK_NEXT_VERSION = 76ab63e24cb1e2258d5e7294b6aa21b4e8f8e98e
ES_THEME_ART_BOOK_NEXT_SITE = $(call github,anthonycaccese,art-book-next-es,$(ES_THEME_ART_BOOK_NEXT_VERSION))

define ES_THEME_ART_BOOK_NEXT_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-next
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-next
endef

$(eval $(generic-package))
