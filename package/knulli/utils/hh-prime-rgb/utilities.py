VERSION = 1
from functools import lru_cache

from math import sin, cos, pi, sqrt, tan, radians
import itertools
from typing import Union

type Numeric = Union[int, float]
type Color = list[Numeric]

def generate_brightness_list(size, max_val):
    """
    Generates a list of integers with a logarithmic curve.
    """
    brightness_list = []
    for i in range(size):
        # Scale i to a 0-1 range and apply a power function.
        # This creates the logarithmic curve.
        normalized_val = (i / (size - 1))**2.5
        
        # Scale to the 0-255 range and round to the nearest integer.
        integer_val = round(normalized_val * max_val)
        brightness_list.append(integer_val)

    for i in range(size):
        if brightness_list[i] < i: brightness_list[i] = i
    return brightness_list

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return [int(hex_color[i:i+2], 16) for i in (0, 2, 4)]

def loop_d(a, b, loop):
    v = abs(a-b)
    p = 1 if a > b else -1
    if v > loop/2:
        return p * (loop-v)
    else:
        return p * v

def isnumeric(a):
    try:
        int(a)
        return True
    except: return False

def condswap(l, c):
    if c:
        return [l[1], l[0]]
    else:
        return l

def easeOutQuart(t):
    t -= 1
    return -(t * t * t * t - 1)

def sin_(n: float) -> float:
    return (sin(n)+1) / 2

sin100_t = [sin(i/100 * pi) for i in range(200)] 
def sin100(i):
    return sin100_t[i%200]

def sin100_(i):
    return (sin100_t[i%200] + 1) / 2

def hsv_fl(h: Numeric, s: Numeric, v: Numeric) -> Color:
    if s:
        if h == 1.0:
            h = 0.0
        i = int(h * 6.0)
        f = h * 6.0 - i

        w = ( v * (1.0 - s) )
        q = ( v * (1.0 - s * f) )
        t = ( v * (1.0 - s * (1.0 - f)) )
        v = v

        if i == 0:
            return [v, t, w]
        if i == 1:
            return [q, v, w]
        if i == 2:
            return [w, v, t]
        if i == 3:
            return [w, q, v]
        if i == 4:
            return [t, w, v]
        if i == 5:
            return [v, w, q]
        return [v, v, v]
    else:
        return [v, v, v]
    
def mix(c1:Color, s1:Numeric, c2:Color, s2:Numeric) -> Color:
    return [
        (c1[0]*s1 + c2[0]*s2),
        (c1[1]*s1 + c2[1]*s2),
        (c1[2]*s1 + c2[2]*s2)
    ]

def dimm(c1:Color, s1:Numeric) -> Color:
    return [c1[0]*s1, c1[1]*s1, c1[2]*s1]

def bucketize(l, bc, f):
        if bc < 1: bc = 1
        ret = []
        acc = 0
        for i, s in enumerate(l):
            if s > acc:
                acc = s
            if i > ((len(ret)+1) / bc)**f * (len(l)-1) or len(l) == i+1:
                ret.append(acc)
                acc = 0
        return ret

def color_upscale(c:Color) -> Color:
    m = 1/max(c)
    return dimm(c, m)

def encode_binary(d):
    return bytes(itertools.chain(*d))
def decode_binary(b):
    return [int(i) for i in b]