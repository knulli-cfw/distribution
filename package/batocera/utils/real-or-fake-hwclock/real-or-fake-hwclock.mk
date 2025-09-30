################################################################################
#
# real-or-fake-hwclock
#
################################################################################

define REAL_OR_FAKE_HWCLOCK_INSTALL_TARGET_CMDS
	$(INSTALL) -D $(CURDIR)/real-or-fake-hwclock.init $(TARGET_DIR)/etc/init.d/S47real-or-fake-hwclock
endef

$(eval $(generic-package))
