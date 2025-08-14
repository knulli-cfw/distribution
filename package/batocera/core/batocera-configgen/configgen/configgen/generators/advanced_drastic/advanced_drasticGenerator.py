from __future__ import annotations

import filecmp
import os
import shutil
from os import environ
import subprocess
from typing import TYPE_CHECKING

from ... import Command
from ...batoceraPaths import CONFIGS
from ...controller import generate_sdl_game_controller_config
from ..Generator import Generator

if TYPE_CHECKING:
    from pathlib import Path

    from ...types import HotkeysContext

class Advanced_DrasticGenerator(Generator):

    def getHotkeysContext(self) -> HotkeysContext:
        return {
            "name": "drastic",
            "keys": { "exit": "KEY_ESC" }
        }

    def generate(self, system, rom, playersControllers, metadata, guns, wheels, gameResolution):

        advanced_drastic_root = "/userdata/system/configs/advanced_drastic"
        advanced_drastic_bin = "/userdata/system/configs/advanced_drastic/launch.sh"
        advanced_drastic_conf = "/userdata/system/configs/advanced_drastic/config/drastic.cfg"
        advanced_drastic_saves = "/userdata/saves/nds/advanced_drastic/saves"
        advanced_drastic_states = "/userdata/saves/nds/advanced_drastic/states"

        board = os.popen("cat /boot/boot/batocera.board").read()
        board=board.rstrip("\n\r ")

        if os.path.isfile(advanced_drastic_root + "/batocera.board"):
            board_installed = os.popen("cat " + advanced_drastic_root + "/batocera.board").read()
            board_installed = board_installed.rstrip("\n\r ")
        else:
            board_installed = ""

        if (not os.path.exists(advanced_drastic_root)) or (board != board_installed):
            os.makedirs(advanced_drastic_root, exist_ok = True)
            os.system("cp -rv /usr/share/advanced_drastic/* /userdata/system/configs/advanced_drastic")
            if os.path.exists("/usr/share/advanced_drastic/devices/" + board ):
                os.system("cp -rv /usr/share/advanced_drastic/devices/" + board + "/* /userdata/system/configs/advanced_drastic")
            os.system("cp /boot/boot/batocera.board /userdata/system/configs/advanced_drastic")

        # Bind mount saves and states locations
        saves_target = os.path.join(advanced_drastic_root, "backup")
        states_target = os.path.join(advanced_drastic_root, "savestates")

        os.makedirs(saves_target, exist_ok=True)
        os.makedirs(states_target, exist_ok=True)
        os.makedirs(advanced_drastic_saves, exist_ok=True)
        os.makedirs(advanced_drastic_states, exist_ok=True)

        # Moves original files before binding
        def move_data(src_dir, dst_dir):
            if os.path.exists(src_dir):
                for filename in os.listdir(src_dir):
                    shutil.move(os.path.join(src_dir, filename), os.path.join(dst_dir, filename))

        # Check if already mounted
        def is_mounted(mount_point: str) -> bool:
            path = os.path.realpath(mount_point)
            with open("/proc/self/mountinfo", "r") as f:
                for line in f:
                    parts = line.split()
                    if len(parts) >= 5 and os.path.realpath(parts[4]) == path:
                        return True
            return False

        # Set bind mounts for exfat. No symlinks
        if not is_mounted(saves_target):
            move_data(saves_target, advanced_drastic_saves)
            subprocess.call(["mount", "--bind", advanced_drastic_saves, saves_target])

        if not is_mounted(states_target):
            move_data(states_target, advanced_drastic_states)
            subprocess.call(["mount", "--bind", advanced_drastic_states, states_target])


        # User Settings
        settings_to_update = {}

        if system.isOptSet("adv_drastic_hires") and system.getOptBoolean('adv_drastic_hires') == True:
            settings_to_update["hires_3d"] = "1"
        else:
            settings_to_update["hires_3d"] = "0"

        if system.isOptSet("adv_drastic_threaded") and system.getOptBoolean('adv_drastic_threaded') == True:
            settings_to_update["threaded_3d"] = "1"
        else:
            settings_to_update["threaded_3d"] = "0"

        if system.isOptSet("adv_drastic_frameskip_type") and system.getOptBoolean('adv_drastic_frameskip_type') == True:
            settings_to_update["frameskip_type"] = "1"
        else:
            settings_to_update["frameskip_type"] = "0"

        if system.isOptSet("adv_drastic_frameskip_value"):
            settings_to_update["frameskip_value"] = str(system.config["adv_drastic_frameskip_value"])

        # Only apply if there are changes detected
        if settings_to_update:
            configureSettings(settings_to_update, advanced_drastic_conf)

        os.chdir(advanced_drastic_root)
        commandArray = [advanced_drastic_bin, rom]
        return Command.Command(
            array=commandArray,
            env={
                'DISPLAY': '0.0',
                'LIB_FB': '3',
                'SDL_GAMECONTROLLERCONFIG': generate_sdl_game_controller_config(playersControllers)
            })

def configureSettings(settings_to_update: dict, config_path: str):
    if not os.path.isfile(config_path):
        return

    with open(config_path, "r") as file:
        lines = file.readlines()

    with open(config_path, "w") as file:
        for line in lines:
            stripped = line.strip()
            if "=" in stripped:
                key, value = map(str.strip, stripped.split("=", 1))
                if key in settings_to_update:
                    new_value = settings_to_update[key]
                    if value != new_value:
                        file.write(f"{key} = {new_value}\n")
                    else:
                        file.write(line)
                else:
                    file.write(line)
            else:
                file.write(line)
