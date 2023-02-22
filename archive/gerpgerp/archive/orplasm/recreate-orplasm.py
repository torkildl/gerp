import numpy as np
import os
from PIL import Image

infile0 = open("./planes00.raw","rb")
infile1 = open("./planes01.raw","rb")
infile2 = open("./planes02.raw","rb")
infile3 = open("./planes03.raw","rb")
infile4 = open("./planes04.raw","rb")

outfile = Image.new("P",(320,160))

for byte in range(0,40):
    for line in range(0,160):
        byte0 = int.from_bytes(infile0.read(1), "big")
        byte1 = int.from_bytes(infile1.read(1), "big")
        byte2 = int.from_bytes(infile2.read(1), "big")
        byte3 = int.from_bytes(infile3.read(1), "big")
        byte4 = int.from_bytes(infile4.read(1), "big")

        for p in range(0,8):
            thebit = 1<<(7-p)
            pix0 = 1*((byte0 & thebit)>0)
            pix1 = 1*((byte1 & thebit)>0)
            pix2 = 1*((byte2 & thebit)>0)
            pix3 = 1*((byte3 & thebit)>0)
            pix4 = 1*((byte4 & thebit)>0)
            pix = pix0 + pix1*2 + pix2*4 + pix3*8 + pix4*16
            x = byte*8 + p
            outfile.putpixel((x,line), pix)

outfile.save("myplasm.png")
