#!/usr/bin/env python
#
# mir.bench.py: see also http://bima.astro.umd.edu/memo/abstracts.html#81
#

import sys, os, time, string
version='2003-03-09'

# command line arguments that can be changed... (but should not in the benchmark)
keyval = {
    "nchan"   : "32",         # number of channels
    "mapsize" : "1024",       # size of the map (should be a power of 2)
    "cell"    : "0.5",        # cell size in arcsec
    "small"   : "0",          # set this to 0 if you want to small quick test run 
    }

# -------------------------------------------------------------------------------
#
#                                            parse command line (must be 'key=val')
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

# -------------------------------------------------------------------------------
#
# define all variables, now in their proper type, for this script
#
tmp='benchXXXXX'
vis=['vis1','vis2','vis3']
ant=['bima9_a.ant', 'bima9_b.ant', 'bima9_c.ant.equ']

small=string.atoi(keyval['small'])
if small:
    print 'Running a small test now....'
    nchan   = 2
    mapsize = 256
    cell    = 2.0
else:
    print 'Running a normal size test....'
    nchan   = string.atoi(keyval['nchan'])
    mapsize = string.atoi(keyval['mapsize'])
    cell    = string.atof(keyval['cell'])

timet=[0,0,0,0,0,0,0,0]           # arrays to store CPU usage
timec=[0,0,0,0,0,0,0,0]

print "MIRBENCH(py): %s : nchan=%d  mapsize=%d cell=%g" % (version, nchan, mapsize, cell)

mir = os.environ['MIR']

# ----------------------------------------------------------------------
# a few useful functions

#   execute a miriad 'command' (a list of strings) and accumulate a log 
def miriad(command):
    mycmd = cmd(command) + '>> bench.log 2>&1'
    return os.system(mycmd)


#   convert a list of strings to a command string
def cmd(cmdlist):
    str = cmdlist[0] 
    for arg in cmdlist[1:]:
        str = str + ' ' + arg
    print str
    return str

#   save CPU info in predefined global slots
def timer(slot):
    global timet, timec
    timet[slot] = time.time()
    timec[slot] = time.clock()

#   create a string to print human readable CPU info between slots 
def cpulen(a,b):
    st = '%.3f ' % (timet[b]-timet[a])
    sc = '%.3f ' % (timec[b]-timec[a])
    return sc + st
       
# ----------------------------------------------------------------------
# a few MIRIAD commands wrapped for this benchmark

def uvgen(id):
    cmd = [
        'uvgen',
        'out=%s' % vis[id],
        'corr=%d,1,100.0,1000.0' % nchan,
        'ant=$MIRCAT/%s' % ant[id],
        'source=$MIRCAT/point.source',
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

# ----------------------------------------------------------------------------
# start of the benchmark

if os.path.isdir(tmp):
    os.system('rm -rf ' + tmp)

os.mkdir(tmp)
os.chdir(tmp)

timer(0); miriad(uvgen(0))
timer(1); miriad(uvgen(1))
timer(2); miriad(uvgen(2))
timer(3); miriad(uvcat(vis))
timer(4); miriad(invert(mapsize,cell))
timer(5); miriad(clean())
timer(6); miriad(restor())
timer(7)

print 'Task:     CPU  WALL'
print 'uvgen1: ' +  cpulen(0,1)
print 'uvgen2: ' +  cpulen(1,2)
print 'uvgen3: ' +  cpulen(2,3)
print 'uvcat:  ' +  cpulen(3,4)
print 'invert: ' +  cpulen(4,5)
print 'clean:  ' +  cpulen(5,6)
print 'restor: ' +  cpulen(6,7)
print 'TOTAL:  ' +  cpulen(0,7)
print 'MirStones %f  ' % (300/(timet[7]-timet[0])) + ' Wall clock  (CPU clock has bug)'
print 'MirStones %f  ' % (300/(timec[7]-timec[0])) + ' CPU clock'      # also has a bug



