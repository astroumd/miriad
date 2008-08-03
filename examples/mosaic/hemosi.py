#!/usr/bin/env python
#
# HEterogenousMOsaicingSImulation (HEMOSI) in Miriad
#
#  History:
#  25-jul-08  pjt   Merged ideas from hex7-15.csh, mosaic.py and hetero.py for carma+sza simulations
#   3-aug-08  pjt   added as hemosi.py to miriad's examples - but lots to clean up
#
#
#
# What you need:
#   0) Miriad and Miriad.py python frontend
#   1) a miriad image (e.g. casc.vla)
#   2) an antenna configuration file (e.g. CZ.ant)
#

import sys, os, time, string, math
from Miriad import *

version='200-08-03'

print "   ---  CARMA Heterogenous Mosaicing simulations  ---   "

# command line arguments that can be changed...
keyval = {
    "dir"       : "run1\n                                         Run directory in which all datasets written",
    "config"    : "CZ\n                                           antenna config file",
    "ants"      : "ovro,6,hatcreek,9,sza,8,carma,sza10,sza6\n     Antennae types, numbers, cross types names",
    "jyperk"    : "43,126,73,383,128,220\n                        Jy/K scaling for all antenna types",
    "tsys"      : "80,290,0.26\n                                  Systemp temperatures",
    "dec"       : "30.0\n         declination where object should be placed",
    "freq"      : "115.0\n        observing frequency [GHz]",
    "image"     : "casc.vla\n     model image to test ",
    "cell"      : "0.04\n         scaling cell size of model in arcsec",
    "size"      : "50.0\n         size of cleaning and plotting region (-size..size) [arcsec]",
    "nchan"     : "1\n            number of channels to use from model image",
    "method"    : "mosmem\n       mossdi, mossdi2, mosmem, joint, or default",
    "niters"    : "200\n          number of iterations in mossdi/mosmem/....",
    "flux"      : "0\n            expected flux in the image (for mosmem)",
    "gnoise"    : "0\n            Noise (percentage)",
    "nring"     : "2\n            number of rings in the mosaic",
    "grid"      : "20.0\n         gridsize (in arcsec) for the mosaic",
    "center"    : "\n             optional center file that overrides (nring,grid)",
    "plot"      : "f\n            Show plots?",
    "VERSION"   : "2.0 pjt\n      VERSION id for the user interface"
    }

help = """
The minimum amount of information you need to run this task is:
   a miriad image (image=) for the model. 
   an antenna configuration file (<config>.ant) for uvgen

   The idea is that you can combine multiple configurations

   CARMA_SZA example:
       ants=ovro,6,hatcreek,9,sza,8,carma,sza10,sza6
       jyperk=....
"""

keyini(keyval,help)
#                                report current defaults, exit if --help given
#setlogger('mosaic.log')
#
# -----------------------------------------------------------------------------

#
# define all variables, now in their proper type, for this script
#

rundir  = keya('dir')
config  = keya('config')
ants    = keyl('ants')
jyperk  = keyl('jyperk')
tsys    = keya('tsys')
dec     = keyr('dec')
cell    = keyr('cell')
size    = keyr('size')
nchan   = keyi('nchan')
method  = keya('method')
niters  = keyi('niters')
center  = keya('center')
flux    = keyr('flux')
image   = keya('image')
nring   = keyi('nring')
grid    = keyr('grid')
plot    = keyb('plot')
freq    = keyr('freq')
gnoise  = keyr('gnoise')


harange = '-2,2,0.013'
select  = '-shadow\(3.5\)'
imsize  = 257                    # avoid 2**N, image size 2**N + 1 is good.  [or calculate from image]

mir = os.environ['MIR']


def sanitize0(s):
    return s

def sanitize(s):
    """sanitize a string for unix shell access.
       (     \(
       )     \)
    """
    s0 = ""
    for i in range(len(s)):
        if s[i]=='(': 
            s0 = s0 + '\\'
        elif s[i] == ')':
            s0 = s0 + '\\'
        s0 = s0 + s[i]
    return s0


# -----------------------------------------------------------------------------

#   returns a list of strings that are the ascii centers as uvgen wants them
#   (in a file) via the center= keyword
def hex(nring,grid):
    center=""
    npoint=0
    for row in range(-nring+1,nring,1):
        y = 0.866025403 * grid * row
        lo = 2-2*nring+abs(row)
        hi = 2*nring-abs(row)-1
        for k in range(lo,hi,2):
            x = 0.5*grid*k
            npoint = npoint + 1
            if center=="":
                center = center + "%.2f,%.2f" % (x,y)
            else:
                center = center + ",%.2f,%.2f" % (x,y)
    return (npoint,center)

def check_config(file):
    f = open(file,"r")
    lines=f.readlines()
    f.close()
    n = 0
    for line in lines:
        if line[0] == '#': continue
        n = n + 1
    return n

#   get the (as a string) value of an item in a dataset
def itemize(data,item):
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

#   copy a file from source (s) to destination (d)
def copy_data(s,d):
    zap(d)
    os.system("cp -r %s %s" % (s,d))


#  should this be
#    units=None
#    if units is None:
#        bla
#    else:
#        bla

def puthd(map,item,value,units=0):
    cmd = [
        'puthd',
        'in=%s/%s' % (map,item),
        ]
    if (units == 0):
        cmd.append("value=%s" % value)
    else:
        cmd.append("value=%s,%s" % (value,units))
    return cmd

def demos(map,vis,out):
    cmd = [
        'demos',
        'map=%s' % map,
        'vis=%s' % vis,
        'out=%s' % out,
        ]
    zap_all(out+"*")
    return cmd;

def invert(vis,map,beam,imsize,select):
    cmd = [
        'invert',
        'vis=%s' % vis,
        'map=%s' % map,
        'beam=%s' % beam,
        'imsize=%d' % imsize,
        'select=%s' % select,
        'sup=0',
        'options=mosaic,double',
        ]
    zap(map)
    zap(beam)
    return cmd

def selfcal(vis):
    cmd = [
        'selfcal',
        'vis=%s' % vis,
        'options=amp'
        ]
    return cmd

def gpcopy(vis,out):
    cmd = [
        'gpcopy',
        'vis=%s' % vis,
        'out=%s' % out
        ]
    return cmd


def cgdisp(map):
    cmd = [
        'cgdisp',
        'in=%s' % map,
        'device=/xs',
        'labtyp=arcsec',
        'nxy=6,6',
        'range=0,0,lin,8'
        ]
    return cmd;

def uvmodel(vis,model,out,select):
    cmd = [
        'uvmodel',
        'vis=%s' % vis,
        'model=%s' % model,
        'out=%s' % out,
        'select=%s' % select,
        'options=add,selradec'
        ]
    zap(out)
    return cmd;

def implot(map,region='quarter'):
    cmd = [
        'implot',
        'in=' + map,
        'device=/xs',
        'units=s',
        'conflag=l',
        'conargs=1.4',
        'region=%s' % region
        ]
    return cmd

def imlist(map):
    cmd = [
        'imlist',
        'in=' + map,
        'options=mosaic'
        ]
    return cmd


def imgen(map,out,pbfwhm):
    cmd = [
        'imgen',
        'in=%s' % map,
        'out=%s' % out,
        'object=gaussian',
        'factor=0',
        'spar=1,0,0,%g,%g' % (pbfwhm,pbfwhm)
        ]
    zap(out)
    return cmd


def mosmem(map,beam,out,region,niters=100,flux=0,default=0):
    cmd = [
        'mosmem',
        'map=%s' % map,
        'beam=%s' % beam,
        'out=%s' % out,
        'region=%s' % region,
#        'rmsfac=200,1',
        'niters=%d' % niters
        ]
    if flux != 0:
        cmd.append('flux=%g' % flux)
    if default != 0:
        cmd.appenx('default=%s' % default)
    zap(out)
    return cmd

def mossdi(map,beam,out,region,niters=100):
    cmd = [
        'mossdi',
        'map=%s' % map,
        'beam=%s' % beam,
        'out=%s' % out,
        'region=%s' % region,
        'niters=%d' % niters
        ]
    zap(out)
    return cmd

def mossdi2(map,beam,out,region,niters=100):
    cmd = [
        'mossdi2',
        'map=%s' % map,
        'beam=%s' % beam,
        'out=%s' % out,
        'region=%s' % region,
        'niters=%d' % niters
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

def mospsf(beam,out):
    cmd = [
        'mospsf',
        'beam=%s' % beam, 
        'out=%s' % out
        ]
    zap(out)
    return cmd

def regrid(map,tin,out):
    cmd = [
        'regrid',
        'in=%s' % map,
        'tin=%s' % tin, 
        'out=%s' % out,
        'axes=1,2'
        ]
    zap(out)
    return cmd

def convol(map,out,b1,b2,pa):
    cmd = [
        'convol',
        'map=%s' % map,
        'out=%s' % out,
        'fwhm=%g,%g' % (b1,b2),
        'pa=%g' % pa 
        ]
    zap(out)
    return cmd

def imframe(map,out):
    cmd = [
        'imframe',
        'in=%s' % map,
        'out=%s' % out,
        'frame=-1024,1024,-1024,1024'           # TODO:: the 1024 here depends on the input image size
        ]
    zap(out)
    return cmd

def uvgen(ant,dec,harange,freq,nchan,out,center,telescop,jyperk,tsys):
    cmd = [
        'uvgen',
        'ant=%s' % ant,
        'baseunit=-3.33564',
        'radec=%s,%g' % (ra,dec),
        'lat=37.28',                            # fix observatory at CARMA....
        'ellim=10',
        'harange=%s' % harange,
        'source=$MIRCAT/no.source',
        'telescop=%s' % telescop,
        'jyperk=%g' % jyperk,
        'systemp=%s' % tsys,
        'freq=%g' % freq,
        'corr=%d,1,0,8000' % nchan,
        'out=%s' % out,
        'center=%s' % center                     # notice we don't use a file, but a string of numbers
        ]
    zap(out)                                     # need to remove it, otherwise uvgen will append
    return cmd

def uvgen_point(ant,dec,harange,freq,nchan,out,telescop,jyperk,tsys,gnoise=0):
    cmd = [
        'uvgen',
        'ant=%s' % ant,
        'baseunit=-3.33564',
        'radec=%s,%g' % (ra,dec),
        'lat=37.28',                            # fix observatory at CARMA....
        'ellim=10',
        'harange=%s' % harange,
        'source=$MIRCAT/point.source',
        'telescop=%s' % telescop,
        'jyperk=%g' % jyperk,
        'systemp=%s' % tsys,
        'freq=%g' % freq,
        'corr=%d,1,0,8000' % nchan,
        'out=%s' % out,
        'gnoise=%g' % gnoise
        ]
    zap(out)                                     # need to remove it, otherwise uvgen will append
    return cmd

def uvindex(vis):
    cmd = [
        'uvindex',
        'vis=%s' % vis
        ]
    return cmd

def imdiff(in1,in2,resid):
    cmd = [
        'imdiff',
        'in1=%s' % in1,
        'in2=%s' % in2,
        'resid=%s' % resid,
        'options=nox,noy,noex'
        ]
    zap(resid)
    return cmd

def histo(map,region):
    cmd = [
        'histo',
        'in=%s' % map,
        'region=%s' % region
        ]
    return cmd

def error(msg):
    print msg
    sys.exit(1)

def antspecs(nants):
    """for a given list of ants, return some other useful lists
    """
    iants=range(len(nants))
    n = 1
    for i in range(len(nants)):
        iants[i] = range(n,n+nants[i])
        n = n + nants[i]

    antselect_k = []

    # create strings
    aa=range(len(nants))
    for i in range(len(nants)):
        num = iants[i]
        a = ""
        for j in num:
            if len(a)==0:
                a="%d" % j
            else:
                a = a + ",%d" % j
        aa[i] = a

    bb=[]
    for j in range(len(nants)):
        bb.append('ant\(%s\)\(%s\)' % (aa[j],aa[j]))

    for j in range(len(nants)):
        for i in range(len(nants)):
            if i < j: 
                bb.append('ant\(%s\)\(%s\)' % (aa[i],aa[j]))

    return bb


# ================================================================================
#
#   start of the actual script
# -----------------------------------------------------------------------------
# Nyquist sample rate for each pointing.
# calc '6/(pi*250)*12'
#cells  = 500*cell
#region = "arcsec,box\(%.2f,-%.2f,-%.2f,%.2f\)" % (cells,cells,cells,cells)
region = "arcsec,box\(%.2f,-%.2f,-%.2f,%.2f\)" % (size,size,size,size)

ant    = config + '.ant'                   # antenna file for uvgen
print 'Found %s antenna in %s' % (check_config(ant),ant)


uv     = "%s/uv"       % rundir 
demos1 = "%s/%s.demos"  % (rundir,config)
base1  = "%s/%s"        % (rundir,config)
base2  = "%s/single"    % (rundir)

map1   = base1 + ".mp"
beam1  = base1 + ".bm"
psf1   = base1 + ".psf"
map2   = base2 + ".map"
beam2  = base2 + ".beam"
mem    = base1 + ".mem"     # used for both sdi and mem
cm     = base1 + ".cm"
mp     = base1 + '.mp'
res    = base1 + '.resid'
conv   = base1 + '.conv'


# supporting the following 3 configurations (T=antenna type, N=number of ants in this type)
#   ants=T1[,N1]                                      (use N1 if you want to use first N1)
#   ants=T1,N1,T2,N2,T12
#   ants=T1,N1,T2,N2,T3,N3,T12,T13,T23                (called m1 entries below)
# Following these
#   jyperk=
# needs N*(N+1)/2 values (N= #types [1,2, or 3])      (called k1 entries below)

telescopes = []
nants      = [0]

m1 = len(ants)

if m1 == 1 or m1 == 2:
    ntypes = 1
    k1     = 1
elif m1 == 5:
    ntypes = 2
    k1     = 3
elif m1 == 9:
    ntypes = 3
    k1     = 6
else:
    error("error ants= (%d); can handle up to 3 different types T1,N1,T2,N2,T3,N3,T12,T13,T23 " % m1)


telescopes.append(ants[0])
if m1 == 1:
    nants[0] = check_config(ant)
else:
    nants[0] = int(ants[1])
if m1>2:
    telescopes.append(ants[2])
    nants.append(int(ants[3]))
    telescopes.append(ants[4])
    if m1>5:
        nants.append(int(ants[5]))
        telescopes.append(ants[6])
        telescopes.append(ants[7])
        telescopes.append(ants[8])
telescope = ants[0]
print 'Telescopes: ',telescopes


antselect_k = antspecs(nants)


if len(jyperk) != k1:
    print "jyperk: %s" % jyperk
    print "Bad number of jyperk=%s " % jyperk
    sys.exit(1)
else:
    tmp = jyperk
    jyperk = []
    for t in tmp:
        jyperk.append(float(t))
    print 'Jy/K:',jyperk



if center == "":
    (npoint,center) = hex(nring,grid)
    print "MOSAIC FIELD, using hexagonal field with nring=%d and grid=%g (%d pointings) " % (nring,grid,npoint)
else:
    centerfile = center
    f = open(centerfile,"r")
    center=f.read()
    f.close()
    npoint = len(string.split(center,","))-1
    center=string.replace(center,'\n',',')
    print "MOSAIC FIELD, using center file %s (%d pointings) " % (centerfile,npoint)

print "   ---  CARMA Mosaicing (Cas A model)   ---   "

print " config  = %s" % config
print " ants    = %s" % ants
print " dec     = %g" % dec
print " scale   = %g" % cell
print " harange = %s  hours" % harange
print " select  = %s" % select
print " freq    = %g" % freq
print " nchan   = %d" % nchan
print " imsize  = %d" % imsize
print " region  = %s" % region
print " method  = %s" % method
print " " 
print "   ---  TIMING   ---   "  


#   might need to fix this to the real RA ?
ra = '23:23:25.80'      

#  create indexed filenames the antenna type; ensure they are in the rundir
uv_k        = []
demos_k     = []
for k in range(0,k1):
    uv_k.append('%s_%d' %  (uv,k))
    demos_k.append('%s_%d_demos' %  (uv,k))


#================================================================================

# start of code

os.system('mkdir -p %s' %  rundir)              # create the run directory

setlogger(rundir+'/miriad.log',1)               # output in logfile in run directory (append)


if method == "mosmem":
    print "Generate mosaic grid"
    #  lambda/2*antdiam (arcsec)
    print "NYQUIST: ",300/freq/2/12e3*2e5

    print "Generate uv-data. Tsys=40K, bandwidth=8 GHz " 


    for k in range(0,k1):
        miriad(uvgen(ant,dec,harange,freq,nchan,uv_k[k],center,telescopes[k],jyperk[k],tsys))
        miriad(uvindex(uv_k[k]))
    
    print "Scale model size from pixel 0.4 to %g arcsec" % cell
    # with 0.4 arcsec pixel size Cas A is about 320 arcsec diameter; image size 1024 == 409.6 arcsec
    # scale model size. eg. cell=0.1 arcsec -> 80 arcsec cell=.01 -> 8 arcsec diameter

    copy_data(image,base2)

    miriad(puthd(base2,'crval1',ra,units='hms'))
    miriad(puthd(base2,'crval2',dec,units='dms'))
    miriad(puthd(base2,'crval3',freq))
    miriad(puthd(base2,'cdelt1',-cell,units='arcsec'))
    miriad(puthd(base2,'cdelt2',cell,units='arcsec'))

    flux = string.atof(grepcmd('histo in=%s' % base2, 'Flux', 5))
    print 'Flux=',flux

    print "Make model images for each pointing center for each antenna type"
    for k in range(0,k1):
        miriad(demos(base2,uv_k[k],demos_k[k]))

    print "Make model uv-data using %s as a model" % image
    vis_all = ""
    for k in range(0,k1):
        for i in range(1,npoint+1):
            if plot: miriad(cgdisp(demos1+"%d"%i))    ###fix name
            vis_i = "%s_%d_%d"% (uv,i,k)
            demos_i = demos_k[k]+"%d"%i
            miriad(uvmodel(uv_k[k],demos_i,vis_i,antselect_k[k]))
            if len(vis_all)==0:
                vis_all=vis_i
            else:
                vis_all=vis_all + ',' + vis_i
    print "UVMODEL: add the model to the noisy sampled uv-data"

    if gnoise > 0:
        print "Adding pointing errors: gnoise=%g" % gnoise
        visgain = 'gains.uv'
        for k in range(0,k1):
            miriad(uvgen_point(ant,dec,harange,freq,nchan,visgain,telescopes[k],jyperk[k],tsys,gnoise))
            miriad(selfcal(visgain))
            for i in range(1,npoint+1):
                vis_i = "%s_%d_%d"% (uv,i,k)
                miriad(gpcopy(visgain,vis_i))
    else:
        print "Skipping adding pointing noise (gnoise)"
            
    miriad(invert(vis_all, base1+".mp", base1+".bm", imsize, select))
            
    print "INVERT: "
        
    if plot: miriad(implot(base1+'.mp',region=region))
    miriad(imlist(base1+'.mp'))
            
    print "Make single dish image and beam"

    s1 = grepcmd("pbplot telescop=%s freq=%g" % (telescope,freq), "FWHM", 2)
    pbfwhm = string.atof(s1) * 60.0

    print "Single dish FWHM = %g arcsec at %g GHz for telescope=%s" % (pbfwhm,freq,telescope)

    miriad(imframe(base2,base2+".bigger"))
    miriad(convol(base2+".bigger",base2+".bigger.map",pbfwhm,pbfwhm,0.0))
    miriad(regrid(base2+".bigger.map",base1+'.mp',base2+".map"))
    miriad(imgen(base2+".map",base2+".beam",pbfwhm))
    
    # odd, for cube this one was all blank
    #miriad(implot(base2+".map"))


    #miriad(puthd(base2+".map",'rms','7.32'))            #  is that 1/100 of the flux ???
    miriad(puthd(base2+".map",'rms','%s' % (flux/100)))

        
if method=='mosmem':
    print "MOSMEM Interferometer only - no flux given" 
    miriad(mosmem(map1,beam1,mem,region,niters=niters))
elif method=='joint':
    print "Joint deconvolution of interferometer and single dish data"
    print "Joint deconvolution of interferometer and single dish data ; niters=200 rmsfac=200,1"
    miriad(mosmem(map1+','+map2,beam1+','+beam2,mem,region,niters=niters))
elif method=='default':
    print "MOSMEM with default single dish image" 
    print "MOSMEM with default single dish image; niters=200 rmsfac=200" 
    miriad(mosmem(map1,beam1,mem,region,niters=niters))
elif method=='mossdi':
    miriad(mossdi(map1,beam1,mem,region,niters=niters))
elif method=='mossdi2':
    miriad(mossdi2(map1,beam1,mem,region,niters=niters))
else:
    print "Unknown method " + method
    sys.exit(1)


print "MOSPSF determines a more realistic value for the PSF of linear mosaic"
miriad(mospsf(beam1,psf1))
bmaj = string.atof(grepcmd('imfit in=%s object=beam' % psf1, 'Major axis (arcsec)', 3))
bmin = string.atof(grepcmd('imfit in=%s object=beam' % psf1, 'Minor axis (arcsec)', 3))
bpa  = string.atof(grepcmd('imfit in=%s object=beam' % psf1, '  Position angle',    3)) 
print 'MOSPSF: Beam = %g x %g arcsec PA = %g degrees' % (bmaj,bmin,bpa)

miriad(restor(map1,beam1,mem,cm))
if plot: miriad(implot(map1,region=region))

print "convolve the model by the beam and subtract from the deconvolved image"
b1 = string.atof(grepcmd('prthd in=%s' % cm, 'Beam', 2))
b2 = string.atof(grepcmd('prthd in=%s' % cm, 'Beam', 4))
b3 = string.atof(grepcmd('prthd in=%s' % cm, 'Position', 2)) 

miriad(convol(base2,base1+'.conv',b1,b2,b3))
if plot: miriad(implot(base1+'.conv',region=region))

print "regrid the convolved model to the deconvolved image template"

miriad(regrid(base1+".conv",base1+".cm",base1+'.regrid'))
if plot: miriad(implot(base1+'.regrid',region=region))

#  skipping cgdisp /gif production

miriad(imdiff(base1+'.cm',base1+'.regrid',base1+'.resid'))
if plot: miriad(implot(base1+'.resid',region=region))
miriad(histo(base1+'.resid',region=region))

# ================================================================================

print "print out results - summarize rms and beam sidelobe levels"
print "   ---  RESULTS   ---   "

#   extract information, the hard way

#   BUG: doesn't look like 'mp' has rms???
#rms    = string.atof(itemize(mp,'rms')) * 1000
rms = -1
srms   = string.atof(grepcmd('histo in=%s' % res, 'Rms', 3)) 
smax   = string.atof(grepcmd('histo in=%s' % res, 'Maximum', 2))
smin   = string.atof(grepcmd('histo in=%s' % res, 'Minimum', 2))
Model_Flux = string.atof(grepcmd('histo in=%s region=%s' % (conv,region),'Flux',5))
Model_Peak = string.atof(grepcmd('histo in=%s region=%s' % (conv,region),'Maximum',2))
Flux       = string.atof(grepcmd('histo in=%s region=%s' % (cm,region),'Flux',5))
Peak       = string.atof(grepcmd('histo in=%s region=%s' % (cm,region),'Maximum',2))
Fidelity   = Peak/srms 

print " Config  DEC  HA[hrs]    Beam[arcsec] scale Model_Flux,Peak  Image_Flux,Peak Residual:Rms,Max,Min[Jy] Fidelity"
print " %s %g %s %.3f %g %g %g %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f" % (config,dec,harange,rms,b1,b2,
                                                              cell,Model_Flux,Model_Peak,Flux,Peak,srms,smax,smin,Fidelity)

sys.exit(0)

#mv timing hex19.$config.$dec.$harange.$nchan.$imsize
#cat $config.$dec.$harange.$nchan.$imsize
#cat casa.results
#enscript -r casa.results

#print "DEBUGGING"
#string.atof(itemize(mp,'rms'))
#!/usr/bin/env python
#
###import sys, os, time, string, math
###from Miriad import *

# mchw 12jun02 - Single Field Imaging
# mchw 09aug02 - version for CARMA
# mchw 14aug02 - reduce size of region in imfit which was including sidelobes in relpix +/- 10
# mchw 20aug02 - hetero.csh This script assumes that the first 6 antennas are OVRO and the next 9 are hatcreek
# mchw 26sep02 - decrease Nyquist sample interval for 2 km configuration.
# mchw 25feb03 - version for ACA with 4 12m and 12 7m antennas.
# pjt  17mar03 - pyramized

# Nyquist sample time = 12 x (dish_diam/2)/(pi*baseline)
# calc '12*(12/2)/(pi*2000)' = 0.01 hours = 36 sec.
# calc '12*(7/2)/(pi*1150)'  = 0.01 hours = 36 sec.


# IDEAS to expand:  in uvgen: systemp, jyperk(3), lat(itude), telescop(2)
#   I cheat since 12/10.4 m == 7/6.1 m == 230/200 GHz
#   (telescop name is used in pb to get primary beam type.
#   It should be possible to use gauss(pbfwhm) as pbtype,
# in uvcat: selectant(3)

# output should look as follows in default (config1,-30) run:
# Config  DEC  HA[hrs]  Rms[\muJy]  Beam[arcsec]  Tb_rms[\muK]  Sidelobe[%]:Rms,Max,Min  Nvis[%] uvrange[m]

# CSH config1   -30   -4,4,.1   14  1.88 x 1.57  110  0.6  4.4  -2.4  100 129114 9 159
# PY  config1   -30   -4,4,0.1  14  1.88 x 1.57  108  1    4.4  -2.4  100 129114 9 159


