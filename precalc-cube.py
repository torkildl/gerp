#!/usr/bin/python

# Precalc cube rotations over 512 frames.
# Saves number of vertices, coordinates in 3d per frame,

import PIL.ImageDraw as ImageDraw
import PIL.Image as Image
import imageio as imageio
import numpy as np
import math
import os
import vg

def rotatex(angle, vertex):
    x = vertex[0]
    y = vertex[1]
    z = vertex[2]
    # y' = y*cos q - z*sin q
    # z' = y*sin q + z*cos q
    xr = x
    yr = y*math.cos(angle) - z*math.sin(angle)
    zr = y*math.sin(angle) + z*math.cos(angle)
    return([xr,yr,zr])

def rotatey(angle, vertex):
    x = vertex[0]
    y = vertex[1]
    z = vertex[2]
    # y' = y*cos q - z*sin q
    # z' = y*sin q + z*cos q
    # x' = x
    xr = z*math.sin(angle) + x*math.cos(angle)
    yr = y
    zr = z*math.cos(angle) - x*math.sin(angle)
    return([xr,yr,zr])

def rotatez(angle, vertex):
    x = vertex[0]
    y = vertex[1]
    z = vertex[2]
    # x' = x*cos q - y*sin q
    # y' = x*sin q + y*cos q
    # z' = z
    xr = x*math.cos(angle) - y*math.sin(angle)
    yr = x*math.sin(angle) + y*math.cos(angle)
    zr = z
    return([xr,yr,zr])

def rotateXYZ(xangle, yangle, zangle, vertex):
    rotx = rotatex(xangle, vertex)
    roty = rotatey(yangle, rotx)
    rotz = rotatez(zangle, roty)
    rot = [round(rotz[0]),round(rotz[1]),round(rotz[2])]
    return rot

def write_uint16(f,x):
    f.write(x.to_bytes(2, byteorder="big", signed=False))

def write_uint8(f,x):
    f.write(x.to_bytes(1, byteorder="big", signed=False))

def write_sint16(f,x):
    f.write(x.to_bytes(2, byteorder="big",signed=True))

def write_sint32(f,x):
    f.write(x.to_bytes(4, byteorder="big",signed=True))
def write_uint32(f,x):
    f.write(x.to_bytes(4, byteorder="big",signed=False))

def convert2d(dist,zoom, vertex):
    dz = zoom/(vertex[2]+dist)
    x = vertex[0]*dz + x_center
    y = vertex[1]*dz + y_center
    return [round(x),round(y)]

# def convert2d(zoom,dist,vertex):
#     dz = (dist/(dist+vertex[2]))
#     x = dz*vertex[0] + x_center
#     y = dz*vertex[1] + y_center
#     return [round(x),round(y)]

x_center = 160           # for 192*192 screens
y_center = 128
zoom = 400
dist = 350          # 380
numframes = 128
xrot = -0.25
yrot = 0
zrot = 0
fpfactor = 64
max_width = 0
min_width = 320

### Main function
if __name__ == '__main__':

    outfile = open("./assets/cubeframes.dat", "wb")
    frames = []
    for i in range(0,numframes):
    #for i in range(0,21):
        xradians = xrot*(i/numframes)*(2*math.pi)
        yradians = yrot*(i/numframes)*(2*math.pi)
        zradians = zrot*(i/numframes)*(2*math.pi)

        v0 = [0, -64, 64]
        v0_rot = rotateXYZ(xradians, yradians, zradians, v0)
        v0_2d = convert2d(zoom,dist,v0_rot)

        v0_x0 = [-64, -64, -64]
        v0_x0_rot = rotateXYZ(xradians, yradians, zradians, v0_x0)
        v0_x0_2d = convert2d(zoom,dist,v0_x0_rot)

        v0_x1 = [64, -64, -64]
        v0_x1_rot = rotateXYZ(xradians, yradians, zradians, v0_x1)
        v0_x1_2d = convert2d(zoom,dist,v0_x1_rot)

        v1 = [0, 64, -64]
        v1_rot = rotateXYZ(xradians, yradians, zradians, v1)
        v1_2d = convert2d(zoom,dist,v1_rot)

        v1_x0 = [-64, 64, -64]
        v1_x0_rot = rotateXYZ(xradians, yradians, zradians, v1_x0)
        v1_x0_2d = convert2d(zoom,dist,v1_x0_rot)

        v1_x1 = [64, 64, -64]
        v1_x1_rot = rotateXYZ(xradians, yradians, zradians, v1_x1)
        v1_x1_2d = convert2d(zoom,dist,v1_x1_rot)

        v2 = [0, 64, 64]
        v2_rot = rotateXYZ(xradians, yradians, zradians, v2)
        v2_2d = convert2d(zoom,dist,v2_rot)

        v2_x0 = [-64, 64, 64]
        v2_x0_rot = rotateXYZ(xradians, yradians, zradians, v2_x0)
        v2_x0_2d = convert2d(zoom,dist,v2_x0_rot)

        v2_x1 = [64, 64, 64]
        v2_x1_rot = rotateXYZ(xradians, yradians, zradians, v2_x1)
        v2_x1_2d = convert2d(zoom,dist,v2_x1_rot)

        width0 = v0_x1_2d[0]-v0_x0_2d[0]
        width1 = v1_x1_2d[0]-v1_x0_2d[0]
        width2 = v2_x1_2d[0]-v2_x0_2d[0]

        if width0>max_width: max_width = width0
        if width0<min_width: min_width = width0
        if width1>max_width: max_width = width1
        if width1<min_width: min_width = width1
        if width2>max_width: max_width = width2
        if width2<min_width: min_width = width2

        y0 = v0_x0_2d[1]
        y1 = v1_x0_2d[1]
        height1 = y1 - y0
        delta_width1 = ((width1-width0)/2)*fpfactor
        delta_texture1 = (128/height1)*fpfactor            # delta Z for face
                                                                 # 128/height
        write_sint16(outfile, height1)
        write_uint16(outfile, y0)
        write_uint16(outfile, int(width0*fpfactor/2))
        if height1>0:
            write_sint16(outfile, round(delta_width1/height1))
            write_uint16(outfile, round(delta_texture1))
        else:
            write_uint16(outfile, int(0))        
            write_uint16(outfile, int(0))        

        write_uint16(outfile, int(0))
        write_uint16(outfile, int(0))
        write_uint16(outfile, int(0))


        y1 = v1_x0_2d[1]
        y2 = v2_x0_2d[1]
        height2 = y2 - y1
        delta_width2 = ((width2-width1)/2)*fpfactor
        delta_texture2 = (128/height2)*fpfactor            # delta Z for face
        write_sint16(outfile, height2)
        write_uint16(outfile, y1)
        write_uint16(outfile, int(width1*fpfactor/2))
        if height2>0:
            write_sint16(outfile, round(delta_width2/height2))
            write_uint16(outfile, round(delta_texture2))
        else:
            write_uint16(outfile, int(0))        
            write_uint16(outfile, int(0))        
        write_uint16(outfile, int(0))
        write_uint16(outfile, int(0))
        write_uint16(outfile, int(0))


        # Simulate drawing
        frame = Image.new("RGB",(160*2,128*2),"white")
        draw = ImageDraw.Draw(frame)
        draw.polygon(((0,0),(319,0),(319,63),(0,63)),"blue")
        draw.polygon(((0,256-64),(319,256-64),(319,255),(0,255)),"blue")
        thepoly = (tuple(v0_x1_2d),tuple(v0_x0_2d),tuple(v1_x0_2d),tuple(v1_x1_2d))
        if height1>0: draw.polygon((thepoly), fill="purple")
        thepoly = (tuple(v1_x1_2d),tuple(v1_x0_2d),tuple(v2_x0_2d),tuple(v2_x1_2d))
        if height2>0: draw.polygon((thepoly), fill="green")
        frames.append(frame)

    imageio.mimsave("./frames.gif", frames)
    outfile.close()
    print(max_width,min_width)
    print("Shrinks:", (max_width-min_width)/2)
