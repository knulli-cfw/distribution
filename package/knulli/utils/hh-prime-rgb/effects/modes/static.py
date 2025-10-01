from effects._base_effect import BaseEffect
from device import Device

_metadata = {
    'name': 'Static',
    'reqs': []
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
    
    def apply(self, t, palettes):
        for z in self.dev.A:
            p = palettes[z.PAL_ID]
            z.all(p.bg)
    
    def framekey(self, t):
        return 0