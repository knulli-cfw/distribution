from effects._base_effect import BaseEffect
from device import Device
from utilities import mix, dimm, sin100

_metadata = {
    'name': 'Wave',
    'reqs': []
}

class Effect(BaseEffect):
    def __init__(self, dev: Device, initial_tick: int) -> None:
        super().__init__(dev, initial_tick)
    
    def apply(self, t, palettes):
        # Wave speed and frequency can be adjusted for different looks
        wave_speed = 60
        wave_frequency = 1
        
        for z in self.dev.A:
            p = palettes[z.PAL_ID]
            
            for i in range(z.COUNT):
                # Use a sin wave based on position and time
                # The t/wave_speed moves the wave, and i/z.COUNT spaces the wave
                # The result is scaled to 0-100 for sin100
                wave_val = ((i / z.COUNT) * wave_frequency + (-t / wave_speed)) % 1
                prog = sin100(int(wave_val * 100))
                
                # Mix the foreground and background colors based on the wave progression
                z[i] = mix(p.bg, 1 - (prog), p.fg, prog)
    
    def framekey(self, t):
        wave_speed = 60
        return (-t / wave_speed) % 1