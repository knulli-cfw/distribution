from colors import Palette
from device import Device
from typing import Hashable

class BaseEffect:
    def __init__(self, dev:Device, initial_tick:int) -> None:
        self.dev = dev
        self._TICK = initial_tick
        pass

    def prepare(self):
        pass

    def apply(self, t:int, palettes:list[Palette]):
        pass

    def framekey(self, t) -> Hashable:
        return None