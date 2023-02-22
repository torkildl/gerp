#!/usr/bin/python


scrolltext = "     A demo of demos! Talent welcomes you to the METAdemo, another Talented simulacrum! Is this one or many demos? Enjoy them multiplying, and Nordlicht 2022! Goodbye!"

import PIL
from PIL import ImageFont
from PIL import Image
from PIL import ImageDraw

maph = 11
scrollx = int(len(scrolltext)*6)
mapw = int(scrollx)+16-(scrollx % 16)

mapw = 1024*(int(mapw/1024)+1)
font = ImageFont.truetype("REDENSEK",maph+1)
img=Image.new("P", (mapw,maph),color=0)
pal=img.putpalette([0,0,0,255,255,255])


draw = ImageDraw.Draw(img)
draw.text((0, 0),scrolltext,1,font=font, color=3)
draw = ImageDraw.Draw(img)

map = img.crop((0,4,mapw,11))
complete = Image.new("P",(mapw,16*16), color=0)
complete.putpalette([0,0,0,255,255,255])

for x in range(0,16):
    dx = 16-x
    complete.paste(map, (dx,x*16))

map.save("./data/readymade-scrollmap.png")
complete.save("./data/readymade-scrollmap-16.png")
complete.size
