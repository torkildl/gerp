#!/usr/bin/python

# Precalc cube rotations over 512 frames.
# Saves number of vertices, coordinates in 3d per frame,

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

def convert2d(dist,zoom, vertex):
    dz = zoom/(vertex[2]+dist)
    x = vertex[0]*dz + x_center
    y = vertex[1]*dz + y_center
    return [round(x),round(y)]

x_center = 128           # for 192*192 screens
y_center = 80
zoom = 380
dist = 300          # 380
numframes = 64
xrot = 0.25
yrot = 0
zrot = 0


### Main function
if __name__ == '__main__':

    outfile = open("./assets/rotlist.dat", "wb")

    for i in range(0,numframes):
    #for i in range(32,33):
        xradians = xrot*(i/numframes)*(2*math.pi)
        yradians = yrot*(i/numframes)*(2*math.pi)
        zradians = zrot*(i/numframes)*(2*math.pi)

        v0 = [0, -64, 64]
        v0_rot = rotateXYZ(xradians, yradians, zradians, v0)
        v0_2d = convert2d(zoom,dist,v0_rot)

        v0_x0 = [-64, -64, 64]
        v0_x0_rot = rotateXYZ(xradians, yradians, zradians, v0_x0)
        v0_x0_2d = convert2d(zoom,dist,v0_x0_rot)

        v0_x1 = [64, -64, 64]
        v0_x1_rot = rotateXYZ(xradians, yradians, zradians, v0_x1)
        v0_x1_2d = convert2d(zoom,dist,v0_x1_rot)

        v1 = [0, 64, 64]
        v1_rot = rotateXYZ(xradians, yradians, zradians, v1)
        v1_2d = convert2d(zoom,dist,v1_rot)

        v1_x0 = [-64, 64, 64]
        v1_x0_rot = rotateXYZ(xradians, yradians, zradians, v1_x0)
        v1_x0_2d = convert2d(zoom,dist,v1_x0_rot)

        v1_x1 = [64, 64, 64]
        v1_x1_rot = rotateXYZ(xradians, yradians, zradians, v1_x1)
        v1_x1_2d = convert2d(zoom,dist,v1_x1_rot)

        v2 = [0, 64, -64]
        v2_rot = rotateXYZ(xradians, yradians, zradians, v2)
        v2_2d = convert2d(zoom,dist,v2_rot)

        v2_x0 = [-64, 64, -64]
        v2_x0_rot = rotateXYZ(xradians, yradians, zradians, v2_x0)
        v2_x0_2d = convert2d(zoom,dist,v2_x0_rot)

        v2_x1 = [64, 64, -64]
        v2_x1_rot = rotateXYZ(xradians, yradians, zradians, v2_x1)
        v2_x1_2d = convert2d(zoom,dist,v2_x1_rot)

        face1lines = v1_2d[1]-v0_2d[1]
        face2lines = v2_2d[1]-v1_2d[1]

        # check if face visible:
        if face1lines > 0 :
            print("Face 1: ",v0_2d, v1_2d)
            write_uint8(outfile, face1lines)
            write_uint8(outfile, v0_2d[1])
            dz = (v1_rot[2]-v0_rot[2])/128
            dy = (v1_rot[1]-v0_rot[1])/128
            currz = v0_rot[2]
            curry = v0_rot[1]
            prev2dy = v0_2d[1]-1
            said_first = 0
            for line in range(0,128):
                # This is a line!
                curr2d = convert2d(zoom,dist,[0,curry,currz])
                x0 = convert2d(zoom,dist, [-64,curry,currz])
                x1 = convert2d(zoom,dist, [64,curry,currz])
                if curr2d[1]!=prev2dy:
                    # This line is at a different scanline than previous. Show it.
                    print("Frame ", i," Face ", 1, " scanline ", curr2d[1], " width ", x1[0]-x0[0])
                    width = int(x1[0]-x0[0])
                    prev2dy = curr2d[1]
                    write_uint8(outfile,width)
                    write_uint8(outfile,line)
                currz=currz+dz
                curry=curry+dy

        if face2lines > 0 :
            print("Face 2:", v1_2d, v2_2d)
            write_uint8(outfile, face2lines)
            write_uint8(outfile, v1_2d[1])
            dz = (v2_rot[2]-v2_rot[2])/128
            dy = (v2_rot[1]-v2_rot[1])/128
            currz = v1_rot[2]
            curry = v1_rot[1]
            # prev2dy = v1_2d[1]-1
            said_first = 0
            for line in range(0,128):
                # This is a line!
                curr2d = convert2d(zoom,dist,[0,curry,currz])
                x0 = convert2d(zoom,dist, [-64,curry,currz])
                x1 = convert2d(zoom,dist, [64,curry,currz])
                if curr2d[1]>prev2dy:
                    # This line is at a different scanline than previous. Show it.
                    print("Frame ", i," Face ", 2, " scanline ", curr2d[1], " width ", x1[0]-x0[0])
                    width = int(x1[0]-x0[0])
                    prev2dy = curr2d[1]
                    write_uint8(outfile,width)
                    write_uint8(outfile,line)
                currz=currz+dz
                curry=curry+dy


    outfile.close()
