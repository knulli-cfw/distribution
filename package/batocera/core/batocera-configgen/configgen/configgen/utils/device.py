from __future__ import annotations

import logging
import subprocess
import sys
from pathlib import Path
from typing import TYPE_CHECKING, Final

from ..batoceraPaths import DEFAULTS_DIR

def hasBoardCapability(capability: str) -> bool | False:
    proc = subprocess.Popen(["knulli-board-capability " + capability], stdout=subprocess.PIPE, shell=True)
    (out, err) = proc.communicate()
    for val in out.decode().splitlines():
        return val == 'true' # return if the first line is the word "True"
