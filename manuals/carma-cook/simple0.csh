#! /bin/csh -f
#
#
#   A super simple example of miriad mapping stages
#   and how data is improved as you add more proper
#   calibration steps. 
#
#   This is a simple example from a fringe test, the
#   standard one in the CARMA cookbook data archive
#


# administration: getting the data

set tar=../fringe.3C273.2008jun18.4.miriad.tar.gz
tar zxf $tar
#set vis=$tar:t:r:r
set vis=fringe.3C273.2008jun18.4.miriad


# get a listing of what happened
listobs vis=$vis log=listobs.log

# select out only the data (cut out the NOISE source and auto correlations
# leaving only the cross correlations)
uvcat vis=$vis  select='-source(NOISE),-auto' out=all.vis

# first attempt to map the data
invert vis=all.vis map=map0 beam=beam0 line=wide,1,1,6,6

# line length calibration
# another try to map it, pretty bad
linecal vis=all.vis
uvcat vis=all.vis out=all_1.vis
invert vis=all_1.vis map=map1 beam=beam1 line=wide,1,1,6,6

# bandpass calibration, looking better
rm -rf all_2.vis map2 beam2
mfcal vis=all_1.vis refant=1
uvcat vis=all_1.vis out=all_2.vis options=nocal
invert vis=all_2.vis map=map2 beam=beam2 line=wide,1,1,6,6

# gain calibration, looking quite nice now
rm -rf all_3.vis map3 beam3
selfcal vis=all_2.vis refant=1
uvcat vis=all_2.vis out=all_3.vis 
invert vis=all_3.vis map=map3 beam=beam3 line=wide,1,1,6,6


# make a cute 2x2 panel showing the 4 maps
rm -rf map.all
imcat in=map0,map1,map2,map3 out=map.all
cgdisp in=map.all device=simple0.ps/vps nxy=2,2 type=g range=-0.5,10
