#!/usr/bin/python

import os

def write_uint8(f,x):
    f.write(x.to_bytes(1, byteorder="big", signed=False))


f = open("./assets/fontspec.dat", "wb")

spec = {
        chr(39): 4,
#        " ": 5,
#        chr(10): 0,
        "I": 4,
        "L": 4,
        "T": 7,
        "U": 7,
        "W": 10,
        "i": 3,
        "a": 7,
        "l": 4,
        "n": 7,
        "o": 7,
        "s": 7,
        "e": 6
    }

for x in range(0,256):
    v = 7
    if chr(x) in spec:
        v = spec[chr(x)]

    write_uint8(f,v)

f.close()
