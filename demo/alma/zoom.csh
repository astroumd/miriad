#!/bin/csh

# mchw 12dec02

echo zoom through beams

# check inputs
  if($#argv<1) then
    echo " Usage: zoom.csh  declination"
    echo "   declination"
    echo "          Source declination in degrees. No default."
    exit 1
  endif

set dec = $1
foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
  set config = config$i
  implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.4 region=quarter
end

