#!/bin/bash

python precalc-cube.py

./build/tools/amigeconv.exe -f bitplane -d 1 ./assets/triangle.png ./assets/triangle.raw

./poke-fontspec.py
./build/tools/amigeconv.exe -f bitplane -d 1 ./assets/font1bpl.png ./assets/font.raw

convert ./assets/logo.png -crop 320x64+0+98 -depth 4 ./assets/logo_320.png
convert ./assets/logo_320.png -resize 160x32 -depth 4 -colors 8 ./assets/logo_160.png
convert ./assets/logo_160.png -resize 80x16 -depth 4 -colors 8 ./assets/logo_80.png

./build/tools/amigeconv.exe -f bitplane -d 4 -l ./assets/logo_320.png ./assets/logo.raw
./build/tools/amigeconv.exe -f palette -p loadrgb4 ./assets/logo_320.png ./assets/logo.pal
./build/tools/amigeconv.exe -f bitplane -d 3 -l ./assets/logo_160.png ./assets/logo_160.raw
./build/tools/amigeconv.exe -f bitplane -d 3 -l ./assets/logo_80.png ./assets/logo_80.raw
./build/tools/amigeconv.exe -f palette -p loadrgb4 ./assets/logo_80.png ./assets/logo_80.pal

