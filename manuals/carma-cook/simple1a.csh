#! /bin/csh -f
#
# extracted from c0319.1D_86GCRing.5.mir, originally observed at CARMA on 20 March 2009.
# PI: Marc Pound and Farhad Yusef-Zadeh.
#
#
# this script works mostly with one visibility file, and uses select= to work on selected data
#
# sources: 
# --------
# MWC349     flux (ignored here)
# 3C345      passband
# 1733-130   phase
# GCRING     source


# administration: getting the data

set tar=../SgrA.mir.tar.gz
tar -zxf $tar
# set vis=$tar:t:r:r
set vis=SgrA.mir

# set an antpos file for baseline correction: two are available 090225 and 090331
set antpos=$MIRCAT/baselines/carma/antpos.090331 

# source names (we use the PURPOSE code from listobs: S, B, G)
set sname=GCRING
set bname=3C345
set gname=1733-130

# reference ants
set bref=2
set pref=2

# work can start -------------------------------------------------------------------------

# get a listing of what happened
listobs vis=$vis log=listobs.log

# select out only the useful astronomical data 
rm -rf all.vis
uvcat vis=$vis  select='-source(NOISE),-auto' out=all.vis

# notice ant 1 has some issue
# smauvplt vis=all.vis device=/xs axis=time,phase options=nocal,nopass
uvflag vis=all.vis flagval=flag select="ant(1)"

# baseline calibration
rm -rf all_1.vis
uvedit vis=all.vis    out=all_1.vis apfile=$antpos

# linelength calibration
rm -rf all_2.vis
linecal vis=all_1.vis 
#gpplt vis=all_1.vis yaxis=phase nxy=5,3 device=/xs options=wrap
uvcat   vis=all_1.vis out=all_2.vis

# smauvplt vis=all_2.vis device=/xs axis=time,phase options=nocal,nopass

# bandpass calibration
rm -rf all_3.vis 
mfcal vis=all_2.vis refant=$bref select="source($bname)" interval=999
#gpplt vis=all_2.vis yaxis=phase nxy=5,3 device=/xs options=bandpass
#gpplt vis=all_2.vis yaxis=amp   nxy=5,3 device=/xs options=bandpass
uvcat vis=all_2.vis out=all_3.vis options=nocal


# gain calibration, looking quite nice now
rm -rf all_4.vis 
mselfcal vis=all_3.vis refant=$pref select="source($gname)" options=amp,apriori,noscale interval=5

#gpplt vis=all_3.vis yaxis=phase nxy=5,3 device=/xs options=gains
#gpplt vis=all_3.vis yaxis=amp   nxy=5,3 device=/xs options=gains

puthd in=all_3.vis/interval value=0.1
uvcat vis=all_3.vis out=all_4.vis 

# should check flagged values in all_3 and all_4 and they should be the same
# if the new interval is long enough to catch all inter- and extra-polations

# map the calibrator

rm -rf beam0 map0  model0 clean0
invert vis=all_4.vis map=map0 beam=beam0 imsize=128 line=wide,1,1,2,2 select="source($gname)"
clean map=map0 beam=beam0 out=model0
restor map=map0 beam=beam0 model=model0 out=clean0

# map the source

rm -rf beam1 map1 model1 clean1
invert vis=all_4.vis map=map1 beam=beam1 line=wide,1,1,2,2 "select=source($sname)" options=mosaic,double,systemp imsize=129
mossdi map=map1 beam=beam1 out=model1
restor map=map1 beam=beam1 model=model1 out=clean1
