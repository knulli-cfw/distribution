from effects._base_effect import BaseEffect
from device import Device

_metadata = {
    'name': 'Framebuffer',
    'reqs': []
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
    
    def apply(self, t, palettes):
        
        a = [0,0,0]

        with open('/dev/fb0', 'rb') as fb:
            a = fb.read(3)
            a = [int(b)/255 for b in a]

        for z in self.dev.A:
            p = palettes[z.PAL_ID]
            z.all([a[2], a[1], a[0]])
    
    def framekey(self, t):
        return t