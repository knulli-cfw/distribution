from effects._base_effect import BaseEffect
from device import Device
from joystick import StickState
from utilities import loop_d, mix, dimm

_metadata = {
    'name': 'Input Fade',
    'reqs': []
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
        self.bg_scale = 0.7
        self.ST = StickState(dev.CONFIG['zones'])
        self.ZD = {r.ID: [0]*r.COUNT for r in self.dev.Z.Rings}
        self.leds = sum([r.COUNT for r in self.dev.Z.Rings])
        self.zeroes = 0
    
    def prepare(self):
        self.ST.update()
        self.zeroes = 0
        for r in self.dev.Z.Rings:
            s = self.ST[r.ID]
            zd = self.ZD[r.ID]
            for x in range(r.COUNT):
                d = (100 - abs(loop_d(r.ANGLES[x], s['angle'], 360))) / 100
                if d > 0 and s['value'] > 0.3:
                    d2 = d * d * ((s['value']-0.3)/0.7)
                    zd[x] = min(d*100, zd[x] + d2*30)
                else:
                    zd[x] = max(0, zd[x]-3)
                    if zd[x] == 0:
                        self.zeroes += 1
    
    def apply(self, t, palettes):
        for r in self.dev.Z.Rings:
            p = palettes[r.PAL_ID]
            zd = self.ZD[r.ID]

            for x in range(r.COUNT):
                p_ = (zd[x] / 100)**0.5
                r[x] = mix(p.fg, p_, p.bg, self.bg_scale*(1-p_))
    
    def framekey(self, t):
        return 0 if self.zeroes == self.leds else t