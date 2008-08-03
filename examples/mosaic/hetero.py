#!/usr/bin/env python
#
import sys, os, time, string, math
from Miriad import *

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



print "   ---  ACA Heterogenous Array Beams  ---   "
print "   This script assumes that the first 4 antennas are ALMA 12m and the next 12 are ACA 7m antennas"

# command line arguments that can be changed...
keyval = {
  "config"  : "config1\n    antenna config file (without the .ant extension)",
  "dec"     : "-30.0\n      declination (can be a real number)",
  "dt"      : "0.01\n       integration time step in hours (range is fixed -4 .. 4)",
  "plot"    : "1\n,         1=make plots   0=no plots",
  "VERSION" : "1.1 mchw\n   VERSION id for the user interface"
  }

help = """
   this script does heterogeneous array simulations. Mel will at some point
   describe this more in a Memo.
"""
keyini(keyval,help,0)
setlogger('hetero.log')


# set parameters

config  = keya('config')
dec     = keyr('dec')
plot    = keyi('plot')
dt      = keyr('dt')
harange = '-4,4,%g' % dt
ellim   = 10
select  = '-shadow\(7\)'
freq    = 230
nchan   = 1
imsize  = 256
region  =  'relpix,box\(-30,-30,30,30\)'

#print "   ---  CARMA Single Field Imaging    ---   " > timing
#print " config           = $config"             >> timing
#print " declination      = $dec"                >> timing
#print " Hour Angle range = $harange  hours"     >> timing
#print " Elevation limit  = $ellim  degrees. "   >> timing
#print " select           = $select"             >> timing
#print " frequency        = $freq"               >> timing
#print " nchan            = $nchan"              >> timing
#print " imsize           = $imsize"             >> timing
#print " " >> timing
#print "   ---  TIMING   ---   "        >> timing
#print "START: `date`" >> timing



# --------------------------------------------------------------------------------

def uvgen(ant,dec,harange,freq,nchan,telescope,jyperk,out):
  cmd = [
    'uvgen',
    'ant=%s' % ant,
    'baseunit=-3.33564',
    'radec=23:23:25.803,%g' % dec,
    'lat=-23.02',
    'harange=%s' % harange,
    'source=$MIRCAT/no.source',
    'systemp=40,290,0.08',
    'jyperk=%g' % jyperk,
    'telescop=%s' % telescope,
    'freq=%g' % freq,
    'corr=%d,1,0,8000' % nchan,
    'out=%s' % out,
    ]
  zap(out)
  return cmd

def uvcat(vis,out,select):
  cmd = [
    'uvcat',
    'vis=%s' % vis,
    'out=%s' % out,
    'select=%s' % select
    ]
  zap(out)
  return cmd;

def uvplt(vis,select,device):
  cmd = [
    'uvplt',
    'vis=%s' % vis,
    'device=%s' % device,
    'select=%s' % select,
    'options=nobase,equal',
    'axis=uc,vc'
    ]
  return cmd;


def invert(vis,map,beam,imsize,select):
  cmd = [
    'invert',
    'vis=%s' % vis,
    'map=%s' % map,
    'beam=%s' % beam,
    'imsize=%d' % imsize,
    'sup=0',
    'options=systemp',
    'select=%s' % select
    ]
  zap(map)
  zap(beam)
  return cmd

def implot(map,region=0):
  cmd = [
    'implot',
    'in=%s' % map,
    'device=/xs',
    'units=s',
    'conflag=an',
    'conargs=0.05'
    ]
  if region != 0:
    cmd.append('region=%s' % region)
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


def imfit(map,out,size=7):
  cmd = [
    'imfit',
    'in=%s' % map,
    'object=gauss',
    'region=relpix,box\(-%d,-%d,%d,%d\)' % (size,size,size,size),
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


# --------------------------------------------------------------------------------

print "generate uv-data"
# assume aperture efficiency 60% to get jyperk, 40 and 120 for 12 and 7m antennas, sqrt = 70 for 12x7
#print "Generate uv-data. Tsys=40K, bandwidth=8 GHz " >> timing


uv1='calm.uv'
uv2='alma.uv'
uv3='aca.uv'
ant = '%s.ant' % config
vis1='calm.%g.uv' % dec
vis2='alma.%g.uv' % dec
vis3='aca.%g.uv' % dec

mp='%s.ant.%g.mp' % (config,dec)
bm='%s.ant.%g.bm' % (config,dec)
cl='%s.ant.%g.cl' % (config,dec)
cm='%s.ant.%g.cm' % (config,dec)

miriad(uvgen(ant,dec,harange,freq,nchan,'carma',70, uv1))
miriad(uvgen(ant,dec,harange,freq,nchan,'ovro', 40, uv2))
miriad(uvgen(ant,dec,harange,freq,nchan,'hatcreek',120, uv3))

#print "UVGEN: `date`">> timing

# select data for heterogenous array

miriad(uvcat(uv1,vis1,'ant\(1,2,3,4\)\(5,6,7,8,9,10,11,12,13,14,15,16\)'))
miriad(uvcat(uv2,vis2,'ant\(1,2,3,4\)\(1,2,3,4\)'))
miriad(uvcat(uv3,vis3,'-ant\(1,2,3,4\)'))

if plot:
  miriad(uvplt(vis1+','+vis2+','+vis3,select,'/xs'))
  miriad(uvplt(vis1+','+vis2+','+vis3,select,'%s.%g.%s.cps/cps' % (config,dec,select)))

print "image"
# natural weight

miriad(invert(vis1+','+vis2+','+vis3,mp,bm,imsize,select), log='invert.log')


#print  "INVERT: `date`" >> timing

print "plotting"

if plot:
  miriad(implot(bm))
  miriad(implot(bm,region=region))


#print IMPLOT: `date` >> timing

print "deconvolve"


miriad(clean(mp,bm,cl))

#print CLEAN: `date` >> timing

miriad(restor(mp,bm,cl,cm))

#print IMFIT: `date` >> timing

print "fit beam and get residual sidelobe levels"


res='residual'

miriad(imfit(bm,res))

miriad(histo(res))

#print FINISH: `date` >> timing
#print " " >> timing

print "print out results - summarize rms and beam sidelobe levels"
#print "   ---  RESULTS   ---   " >> timing
rms    = string.atof(itemize1(mp,'rms')) * 1e6
bmaj   = string.atof(grepcmd('prthd in=%s' % cm, 'Beam', 2))
bmin   = string.atof(grepcmd('prthd in=%s' % cm, 'Beam', 4))
srms   = string.atof(grepcmd('histo in=%s' % res, 'Rms', 3)) * 100
smax   = string.atof(grepcmd('histo in=%s' % res, 'Maximum', 2)) * 100
smin   = string.atof(grepcmd('histo in=%s' % res, 'Minimum', 2)) * 100
nvis   = string.atoi(greplog('invert.log','Visibilities',2))

pi     = math.pi
log2   = math.log(2)
tbrms  = rms*0.3/freq*0.3/freq/2/1.38e3/(pi/(4*log2)*bmaj*bmin/4.25e10)

# get number of visibilities written and number unshadowed

ncalm  = string.atoi(grepcmd('uvindex vis=%s' % vis1, 'There', 2))
nalma  = string.atoi(grepcmd('uvindex vis=%s' % vis2, 'There', 2))
naca   = string.atoi(grepcmd('uvindex vis=%s' % vis3, 'There', 2))

records = ncalm+nalma+naca

nvis/records

Nvis = 100*nvis/records

# uvrange = `uvcheck vis=calm.uv    | awk '{if(NR==6)print 0.3*$6, 0.3*$7}'`
uvmin = string.atof(grepcmd('uvcheck vis=%s' % uv1, 'records=', 5)) * 0.3
uvmax = string.atof(string.replace(grepcmd('uvcheck vis=%s' % uv1,'records=', 6),')',' ')) * 0.3

print " "
#>> timing

print " Config  DEC  HA[hrs]  Rms[\muJy]  Beam[arcsec]  Tb_rms[\muK]  Sidelobe[%]:Rms,Max,Min  Nvis[%] uvrange[m]"

#>> timing

print " %s %g %s  %.0f  %.2f  %.2f  %.0f %1.f %.1f %.1f %d %g %g" % (config,dec,harange,rms,bmaj,bmin,tbrms,srms,smax,smin,nvis,uvmin,uvmax)


#>> timing

print " "
print " %s %g %s  %.0f  %.2f x %.2f  %.0f %1.f %.1f %.1f %d %d %g %g" % (config,dec,harange,rms,bmaj,bmin,tbrms,srms,smax,smin,Nvis,nvis,uvmin,uvmax)

#>> beams.results

#mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
#cat $config.$dec.$harange.$nchan.$imsize.$nvis
#tail beams.results

