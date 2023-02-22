#!/usr/bin/python
from PIL import Image

# Create colorbands across Y
# Colors 1-7

maxX = 64*8
maxY = 128
minX = 16

bilde = Image.new(mode="P",size=(maxX,maxY))
palettedata = [0, 0, 0, 102, 102, 102, 176, 176, 176, 255, 255, 255]
bilde.putpalette(palettedata)

currWidth = minX
deltaWidth = ((maxX-minX)/2)/maxY
for y in range(0,maxY):
    currWidth = int(currWidth+deltaWidth)
    bands = 3 + currWidth/16
    currX = int(maxX/2-(currWidth/2))
    currXend = int(maxX/2+(currWidth/2))
    col = 1
    currband = 0
    
    for x in range(currX,currXend):
        col = ((col+1) % 6)+1
        bilde.putpixel((x,y),col)
