#!/bin/csh -vf


echo "PLOT BEAM SHAPE RESIDUAL AFTER GAUSSIAN FIT" >> beam_shape.results

#echo " 1)  NATURAL WEIGHTING" >> beam_shape.results
#echo " 2)  NATURAL WEIGHTING ;  missing antennas 10,20,30 " >> beam_shape.results
echo " 3)  NATURAL WEIGHTING ;  missing antennas 11,12,13,14,15,16 " >> beam_shape.results


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

residual.csh config$i $dec 1

 end
