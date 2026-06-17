import os
import struct
from time import sleep
from math import sqrt, atan2, degrees
from functools import lru_cache
from copy import deepcopy
from utilities import loop_d

JS_EVENT_FORMAT = 'IhBB'
JS_EVENT_SIZE = struct.calcsize(JS_EVENT_FORMAT)

JS_EVENT_BUTTON = 0x01  # Button pressed/released
JS_EVENT_AXIS   = 0x02  # Analog stick moved
JS_EVENT_INIT   = 0x80  # Initial state of device

@lru_cache(maxsize=1024)
def calc_value(x, y):
    return int(sqrt(x**2 + y**2))

class StickState:
    def __init__(self, config:dict[str,dict]):
        self._js0 = os.open('/dev/input/js0', os.O_RDONLY | os.O_NOCTTY | os.O_NONBLOCK) # pyright: ignore[reportAttributeAccessIssue]
        self.__state = {
            a: {
                'axis': config[a]['input'],
                'raw': [0, 0],
                'polarity': config[a].get('input_polarity', ['+', '+']),
                'angle': 0,
                'value': 0,
            }
            for a in config if 'input' in config[a]
        }
        self._state = deepcopy(self.__state)
        self._smoothing = True
        self._axis_cache = {axis_id: [stick_id, i] for stick_id in self.__state for i, axis_id in enumerate(config[stick_id]['input'])}
    
    def update(self):
        try:
            while True:
                event_data = os.read(self._js0, JS_EVENT_SIZE)
                _, e_value, e_type, e_number = struct.unpack(JS_EVENT_FORMAT, event_data)

                if (e_type == JS_EVENT_AXIS):
                    self._smoothing = True
                    self.calc(e_number, int(e_value // 256))
        except:
            pass
        
    def calc(self, id, value):
        stick, axis = self._axis_cache[id]

        self.__state[stick]['raw'][axis] = value if self.__state[stick]['polarity'][axis] == '+' else -value
        x, y = self.__state[stick]['raw']

        raw_value = calc_value(x, y)
        self.__state[stick]['angle'] = 180-degrees(atan2(x, y))
        self.__state[stick]['value'] = 1 if raw_value > 125 else raw_value / 125
    
    def __getitem__(self, name:str) -> dict:
        return self.__state[name]
