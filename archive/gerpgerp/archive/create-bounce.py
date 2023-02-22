#!/usr/bin/python
import math
import numpy
import matplotlib.pyplot as plt
import os

#
def write_uint16(f,x):
    f.write(x.to_bytes(2, byteorder="big", signed=False))

def write_sint16(f,x):
    f.write(x.to_bytes(2, byteorder="big",signed=True))

#  y = ax²+bx+c
#  h = ax² + h0
#
maxt = 128
heights = numpy.zeros(maxt, int)
topt = -128
a = -0.046
b = topt*a
h0 = 0
for t in range(0,maxt):
    ht = (a*t*t) + (b*t) + h0
    heights[t] = ht

numpy.max(heights)
numpy.min(heights)
numpy.average(heights)
# plt.plot(range(0,len(heights)),heights)

outfile = open("./data/bounce-pattern-1.raw", "wb")

for x in heights:
    thex = int(x)
    write_uint16(outfile, thex)

outfile.close()



maxt = 128
heights = numpy.zeros(maxt, int)
topt = -128
a = -0.036
b = topt*a
h0 = 0
for t in range(0,maxt):
    ht = (a*t*t) + (b*t) + h0
    heights[t] = ht

numpy.max(heights)
numpy.min(heights)
numpy.average(heights)
# plt.plot(range(0,len(heights)),heights)

outfile = open("./data/bounce-pattern-2.raw", "wb")

for x in heights:
    thex = int(x)
    write_uint16(outfile, thex)

outfile.close()


maxt = 128
heights = numpy.zeros(maxt, int)
topt = -128
a = -0.040
b = topt*a
h0 = 0
for t in range(0,maxt):
    ht = (a*t*t) + (b*t) + h0
    heights[t] = ht

numpy.max(heights)
numpy.min(heights)
numpy.average(heights)
# plt.plot(range(0,len(heights)),heights)

outfile = open("./data/bounce-pattern-3.raw", "wb")

for x in heights:
    thex = int(x)
    write_uint16(outfile, thex)

outfile.close()
