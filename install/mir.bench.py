#!/usr/bin/env python
#
# mir.bench.py: see also http://bima.astro.umd.edu/memo/abstracts.html#81
#
# 10-mar-2003:  PJT    derived from the mir.bench and mir.bigbench scripts
#
#

import sys, os, time, string, tempfile
version='2003-03-10'

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

# -----------------------------------------------------------------------------
#
# define all variables, now in their proper type, for this script
#
tmp='benchXXXXX'
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

timet=[0,0,0,0,0,0,0,0]           # arrays to store CPU usage
timec=[0,0,0,0,0,0,0,0]

mir = os.environ['MIR']

# -----------------------------------------------------------------------------
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
    timec[slot] = time.clock()
    timet[slot] = time.time()

#   create a string to print human readable CPU info between slots 
def cpulen(a,b):
    st = '%.3f ' % (timet[b]-timet[a])
    sc = '%.3f ' % (timec[b]-timec[a])
    return sc + st
       
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
    timer(0); miriad(uvgen(0));
    timer(1)
    print 'uvgen-big: ' + cpulen(0,1)
else:
    print "MIRBENCH(py): %s : nchan=%d mapsize=%d" % (version,nchan,mapsize)
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
    if timet[7] != timet[0]:
        print 'MirStones %f  ' % (300/(timet[7]-timet[0])) + ' Wall clock  (CPU clock has bug?)'
    if timec[7] != timec[0]:
        print 'MirStones %f  ' % (300/(timec[7]-timec[0])) + ' CPU clock'   

print 'All done.'


