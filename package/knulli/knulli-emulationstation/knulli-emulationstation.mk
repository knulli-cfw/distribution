################################################################################
#
# knulli-emulationstation
#
################################################################################
# Last update: Commits on Oct 18, 2024
KNULLI_EMULATIONSTATION_VERSION = knulli
KNULLI_EMULATIONSTATION_SITE = https://github.com/knulli-cfw/batocera-emulationstation
KNULLI_EMULATIONSTATION_SITE_METHOD = git
KNULLI_EMULATIONSTATION_LICENSE = MIT
KNULLI_EMULATIONSTATION_GIT_SUBMODULES = YES
KNULLI_EMULATIONSTATION_LICENSE = MIT, Apache-2.0
KNULLI_EMULATIONSTATION_DEPENDENCIES = sdl2 sdl2_mixer vlc libfreeimage freetype alsa-lib
KNULLI_EMULATIONSTATION_DEPENDENCIES += libcurl rapidjson batocera-es-system host-gettext
# install in staging for debugging (gdb)
KNULLI_EMULATIONSTATION_INSTALL_STAGING = YES
# KNULLI_EMULATIONSTATION_OVERRIDE_SRCDIR = /sources/batocera-emulationstation

KNULLI_EMULATIONSTATION_CONF_OPTS += \
    -DCMAKE_CXX_FLAGS=-D$(call UPPERCASE,$(BATOCERA_SYSTEM_ARCH))

ifeq ($(BR2_PACKAGE_HAS_LIBMALI),y)
KNULLI_EMULATIONSTATION_DEPENDENCIES += libmali
KNULLI_EMULATIONSTATION_CONF_OPTS += -DCMAKE_EXE_LINKER_FLAGS=-lmali
KNULLI_EMULATIONSTATION_CONF_OPTS += -DCMAKE_SHARED_LINKER_FLAGS=-lmali
endif

ifeq ($(BR2_PACKAGE_HAS_LIBGL)$(BR2_PACKAGE_XSERVER_XORG_SERVER),yy)
KNULLI_EMULATIONSTATION_CONF_OPTS += -DGL=ON
else
ifeq ($(BR2_PACKAGE_HAS_LIBGLES),y)
KNULLI_EMULATIONSTATION_CONF_OPTS += -DGLES2=ON
endif
endif

ifeq ($(BR2_PACKAGE_RPI_USERLAND),y)
KNULLI_EMULATIONSTATION_CONF_OPTS += -DBCM=ON -DRPI=ON
endif

ifeq ($(BR2_PACKAGE_ESPEAK),y)
KNULLI_EMULATIONSTATION_CONF_OPTS += -DENABLE_TTS=ON
KNULLI_EMULATIONSTATION_DEPENDENCIES += espeak
endif

ifeq ($(BR2_PACKAGE_KODI)$(BR2_PACKAGE_KODI21),y)
KNULLI_EMULATIONSTATION_CONF_OPTS += -DDISABLE_KODI=OFF
else
KNULLI_EMULATIONSTATION_CONF_OPTS += -DDISABLE_KODI=ON
endif

ifeq ($(BR2_PACKAGE_PULSEAUDIO_ENABLE_ATOMIC),y)
KNULLI_EMULATIONSTATION_CONF_OPTS += -DENABLE_PULSE=ON
else
KNULLI_EMULATIONSTATION_CONF_OPTS += -DENABLE_PULSE=OFF
endif

ifeq ($(BR2_PACKAGE_XORG7),y)
KNULLI_EMULATIONSTATION_CONF_OPTS += -DENABLE_FILEMANAGER=ON
else
KNULLI_EMULATIONSTATION_CONF_OPTS += -DENABLE_FILEMANAGER=OFF
endif

KNULLI_EMULATIONSTATION_CONF_OPTS += -DBATOCERA=ON

KNULLI_EMULATIONSTATION_SOURCE_PATH = \
    $(BR2_EXTERNAL_BATOCERA_PATH)/package/knulli/knulli-emulationstation

KNULLI_EMULATIONSTATION_KEY_SCREENSCRAPER_DEV_LOGIN=\
    $(shell grep -E '^SCREENSCRAPER_DEV_LOGIN=' \
	$(KNULLI_EMULATIONSTATION_SOURCE_PATH)/keys.txt | cut -d = -f 2-)
KNULLI_EMULATIONSTATION_KEY_GAMESDB_APIKEY=\
    $(shell grep -E '^GAMESDB_APIKEY=' \
	$(KNULLI_EMULATIONSTATION_SOURCE_PATH)/keys.txt | cut -d = -f 2-)
KNULLI_EMULATIONSTATION_KEY_CHEEVOS_DEV_LOGIN=\
    $(shell grep -E '^CHEEVOS_DEV_LOGIN=' \
	$(KNULLI_EMULATIONSTATION_SOURCE_PATH)/keys.txt | cut -d = -f 2-)
KNULLI_EMULATIONSTATION_KEY_HFS_DEV_LOGIN=\
    $(shell grep -E '^HFS_DEV_LOGIN=' \
	$(KNULLI_EMULATIONSTATION_SOURCE_PATH)/keys.txt | cut -d = -f 2-)

ifneq ($(KNULLI_EMULATIONSTATION_KEY_SCREENSCRAPER_DEV_LOGIN),)
KNULLI_EMULATIONSTATION_CONF_OPTS += \
    "-DSCREENSCRAPER_DEV_LOGIN=$(KNULLI_EMULATIONSTATION_KEY_SCREENSCRAPER_DEV_LOGIN)"
endif
ifneq ($(KNULLI_EMULATIONSTATION_KEY_GAMESDB_APIKEY),)
KNULLI_EMULATIONSTATION_CONF_OPTS += \
    "-DGAMESDB_APIKEY=$(KNULLI_EMULATIONSTATION_KEY_GAMESDB_APIKEY)"
endif
ifneq ($(KNULLI_EMULATIONSTATION_KEY_CHEEVOS_DEV_LOGIN),)
KNULLI_EMULATIONSTATION_CONF_OPTS += \
    "-DCHEEVOS_DEV_LOGIN=$(KNULLI_EMULATIONSTATION_KEY_CHEEVOS_DEV_LOGIN)"
endif
ifneq ($(KNULLI_EMULATIONSTATION_KEY_HFS_DEV_LOGIN),)
KNULLI_EMULATIONSTATION_CONF_OPTS += \
    "-DHFS_DEV_LOGIN=$(KNULLI_EMULATIONSTATION_KEY_HFS_DEV_LOGIN)"
endif

define KNULLI_EMULATIONSTATION_RPI_FIXUP
	$(SED) 's|.{CMAKE_FIND_ROOT_PATH}/opt/vc|$(STAGING_DIR)/usr|g' $(@D)/CMakeLists.txt
	$(SED) 's|.{CMAKE_FIND_ROOT_PATH}/usr|$(STAGING_DIR)/usr|g'    $(@D)/CMakeLists.txt
endef

define KNULLI_EMULATIONSTATION_EXTERNAL_POS
	cp $(STAGING_DIR)/usr/share/batocera-es-system/es_external_translations.h \
	    $(STAGING_DIR)/usr/share/batocera-es-system/es_keys_translations.h $(@D)/es-app/src
	for P in $(STAGING_DIR)/usr/share/batocera-es-system/locales/*; \
	    do if test -e $$P/batocera-es-system.po; then \
	    cp $(@D)/locale/lang/$$(basename $$P)/LC_MESSAGES/emulationstation2.po \
	    $(@D)/locale/lang/$$(basename $$P)/LC_MESSAGES/emulationstation2.po.tmp && \
	    $(HOST_DIR)/bin/msgcat \
		$(@D)/locale/lang/$$(basename $$P)/LC_MESSAGES/emulationstation2.po.tmp \
	    $$P/batocera-es-system.po > \
	    $(@D)/locale/lang/$$(basename $$P)/LC_MESSAGES/emulationstation2.po; fi; done
endef

define KNULLI_EMULATIONSTATION_RESOURCES
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/usr/share/emulationstation/resources/help
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/usr/share/emulationstation/resources/flags
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/usr/share/emulationstation/resources/battery
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/usr/share/emulationstation/resources/services
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/usr/share/emulationstation/resources/shaders
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/usr/share/emulationstation/resources/shaders/kawase
	$(INSTALL) -m 0644 -D $(@D)/resources/*.* \
	    $(TARGET_DIR)/usr/share/emulationstation/resources
	$(INSTALL) -m 0644 -D $(@D)/resources/help/*.* \
	    $(TARGET_DIR)/usr/share/emulationstation/resources/help
	$(INSTALL) -m 0644 -D $(@D)/resources/flags/*.* \
	    $(TARGET_DIR)/usr/share/emulationstation/resources/flags
	$(INSTALL) -m 0644 -D $(@D)/resources/battery/*.* \
	    $(TARGET_DIR)/usr/share/emulationstation/resources/battery
	$(INSTALL) -m 0644 -D $(@D)/resources/services/*.* \
	    $(TARGET_DIR)/usr/share/emulationstation/resources/services
	$(INSTALL) -m 0644 -D $(@D)/resources/shaders/*.* \
	    $(TARGET_DIR)/usr/share/emulationstation/resources/shaders
	$(INSTALL) -m 0644 -D $(@D)/resources/shaders/*.* \
	    $(TARGET_DIR)/usr/share/emulationstation/resources/shaders/kawase

	# es_input.cfg
	mkdir -p $(TARGET_DIR)/usr/share/batocera/datainit/system/configs/emulationstation
	cp $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/controllers/es_input.cfg $(TARGET_DIR)/usr/share/emulationstation

	# savestates config
	$(INSTALL) -m 0644 $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/es_savestates.cfg $(TARGET_DIR)/usr/share/emulationstation

	# hooks
	cp $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/batocera-preupdate-gamelists-hook \
	    $(TARGET_DIR)/usr/bin/
endef

### S31emulationstation
# default for most of architectures
KNULLI_EMULATIONSTATION_PREFIX = SDL_NOMOUSE=1
KNULLI_EMULATIONSTATION_CMD = emulationstation-standalone
KNULLI_EMULATIONSTATION_ARGS = --no-splash $${EXTRA_OPTS}
KNULLI_EMULATIONSTATION_POSTFIX = \&

# disabling cec. causing perf issue on init/deinit
#ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_RK3128),y)
KNULLI_EMULATIONSTATION_CONF_OPTS += -DCEC=OFF
#else
#KNULLI_EMULATIONSTATION_CONF_OPTS += -DCEC=ON
#endif

# on SPLASH_MPV, the splash with video + es splash is ok
ifeq ($(BR2_PACKAGE_BATOCERA_SPLASH_MPV),y)
KNULLI_EMULATIONSTATION_ARGS = $${EXTRA_OPTS}
endif

# es splash is ok when there is no video
ifeq ($(BR2_PACKAGE_BATOCERA_SPLASH_IMAGE),y)
KNULLI_EMULATIONSTATION_ARGS = $${EXTRA_OPTS}
endif

## on x86/x86_64: startx runs ES
ifeq ($(BR2_PACKAGE_XSERVER_XORG_SERVER),y)
KNULLI_EMULATIONSTATION_PREFIX =
KNULLI_EMULATIONSTATION_CMD = startx
KNULLI_EMULATIONSTATION_ARGS = --windowed
KNULLI_EMULATIONSTATION_POST_INSTALL_TARGET_HOOKS += KNULLI_EMULATIONSTATION_XORG
endif

## on Wayland sway runs ES
ifeq ($(BR2_PACKAGE_BATOCERA_WAYLAND_SWAY),y)
KNULLI_EMULATIONSTATION_CMD = sway-launch
KNULLI_EMULATIONSTATION_DEPENDENCIES += sway
KNULLI_EMULATIONSTATION_POST_INSTALL_TARGET_HOOKS += KNULLI_EMULATIONSTATION_WAYLAND_SWAY
endif

define KNULLI_EMULATIONSTATION_XORG
	$(INSTALL) -D -m 0755 $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/xorg/xinitrc \
	    $(TARGET_DIR)/etc/X11/xinit/xinitrc
endef

define KNULLI_EMULATIONSTATION_WAYLAND_SWAY
	$(INSTALL) -D -m 0755 $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/wayland/sway/04-sway.sh \
	    $(TARGET_DIR)/etc/profile.d/04-sway.sh
    $(INSTALL) -D -m 0755 $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/wayland/sway/config \
	    $(TARGET_DIR)/etc/sway/config
    $(INSTALL) -D -m 0755 $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/wayland/sway/sway-launch \
	    $(TARGET_DIR)/usr/bin/sway-launch
endef

define KNULLI_EMULATIONSTATION_BOOT
	$(INSTALL) -D -m 0755 $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/S31emulationstation \
	    $(TARGET_DIR)/etc/init.d/S31emulationstation
	$(INSTALL) -D -m 0755 $(KNULLI_EMULATIONSTATION_SOURCE_PATH)/emulationstation-standalone \
	    $(TARGET_DIR)/usr/bin/emulationstation-standalone
	sed -i -e 's;%KNULLI_EMULATIONSTATION_PREFIX%;${KNULLI_EMULATIONSTATION_PREFIX};g' \
		-e 's;%KNULLI_EMULATIONSTATION_CMD%;${KNULLI_EMULATIONSTATION_CMD};g' \
		-e 's;%KNULLI_EMULATIONSTATION_ARGS%;${KNULLI_EMULATIONSTATION_ARGS};g' \
		-e 's;%KNULLI_EMULATIONSTATION_POSTFIX%;${KNULLI_EMULATIONSTATION_POSTFIX};g' \
		$(TARGET_DIR)/usr/bin/emulationstation-standalone
	sed -i -e 's;%KNULLI_EMULATIONSTATION_PREFIX%;${KNULLI_EMULATIONSTATION_PREFIX};g' \
		-e 's;%KNULLI_EMULATIONSTATION_CMD%;${KNULLI_EMULATIONSTATION_CMD};g' \
		-e 's;%KNULLI_EMULATIONSTATION_ARGS%;${KNULLI_EMULATIONSTATION_ARGS};g' \
		-e 's;%KNULLI_EMULATIONSTATION_POSTFIX%;${KNULLI_EMULATIONSTATION_POSTFIX};g' \
		$(TARGET_DIR)/etc/init.d/S31emulationstation
endef

KNULLI_EMULATIONSTATION_PRE_CONFIGURE_HOOKS += KNULLI_EMULATIONSTATION_RPI_FIXUP
KNULLI_EMULATIONSTATION_PRE_CONFIGURE_HOOKS += KNULLI_EMULATIONSTATION_EXTERNAL_POS
KNULLI_EMULATIONSTATION_POST_INSTALL_TARGET_HOOKS += KNULLI_EMULATIONSTATION_RESOURCES
KNULLI_EMULATIONSTATION_POST_INSTALL_TARGET_HOOKS += KNULLI_EMULATIONSTATION_BOOT

$(eval $(cmake-package))
