
import os
from time import sleep

class RGBDriver:

    def __init__(self, extra:dict) -> None:
        
        self.RGB_ORDER = extra['rgb_order']
        self.PATCHTABLE:dict = {a: b for a,b in extra['patchtable']}

        with open('/sys/class/led_anim/effect_rgb_hex_lr', 'w') as _temp:
            _temp.write('000000')
        with open('/sys/class/led_anim/effect_rgb_hex_m', 'w') as _temp:
            _temp.write('000000')
        sleep(1)
        with open('/sys/class/led/tg5040_exterme_brightness', 'w') as _temp:
            _temp.write('255')
        with open('/sys/class/led_anim/max_scale', 'w') as _temp:
            _temp.write('255')
        with open('/sys/class/led_anim/effect_enable', 'w') as _temp:
            _temp.write('0')

        self.rgb_sink = os.open('/sys/class/led_anim/frame', os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK) # type: ignore

    # expects a list of rgb values [255,0,0, ... ]
    def render(self, rgb_data:list[int]) -> bytes:
        rgb_data_ = []
        for i in range(int(len(rgb_data)/3*4)):
            if(i%4 == 3):
                rgb_data_.append(0)
            else:
                corr = i//4
                i_ = self.PATCHTABLE.get(i-corr, i-corr)
                rgb_data_.append(rgb_data[(i_//3)*3 + self.RGB_ORDER[i_%3]])
        return bytes(rgb_data_)

    def write(self, led_data:bytes):
        os.write(self.rgb_sink, led_data)
    
    def close(self) -> None:        
        os.close(self.rgb_sink)

    

