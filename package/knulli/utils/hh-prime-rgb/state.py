from enum import Enum
import json
from colors import BLUE, GREEN, RED, WHITE, Palette
from device import Device
from effects.effect_store import MODES, NOTIS, STATES
from effects._base_effect import BaseEffect
from utilities import generate_brightness_list
from confloader import CONFIG, refresh as conf_refresh

MAX_BR = 100

class RGBState:
    def __init__(self) -> None:
        self.DEV = Device()
        self._br = 100
        self._tr = 100
        self._palette = [Palette([0,0,0], [0,0,0]), Palette([0,0,0], [0,0,0])]
        self._target_palette = [Palette([0,0,0], [0,0,0]), Palette([0,0,0], [0,0,0])]
        self._target_br = 100
        self._target_tr = 100

        # Flip true if config changes
        self._idle = False

        self._tick = 0

        self.FPS = 30
        #self.FPS = 1
        self.FRTM = int(1000 / self.FPS)

        self._mode = 'static'
        self.modes:list[BaseEffect] = [MODES['static']['class'](self.DEV, self._tick)]
        self.events:list[Event] = [
            #Event(EventType.RunEffect, 'up', 1, RED),
            #Event(EventType.RunEffect, 'up', 1, GREEN),
            #Event(EventType.RunEffect, 'up', 1, BLUE),
            Event(EventType.Notification, 'round', 1, WHITE),
            Event(EventType.Notification, 'blink_off', 1, WHITE),
            Event(EventType.FadeIn)
        ]
    
    @staticmethod
    def get() -> 'RGBState':
        global _INSTANCE
        if _INSTANCE is None:
            _INSTANCE = RGBState()
        return _INSTANCE

    def manage_events(self):
        if len(self.events) > 0:
            print([f"{a.type.name}/{a.payload}: {a.timer} {a.running}" for a in self.events])
            self._idle = False
            event = self.events[0]
            if event.type == EventType.LoadConfig:
                self.load_config()
                self.events.pop(0)
            if event.type == EventType.Die:
                self.DEV.close()
                quit()
            if event.type == EventType.FadeIn:
                self.DEV.nuke_savestates()
                self._target_tr = MAX_BR
                self.events.pop(0)
                return True
            if event.type == EventType.FadeOut:
                if not event.running:
                    self.DEV.nuke_savestates()
                    self._target_tr = 0
                    event.running = True
                    event.timer = 4
                if(self._tr == 0):
                    event.timer -= 1
                    if event.timer == 0:
                        self.events.pop(0)
            if event.type == EventType.AddLayer:
                running = False
                for i in range(len(self.modes)):
                    if self.modes[i].__class__ is STATES[event.payload]['class']:
                        running = True
                if not running:
                    self.modes.append(STATES[event.payload]['class'](self.DEV, self._tick))
                self.events.pop(0)
            if event.type == EventType.RemoveLayer:
                for i in range(len(self.modes)):
                    if self.modes[i].__class__ is STATES[event.payload]['class']:
                        self.modes.pop(i)
                        self.DEV.nuke_savestates()
                        self._target_tr = MAX_BR
                self.events.pop(0)
            if event.type == EventType.ChangeMode:
                self.modes[0] = MODES[event.payload]['class'](self.DEV, self._tick)
                self._tr = 0
                self.events.pop(0)
                self.DEV.nuke_savestates()
                self.events.append(Event(EventType.FadeIn))
            if event.type == EventType.Notification:
                if not event.running:
                    self.DEV.nuke_savestates()
                    self._tr = MAX_BR
                    self._target_tr = MAX_BR
                    self.apply_brightness()
                    event.running = True
                    self.modes.append(NOTIS[event.payload]['class'](self.DEV, self._tick))
                    event.timer = event.repeat * NOTIS[event.payload]['metadata']['duration']
                else:
                    event.timer -= 1
                    if event.timer == 0:
                        self.events.pop(0)
                        self.modes.pop()
                        self._tr = 0
                        self._target_tr = 0
                        self.apply_brightness()
                        self.DEV.nuke_savestates()
                        return True

    def get_palette(self):
        if len(self.events) > 0:
            if self.events[0].palette is not None:
                return [self.events[0].palette, self.events[0].palette]
        return self._palette

    def render(self, TICK):
        self._tick = TICK
        while self.manage_events(): pass
        mode = self.modes[-1]
        conf_done = True

        if not self._idle:
            conf_done = self.smooth_conf()
            if conf_done:
                self._idle = True
            #print("Idle", self._idle)

        #print("cd:", conf_done, "id:", self._idle, "br:", int(self.DEV.BR*100))
        mode.prepare()

        framekey = mode.framekey(TICK)
        if not self.DEV.recall(framekey):
            mode.apply(TICK, self.get_palette())
            if conf_done:
                self.DEV.savestate(framekey)

    def write(self):
        self.DEV.write()
    
    def load_config(self):
        conf_refresh()

        print(CONFIG)
        self.DEV.nuke_savestates()

        if CONFIG['mode'] != self._mode:
            if self._mode != "null":
                self.events.append(Event(EventType.FadeOut))
            self.events.append(Event(EventType.ChangeMode, CONFIG['mode']))
            self.events.append(Event(EventType.FadeIn))
            self._mode = CONFIG['mode']

        self._target_br = CONFIG['brightness']

        raw_palette = CONFIG['palette']
        self._target_palette = [Palette(*raw_palette), Palette(*raw_palette)]
        if CONFIG['palette_swap']:
            self._target_palette = [p.swap() for p in self._target_palette]
        if CONFIG['palette_swap_secondary']:
            self._target_palette[1] = self._target_palette[1].swap()
    
    def apply_brightness(self):
        self.DEV.BR = self._tr*self._br*self._br *self._br / (100**4)

    def smooth_conf(self):

        done = True

        for i in range(2):
            done = self._palette[i].paintdrop(self._target_palette[i]) and done
        
        if self._br != self._target_br:
            self._br += -1 if self._target_br < self._br else 1
            done = False

        if self._tr != self._target_tr:
            self._tr += -10 if self._target_tr < self._tr else 10
            done = False
        
        if not done:
            self.apply_brightness()
        
        return done

_INSTANCE:RGBState|None = None

class EventType(Enum):
    Die = 'die'
    LoadConfig = 'load_config'
    ChangeMode = 'change_mode'
    AddLayer = 'add_layer'
    RemoveLayer = 'remove_layer'
    Notification = 'notification'
    FadeOut = 'fadeout'
    FadeIn = 'fadein'

class Event:
    def __init__(self, type:EventType, payload:str='', repeat:int=1, palette:Palette|None=None) -> None:
        self.type = type
        self.payload = payload
        self.repeat = repeat
        self.palette = palette
        self.timer = 0
        self.running = False
    
    def __str__(self) -> str:
        return f'Event: {self.type}/{self.payload}'