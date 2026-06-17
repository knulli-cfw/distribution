import json
import confloader
import os
from importlib import import_module

config = json.load(open('device_configs/'+confloader.identify_device()+'.json'))

RGBDriver = import_module("drivers."+config['driver']).RGBDriver

print("Loaded Driver:", config['driver']) # pyright: ignore[reportPossiblyUnboundVariable]

class Device:
    def __init__(self) -> None:
        self.CONFIG = config

        self.LED_COUNT = config['leds']

        self.FB0 = [0, 0, 0] * config['leds']
        self.BR:float = 100

        self.BATTERY = {
            'percentage': 0,
            'state': ''
        }

        self.nuke_savestates()
    
        self.driver = RGBDriver(config.get('driver_extra_params', {})) # pyright: ignore[reportPossiblyUnboundVariable]

        self.Raw = RawZone(
            self,
            {
                'id': 'raw',
                'leds': self.LED_COUNT,
                'led_indexes': list(range(self.LED_COUNT))
            }
        )

        self.Z = ZoneStore()
        self.A = []

        for zone_id in config['zones']:
            config['zones'][zone_id]['id'] = zone_id
            zone_config = config['zones'][zone_id]
            if zone_config['type'] == 'Ring':
                self.Z.Rings.append(RingZone(self, zone_config))
            if zone_config['type'] == 'Led':
                self.Z.Leds.append(LineZone(self, zone_config))

        self.A = self.Z.Leds + self.Z.Rings

    def savestate(self, key):
        self.CACHED_BYTESTREAM = self.render()
        self.CACHE[key] = self.CACHED_BYTESTREAM
        self.CACHE_LAST_KEY = key
    
    def nuke_savestates(self):
        self.CACHE = {}
        self.CACHE_SKIP = False
        self.CACHE_LAST_KEY = None
        self.CACHED_BYTESTREAM = None

    def recall(self, key):
        if key in self.CACHE:
            self.CACHED_BYTESTREAM = self.CACHE[key]
            if self.CACHE_LAST_KEY == key:
                self.CACHE_SKIP = True
            self.CACHE_LAST_KEY = key
            return True
        self.CACHED_BYTESTREAM = None
        return False

    def render(self):
        return self.driver.render([int(a*a*self.BR*255+0.49) for a in self.FB0])
        
    def write(self) -> None:
        bytestream = self.CACHED_BYTESTREAM
        if bytestream is None:
            bytestream = self.render()
        if not self.CACHE_SKIP:
            self.driver.write(bytestream)
        else:
            self.CACHE_SKIP = False

    def close(self) -> None:
        self.driver.close()
    
    def __getitem__(self, index) -> list[float]:
        return [
            self.FB0[index*3],
            self.FB0[index*3+1],
            self.FB0[index*3+2]
        ]
    
    def __setitem__(self, index:int, c:list[float]):
        self.FB0[index*3] = c[0]
        self.FB0[index*3+1] = c[1]
        self.FB0[index*3+2] = c[2]

class ZoneStore:
    def __init__(self):
        self.Rings:list[RingZone] = []
        self.Lines:list[LineZone]  = []
        self.Leds:list[RawZone] = []

class RawZone:
    def __init__(self, dev:Device, zone_config):
        self.ID = zone_config['id']
        self._dev = dev
        self._ind = zone_config['led_indexes']
        self.COUNT = zone_config['leds']
        self.PAL_ID = zone_config.get('secondary', 0)
        self.COUNT_2_F = self.COUNT // 2
        self.COUNT_2_C = self.COUNT // 2 + 1
    
    def all(self, c) -> None:
        for index in self._ind: 
            self._dev.FB0[index*3] = c[0]
            self._dev.FB0[index*3+1] = c[1]
            self._dev.FB0[index*3+2] = c[2]
    
    def __getitem__(self, index) -> list[float]:
        return [
            self._dev.FB0[index*3],
            self._dev.FB0[index*3+1],
            self._dev.FB0[index*3+2]
        ]
    
    def __setitem__(self, index:int, c:list[float]) -> None:
        self._dev.FB0[self._ind[index]*3] = c[0]
        self._dev.FB0[self._ind[index]*3+1] = c[1]
        self._dev.FB0[self._ind[index]*3+2] = c[2]

class LineZone(RawZone):
    def __init__(self, dev:Device, zone_config):
        super().__init__(dev, zone_config)

class RingZone(RawZone):
    def __init__(self, dev:Device, zone_config):
        super().__init__(dev, zone_config)
        if 'led_angles' not in zone_config: 
            self.ANGLES = [i/self.COUNT*360 for i in range(len(self._ind))]
        else:
            self.ANGLES = zone_config['led_angles']

        