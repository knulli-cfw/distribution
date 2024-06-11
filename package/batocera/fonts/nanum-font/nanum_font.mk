################################################################################
#
# nanum-font
#
################################################################################

NANUM_FONT_VERSION = 2fcec32b56150befeaddc0d751845bf8972be7f4
NANUM_FONT_SITE = $(call github,moonspam,NanumSquareNeo,$(NANUM_FONT_VERSION))

NANUM_FONT_TARGET_DIR=$(TARGET_DIR)/usr/share/fonts/truetype/nanum

define NANUM_FONT_INSTALL_TARGET_CMDS
	@mkdir -p $(NANUM_FONT_TARGET_DIR)
	@cp $(@D)/NanumSquareNeoTTF-bRg.ttf $(NANUM_FONT_TARGET_DIR)/NanumMyeongjo.ttf
endef

$(eval $(generic-package))
