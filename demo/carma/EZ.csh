#!/bin/csh -vf

echo EZ.csh

#echo "Compare E and EZ30S" >>  casa.results

echo " "      >> casa.results
echo "Increase image size to 257" >>  casa.results
echo "july 8" >> casa.results
echo " " >> casa.results
# mchw july 2004

set CONFIG = EZ30S
set CONFIG = DZ

foreach DEC (-15 30)
 foreach SIZE (.05 .1)
  echo " " >>  casa.results
  hex7.csh    $CONFIG  $DEC $SIZE
  default.csh $CONFIG $DEC $SIZE
  joint.csh   $CONFIG  $DEC $SIZE
  cgdisp device=/xs in=$CONFIG.$DEC.cas.$SIZE.cm
 end
end

end:
