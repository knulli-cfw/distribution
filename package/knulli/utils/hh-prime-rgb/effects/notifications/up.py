from effects._base_effect import BaseEffect
from device import Device
from utilities import loop_d, dimm

_metadata = {
    'name': 'Notification Up',
    'reqs': [],
    'duration': 23
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
    
    def apply(self, t, palettes):
        t = t-self._TICK + 0
        for z in self.dev.Z.Rings:
            p = palettes[z.PAL_ID]
            for x in range(z.COUNT):
                td = (t*20) % 450
                _d = abs(td - abs(loop_d(z.ANGLES[x], 180, 360)) - 120)
                if(_d < 120):
                    z[x] = dimm(p.fg, 1 - abs(_d) / 120)
                else:
                    z[x] = [0, 0, 0]
        for z in self.dev.Z.Leds:
            z.all([0,0,0])
    
    def framekey(self, t):
        return (t*20) % 450