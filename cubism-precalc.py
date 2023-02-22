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

vertices = [[-64,64,64],
            [64,64,64],
            [64,-64,64],
            [-64,-64,64],
            [-64,64,-64],
            [64,64,-64],
            [64,-64,-64],
            [-64,-64,-64]]

unitvectors = [[16,0,0],[0,16,0],[0,0,16]]

faces = [[4, 1, 0, 1, 2, 3, 0],
         [4, 1, 4, 7, 6, 5, 4],
         [4, 2, 4, 0, 3, 7, 4],
         [4, 2, 5, 6, 2, 1, 5],
         [4, 3, 5, 1, 0, 4, 5],
         [4, 3, 6, 7, 3, 2, 6]]

x_center = 96           # for 192*192 screens
y_center = 96
zoom = 310
dist = 380
min_x = x_center*2
min_y = y_center*2
max_x = 0
max_y = 0
numframes = 512
xrot = 3
yrot = -1
zrot = 2

### Main function
if __name__ == '__main__':

    all_normals = []
    all_frontsides = []
    all_backsides = []
    all_unitvectors = []

    for i in range(0,numframes):
        xradians = xrot*(i/numframes)*(2*math.pi)
        yradians = yrot*(i/numframes)*(2*math.pi)
        zradians = zrot*(i/numframes)*(2*math.pi)

        rotated_unitvectors = []
        for unitvec in unitvectors:
            new_vec = rotateXYZ(xradians,yradians,zradians, unitvec)
            rotated_unitvectors.append(new_vec)
        all_unitvectors.append(rotated_unitvectors)

        rotated_vertices = []
        for vertex in vertices:
            new_vertex = rotateXYZ(xradians, yradians, zradians, vertex)
            rotated_vertices.append(new_vertex)

        transformed_vertices = []
        for vertex in vertices:
            new_vertex = rotateXYZ(xradians, yradians, zradians, vertex)
            dz = zoom/(new_vertex[2]+dist)
            vertex_x = new_vertex[0]*dz + x_center
            vertex_y = new_vertex[1]*dz + y_center
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
        thenormals = [0,0,0,0]
        frontlines = []
        backlines = []
        for face in faces:
            v1 = np.array(rotated_vertices[face[4]])-np.array(rotated_vertices[face[3]])  # første linje i planet
            v2 = np.array(rotated_vertices[face[5]])-np.array(rotated_vertices[face[4]])  # andre linje i planet
            vecprod = np.cross(v1,v2)
            fnormal = vg.normalize(vecprod)
            fcosine = 127*np.dot(fnormal,np.array([0,0,1]))                     # Finn skalaprod med lysvektoren (rett frem)

            v1 = np.array(transformed_vertices[face[4]])-np.array(transformed_vertices[face[3]])  # første linje i planet
            v2 = np.array(transformed_vertices[face[5]])-np.array(transformed_vertices[face[4]])  # andre linje i planet
            vecprod2d = np.cross(v1/50,v2/50)*128

            if vecprod2d>0:
                thenormals[face[1]] = int(round(fcosine,0))
                # plot the coords for the four lines
                for i in range(0,4):
                    v1 = face[i+2]
                    v2 = face[i+1+2]
                    vstart = transformed_vertices[v1]
                    vstop = transformed_vertices[v2]
                    if vstart[1]>vstop[1]:
                        tmpv = vstart
                        vstart = vstop
                        vstop = tmpv
                    frontlines.append([face[1],vstart,vstop])

            if vecprod2d<0:
                # plot the coords for the four lines
                for i in range(0,4):
                    v1 = face[i+2]
                    v2 = face[i+1+2]
                    vstart = transformed_vertices[v1]
                    vstop = transformed_vertices[v2]
                    if vstart[1]>vstop[1]:
                        tmpv = vstart
                        vstart = vstop
                        vstop = tmpv
                    backlines.append([face[1],vstart,vstop])

        all_normals.append(thenormals)
        all_frontsides.append(frontlines)  # Save the visible lines
        all_backsides.append(backlines)     # Save the invisible lines

print("Minimum screen X:", min_x)
print("Minimum screen Y:", min_y)
print("Maximum screen X:", max_x)
print("Maximum screen Y:", max_y)

###
### Output stuff to files
###

# ### Remove unneeded lines
# xored_frontlines = {}
#
# thisfront = {}
# for aline in all_frontsides[69]:
#     col = aline[0]
#     xy1 = aline[1]
#     xy2 = aline[2]
#     key = tuple(xy1+xy2) #list(xy1).append(xy2)
#     thisfront[key] = thisfront[key] | col
# {tuple([50,50,50,50]) : 1}
#

### Linelist for complete cube (4 bitplanes)
numlines = 0
cubecoords2d  = open("./data/precalc-coords2d.dat", "wb")
cubeoffsets2d  = open("./data/precalc-coords2d-offsets.dat", "wb")
cubeoffset = int(0)
# Make combined linelist
for i in range(0,numframes):
    write_uint16(cubeoffsets2d, int(cubeoffset))

    if len(all_frontsides[i])>0:
        for line in all_frontsides[i]:
            vstart = line[1]
            vstop = line[2]
            write_uint8(cubecoords2d,line[0])
            write_uint8(cubecoords2d, int(round(vstart[0])))
            write_uint8(cubecoords2d, int(round(vstart[1])))
            write_uint8(cubecoords2d, int(round(vstop[0])))
            write_uint8(cubecoords2d, int(round(vstop[1])))
            cubeoffset= cubeoffset+5
    if len(all_backsides[i])>0:
        for line in all_backsides[i]:
            vstart = line[1]
            vstop = line[2]
            write_uint8(cubecoords2d,line[0]*4)
            write_uint8(cubecoords2d, int(round(vstart[0])))
            write_uint8(cubecoords2d, int(round(vstart[1])))
            write_uint8(cubecoords2d, int(round(vstop[0])))
            write_uint8(cubecoords2d, int(round(vstop[1])))
            cubeoffset= cubeoffset+5

    write_uint8(cubecoords2d,0)
    cubeoffset = cubeoffset+1

cubecoords2d.close()
cubeoffsets2d.close()



### Linelist for front sides
frontcoords2d = open("./data/precalc-frontcoords2d.dat", "wb")
fc2doffsets = open("./data/precalc-frontcoords2d-offsets.dat", "wb")
frontcoordsoffset = 0
for front in all_frontsides:
    write_uint16(fc2doffsets, int(frontcoordsoffset))

    if len(front)>0:
        for line in front:
            vstart = line[1]
            vstop = line[2]
            write_uint8(frontcoords2d,line[0])
            write_uint8(frontcoords2d, int(round(vstart[0])))
            write_uint8(frontcoords2d, int(round(vstart[1])))
            write_uint8(frontcoords2d, int(round(vstop[0])))
            write_uint8(frontcoords2d, int(round(vstop[1])))
            frontcoordsoffset= frontcoordsoffset+5

    write_uint8(frontcoords2d,0)
    frontcoordsoffset= frontcoordsoffset+1

frontcoords2d.close()
fc2doffsets.close()

### Linelist for backside
backcoords2d = open("./data/precalc-backcoords2d.dat", "wb")
bc2doffsets = open("./data/precalc-backcoords2d-offsets.dat", "wb")
backcoordsoffset = 0
for back in all_backsides:
    write_uint16(bc2doffsets, int(frontcoordsoffset))

    if len(back)>0:
        for line in back:
            vstart = line[1]
            vstop = line[2]
            write_uint8(backcoords2d,line[0])
            write_uint8(backcoords2d, int(round(vstart[0])))
            write_uint8(backcoords2d, int(round(vstart[1])))
            write_uint8(backcoords2d, int(round(vstop[0])))
            write_uint8(backcoords2d, int(round(vstop[1])))
            backcoordsoffset= backcoordsoffset+5

    write_uint8(backcoords2d,0)
    backcoordsoffset= backcoordsoffset+1

backcoords2d.close()
bc2doffsets.close()

# Defining region codes
INSIDE = 0  # 0000
LEFT = 1    # 0001
RIGHT = 2   # 0010
BOTTOM = 4  # 0100
TOP = 8     # 1000

def computeCode(x, y, y_min, y_max):
    code = INSIDE
    if y < y_min:      # below the rectangle
        code |= BOTTOM
    elif y > y_max:    # above the rectangle
        code |= TOP
    return code

def clipIt(line, y_min, y_max):
    v1 = line[1]
    v2 = line[2]

    x1 = v1[0]
    y1 = v1[1]
    x2 = v2[0]
    y2 = v2[1]

    code1 = computeCode(x1, y1, y_min, y_max)
    code2 = computeCode(x2, y2, y_min, y_max)
    accept = False

    while True:
        # If both endpoints lie within rectangle
        if code1 == 0 and code2 == 0:
            accept = True
            break

        # If both endpoints are outside rectangle
        elif (code1 & code2) != 0:
            break

        # Some segment lies within the rectangle
        else:
            # Line Needs clipping. At least one of the points is outside,
            # select it
            x = 1.0
            y = 1.0
            if code1 != 0:
                code_out = code1
            else:
                code_out = code2

            # Find intersection point
            # using formulas y = y1 + slope * (x - x1),
            # x = x1 + (1 / slope) * (y - y1)
            if code_out & TOP:
                # point is above the clip rectangle
                x = x1 + ((x2 - x1) / (y2 - y1)) * (y_max - y1)
                y = y_max

            elif code_out & BOTTOM:
                # point is below the clip rectangle
                x = x1 + ((x2 - x1) / (y2 - y1)) * (y_min - y1)
                y = y_min

            # Now intersection point x, y is found
            # We replace point outside clipping rectangle
            # by intersection point
            if code_out == code1:
                x1 = x
                y1 = y
                code1 = computeCode(x1, y1, y_min, y_max)

            else:
                x2 = x
                y2 = y
                code2 = computeCode(x2, y2, y_min, y_max)

    if accept:
        #print ("Line accepted from %.2f, %.2f to %.2f, %.2f" % (x1, y1, x2, y2))
        theline = [line[0],[x1,y1],[x2,y2]]
        return(theline)
    else:
        #print("Line rejected")
        return([0])

### Clipped backsides, 1

for segment in range(0,6):
    coordsfile = "./data/precalc-clippedback" + str(segment) + ".dat"
    clippedcoords = open(coordsfile, "wb")
    offsetsfile = "./data/precalc-clippedback" + str(segment) + "-offsets.dat"
    clippedoffsets = open(offsetsfile, "wb")
    clippedcoordsoffset = 0
    clip_ymin = 0+segment*32
    clip_ymax = clip_ymin+31
    for back in all_backsides:
        write_uint16(clippedoffsets, clippedcoordsoffset)
        if len(back)>0:
            for line in back:
                vstart = line[1]
                vstop = line[2]
                clippedLine = clipIt(line,clip_ymin,clip_ymax)
                if clippedLine[0]!=0:
                    vstart = clippedLine[1]
                    vstop = clippedLine[2]
                    write_uint8(clippedcoords,line[0])
                    write_uint8(clippedcoords, int(round(vstart[0])))
                    write_uint8(clippedcoords, int(round(vstart[1])))
                    write_uint8(clippedcoords, int(round(vstop[0])))
                    write_uint8(clippedcoords, int(round(vstop[1])))
                    clippedcoordsoffset= clippedcoordsoffset+5

        write_uint8(clippedcoords,0)
        clippedcoordsoffset = clippedcoordsoffset+1

    clippedcoords.close()
    clippedoffsets.close()


### Normal vectors
normals = open("./data/precalc-normals.dat", "wb")
for thenormals in all_normals:
    write_uint16(normals, thenormals[0])
    write_uint16(normals, thenormals[1])
    write_uint16(normals, thenormals[2])
    write_uint16(normals, thenormals[3])

normals.close()
