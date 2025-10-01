from effects._base_effect import BaseEffect
from device import Device
from utilities import dimm, easeOutQuart

_metadata = {
    'name': 'Notification Round',
    'reqs': [],
    'duration': 30
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
    
    def apply(self, t, palettes):
        t = t-self._TICK + 0
        c = dimm(palettes[0].fg, min(t/20, 1))
        for z in self.dev.Z.Rings:
            _p = easeOutQuart((t*10) / 360)
            for x in range(z.COUNT):
                td = _p * 360
                if z.ANGLES[x] < td - 40:
                    z[x] = c
                elif td - 40 <= z.ANGLES[x] < td:
                    __p = ((z.ANGLES[x] - td) / 40) % 1
                    z[x] = dimm(c, 1-__p)
                else:
                    z[x] = [0,0,0]
        
        for z in self.dev.Z.Leds:
            z.all(c)
    
    def framekey(self, t):
        return t