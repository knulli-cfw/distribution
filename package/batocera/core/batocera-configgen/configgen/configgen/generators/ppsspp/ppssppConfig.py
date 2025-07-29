from __future__ import annotations

import logging
import subprocess
from typing import TYPE_CHECKING, Final

from ...batoceraPaths import ensure_parents_and_open
from ...utils.configparser import CaseSensitiveConfigParser
from .ppssppPaths import PPSSPP_PSP_SYSTEM_DIR

if TYPE_CHECKING:
    from ...Emulator import Emulator


eslog = logging.getLogger(__name__)

ppssppConfig: Final   = PPSSPP_PSP_SYSTEM_DIR / 'ppsspp.ini'
ppssppControls: Final = PPSSPP_PSP_SYSTEM_DIR / 'controls.ini'
ppssppRetroach: Final = PPSSPP_PSP_SYSTEM_DIR / 'ppsspp_retroachievements.dat'

def writePPSSPPConfig(system: Emulator):
    iniConfig = CaseSensitiveConfigParser(interpolation=None)
    if ppssppConfig.exists():
        try:
            with ppssppConfig.open('r', encoding='utf_8_sig') as fp:
                iniConfig.readfp(fp)
        except:
            pass

    createPPSSPPConfig(iniConfig, system)
    # Save the ini file
    with ensure_parents_and_open(ppssppConfig, 'w') as configfile:
        iniConfig.write(configfile)

def writeRetroAchievements(token: str):
    if token:
        with ensure_parents_and_open(ppssppRetroach, 'w') as retroach_file:
            retroach_file.write(token)

def createPPSSPPConfig(iniConfig, system):

    ## [GRAPHICS]
    if not iniConfig.has_section("Graphics"):
        iniConfig.add_section("Graphics")

    # Graphics Backend
    if system.isOptSet('gfxbackend'):
        iniConfig.set("Graphics", "GraphicsBackend", system.config["gfxbackend"])
    else:
        iniConfig.set("Graphics", "GraphicsBackend", "0 (OPENGL)")
    # If Vulkan
    if system.isOptSet("gfxbackend") and system.config["gfxbackend"] == "3 (VULKAN)":
        # Check if we have a discrete GPU & if so, set the Name
        try:
            have_vulkan = subprocess.check_output(["/usr/bin/batocera-vulkan", "hasVulkan"], text=True).strip()
            if have_vulkan == "true":
                eslog.debug("Vulkan driver is available on the system.")
                try:
                    have_discrete = subprocess.check_output(["/usr/bin/batocera-vulkan", "hasDiscrete"], text=True).strip()
                    if have_discrete == "true":
                        eslog.debug("A discrete GPU is available on the system. We will use that for performance")
                        try:
                            discrete_name = subprocess.check_output(["/usr/bin/batocera-vulkan", "discreteName"], text=True).strip()
                            if discrete_name != "":
                                eslog.debug("Using Discrete GPU Name: {} for PPSSPP".format(discrete_name))
                                iniConfig.set("Graphics", "VulkanDevice", discrete_name)
                            else:
                                eslog.debug("Couldn't get discrete GPU Name")
                        except subprocess.CalledProcessError:
                            eslog.debug("Error getting discrete GPU Name")
                    else:
                        eslog.debug("Discrete GPU is not available on the system. Using default.")
                except subprocess.CalledProcessError:
                    eslog.debug("Error checking for discrete GPU.")
            else:
                eslog.debug("Vulkan driver is not available on the system. Falling back to OpenGL")
                iniConfig.set("Graphics", "GraphicsBackend", "0 (OPENGL)")
        except subprocess.CalledProcessError:
            eslog.debug("Error executing batocera-vulkan script.")

    # Display FPS
    if system.isOptSet('showFPS') and system.getOptBoolean('showFPS') == True:
        iniConfig.set("Graphics", "ShowFPSCounter", "3") # 1 for Speed%, 2 for FPS, 3 for both
    else:
        iniConfig.set("Graphics", "ShowFPSCounter", "0")

    # Frameskip
    iniConfig.set("Graphics", "FrameSkipType", "0") # Use number and not percent
    if system.isOptSet("frameskip") and not system.config["frameskip"] == "automatic":
        iniConfig.set("Graphics", "FrameSkip", str(system.config["frameskip"]))
    elif system.isOptSet('skip_buffer_effects') and system.getOptBoolean('skip_buffer_effects') == True:
        iniConfig.set("Graphics", "FrameSkip", "0")
    else:
        iniConfig.set("Graphics", "FrameSkip", "2")

    # Buffered rendering
    if system.isOptSet('skip_buffer_effects') and system.getOptBoolean('skip_buffer_effects') == True:
        iniConfig.set("Graphics", "SkipBufferEffects", "True")
        # Have to force autoframeskip off here.
        iniConfig.set("Graphics", "AutoFrameSkip", "False")
    else:
        iniConfig.set("Graphics", "SkipBufferEffects", "False")
        # Both internal resolution and auto frameskip are dependent on buffered rendering being on, only check these if the user is actually using buffered rendering.
        # Internal Resolution
        if system.isOptSet('internal_resolution'):
            iniConfig.set("Graphics", "InternalResolution", str(system.config["internal_resolution"]))
        else:
            iniConfig.set("Graphics", "InternalResolution", "1")
        # Auto frameskip
        if system.isOptSet("autoframeskip") and system.getOptBoolean("autoframeskip") == False:
            iniConfig.set("Graphics", "AutoFrameSkip", "False")
        else:
            iniConfig.set("Graphics", "AutoFrameSkip", "True")

    # VSync Interval
    if system.isOptSet('vsyncinterval') and system.getOptBoolean('vsyncinterval') == False:
        iniConfig.set("Graphics", "VSyncInterval", "False")
    else:
        iniConfig.set("Graphics", "VSyncInterval", "True")

    # Texture Scaling Level
    if system.isOptSet('texture_scaling_level'):
        iniConfig.set("Graphics", "TexScalingLevel", system.config["texture_scaling_level"])
    else:
        iniConfig.set("Graphics", "TexScalingLevel", "1")
    # Texture Scaling Type
    if system.isOptSet('texture_scaling_type'):
        iniConfig.set("Graphics", "TexScalingType", system.config["texture_scaling_type"])
    else:
        iniConfig.set("Graphics", "TexScalingType", "0")
    # Texture Deposterize
    if system.isOptSet('texture_deposterize'):
        iniConfig.set("Graphics", "TexDeposterize", system.config["texture_deposterize"])
    else:
        iniConfig.set("Graphics", "TexDeposterize", "True")

    # Anisotropic Filtering
    if system.isOptSet('anisotropic_filtering'):
        iniConfig.set("Graphics", "AnisotropyLevel", system.config["anisotropic_filtering"])
    else:
        iniConfig.set("Graphics", "AnisotropyLevel", "3")
    # Texture Filtering
    if system.isOptSet('texture_filtering'):
        iniConfig.set("Graphics", "TextureFiltering", system.config["texture_filtering"])
    else:
        iniConfig.set("Graphics", "TextureFiltering", "1")

   ## [SYSTEM PARAM]
    if not iniConfig.has_section("SystemParam"):
        iniConfig.add_section("SystemParam")

    # Forcing Nickname to Batocera or User name
    if system.isOptSet('retroachievements') and system.getOptBoolean('retroachievements') == True and system.isOptSet('retroachievements.username') and system.config.get('retroachievements.username', "") != "":
        iniConfig.set("SystemParam", "NickName", system.config.get('retroachievements.username', ""))
    else:
        iniConfig.set("SystemParam", "NickName", "Batocera")
    # Disable Encrypt Save (permit to exchange save with different machines)
    iniConfig.set("SystemParam", "EncryptSave", "False")


    ## [GENERAL]
    if not iniConfig.has_section("General"):
        iniConfig.add_section("General")

    # Rewinding
    if system.isOptSet('rewind') and system.getOptBoolean('rewind') == True:
        iniConfig.set("General", "RewindFlipFrequency", "300") # 300 = every 5 seconds
    else:
        iniConfig.set("General", "RewindFlipFrequency",  "0")
    # Cheats
    if system.isOptSet('enable_cheats'):
        iniConfig.set("General", "EnableCheats", system.config["enable_cheats"])
    else:
        iniConfig.set("General", "EnableCheats", "False")
    # Don't check for a new version
    iniConfig.set("General", "CheckForNewVersion", "False")

    # SaveState
    if system.isOptSet('state_slot'):
        iniConfig.set("General", "StateSlot", str(system.config["state_slot"]))
    else:
        iniConfig.set("General", "StateSlot", "0")

    ## [UPGRADE] - don't upgrade
    if not iniConfig.has_section("Upgrade"):
        iniConfig.add_section("Upgrade")
    iniConfig.set("Upgrade", "UpgradeMessage", "")
    iniConfig.set("Upgrade", "UpgradeVersion", "")
    iniConfig.set("Upgrade", "DismissedVersion", "")

    ## [RetroAchievements]
    if not iniConfig.has_section("Achievements"):
        iniConfig.add_section("Achievements")
        
    # Achievements enabled
    if system.isOptSet('retroachievements') and system.getOptBoolean('retroachievements') == True:
      iniConfig.set("Achievements", "AchievementsEnable", "True")
    else:
      iniConfig.set("Achievements", "AchievementsEnable", "False")
    
    # Achievements credentials
    iniConfig.set("Achievements", "AchievementsUserName", system.config.get("retroachievements.username", ""))
    writeRetroAchievements(str(system.config.get("retroachievements.token", None)))
    
    # Achievements hardcore mode
    if system.isOptSet('retroachievements.hardcore') and system.getOptBoolean('retroachievements.hardcore') == True:
        iniConfig.set("Achievements", "AchievementsChallengeMode", "True")
    else:
        iniConfig.set("Achievements", "AchievementsChallengeMode", "False")
    
    # Achievements encore mode
    if system.isOptSet('retroachievements.encore') and system.getOptBoolean('retroachievements.encore') == True:
        iniConfig.set("Achievements", "AchievementsEncoreMode", "True")
    else:
        iniConfig.set("Achievements", "AchievementsEncoreMode", "False")

    # Achievements sound enabled
    if system.isOptSet("retroachievements.sound") and system.config["retroachievements.sound"] != "none":
        iniConfig.set("Achievements", "AchievementsSoundEffects", "True")
    else:
        iniConfig.set("Achievements", "AchievementsSoundEffects", "False")

    # Custom : allow the user to configure directly PPSSPP via batocera.conf via lines like : ppsspp.section.option=value
    for user_config in system.config:
        if user_config[:7] == "ppsspp.":
            section_option = user_config[7:]
            section_option_splitter = section_option.find(".")
            custom_section = section_option[:section_option_splitter]
            custom_option = section_option[section_option_splitter+1:]
            if not iniConfig.has_section(custom_section):
                iniConfig.add_section(custom_section)
            iniConfig.set(custom_section, custom_option, str(system.config[user_config]))
