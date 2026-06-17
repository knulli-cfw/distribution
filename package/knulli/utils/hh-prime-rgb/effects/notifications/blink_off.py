from effects._base_effect import BaseEffect
from device import Device
from utilities import generate_brightness_list, loop_d, dimm

_metadata = {
    'name': 'Notification Blink OFF',
    'reqs': [],
    'duration': 15
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
    
    def apply(self, t, palettes):
        t = t-self._TICK + 0
        p = palettes[0]
        c = dimm(p.fg, 1-t/15)
        self.dev.Raw.all(c)
    
    def framekey(self, t):
        return t % 15
