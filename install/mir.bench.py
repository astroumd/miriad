#!/usr/bin/env python
#
# mir.bench.py: see also http://bima.astro.umd.edu/memo/abstracts.html#81
#
# 10-mar-2003:  PJT    derived from the mir.bench and mir.bigbench scripts
# 15-mar-2003:  PJT    now using Miriad.py 
#

import sys, os, time, string, tempfile
from Miriad import *

version='2003-03-15'

# command line arguments that can be changed...
keyval = {
    "nchan"   : "32",       # number of channels
    "mapsize" : "1024",     # size of the map (should be a power of 2)
    "cell"    : "0.5",      # cell size in arcsec
    "dt"      : "0.01",     # integration step (in hrs, assuming harange -6..6)
    "small"   : "0",        # set this to 1 if you want to small quick test run 
    "big"     : "0",        # set this to 1 if you want the 2GB+ test run
    }

# -----------------------------------------------------------------------------
#
#                                       parse command line (must be 'key=val')
for arg in sys.argv[1:]:
    i=string.find(arg,"=")
    if i > 0:
        key = arg[0:i]
        val = arg[i+1:]
        print arg,i,key
        if keyval.has_key(key):
            keyval[key] = val

#                                            report current defaults
print "Current command line defaults are:"
for k in keyval.keys():
    print k + '=' + keyval[k]
setlogger('pjt.log')
# -----------------------------------------------------------------------------
#
# define all variables, now in their proper type, for this script
#
vis=['vis1','vis2','vis3']
ant=['bima9_a.ant', 'bima9_b.ant', 'bima9_c.ant.equ']

small=string.atoi(keyval['small'])
big=string.atoi(keyval['big'])
if small:
    print 'Running a small test now....'
    nchan   = 2
    mapsize = 256
    cell    = 2.0
    dt      = 0.1
elif big:
    print 'Running a 2.5GB test....'
    nchan   = 1024
    mapsize = 256
    cell    = 2.0
    dt      = 0.007
    ant     = ['vla_a.ant']
    vis     = ['vis1']
else:
    print 'Running a normal size test....'
    nchan   = string.atoi(keyval['nchan'])
    mapsize = string.atoi(keyval['mapsize'])
    cell    = string.atof(keyval['cell'])
    dt      = string.atof(keyval['dt'])

t=Timer()

# -----------------------------------------------------------------------------
# a few MIRIAD commands wrapped for this benchmark

def uvgen(id):
    cmd = [
        'uvgen',
        'out=%s' % vis[id],
        'corr=%d,1,100.0,1000.0' % nchan,
        'ant=$MIRCAT/%s' % ant[id],
        'source=$MIRCAT/point.source',
        'harange=-6,6,%g' % dt,
        'spectra=1.0,100.0,0.1',
        'gnoise=0.1',
        'pnoise=10,0,0,0',
        'systemp=75,290,0.15',
        'tpower=0,0',
        'jyperk=150'
        ]
    return cmd

def uvcat(infiles):
    vis=infiles[0]
    for v in infiles[1:]:
        vis = vis + ',' + v
    cmd = [
        'uvcat',
        'vis=%s' % vis,
        'out=vis'
        ]
    return cmd

def invert(mapsize,cell):
    cmd = [
     'invert',
     'vis=vis',
     'map=map1',
     'beam=beam1',
     'imsize=%d' % mapsize,
     'cell=%g' % cell
     ]
    return cmd

def clean():
    cmd = [
        'clean',
        'map=map1',
        'beam=beam1',
        'out=clean1'
        ]
    return cmd

def restor():
    cmd = [
        'restor',
        'model=clean1',
        'map=map1',
        'beam=beam1',
        'out=cmap1'
        ]
    return cmd

# -----------------------------------------------------------------------------
# start of the benchmark

#   work in a temporary directory
tmp = 'bench' + tempfile.gettempprefix()
os.mkdir(tmp)
os.chdir(tmp)
print "Working in directory " + tmp

if big:
    print "MIRBIGBENCH(py): %s : nchan=%d dt=%g" % (version,nchan,dt)
    miriad(uvgen(0));
else:
    print "MIRBENCH(py): %s : nchan=%d mapsize=%d" % (version,nchan,mapsize)
    
    t.tag()
    miriad(uvgen(0))
    miriad(uvgen(1))
    miriad(uvgen(2))
    miriad(uvcat(vis))
    miriad(invert(mapsize,cell))
    miriad(clean())
    miriad(restor())
    t.tag(); 

    print 'MirStones %f  ' % (300/(t.dt(0,1))) + ' Wall clock'

print 'All done.'


