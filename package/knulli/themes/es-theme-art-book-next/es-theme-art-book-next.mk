################################################################################
#
# EmulationStation theme "Art Book Next"
#
################################################################################
# Version.: Commits on December 30, 2024
ES_THEME_ART_BOOK_NEXT_VERSION = a212e908879bdfec21ded89b856421b83da57cd0
ES_THEME_ART_BOOK_NEXT_SITE = $(call github,anthonycaccese,art-book-next-es,$(ES_THEME_ART_BOOK_NEXT_VERSION))

define ES_THEME_ART_BOOK_NEXT_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-next
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-art-book-next
endef

$(eval $(generic-package))
