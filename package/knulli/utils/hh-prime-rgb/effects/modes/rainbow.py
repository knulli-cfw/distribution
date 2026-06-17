from effects._base_effect import BaseEffect
from device import Device
from utilities import color_upscale, hsv_fl

_metadata = {
    'name': 'Rainbow',
    'reqs': []
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
    
    def apply(self, t, palettes):
        key = (-t / 2 / 45) % 1
        for z in self.dev.A:
            for i in range(z.COUNT):
                z[i] = color_upscale(hsv_fl((key + i / z.COUNT) % 1, 1, 0.5))
    
    def framekey(self, t):
        return (-t / 2 / 45) % 1
