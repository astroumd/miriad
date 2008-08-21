#!/bin/csh -vf

goto start

start:

foreach dec ( 30 0 -30 )
  foreach config ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
    mfs.csh config$config $dec -1,1,.1 1
  end
end
goto end

foreach i ( 1 2 3 4 5 )
  uvcheck vis=config$i.-30.uv options=hist var=uvdist log=config$i.-30.uvdist
end

end:
