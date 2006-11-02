#!/bin/csh -vf

set start=1
set end=29
set tmp=tmp$$.awk

goto start

foreach i (`echo $start $end | awk '{for (i=$1; i<=$2; i++) print i}'`)
  set n=`expr $i + 4`
  echo '{if($'$n'==1) printf("%.1f  %.1f  %.1f\n", $3+10*(rand()-0.5), $2+10*(rand()-0.5), $4+10*(rand()-0.5))}' > $tmp
  nawk -f $tmp conway.configs > random$i.ant
end
rm $tmp

start:

set dec = -30
set nchan = 1
foreach i (`echo $start $end | awk '{for (i=$1; i<=$2; i++) print i}'`)
  mfs.csh random$i $dec $nchan
end
rm $tmp

end:
