################################################################################
#
# EmulationStation theme "Art Book Next"
#
################################################################################
# Version.: Commits on May 17, 2024
ES_THEME_ART_BOOK_NEXT_VERSION = aa26b24acf9b8b32a35de308d6ab31acf1ad2382
ES_THEME_ART_BOOK_NEXT_SITE = $(call github,UzuCore,es-theme-art-book-dc,$(ES_THEME_ART_BOOK_NEXT_VERSION))

define ES_THEME_ART_BOOK_NEXT_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-dc
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-dc
endef

$(eval $(generic-package))
