#! /bin/env python
#
#
#   Script to convert carma XYZ positions (in ns) to ENU (in m)
#
#   24-jun-2009      written,    Peter Teuben
#

import math,sys

def read_antpos(file):
    fp = open(file)
    lines = fp.readlines()
    fp.close()
    xyz=[]
    for line in lines:
        if line[0] == '#': continue
        w = line.split()
        x = float(w[0])
        y = float(w[1])
        z = float(w[2])
        xyz.append( (x,y,z) )
    return xyz

def xyz2enu(xyz,lat):
    sinl=math.sin(lat*math.pi/180.0)
    cosl=math.cos(lat*math.pi/180.0)
    enu=[]
    ns2m = 0.299792458
    for p in xyz:
        e = ( p[1]                 ) * ns2m
        n = (-p[0]*sinl + p[2]*cosl) * ns2m
        u = ( p[0]*cosl + p[2]*sinl) * ns2m
        enu.append( (e,n,u) )
    return enu

def range_enu(enu):
    bl = 0
    dmin =  999999
    dmax = -999999
    for i in range(0,len(enu)):
        e1 = enu[i][0]
        n1 = enu[i][1]
        for j in range(i+1,len(enu)):
            bl = bl + 1
            de = enu[j][0] - e1
            dn = enu[j][1] - n1
            d = math.sqrt(de*de+dn*dn)
            if d<dmin: dmin=d
            if d>dmax: dmax=d
    print "Min and Max baseline: ",dmin,dmax

def print3(label,xyz):
    for p in xyz:
        print "%s   %10.3f %10.3f %10.3f" % (label,p[0],p[1],p[2])

        
if __name__ == '__main__':
    if len(sys.argv) > 1:
        file = sys.argv[1]
        lat = 37.2804
        if len(sys.argv) > 2: lat = float(sys.argv[2])
        xyz = read_antpos(file)
        print "Found %d ants in %s, lat=%f" % (len(xyz),file,lat)
        print3('xyz (ns)',xyz)
        enu = xyz2enu(xyz,lat)
        print3('enu (m) ',enu)
        range_enu(enu)
        
    else:
        print 'Need antpos filename, optionally followed by latitude of observatory'
        print 'Default is for carma at latitude 37.2804'
