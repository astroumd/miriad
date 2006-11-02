#!/bin/csh

echo ALMA DATA PROCESSING 
echo This script give some examples of data reduction for ALMA data using MIRIAD

#History:
# 18nov02  catenate some examples for multichannel, mfs and mosaic imaging.

goto 0

0:
echo make single channel maps and beams for all 29 configurations for dec=-30
set dec = -30
foreach i ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
  mfs.csh config$i $dec 1
end

echo plot central beam patch for all 29 configurations for dec=-30
set dec = -30
foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
  set config = config$i
  set region = 'relpix,box(-10,-10,10,10)'
  implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.4 region=$region
end


1:
echo 4km configuration MFS imaging
mfs.csh config29 -30 10


2:
echo compact configuration - small maps with 10 and 100 channels
multichan.csh config1 -30 10
multichan.csh config1 15 100


3:
echo 4km  configuration - large maps with 10 channels
echo " Warning: it is faster to image large maps with a few channels at a time."
multichan.csh config29 -30 10


4:
echo small mosaic with 3 different MEM deconvolutions 
hex7.csh    config1 30 0.04
default.csh config1 30 0.04
joint.csh   config1 30 0.04


5:
echo larger mosaic with 3 different MEM deconvolutions 
hex19.csh   config1 0 0.05
default.csh config1 0 0.05
joint.csh   config1 0 0.05


6:
echo MOSMEM FOR 5 CONFIGURATIONS >> casa.results
oecho "   ---  TIMING   ---   "       >> casa.results
echo START: `date` >> casa.results

foreach i ( 1 2 3 4 5 )
  foreach dec ( 30 0 -30 )
    hex19.csh   config$i $dec 0.05
    default.csh config$i $dec 0.05
    joint.csh   config$i $dec 0.05
  end
end
echo END: `date` >> casa.results


7:

# These scripts do not re-generate the uv-data, which was generated for #6 above.

echo "ADD NOISE TO SINGLE DISH FOR MOSMEM IN 5 CONFIGURATIONS"  >> casa.results
echo "   ---  TIMING   ---   "       >> casa.results
echo START: `date` >> casa.results

foreach rms ( 1 2 4 )
  foreach i ( 1 2 3 4 5 )
    foreach dec ( 30 0 -30 )
      hex19_noise.csh   config$i $dec 0.05 $rms
      default_noise.csh config$i $dec 0.05 $rms
      joint_noise.csh   config$i $dec 0.05 $rms
    end
  end
end
echo END: `date` >> casa.results

goto end

end:
