from __future__ import annotations

import logging
import os
import subprocess
import shutil
from pathlib import Path
from typing import TYPE_CHECKING, Final

from ... import Command
from ...batoceraPaths import BIOS, HOME, ROMS, SAVES, SCREENSHOTS, ensure_parents_and_open
from ...controller import generate_sdl_game_controller_config
from ..Generator import Generator

if TYPE_CHECKING:
    from ...types import HotkeysContext

eslog = logging.getLogger(__name__)

PICO8_BIN_PATH: Final = BIOS / "pico-8" / "pico8"
PICO8_ROOT_PATH: Final = ROMS / "pico8"
#SPLORE_ROMS_PATH: Final = ROMS / "pico8" / "splore"
#SPLORE_PATH: Final = HOME / ".lexaloffle" / "pico-8" / "bbs" / "carts"
PICO8_CONTROLLERS: Final = HOME / ".lexaloffle" / "pico-8" / "sdl_controllers.txt"
PICO8_CONFIG_PATH=HOME / ".lexaloffle" / "pico-8" / "config.txt"
PICO8_SAVES_PATH: Final = SAVES / "pico8"
VOX_BIN_PATH: Final = BIOS / "voxatron" / "vox"
VOX_ROOT_PATH: Final = ROMS / "voxatron"
VOX_CONTROLLERS: Final = HOME / ".lexaloffle" / "Voxatron" / "sdl_controllers.txt"

# Generator for the official pico8 binary from Lexaloffle
class LexaloffleGenerator(Generator):

    def getHotkeysContext(self) -> HotkeysContext:
        return {
            "name": "lexaloffle",
            "keys": { "exit": ["KEY_LEFTCTRL", "KEY_Q"] }
        }

    def generate(self, system, rom, playersControllers, metadata, guns, wheels, gameResolution):
        rom_path = Path(rom)

        if (system.name == "pico8"):
            BIN_PATH=PICO8_BIN_PATH
            CONTROLLERS=PICO8_CONTROLLERS
            ROOT_PATH=PICO8_ROOT_PATH
        elif (system.name == "voxatron"):
            BIN_PATH=VOX_BIN_PATH
            CONTROLLERS=VOX_CONTROLLERS
            ROOT_PATH=VOX_ROOT_PATH
        else:
            eslog.error(f"The Lexaloffle generator has been called for an unknwon system: {system.name}.")
            return -1
        if not BIN_PATH.exists():
            eslog.error(f"Lexaloffle official binary not found at {BIN_PATH}")
            return -1
        if not os.access(BIN_PATH, os.X_OK):
            eslog.error(f"File {BIN_PATH} is not set as executable")
            return -1


        # Initialize dictionary
        config_settings = {}

        # Set defaults
        config_settings["window_size"] = "0 0" # window width, height
        config_settings["screen_size"] = "0 0" # screen width, height (stretched to window)
        config_settings["windowed"] = "0" # full screen
        config_settings["window_position"] = "-1 -1" # x and y position of window (-1, -1 to let the window manager decide)
        config_settings["frameless"] = "1" # 1 to use a window with no frame
        config_settings["fullscreen_method"] = "1" # 0 maximized window (linux)  1 borderless desktop-sized window  2 hardware fullscreen (warning: erratic behaviour under some drivers)
        config_settings["blit_method"] = "0" # 0 auto  1 software (slower but sometimes more reliable)  2 hardware (can do filtered scaling)
        config_settings["background_sleep_ms"] = "10" # number of milliseconds to sleep each frame when running in the background
        config_settings["rmb_key"] = "0" # 0 for none  226 for LALT
        config_settings["desktop_path"] = "/userdata/screenshots/" # Desktop for saving screenshots etc. Defaults to $HOME/Desktop
        config_settings["read_controllers_in_background"] = "0" # 1 to allow controller input even when application is in background
        config_settings["sound_volume"] = "256" # 0..256
        config_settings["music_volume"] = "256" # 0..256
        config_settings["volume"] = "256" # 0..256
        config_settings["mix_buffer_size"] = "1024" # Needed otherwise unstable // usually 1024. Try 2048 if you get choppy sound
        config_settings["use_wget"] = "0" # (Linux) 1 to use wget for downloads instead of libcurl (must be installed)
        config_settings["joystick_index"] = "0" # Specify which player index joystick control begins at (0..7)
        config_settings["button_keys"] = "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0" # Custom keyboard scancodes for buttons. player0 0..6, player1 0..5, menu_button, player2 0..5, player3 0..5
        config_settings["live_notes"] = "0" # Play notes as they are plotted in frequency mode
        config_settings["cursor_snap"] = "0" # if 1: when using keyboard cursor, snap to closest pixel / map cel
        config_settings["gui_theme"] = "0" # 0 default  1 dark blue background in code editor  2 black background in code editor   3 gray background in code editor
        config_settings["screenshot_scale"] = "3" # scale of screenshots and gifs // 2 means 256x256
        config_settings["gif_scale"] = "3" # scale of screenshots and gifs // 2 means 256x256
        config_settings["gif_len"] = "16" # maximum gif length in seconds (0..120; 0 means no gif recording)
        config_settings["gif_reset_mode"] = "0" # when 1, reset the recording when pressing ctrl-9 (useful for creating a non-overlapping sequence)
        config_settings["host_framerate_control"] = "0" # 0 for off. 1 for auto. 2 to allow control of a cart's framerate due to host machine's cpu capacity
        config_settings["tab_width"] = "1" # tab display width (1 ~ 4 spaces)
        config_settings["draw_tabs"] = "0" # 0 off 1 on: draw tab characters as small vertical lines
        config_settings["record_activity_log"] = "0" # 0 off 1 on: record the current cartridge and editor view every 3 seconds (see [appdata]/activity.log.txt)
        config_settings["allow_function_keys"] = "1" # 0 off 1 on: allow F6..F9 (alternative: ctrl 6..9)
        config_settings["check_for_cart_updates"] = "1" # 0 off 1 on: automatically check for a newer version of a BBS cart each time it is run.
        config_settings["enable_gpio"] = "1" # 0 off 1 on: allow access to hardware GPIO at 0x5f80..0x5fff (might need to sudo pico8)
        config_settings["auto_hide_mouse_cursor"] = "5" # hide mouse cursor for n seconds when typing.
        config_settings["aggressive_backups"] = "0" # 0 off 1 on: backup with a new timestamped filename on every run
        config_settings["periodic_backups"] = "20" # back up cartridge in editor every n minutes when not idle (0 for no periodic backups)
        config_settings["transform_screen"] = "0" # 129 flip horizontally // 130 flip vertically // 133 rotate CW 90 degrees // 134 rotate CW 180 degrees // 135 rotate CW 270 degrees
        config_settings["gfx_grid_lines"] = "0" # 0 off  > 1: colour to draw pixel grid in the gfx editor at zoom:8 and zoom:4 (16 for black)
        config_settings["capture_timestamps"] = "0" # 0 sequential (foo_0.png, foo_1.png)    1 timestamp (foo_20240115_120823.png)

        # Treat the first n controllers as if they were a single merged controller
        p1_handheld = subprocess.getoutput("batocera-settings-get system.input.p1_handheld").strip()
        if p1_handheld == "1":
            config_settings["merge_joysticks"] = "0"
        else:
            config_settings["merge_joysticks"] = "2"

        # Display FPS
        if system.isOptSet("pico8_showfps") and system.config['pico8_showfps'] == '1':
            config_settings["show_fps"] = "1"
        else:
            config_settings["show_fps"] = "0"

        # Filter mature games in splore
        if system.isOptSet("pico_splorefilter") and system.config['pico_splorefilter'] == '1':
            config_settings["splore_filter"] = "1"
        else:
            config_settings["splore_filter"] = "0"

        # Number of milliseconds to sleep each frame. Try 10 to conserve battery power
        if system.isOptSet("pico8_framesleep"):
            config_settings["foreground_sleep_ms"] = system.config['pico8_framesleep']
        else:
            config_settings["foreground_sleep_ms"] = "1"

        # Number of threads to prefetch carts in splore
        # 0 as default to only prefetch the visited carts, which will prevent many unexpected carts showing up in the pico8/splore folder
        if system.isOptSet("max_prefetch_threads"):
            config_settings["max_prefetch_threads"] = system.config['max_prefetch_threads']
        else:
            config_settings["max_prefetch_threads"] = "0"

        # Write config_settings to config.txt
        self.write_config(config_settings)

        # The command to run
        commandArray = [BIN_PATH]

        basename = os.path.basename(rom)
        rombase, romext = os.path.splitext(basename)

        rombase = rom_path.stem

        # .m3u support for multi-cart pico-8
        if rom_path.suffix.lower() == ".m3u":
            with rom_path.open() as fpin:
                lines = fpin.readlines()
            fullpath = rom_path.absolute().parent / lines[0].strip()
            commandArray.extend(["-root_path", fullpath.parent])
            rom_path = fullpath
        else:
            commandArray.extend(["-root_path", ROOT_PATH]) # store carts from splore

        if (rombase.lower() == "splore" or rombase.lower() == "console"):
            commandArray.extend(["-splore"])
        else:
            commandArray.extend(["-run", rom])

        commandArray.extend(["-cdata_path", PICO8_SAVES_PATH])

        # Pixel perfect / integer scaling
        if system.isOptSet("pico8_pixelperfect") and system.config['pico8_pixelperfect'] == '1':
            commandArray.extend(["-pixel_perfect", "1"])

        controllersdir = os.path.dirname(CONTROLLERS)
        if not os.path.exists(controllersdir):
                os.makedirs(controllersdir)
        controllersconfig = generate_sdl_game_controller_config(playersControllers)
        with ensure_parents_and_open(CONTROLLERS, "w") as file:
               file.write(controllersconfig)

        return Command.Command(array=commandArray, env={})

    def write_config(self, settings):
        configdir = os.path.dirname(PICO8_CONFIG_PATH)
        if not os.path.exists(configdir):
            os.makedirs(configdir)
        with open(PICO8_CONFIG_PATH, "w") as config_file:
            for key, value in settings.items():
                config_file.write(f"{key} {value}\n")

    def getInGameRatio(self, config, gameResolution, rom):
        return 4/3
