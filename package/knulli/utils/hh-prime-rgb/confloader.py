import os
import re

from colors import get_palette

CONFIG = {
    "fps": 30,
    "mode": "null",
    "brightness": 100,
    "palette": [[0, 0, 0], [0, 0, 0]],
    "palette_swap": False,
    "palette_swap_secondary": False,
    "speed": 0
}

palettes = [
    # --- High Contrast (Color + Neutral) ---
    ["PRed", "White"],
    ["PBlue", "Black"],
    ["Yellow", "Black"],
    ["Magenta", "White"],
    ["Cyan", "Black"],
    ["Green", "White"],
    ["Orange", "Black"],
    ["Violet", "Silver"],
    ["Gold", "Black"],
    ["Pink", "Silver"],

    # --- Complementary & Contrasting Hues ---
    ["Orange", "Blue"],
    ["Red", "Cyan"],
    ["Green", "Magenta"],
    ["Yellow", "Violet"],
    ["Gold", "PBlue"],

    # --- Analogous & Similar Hues ---
    ["Cyan", "Aqua"],
    ["Green", "Mint"],
    ["Red", "Pink"],
    ["Orange", "Gold"],
    ["Blue", "Violet"],
    
    # --- Other Vibrant Pairings ---
    ["Magenta", "Aqua"],
    ["Pink", "Mint"],
    ["Red", "Gold"],
    ["PBlue", "Yellow"],
    ["Violet", "Pink"],
]

KEY_LED_MODE="led.mode"
KEY_LED_BRIGHTNESS="led.brightness"
KEY_LED_BRIGHTNESS_ADAPTIVE="led.brightness.adaptive"
KEY_LED_SPEED="led.speed"
KEY_LED_COLOUR="led.colour"
KEY_LED_COLOUR_RIGHT="led.colour.right"
KEY_LED_BATTERY_LOW_THRESHOLD="led.battery.low"
KEY_LED_BATTERY_CHARGING_ENABLED="led.battery.charging"

mode_map = {
    '0' : 'null',
    '1' : 'framebuffer',
    '2' : 'shimmer',
    '3' : 'input_fade',
    '4' : 'wave',
    '5' : 'rainbow',
    '6' : 'static'
}

def identify_device():
    board = ""

    try:
        with open('/boot/boot/batocera.board', 'r') as f:
            board = f.read().strip()
    except (IOError, FileNotFoundError):
        pass

    return board

def get_param(key):
    return os.popen('batocera-settings-get '+key).read().strip()

def refresh(key:str|None=None):
    try:
        if key is None or key == KEY_LED_MODE:
            val = get_param(KEY_LED_MODE)
            CONFIG['mode'] = mode_map[val]
        
        if key is None or key == KEY_LED_BRIGHTNESS:
            val = get_param(KEY_LED_BRIGHTNESS)
            CONFIG['brightness'] = 40 + int(int(val) * 0.6)
        
        if key is None or key == KEY_LED_COLOUR:
            val1, val2, val3 = [int(x) for x in get_param(KEY_LED_COLOUR).split()]
            sp = palettes[(val1//10)%len(palettes)]
            CONFIG['palette'] = get_palette('-'.join(sp))
            CONFIG['palette_swap'] = val2 > 0
            CONFIG['palette_swap_secondary'] = val3 > 0
    except:
        pass
