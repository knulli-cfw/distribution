from time import time_ns, sleep
import threading
from api import run_api
from state import RGBState

TICK = 0
STATE = RGBState.get()

def main():
    global TICK
    log = False
    STATE.load_config()

    while True:
        
        _start = time_ns() // 1_000

        if TICK > 0:
            STATE.render(TICK)

        _rend = time_ns() // 1_000

        STATE.write()

        _wrt = time_ns() // 1_000

        ticks_ms_ = time_ns() // 1_000_000
        ms_left = (TICK+1)*STATE.FRTM - ticks_ms_
        
        if ms_left > 0:
            sleep(ms_left/1000)
        else:
            ms_left = 0
        
        nTICK = (ticks_ms_ + ms_left + 5) // STATE.FRTM
        align_TICK = (ticks_ms_ + ms_left + 5) % STATE.FRTM


        _end = time_ns() // 1_000

        if log:
            FPS = STATE.FPS
            print("->t:" if (TICK + 1 == nTICK) else "t:", f"{nTICK//(FPS*3600):02}:{(nTICK%(FPS*3600))//(FPS*60):02}:{(nTICK%(FPS*60)//FPS):02}.{nTICK%FPS:02}",
                " rend:", _rend-_start, " wrt:", _wrt-_rend, " tot:", _end-_start-ms_left,
                " fmt:", int(STATE.FRTM), " slp:", ms_left, " alg:", align_TICK, end="\r")
        
        TICK = int(nTICK)

if False:
    main()
else:
    t1 = threading.Thread(target=main)
    t2 = threading.Thread(target=run_api, daemon=True)

    t1.start()
    t2.start()