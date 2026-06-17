from colors import GREEN
from effects._base_effect import BaseEffect
from device import Device
from utilities import dimm, easeOutQuart, mix, sin100, sin100_

_metadata = {
    'name': 'Battery State',
    'reqs': [],
    'duration': 30
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
    
    def apply(self, t, palettes):

        pct =  self.dev.BATTERY['percentage']

        pct_dg = pct * 3.6

        palette = GREEN

        t = t-self._TICK - 10
        if t < 0:
            self.dev.Raw.all([0,0,0])

        fg = dimm(palette.fg, min(t/20, 1))
        bg = dimm([0.3,0.3,0.3], max(min((t)/40, 1), 0))
        for z in self.dev.Z.Rings:
            _p = easeOutQuart((t*10) / 360) * pct / 100 if t < 30 else pct / 100
            for x in range(z.COUNT):
                td = _p * 360
                fg1 = dimm(fg, sin100_(-t*2 + int(z.ANGLES[x]/3.6))**10*0.6 + 0.4)
                if z.ANGLES[x] < td - 40:
                    z[x] = fg1
                elif td - 40 <= z.ANGLES[x] < td:
                    __p = ((z.ANGLES[x] - td) / 40) % 1
                    z[x] = mix(fg1, 1-__p, bg, __p)
                else:
                    z[x] = bg
        
        for z in self.dev.Z.Leds:
            z.all(bg)
    
    def framekey(self, t):
        return t