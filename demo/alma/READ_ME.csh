#!/bin/csh

echo ALMA DATA PROCESSING 
echo This script give some examples of data reduction for ALMA data using MIRIAD

#History:
# 18nov02  catenate some examples for multichannel, mfs and mosaic imaging.
# 18sep09  revised multichan.csh input parameters
# 13jul10  revised mfs.csh input parameters


goto 0

goto start
0:
echo make single channel maps and beams for all 29 configurations for dec=-30
set dec = -30
#foreach i ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
foreach i (1 3 5 7 9 11 13 15 17 19)
  mfs.csh config$i $dec -.5,.5,.1 1 robust=.5 '-shadow(12)'
end

01:
echo plot central beam patch for all 29 configurations for dec=-30
set dec = -30
foreach i (1 3 5 7 9 11 13 15 17 19)
#foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
  set config = config$i
  set region = 'relpix,box(-20,-20,20,20)'
  implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.4 region=$region
end

02:
echo plot central beam patch for all 29 configurations for dec=-30
set dec = -30
foreach i (1 3 5 7 9 11 13 15 17 19)
  set config = config$i
  set region = 'arcsec,box(-10,-10,10,10)'
  implot in=$config.$dec.cm device=/xs units=s conflag=l conargs=1.4 region=$region
end


start:

03:
echo "Show central hole"
uvplt device=/xs vis=config1.-30.uv axis=uc,vc options=nobase,equal


goto 5

goto end


1:
echo 4km configuration MFS imaging
mfs.csh config29 -30 -1,1,.1 10 robust=.5 '-shadow(12)'


2:
echo compact configuration - small maps with 10 and 100 channels
multichan.csh config1 -30 -1,1,.1 10 sup=0
multichan.csh config1 15  -1,1,.1 100 sup=0


3:
echo 4km  configuration - large maps with 10 channels
echo " Warning: it is faster to image large maps with a few channels at a time."
multichan.csh config29 -30 -1,1,.1 10 sup=0


4:
echo small mosaic with 3 different MEM deconvolutions 
hex7_demo.csh


5:
echo larger mosaic with 3 different MEM deconvolutions 
hex19_demo.csh


end:
