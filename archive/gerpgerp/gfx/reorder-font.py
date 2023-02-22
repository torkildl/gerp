#!python

from PIL import Image
import os

fontfile = "adjusted-font.png"
fontimage = Image.open(fontfile)

chars1 = "ABCDEFGHIJKLMNOPQRST"
chars2 = "UWXYZabcdefghijklmno"
chars3 = "pqrstuvwxyz 12345678"
chars4 = "9()!?@.,`-+=/\:;&*[]"
chars5 = "}W0"
chars = chars1 + chars2+ chars3+ chars4  + chars5
charlist = [*chars]

resultimage = Image.new(mode = "RGB",size = (8,256*16))
charnum = 0

xadjusts = {
    "I" : -2,
    "i" : -2,
    "l" : -2
}
# xadjusts.keys()
# xadjusts["I"]

for letter in charlist:
    row = int(charnum/20)
    col = int(charnum % 20)
    top = row*16
    bottom = top+16
    left = col*8
    right = left+8
    if xadjusts.get(letter):
        left = left - xadjusts.get(letter)
        right = right + xadjusts.get(letter)
    thechar = fontimage.crop((left, top, right, bottom))
    dx = 0
    dy = ord(letter)*16
    back = resultimage.copy()
    back.paste(thechar, (dx,dy))
    resultimage = back.copy()
    print(letter, row, col, top, bottom, left, right, dx, dy)
    charnum = charnum+1

resultimage.save("reorderedfont.png")
