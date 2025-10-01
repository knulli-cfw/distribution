from bottle import run, route, get, request
from colors import BLUE, GREEN, RED, Palette
from state import RGBState, Event, EventType
from utilities import hex_to_rgb
from copy import deepcopy

STATE = RGBState.get()

presets = {
    'battery_charging': [
        Event(EventType.Notification, 'up', 3, GREEN),
    ],
    'battery_full': [
        Event(EventType.Notification, 'up', 1, GREEN),
        Event(EventType.Notification, 'round', 1, GREEN),
        Event(EventType.Notification, 'blink_off', 1, GREEN),
    ],
    'battery_low': [
        Event(EventType.Notification, 'blink', 3, RED),
    ],
    'cheevo': [
        Event(EventType.Notification, 'cheevo', 1),
    ]
}

def run_preset_effect(preset):
    STATE.events.append(Event(EventType.FadeOut))
    for e in preset:
        STATE.events.append(deepcopy(e))
    STATE.events.append(Event(EventType.FadeIn))

@route("/reload-config")
def json():
    STATE.events.append(Event(EventType.LoadConfig))
    return ""

@route("/animation", method='POST')
def animation():
    req = request.body.read().decode() # pyright: ignore[reportAttributeAccessIssue]
    if req == 'charging':
        run_preset_effect(presets['battery_charging'])
    elif req == 'cheevo':
        run_preset_effect(presets['cheevo'])
    elif req == 'battery_low':
        run_preset_effect(presets['battery_low'])
    elif req == 'battery_full':
        run_preset_effect(presets['battery_full'])
    else:
        req_ = req.split()
        try:
            if len(req_):
                STATE.events.append(Event(EventType.FadeOut))
        except Exception as e:
            return "Error while processing Command:\n[name] [count] [hex_color]\n"
    return ""


@route("/update-battery-state", method='POST')
def battery():
    req = request.body.read().decode().split() # pyright: ignore[reportAttributeAccessIssue]
    STATE.DEV.BATTERY['percentage'] = int(req[0])

    last_state = STATE.DEV.BATTERY['state']

    if False: # notification mode
        if req[1] != last_state and req[1] == 'Charging':
            run_preset_effect(presets['battery_charging'])
        if req[1] != last_state and req[1] == 'Full':
            run_preset_effect(presets['battery_full'])
        STATE.DEV.BATTERY['state'] = req[1]
    else:
        if req[1] != last_state:
            if req[1] == 'Charging':
                STATE.events.append(Event(EventType.AddLayer, 'charging'))
            else:
                STATE.events.append(Event(EventType.RemoveLayer, 'charging'))


@route("/update-screen-state", method='POST')
def screen():
    pass

@get("/kill")
def kill():
    STATE.events.append(Event(EventType.FadeOut))
    STATE.events.append(Event(EventType.Die))


def run_api():
    run(host='localhost', port=1235)

if __name__ == '__main__':
    run_api()