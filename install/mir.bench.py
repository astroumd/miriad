#!/usr/bin/env python
#
#

import sys, os, time

version='2003-03-07'

# -------------------------------------------------------------------------------

tmp='benchXXXXX'
nchan=32
mapsize=1024
cell=0.5
small=1
vis=['vis1','vis2','vis3']
ant=['bima9_a.ant', 'bima9_b.ant', 'bima9_c.ant.equ']

if small:
    print 'Running a small test now....'
    nchan=2
    mapsize=256
    cell=2


timet=[0,0,0,0,0,0,0,0]
timec=[0,0,0,0,0,0,0,0]

#print "MIRBENCH: %(version)s: nchan=%(nchan)d  mapsize=%(mapsize)d"
print "MIRBENCH: %s: nchan=%d  mapsize=%d" % (version, nchan, mapsize)

mir = os.environ['MIR']

# ----------------------------------------------------------------------

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

def uvcat():
    cmd = [
        'uvcat',
        'vis=vis1,vis2,vis3',
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

print mir

if os.path.isdir(tmp):
    cmd = ' rm -rf %s ' % tmp
    print cmd
    #    os.system('rm -rf benchXXXXX')

os.mkdir(tmp)
os.chdir(tmp)

timer(0); miriad(uvgen(0))
timer(1); miriad(uvgen(1))
timer(2); miriad(uvgen(2))
timer(3); miriad(uvcat())
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
print 'MirStones %f  ' % (300/(timet[7]-timet[0])) + ' Wall clock '
print 'MirStones %f  ' % (300/(timec[7]-timec[0])) + ' CPU clock'



