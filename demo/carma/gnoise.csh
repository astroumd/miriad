#!/bin/csh -vf

echo "  ---  RESULTS WITH GAIN NOISE  08 Sept 2005  --- " >> casc.vla.results

goto start
start:

hex7-15.csh   E 22 .1  5
joint7-15.csh E 22 .1  5

hex7-15.csh   E 22 .05 5
joint7-15.csh E 22 .05 5

hex7-15.csh   D 22 .05 5
joint7-15.csh D 22 .05 5

hex7-15.csh   E 22 .1  10
joint7-15.csh E 22 .1  10

hex7-15.csh   E 22 .05 10
joint7-15.csh E 22 .05 10

hex7-15.csh   D 22 .05 10
joint7-15.csh D 22 .05 10


hex7-15.csh   E 22 .1  15
joint7-15.csh E 22 .1  15

hex7-15.csh   E 22 .05 15
joint7-15.csh E 22 .05 15

hex7-15.csh   D 22 .05 15
joint7-15.csh D 22 .05 15

end:
