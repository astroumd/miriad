#!/bin/csh -vf


echo "PLOT BEAM SHAPE RESIDUAL AFTER GAUSSIAN FIT"

# History
#  14dec02  mchw

 inputs
  if($#argv<1) then
    echo " Usage: Residual.csh    declination"
    echo "   declination"
    echo "          Source declination in degrees. No default."
    exit 1
  endif

 set dec = $1

 foreach i ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )

rm -r residual
imfit in=config$i.$dec.bm object=gauss 'region=relpix,box(-25,-25,25,25)' out=residual options=residual
implot in=residual device=/xs units=s conflag=an conargs=0.025 'region=relpix,box(-15,-15,15,15)'

 end
