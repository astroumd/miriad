#!/usr/bin/env python
#
# mfs.py      
#
# 12-mar-2003:  PJT    derived from mfs.csh as a python excersize at 35,000ft
#
#

import sys, os, time, string, math

version='2003-03-12'
usage='echo "Performance tests for mfs imaging'

# command line arguments that can be changed...
keyval = {
    "config"  : "config1",           # antenna config file (without the .ant extension)
    "dec"     : "30",                # declination (can be a real number)
    "nchan"   : "2",                 # number of channels
    "mfs"     : "0",                 # 1=with mfs  0=multichannel
    "VERSION" : "1.0 PJT"            # VERSION id for the user interface
    }

# -----------------------------------------------------------------------------
# MIRIAD
#                                       parse command line (must be 'key=val')
quit = 0
for arg in sys.argv[1:]:
    i=string.find(arg,"=")
    if i > 0:
        key = arg[0:i]
        val = arg[i+1:]
        print arg,i,key
        if keyval.has_key(key):
            keyval[key] = val
    elif arg == '--help':
        quit = 1

# MIRIAD
#                                            report current defaults
print "Current command line defaults are:"
for k in keyval.keys():
    print k + '=' + keyval[k]

if quit:
    os._exit(0)
#    sys.exit(0)

# -----------------------------------------------------------------------------
#
# define all variables, now in their proper type, for this script
#

log = 'mfs.log'
logger = '>> %s 2>&1' % log                        # blank this is you want logging to the screen
#logger = ''

config  = keyval['config'] + '.ant'
dec     = string.atof(keyval['dec'])
nchan   = string.atoi(keyval['nchan'])
mfs     = string.atoi(keyval['mfs'])

#harange = '-1,1,0.0057'
harange = '-1,1,0.1'
select  = '-shadow\(12\)'
freq    = 230.0
imsize  = 0

timet=[]
timec=[]

mir = os.environ['MIR']

# -----------------------------------------------------------------------------
# a few useful functions

# MIRIAD
#   remove a possibly existing miriad dataset (no wildcards)
def zap(file):
    if os.path.isdir(file):
        os.system('rm -rf ' + file)
#   remove all datasets (wildcards now allowed)
def zap_all(files):
    os.system('rm -rf ' + files)

# MIRIAD
#   execute a miriad 'command' (a list of strings) and accumulate a log 
def miriad(command,log=0):
    if (log != 0):
        mycmd = cmd(command) + '> %s.log 2>&1' % command[0]
    else:
        mycmd = cmd(command) + logger;
    return os.system(mycmd)

# MIRIAD
#   convert a list of strings to a command string
def cmd(cmdlist):
    str = cmdlist[0] 
    for arg in cmdlist[1:]:
        str = str + ' ' +  arg
    print str
    return str

# MIRIAD
#   save CPU info in predefined global slots
def timer(slot):
    global timet, timec
    timec[slot] = time.clock()
    timet[slot] = time.time()

# MIRIAD
#   create a string to print human readable CPU info between slots 
def cpulen(a,b):
    st = '%.3f ' % (timet[b]-timet[a])
    sc = '%.3f ' % (timec[b]-timec[a])
    return sc + st
       
# -----------------------------------------------------------------------------
# a few MIRIAD commands wrapped up for this script


def uvgen(config,dec,harange,freq,nchan,out):
    cmd = [
        'uvgen',
        'ant=%s' % config,
        'baseunit=-3.33564',
        'radec=23:23:25.803,%g' % dec,
        'lat=-23.02',
        'harange=%s' % harange,
        'source=$MIRCAT/point.source',
        'telescop=alma',
        'systemp=40',
        #        'pnoise=30',
        'jyperk=40',
        'freq=%g' % freq,
        'corr=%d,1,1,8000' % nchan,
        'out=%s' % out,
        ]
    zap(out)
    return cmd


def implot(map):
    cmd = [
        'implot',
        'in=' + map,
        'device=/xs',
        'units=s',
        'conflag=l',
        'conargs=1.4',
        'region=quarter'
        ]
    return cmd

def invert(vis,map,beam,imsize,select,mfs):
    cmd = [
     'invert',
     'vis=%s' % vis,
     'map=%s' % map,
     'beam=%s' % beam,
     'imsize=%d' % imsize,
     'sup=0',
     'select=%s' % select
     ]
    if (mfs):
        cmd.append('options=mfs')
    zap(map)
    zap(beam)
    return cmd



def clean(map,beam,out):
    cmd = [
        'clean',
        'map=%s' % map,
        'beam=%s' % beam,
        'out=%s' % out
        ]
    zap(out)
    return cmd

def clean(map,beam,out):
    cmd = [
        'clean',
        'map=%s' % map,
        'beam=%s' % beam,
        'out=%s' % out
        ]
    zap(out)
    return cmd


def restor(map,beam,model,out):
    cmd = [
        'restor',
        'model=%s' %  model,
        'map=%s' % map,
        'beam=%s' % beam, 
        'out=%s' % out
        ]
    zap(out)
    return cmd


def imfit(map,out):
    cmd = [
        'imfit',
        'in=%s' % map,
        'object=gauss',
        'region=relpix,box\(-25,-25,25,25\)',
        'out=%s' % out,
        'options=residual'
        ]
    zap(out)
    return cmd

def histo(map):
    cmd = [
        'histo',
        'in=%s' % map
        ]
    return cmd

# -----------------------------------------------------------------------

#   get the (as a string) value of an item in a dataset
def itemize1(data,item):
    log = 'tmp.log'
    cmd = [
        'itemize',
        'in=%s/%s' % (data, item),
        'log=%s' % log
        ]
    miriad(cmd)
    f = open(log,"r")
    v = string.split(f.readline())
    f.close()
    return v[2]
# MIRIAD
#   run a command, grep through the output for a word and return a 0-indexed word
#   should use popen()
def grepcmd(cmd,word,index=0):
    log = 'tmp.log'
    os.system(cmd + ' > %s' % log)
    f = open(log,"r")
    v = f.read()
    va=string.split(v,"\n")
    f.close()
    for s in va:
        if string.find(s,word)>=0:
            sa=string.split(s)
            # print 'Match ' + word + '=>' + sa[index]
            return sa[index]
    print 'No match on' + word
    return "no-match"

# MIRIAD
#   grep through a logfile for a word and return a 0-indexed word
def greplog(log,word,index=0):
    f = open(log,"r")
    v = f.read()
    va=string.split(v,"\n")
    f.close()
    for s in va:
        if string.find(s,word)>=0:
            sa=string.split(s)
            # print 'Match ' + word + '=>' + sa[index]
            return sa[index]
    print 'No match on' + word
    return "no-match"


# -----------------------------------------------------------------------------
# start of the script

# should consider making this a function, so perhaps we should do 
# if __name__ == '__main__':
#    <true body>
# and have no true global variables!!!
#
print "   ---  ALMA Single Field MFS Imaging    ---   " 
print " config  = %s" % config
print " dec     =  %g" % dec
print " harange =  %s  hours" % harange
print " select  =  %s" % select
print " freq    =  %g" % freq
print " nchan   = %d" % nchan
print " imsize  = %d" % imsize
print " " 
print "   ---  TIMING   ---   "        
print "  START: `date`"


#  some more variables

out = keyval['config'] + '.' + keyval['dec']
uv = out + '.uv'
mp = out + '.mp'
bm = out + '.bm'
cl = out + '.cl'
cm = out + '.cm'
res = 'residual'

#   run the script

miriad(uvgen(config,dec,harange,freq,nchan,uv))
miriad(invert(uv,mp,bm,imsize,select,mfs), log='invert.log')
miriad(implot(bm))
miriad(clean(mp,bm,cl))
miriad(restor(mp,bm,cl,cm))
miriad(imfit(bm,res))
miriad(histo(res))

#   extract information, the hard way
rms    = string.atof(itemize1(mp,'rms')) * 1e6
bmaj   = string.atof(grepcmd('prthd in=%s' % cm, 'Beam', 2))
bmin   = string.atof(grepcmd('prthd in=%s' % cm, 'Beam', 4))
srms   = string.atof(grepcmd('histo in=%s' % res, 'Rms', 3)) * 100
smax   = string.atof(grepcmd('histo in=%s' % res, 'Maximum', 2)) * 100
smin   = string.atof(grepcmd('histo in=%s' % res, 'Minimum', 2)) * 100
nvis   = string.atoi(greplog('invert.log','Visibilities',2))
records= string.atoi(greplog(uv+'/history','records',1))


pi     = math.pi
log2   = math.log(2)
tbrms  = rms*0.3/freq*0.3/freq/2/1.38e3/(pi/(4*log2)*bmaj*bmin/4.25e10)

#   python does a bad job on this, it does integer division!!
if (mfs):
    Nvis   = 100*nvis/records/nchan
else:
    Nvis   = 100*nvis/records


print "   ---  RESULTS   ---   " 
os.system('grep records %s/history' % uv)
os.system('grep phases  %s/history' % uv)


print " Config  DEC  Nchan HA[hrs]  Rms[\muJy]  Beam[arcsec] Tb_rms[\muK] Sidelobe[%]:Rms,Max,Min Nvis[%]"
print " %s %g %d %s %.1f %.2f %.2f %0.f %.1f %.1f %.1f %d" % (config,
                                                              dec,nchan,harange,rms,bmaj,bmin,tbrms,srms,smax,smin,nvis)
print " %s %g %d %s %.1f %.2f %.2f %.0f %.1f %.1f %.1f %d" % (config,
                                                              dec,nchan,harange,rms,bmaj,bmin,tbrms,srms,smax,smin,Nvis)



print freq
print Nvis
print tbrms


print "%g*0.3/%g*0.3/%g/2/1.38e3/(%g/(4*%g)*%g*%g/4.25e10)" % (rms,freq,freq,pi,log2,bmaj,bmin)

