#!/usr/bin/python
# Precalc cube rotations over 512 frames.

# Saves number of vertices, coordinates in 3d per frame,

import numpy as np
import math
import os
import vg
from PIL import Image,ImagePalette,ImageDraw

vertices = [[-100,100,100],
    [100,100,100],
    [100,-100,100],
    [-100,-100,100],
    [-100,100,-100],
    [100,100,-100],
    [100,-100,-100],
    [-100,-100,-100]]


faces = [[4, 1, 0, 1, 2, 3, 0],
    [4, 1, 4, 7, 6, 5, 4],
    [4, 2, 4, 0, 3, 7, 4],
    [4, 2, 5, 6, 2, 1, 5],
    [4, 3, 5, 1, 0, 4, 5],
    [4, 3, 6, 7, 3, 2, 6]]

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

def write_sint16(f,x):
    f.write(x.to_bytes(2, byteorder="big",signed=True))

x_center = 64           # for 64*64 canvas
y_center = 64
zoom = 350
dist = 2000
min_x = x_center*2
min_y = y_center*2
max_x = 0
max_y = 0
crop_rectangle = (32,32,96,96)

the_colors = [(0,0,0), (255,255,255),
    (255,0,0),
    (0,255,0),
    (0,0,255),
    (255,0,255),
    (255,255,0),
    (0,255,255)]

numframes = 128
background_col = 1

intmin = 1
intmax = -1
maxcol=0
mincol=9



### Main function
if __name__ == '__main__':

    anim = Image.new(mode="RGB", size=(x_center,y_center*numframes))
    for i in range(0,numframes):

        # define it
        frame = Image.new("RGB", (128,128), color =the_colors[background_col])
        frame = frame.convert("RGB", palette = the_colors, colors = 8)
        draw = ImageDraw.Draw(frame)

        xradians = (i/numframes)*(2*math.pi)/1
        yradians = -(i/numframes)*(2*math.pi)/1
        zradians = (i/numframes)*(2*math.pi)/1
        rotated_vertices = []
        for vertex in vertices:
            new_vertex = rotateXYZ(xradians, yradians, zradians, vertex)
            rotated_vertices.append(new_vertex)

        # 700/(z+dist) = 700/(-100+1200) = 700/1100 = 2/3
        # 144*
        transformed_vertices = []
        for vertex in vertices:
            new_vertex = rotateXYZ(xradians, yradians, zradians, vertex)
            dz = zoom/(new_vertex[2]+dist)
            vertex_x = int(new_vertex[0]*dz + x_center)
            vertex_y = int(new_vertex[1]*dz + y_center)
            if vertex_x<0 or vertex_y<0:
                print("ERROR! Negative screen values!")
                print("Frame ",i, ": X/Y:", vertex_x, vertex_y)
                exit(1)
            transformed_vertices.append([vertex_x, vertex_y])
            if vertex_x<min_x: min_x = vertex_x
            if vertex_y<min_y: min_y = vertex_y

            if vertex_x>max_x: max_x = vertex_x
            if vertex_y>max_y: max_y = vertex_y

        # Calculate normal vector for faces
        for face in faces:
            v1 = np.array(rotated_vertices[face[4]])-np.array(rotated_vertices[face[3]])  # første linje i planet
            v2 = np.array(rotated_vertices[face[5]])-np.array(rotated_vertices[face[4]])  # andre linje i planet
            # print("New face:")
            # for v in face[3:7]:
            #     print(rotated_vertices[v])

            #print(v1,v2)
            vecprod = np.cross(v1,v2)
            #print(vecprod)
            fnormal = vg.normalize(vecprod)
            #print(fnormal)
            fcosine = 128*np.dot(fnormal,np.array([0,0,1]))                     # Finn skalaprod med lysvektoren (rett frem)
            # print(fcosine)
            v1 = np.array(transformed_vertices[face[4]])-np.array(transformed_vertices[face[3]])  # første linje i planet
            v2 = np.array(transformed_vertices[face[5]])-np.array(transformed_vertices[face[4]])  # andre linje i planet
            # print("New face:")
            # for v in face[3:7]:
            #     print(rotated_vertices[v])

            #print(v1,v2)
            vecprod2d = np.cross(v1/50,v2/50)*128
            # print(vecprod2d)
            #fcosine2d = 128*np.dot(fnormal2d,np.array([0,0,1]))   # skalaprod med lysvektoren (rett frem)
            #print(fcosine2d)
            #write_sint16(outfile, int(round(fnormal[1])))
            #write_sint16(outfile, int(round(fnormal[2])))
            #write_sint16(outfile, int(round(fcosine,0)))
            if vecprod2d>0:
                vs = face[2:len(face)-1]
                thepoly = []
                for k in range(0,len(vs)):
                    thepoly.append(transformed_vertices[vs[k]])
                thepoly = [tuple(x) for x in thepoly]
                #print(fcosine)
                # intensity = (fcosine/128)
                # if intensity<intmin: intmin=intensity
                # if intensity>intmax: intmax=intensity
                # thecol = int(intensity*5)+2
                # if thecol>maxcol: maxcol=thecol
                # if thecol<mincol: mincol=thecol
                #print(i, " ", intmin, " ", intensity, "  ", thecol)
                facecol = face[1]+2
                # draw.polygon(thepoly, fill=2the_colors[facecol], outline=3) the_colors[facecol])
                draw.polygon(thepoly, fill=the_colors[2],outline=the_colors[1])
        cutout = frame.crop(crop_rectangle)
        cpy = anim.copy()
        cpy.paste(cutout,(0,i*y_center))
        anim = cpy.copy()

    ready = anim.convert(mode="P", colors=3)
    ready.getcolors()
    ready.save("./data/cubeframes.png")


print("PRECALC OVER:")
print("Minimum screen X:", min_x-32)
print("Minimum screen Y:", min_y-32)
print("Maximum screen X:", max_x-32)
print("Maximum screen Y:", max_y-32)
print("Minimum col id:", mincol)
print("Maximum col id:", maxcol)
print("Minimum intensity id:", intmin)
print("Maximum intensity id:", intmax)
